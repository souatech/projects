import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/models/coupon_model.dart';
import 'package:customer/models/wallet_transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../models/parcel_order_model.dart';
import '../constant/constant.dart';
import '../models/payment_model/cod_setting_model.dart';
import '../models/payment_model/paydunya_config_model.dart';
import '../models/payment_model/wallet_setting_model.dart';
import '../models/user_model.dart';
import '../payment/paydunya_screen.dart';
import '../screen_ui/multi_vendor_service/wallet_screen/wallet_screen.dart';
import '../screen_ui/parcel_service/order_successfully_placed.dart';
import '../service/fire_store_utils.dart';
import '../themes/show_toast_dialog.dart';
import '../utils/preferences.dart';

class ParcelOrderConfirmationController extends GetxController {
  RxBool isLoading = true.obs;
  final Rx<ParcelOrderModel> parcelOrder = ParcelOrderModel().obs;
  final RxList<XFile> images = <XFile>[].obs;
  final RxString paymentBy = "Receiver".obs;

  RxString selectedPaymentMethod = ''.obs;
  RxBool isOrderPlaced = false.obs;
  RxBool customerPaysFullAmountToDriver = false.obs;

  RxDouble orderTaxAmount = 0.0.obs;
  RxDouble platformTaxAmount = 0.0.obs;
  RxDouble subTotal = 0.0.obs;
  RxDouble discount = 0.0.obs;
  RxDouble taxAmount = 0.0.obs;
  RxDouble totalAmount = 0.0.obs;
  RxDouble collectionFee = 0.0.obs;

  Rx<TextEditingController> couponController = TextEditingController().obs;
  Rx<UserModel> userModel = UserModel().obs;

  @override
  void onInit() {
    super.onInit();
    getArgument();
  }

  Rx<CouponModel> selectedCouponModel = CouponModel().obs;

  Future<void> getArgument() async {
    final dynamic args = Get.arguments;
    if (args != null) {
      parcelOrder.value = args['parcelOrder'];
      collectionFee.value = double.tryParse(parcelOrder.value.collectionFee ?? '0') ?? 0.0;
      images.value = List<XFile>.from(args['images'] ?? []);
      calculatePrice();
    }

    userModel.value = Constant.userModel!;
    await fetchCoupons();
    await getPaymentSettings();
    isLoading.value = false;
    update();
  }

  void calculatePrice() {
    subTotal.value = 0;
    discount.value = 0;
    taxAmount.value = 0;
    orderTaxAmount.value = 0;
    platformTaxAmount.value = 0;

    subTotal.value = double.tryParse(parcelOrder.value.subTotal ?? '0') ?? 0.0;

    if (selectedCouponModel.value.id != null) {
      discount.value = Constant.calculateDiscount(amount: subTotal.value.toString(), offerModel: selectedCouponModel.value);
    }

    /// ---------------- ORDER TAX ----------------
    for (var taxElement in Constant.orderProductTaxList ?? []) {
      orderTaxAmount.value += Constant.calculateTax(amount: (subTotal.value - discount.value).toString(), taxModel: taxElement);
    }

    /// ---------------- PLATFORM TAX ----------------
    if (Constant.platformFeeModel?.enable == true && double.parse(Constant.platformFeeModel?.fee ?? '0.0') > 0.0) {
      for (var taxElement in Constant.platformTaxList ?? []) {
        platformTaxAmount.value += Constant.calculateTax(amount: Constant.platformFeeModel?.fee ?? '0.0', taxModel: taxElement);
      }
    }

    taxAmount.value = orderTaxAmount.value + platformTaxAmount.value;

    totalAmount.value = (subTotal.value - discount.value) + double.parse(Constant.platformFeeModel?.fee ?? '0.0') + taxAmount.value + collectionFee.value;
  }

  RxList<CouponModel> couponList = <CouponModel>[].obs;

  Future<void> fetchCoupons() async {
    try {
      await FireStoreUtils.getParcelCoupon().then((value) {
        couponList.value = value;
      });
    } catch (e) {
      print("Error fetching coupons: $e");
    }
  }

