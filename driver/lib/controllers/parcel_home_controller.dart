import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:driver/app/wallet_screen/payment_list_screen.dart';
import 'package:driver/constant/collection_name.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/send_notification.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/models/parcel_order_model.dart';
import 'package:driver/models/user_model.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:get/get.dart';

class ParcelHomeController extends GetxController {
  StreamSubscription? _driverSubscription;
  StreamSubscription? _ownerSubscription;

  RxList<ParcelOrderModel> parcelOrdersList = <ParcelOrderModel>[].obs;
  RxBool isLoading = true.obs;
  Rx<Map<String, dynamic>?> pendingParcelRequest = Rx<Map<String, dynamic>?>(null);

  @override
  void onInit() {
    // TODO: implement onInit
    getParcelList();
    super.onInit();
  }

  Rx<UserModel> userModel = UserModel().obs;
  Rx<UserModel> ownerModel = UserModel().obs;

  Future<void> getParcelList() async {
    // print("==>${userModel.value.isActive}");
    _driverSubscription = FireStoreUtils.fireStore.collection(CollectionName.users).doc(FireStoreUtils.getCurrentUid()).snapshots().listen(
      (event) {
        if (event.exists) {
          userModel.value = UserModel.fromJson(event.data()!);
          final rawData = event.data()?['orderParcelRequestData'];
          if (rawData != null && rawData is Map<String, dynamic>) {
            if (pendingParcelRequest.value == null) {
              log('[PARCEL_ORDER_REQUEST_RECEIVED] orderId=${rawData['id']}');
              pendingParcelRequest.value = Map<String, dynamic>.from(rawData);
              _showParcelRequestPopup(pendingParcelRequest.value!);
            }
          } else if (pendingParcelRequest.value != null) {
            pendingParcelRequest.value = null;
          }
          update();
        }
      },
      onError: (e) {},
    );
    // print("==>${userModel.value.isActive}");


    await FireStoreUtils.getOnGoingParcelList().then(
      (value) {
        parcelOrdersList.value = value;
        update();
      },
    );

    if (Constant.userModel!.ownerId != null && Constant.userModel!.ownerId!.isNotEmpty) {
      _ownerSubscription = FireStoreUtils.fireStore.collection(CollectionName.users).doc(Constant.userModel!.ownerId).snapshots().listen(
        (event) async {
          if (event.exists) {
            ownerModel.value = UserModel.fromJson(event.data()!);
          }
        },
        onError: (e) {},
      );
    }
    isLoading.value = false;
    update();
  }

  @override
  void onClose() {
    _driverSubscription?.cancel();
    _ownerSubscription?.cancel();
    super.onClose();
  }

  Future<void> pickupParcel(ParcelOrderModel parcelBookingData) async {
    ShowToastDialog.showLoader("Please wait".tr);
    parcelBookingData.status = Constant.orderInTransit;
    await FireStoreUtils.setParcelOrder(parcelBookingData);
    await getParcelList();
    ShowToastDialog.closeLoader();
  }

  Future<void> completeParcel(ParcelOrderModel parcelBookingData, {String? collectedPaymentMethod}) async {
    ShowToastDialog.showLoader("Please wait");
    parcelBookingData.status = Constant.orderCompleted;
    if (collectedPaymentMethod != null) {
      parcelBookingData.collectedPaymentMethod = collectedPaymentMethod;
      parcelBookingData.collectedByDriverId = Constant.userModel?.id;
      parcelBookingData.collectedAt = Timestamp.now();
      parcelBookingData.collectedPaymentStatus = 'collected';
    }

    await updateCabWalletAmount(parcelBookingData);
    await FireStoreUtils.setParcelOrder(parcelBookingData);
    Map<String, dynamic> payLoad = <String, dynamic>{"type": "parcel_order", "orderId": parcelBookingData.id};
    await SendNotification.sendFcmMessage(Constant.parcelCompleted, parcelBookingData.author!.fcmToken.toString(), payLoad);
    await getParcelList();
    await FireStoreUtils.getParcelFirstOrderOrNOt(parcelBookingData).then((value) async {
      if (value == true) {
        await FireStoreUtils.updateParcelReferralAmount(parcelBookingData);
      }
    });

    await FireStoreUtils.fireStore
        .collection(CollectionName.users)
        .doc(FireStoreUtils.getCurrentUid())
        .update({'orderParcelRequestData': FieldValue.delete()});

    ShowToastDialog.closeLoader();
    Get.back();
  }