  String formatDate(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return DateFormat("dd MMM yyyy, hh:mm a").format(dateTime);
  }

  Future<void> placeOrder() async {
    ShowToastDialog.showLoader("Please wait...".tr);

    try {
      List<String> parcelImages = [];
      if (images.isNotEmpty) {
        for (var image in images) {
          final upload = await FireStoreUtils.uploadChatImageToFireStorage(File(image.path), Get.context!);
          parcelImages.add(upload.url);
        }
      }

      parcelOrder.value.parcelImages = parcelImages;
      parcelOrder.value.discount = discount.value.toString();
      parcelOrder.value.discountType = selectedCouponModel.value.discountType.toString();
      parcelOrder.value.discountLabel = selectedCouponModel.value.code.toString();
      parcelOrder.value.adminCommission = Constant.sectionConstantModel?.adminCommision?.amount?.toString();
      parcelOrder.value.adminCommissionType = Constant.sectionConstantModel?.adminCommision?.commissionType;
      final bool isGpParcel = (double.tryParse(parcelOrder.value.collectionFee ?? '0') ?? 0) > 0;
      parcelOrder.value.customerPaysFullAmountToDriver = isGpParcel ? customerPaysFullAmountToDriver.value : false;
      parcelOrder.value.gpAdminCommission = Constant.sectionConstantModel?.adminCommision?.amount?.toString();
      parcelOrder.value.gpAdminCommissionType = Constant.sectionConstantModel?.adminCommision?.commissionType;
      parcelOrder.value.sectionId = Constant.sectionConstantModel?.id ?? '';
      parcelOrder.value.status = Constant.orderPlaced;
      parcelOrder.value.createdAt = Timestamp.now();
      parcelOrder.value.author = userModel.value;
      parcelOrder.value.authorID = FireStoreUtils.getCurrentUid();
      parcelOrder.value.paymentMethod = paymentBy.value == "Receiver" ? "cod" : selectedPaymentMethod.value;
      parcelOrder.value.paymentCollectByReceiver = paymentBy.value == "Receiver";
      parcelOrder.value.senderZoneId = Constant.getZoneId(parcelOrder.value.senderLatLong!.latitude ?? 0.0, parcelOrder.value.senderLatLong!.longitude ?? 0.0);
      parcelOrder.value.receiverZoneId = Constant.getZoneId(parcelOrder.value.receiverLatLong!.latitude ?? 0.0, parcelOrder.value.receiverLatLong!.longitude ?? 0.0);

      if (paymentBy.value != "Receiver") {
        if (selectedPaymentMethod.value == PaymentGateway.wallet.name) {
          WalletTransactionModel transactionModel = WalletTransactionModel(
            id: Constant.getUuid(),
            amount: double.parse(totalAmount.value.toString()),
            date: Timestamp.now(),
            paymentMethod: PaymentGateway.wallet.name,
            transactionUser: "customer",
            userId: FireStoreUtils.getCurrentUid(),
            isTopup: false,
            orderId: parcelOrder.value.id,
            note: "Parcel Amount debited",
            paymentStatus: "success",
            serviceType: Constant.parcelServiceType,
          );

          await FireStoreUtils.setWalletTransaction(transactionModel).then((value) async {
            if (value == true) {
              await FireStoreUtils.updateUserWallet(amount: "-${totalAmount.value.toString()}", userId: FireStoreUtils.getCurrentUid());
            }
          });
        }
      }

      await FireStoreUtils.parcelOrderPlace(parcelOrder.value).then((value) async {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Order placed successfully".tr);
        try {
          final dispatchUrl = '${Constant.adminUrl}parcel/dispatch/${parcelOrder.value.id}';
          log('[PARCEL_DISPATCH_API_CALLED] POST $dispatchUrl');
          final resp = await http.post(Uri.parse(dispatchUrl), headers: {'Content-Type': 'application/json', 'Accept': 'application/json'});
          log('[PARCEL_DISPATCH_API_RESPONSE] status=${resp.statusCode} body=${resp.body}');
        } catch (e) {
          log('[PARCEL_DISPATCH_API_ERROR] $e');
        }
        Get.offAll(() => OrderSuccessfullyPlaced(), arguments: {'parcelOrder': parcelOrder.value});
        await FireStoreUtils.sendParcelBookEmail(orderModel: parcelOrder.value);
      });
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Something went wrong. Please try again.".tr);
    }
  }