  Future<void> updateCabWalletAmount(ParcelOrderModel orderModel) async {
    // GP parcel: collectionFee = driver local fee (fixed, ex: 2000)
    //             subTotal     = GP amount (variable, price × weight)
    // Regular parcel: collectionFee = 0, subTotal = delivery price
    final double rawCollectionFee = double.tryParse(orderModel.collectionFee ?? '0') ?? 0.0;
    final bool isGp = rawCollectionFee > 0;
    final bool driverCollectsGP = orderModel.customerPaysFullAmountToDriver == true;
    final bool isCash = orderModel.paymentMethod.toString() == PaymentGateway.cod.name;

    final double driverFeeBase = isGp ? rawCollectionFee : double.parse(orderModel.subTotal ?? '0.0');
    final double gpAmount = isGp ? (double.tryParse(orderModel.subTotal ?? '0') ?? 0.0) : 0.0;
    final double discount = double.parse(orderModel.discount ?? '0.0');

    double totalTax = 0.0;
    for (var element in orderModel.taxSetting!) {
      totalTax += Constant.calculateTax(amount: (driverFeeBase - discount).toString(), taxModel: element);
    }

    double adminComm = 0.0;
    if (orderModel.adminCommission!.isNotEmpty) {
      adminComm = Constant.calculateAdminCommission(
          amount: (driverFeeBase - discount).toString(),
          adminCommissionType: orderModel.adminCommissionType.toString(),
          adminCommission: orderModel.adminCommission ?? '0');
    }

    final double driverTotal = (driverFeeBase - discount) + totalTax;
    orderModel.driverEarning = driverTotal - adminComm;
    orderModel.driverAdminCommAmount = adminComm;
    orderModel.driverPayoutStatus = 'unpaid';

    if (isGp) {
      double gpAdminComm = 0.0;
      final String gpComm = orderModel.gpAdminCommission ?? orderModel.adminCommission ?? '';
      final String gpCommType = orderModel.gpAdminCommissionType ?? orderModel.adminCommissionType ?? '';
      if (gpComm.isNotEmpty) {
        gpAdminComm = Constant.calculateAdminCommission(
            amount: gpAmount.toString(), adminCommissionType: gpCommType, adminCommission: gpComm);
      }
      orderModel.gpEarning = gpAmount - gpAdminComm;
      orderModel.gpAdminCommAmount = gpAdminComm;

      if (driverCollectsGP) {
        orderModel.gpAmountCollectedByDriver = gpAmount;
        orderModel.gpCashToRemit = gpAmount;
        orderModel.gpPaymentStatus = 'pending';
        orderModel.gpPayoutStatus = 'unpaid';
        orderModel.cashToRemit = (isCash ? driverTotal : 0.0) + gpAmount;
      } else {
        orderModel.gpAmountCollectedByDriver = 0.0;
        orderModel.gpCashToRemit = 0.0;
        orderModel.gpPaymentStatus = 'not_collected_by_driver';
        orderModel.gpPayoutStatus = 'unpaid';
        orderModel.cashToRemit = isCash ? driverTotal : 0.0;
      }
    } else {
      orderModel.cashToRemit = isCash ? driverTotal : 0.0;
    }

    orderModel.cashRemittanceStatus = (orderModel.cashToRemit ?? 0) > 0 ? 'pending' : 'not_applicable';
  }

  void _showParcelRequestPopup(Map<String, dynamic> data) {
    if (Get.isDialogOpen == true) return;
    final senderAddr = data['senderAddress'] as String? ?? '';
    final receiverAddr = data['receiverAddress'] as String? ?? '';
    final price = data['subTotal'];
    Get.dialog(
      AlertDialog(
        title: const Text('Nouvelle demande colis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('De : $senderAddr'),
            const SizedBox(height: 8),
            Text('À : $receiverAddr'),
            const SizedBox(height: 8),
            Text('Montant : ${Constant.amountShow(amount: (price ?? 0).toString())}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              rejectParcelRequest(data);
            },
            child: const Text('Refuser', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              acceptParcelRequest(data);
            },
            child: const Text('Accepter', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Future<void> acceptParcelRequest(Map<String, dynamic> requestData) async {
    final orderId = requestData['id'] as String? ?? '';
    ShowToastDialog.showLoader('Please wait'.tr);
    try {
      await FireStoreUtils.fireStore.collection(CollectionName.parcelOrders).doc(orderId).update({
        'status': Constant.driverAccepted,
        'driverId': FireStoreUtils.getCurrentUid(),
        'driverAssignedAt': Timestamp.now(),
      });
      await FireStoreUtils.fireStore.collection(CollectionName.users).doc(FireStoreUtils.getCurrentUid()).update({
        'orderParcelRequestData': FieldValue.delete(),
      });
      pendingParcelRequest.value = null;
      await getParcelList();
    } catch (e) {
      log('[PARCEL_ACCEPT_ERROR] $e');
    }
    ShowToastDialog.closeLoader();
  }

  Future<void> rejectParcelRequest(Map<String, dynamic> requestData) async {
    final orderId = requestData['id'] as String? ?? '';
    try {
      await FireStoreUtils.fireStore.collection(CollectionName.users).doc(FireStoreUtils.getCurrentUid()).update({
        'orderParcelRequestData': FieldValue.delete(),
      });
      await FireStoreUtils.fireStore.collection(CollectionName.parcelOrders).doc(orderId).update({
        'status': Constant.orderAccepted,
        'rejectedByDrivers': FieldValue.arrayUnion([FireStoreUtils.getCurrentUid()]),
        'driverId': FieldValue.delete(),
        'driverAssignedAt': FieldValue.delete(),
      });
      pendingParcelRequest.value = null;
    } catch (e) {
      log('[PARCEL_REJECT_ERROR] $e');
    }
  }

  String calculateParcelTotalAmountBooking(ParcelOrderModel parcelBookingData) {
    String subTotal = parcelBookingData.subTotal.toString();
    String discount = parcelBookingData.discount ?? "0.0";
    String taxAmount = "0.0";
    for (var element in parcelBookingData.taxSetting!) {
      taxAmount = (double.parse(taxAmount) +
              Constant.calculateTax(amount: (double.parse(subTotal) - double.parse(discount)).toString(), taxModel: element))
          .toStringAsFixed(int.tryParse(Constant.currencyModel!.decimalDigits.toString()) ?? 2);
    }

    return ((double.parse(subTotal) - (double.parse(discount))) + double.parse(taxAmount))
        .toStringAsFixed(int.tryParse(Constant.currencyModel!.decimalDigits.toString()) ?? 2);
  }
}