  Future<void> initiatePaydunyaPayment(BuildContext context) async {
    ShowToastDialog.showLoader("Please wait...".tr);
    try {
      List<String> parcelImages = [];
      if (images.isNotEmpty) {
        for (var image in images) {
          final upload = await FireStoreUtils.uploadChatImageToFireStorage(File(image.path), Get.context!);
          parcelImages.add(upload.url);
        }
      }

      parcelOrder.value.parcelImages = parcelImages;
      parcelOrder.value.discount = discount.value.toString();
      parcelOrder.value.discountType = selectedCouponModel.value.discountType.toString();
      parcelOrder.value.discountLabel = selectedCouponModel.value.code.toString();
      parcelOrder.value.adminCommission = Constant.sectionConstantModel?.adminCommision?.amount?.toString();
      parcelOrder.value.adminCommissionType = Constant.sectionConstantModel?.adminCommision?.commissionType;
      final bool isGpParcelPd = (double.tryParse(parcelOrder.value.collectionFee ?? '0') ?? 0) > 0;
      parcelOrder.value.customerPaysFullAmountToDriver = isGpParcelPd ? customerPaysFullAmountToDriver.value : false;
      parcelOrder.value.gpAdminCommission = Constant.sectionConstantModel?.adminCommision?.amount?.toString();
      parcelOrder.value.gpAdminCommissionType = Constant.sectionConstantModel?.adminCommision?.commissionType;
      parcelOrder.value.sectionId = Constant.sectionConstantModel?.id ?? '';
      parcelOrder.value.status = Constant.paymentPending;
      parcelOrder.value.createdAt = Timestamp.now();
      parcelOrder.value.author = userModel.value;
      parcelOrder.value.authorID = FireStoreUtils.getCurrentUid();
      parcelOrder.value.paymentMethod = PaymentGateway.paydunya.name;
      parcelOrder.value.paymentCollectByReceiver = false;
      parcelOrder.value.senderZoneId = Constant.getZoneId(parcelOrder.value.senderLatLong!.latitude ?? 0.0, parcelOrder.value.senderLatLong!.longitude ?? 0.0);
      parcelOrder.value.receiverZoneId = Constant.getZoneId(parcelOrder.value.receiverLatLong!.latitude ?? 0.0, parcelOrder.value.receiverLatLong!.longitude ?? 0.0);
      await FireStoreUtils.parcelOrderPlace(parcelOrder.value);

      log('[PayDunya] config: isEnabled=${paydunyaConfig.value.isEnabled}, mode=${paydunyaConfig.value.mode}');

      final createBody = jsonEncode({
        'amount': totalAmount.value,
        'order_id': parcelOrder.value.id,
        'customer_name': Constant.userModel?.fullName() ?? '',
        'customer_email': Constant.userModel?.email ?? '',
      });
      final createUrl = '${Uri.parse(Constant.globalUrl).origin}/process-paydunya';
      log('[PayDunya] → POST $createUrl');
      log('[PayDunya] body: $createBody');

      final response = await http.post(
        Uri.parse(createUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
        },
        body: createBody,
      );

      log('[PayDunya] ← ${response.statusCode}: ${response.body}');
      ShowToastDialog.closeLoader();

      if (response.statusCode != 200) {
        String errMsg = response.body;
        try {
          final j = jsonDecode(response.body);
          errMsg = j['message'] ?? j['error'] ?? j['msg'] ?? j['detail'] ?? response.body;
        } catch (_) {}
        log('[PayDunya] create error: $errMsg');
        ShowToastDialog.showToast('PayDunya [${response.statusCode}]: $errMsg');
        return;
      }

      final data = jsonDecode(response.body);
      final String paymentUrl = data['checkout_url'] ?? data['payment_url'] ?? data['redirect_url'] ?? data['url'] ?? '';
      final String paydunyaToken = data['token'] ?? data['invoice_token'] ?? data['reference'] ?? '';
      log('[PayDunya] checkout_url: $paymentUrl  token: $paydunyaToken');

      if (paymentUrl.isEmpty) {
        ShowToastDialog.showToast('PayDunya: URL de paiement manquante');
        return;
      }

      final result = await Get.to(() => PaydunyaScreen(
        paymentUrl: paymentUrl,
        token: paydunyaToken,
        orderId: parcelOrder.value.id ?? '',
      ));

      if (result == true) {
        parcelOrder.value.status = Constant.orderPlaced;
        await FireStoreUtils.parcelOrderPlace(parcelOrder.value);
        try {
          final dispatchUrl = '${Constant.adminUrl}parcel/dispatch/${parcelOrder.value.id}';
          log('[PARCEL_DISPATCH_API_CALLED] POST $dispatchUrl');
          final resp = await http.post(Uri.parse(dispatchUrl), headers: {'Content-Type': 'application/json', 'Accept': 'application/json'});
          log('[PARCEL_DISPATCH_API_RESPONSE] status=${resp.statusCode} body=${resp.body}');
        } catch (e) {
          log('[PARCEL_DISPATCH_API_ERROR] $e');
        }
        ShowToastDialog.showToast("Réservation confirmée !".tr);
        Get.offAll(() => OrderSuccessfullyPlaced(), arguments: {'parcelOrder': parcelOrder.value});
        await FireStoreUtils.sendParcelBookEmail(orderModel: parcelOrder.value);
      } else if (result == 'expired') {
        parcelOrder.value.status = Constant.orderCancelled;
        await FireStoreUtils.parcelOrderPlace(parcelOrder.value);
        ShowToastDialog.showToast("Délai de paiement dépassé. Commande annulée.".tr);
      } else {
        parcelOrder.value.status = Constant.orderCancelled;
        await FireStoreUtils.parcelOrderPlace(parcelOrder.value);
        ShowToastDialog.showToast("Paiement annulé.".tr);
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Une erreur est survenue. Veuillez réessayer.".tr);
      log('PayDunya parcel payment error: $e');
    }
  }

  Rx<WalletSettingModel> walletSettingModel = WalletSettingModel().obs;
  Rx<CodSettingModel> cashOnDeliverySettingModel = CodSettingModel().obs;
  Rx<PaydunyaConfigModel> paydunyaConfig = PaydunyaConfigModel().obs;

  Future<void> getPaymentSettings() async {
    await FireStoreUtils.getPaymentSettingsData().then((value) {
      walletSettingModel.value = WalletSettingModel.fromJson(jsonDecode(Preferences.getString(Preferences.walletSettings)));
      cashOnDeliverySettingModel.value = CodSettingModel.fromJson(jsonDecode(Preferences.getString(Preferences.codSettings)));

      if (walletSettingModel.value.isEnabled == true) {
        selectedPaymentMethod.value = PaymentGateway.wallet.name;
      } else if (cashOnDeliverySettingModel.value.isEnabled == true) {
        selectedPaymentMethod.value = PaymentGateway.cod.name;
      }

      final paydunyaPrefs = Preferences.getString(Preferences.paydunyaSettings, defaultValue: '');
      if (paydunyaPrefs.isNotEmpty) {
        paydunyaConfig.value = PaydunyaConfigModel.fromJson(jsonDecode(paydunyaPrefs));
        if (paydunyaConfig.value.isEnabled && selectedPaymentMethod.value.isEmpty) {
          selectedPaymentMethod.value = PaymentGateway.paydunya.name;
        }
      }
    });
  }
}
