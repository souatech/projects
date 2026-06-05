import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/models/cab_order_model.dart';
import 'package:customer/models/payment_model/cod_setting_model.dart';
import 'package:customer/models/payment_model/wallet_setting_model.dart';
import 'package:customer/models/user_model.dart';
import 'package:customer/models/wallet_transaction_model.dart';
import 'package:customer/service/fire_store_utils.dart';
import 'package:customer/themes/show_toast_dialog.dart';
import 'package:customer/utils/preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../screen_ui/multi_vendor_service/wallet_screen/wallet_screen.dart';

class MyCabBookingController extends GetxController {
  RxBool isLoading = true.obs;
  RxString selectedTab = "New".obs;

  RxList<CabOrderModel> cabOrder = <CabOrderModel>[].obs;

  final List<String> tabKeys = ["New", "On Going", "Completed", "Cancelled"];

  Rx<UserModel> userModel = UserModel().obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    fetchParcelData();
  }

  Future<void> selectTab(String tab) async {
    selectedTab.value = tab;
  }

  Future<void> fetchParcelData() async {
    isLoading.value = true;

    if (FirebaseAuth.instance.currentUser != null) {
      await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid()).then((user) {
        if (user != null) {
          userModel.value = user;
        }
      });

      FireStoreUtils.getCabDriverOrders().listen((orders) {
        cabOrder.value = orders;
      });

      await getPaymentSettings();
    }

    isLoading.value = false;
  }

  List<CabOrderModel> get filteredParcelOrders => getOrdersForTab(selectedTab.value);

  List<CabOrderModel> getOrdersForTab(String tab) {
    switch (tab) {
      case "New":
        return cabOrder.where((order) => ["Order Placed", "Driver Pending"].contains(order.status)).toList();

      case "On Going":
        return cabOrder.where((order) => ["Driver Accepted", "Order Shipped", "In Transit"].contains(order.status)).toList();

      case "Completed":
        return cabOrder.where((order) => ["Order Completed"].contains(order.status)).toList();

      case "Cancelled":
        return cabOrder.where((order) => ["Order Rejected", "Order Cancelled", "Driver Rejected"].contains(order.status)).toList();

      default:
        return [];
    }
  }

  /// Get localized title for UI
  String getLocalizedTabTitle(String tabKey) {
    switch (tabKey) {
      case "New":
        return "New".tr;
      case "On Going":
        return "On Going".tr;
      case "Completed":
        return "Completed".tr;
      case "Cancelled":
        return "Cancelled".tr;
      default:
        return tabKey;
    }
  }

  String formatDate(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return DateFormat("dd MMM yyyy, hh:mm a").format(dateTime);
  }

  Rx<WalletSettingModel> walletSettingModel = WalletSettingModel().obs;
  Rx<CodSettingModel> cashOnDeliverySettingModel = CodSettingModel().obs;

  final RxString selectedPaymentMethod = ''.obs;

  Rx<CabOrderModel> currentOrder = CabOrderModel().obs;

  Rx<CabOrderModel> selectedOrder = CabOrderModel().obs;
  RxDouble totalAmount = 0.0.obs;

  RxDouble subTotal = 0.0.obs;
  RxDouble discount = 0.0.obs;
  RxDouble taxAmount = 0.0.obs;
  RxDouble orderTaxAmount = 0.0.obs;
  RxDouble platformTaxAmount = 0.0.obs;

  void calculateTotalAmount(CabOrderModel order) {
    subTotal.value = 0.0;
    discount.value = 0.0;
    taxAmount.value = 0.0;
    totalAmount.value = 0.0;
    platformTaxAmount.value = 0.0;
    orderTaxAmount.value = 0.0;

    selectedOrder.value = order;
    try {
      subTotal.value = double.tryParse(selectedOrder.value.subTotal?.toString() ?? "0") ?? 0.0;
      discount.value = double.tryParse(selectedOrder.value.discount?.toString() ?? "0") ?? 0.0;
      taxAmount.value = 0.0;

      subTotal.value = subTotal.value;

      for (var taxElement in Constant.orderProductTaxList ?? []) {
        orderTaxAmount.value += Constant.calculateTax(amount: (subTotal.value - discount.value).toString(), taxModel: taxElement);
      }

      /// ---------------- PLATFORM TAX ----------------
      if (double.parse(Constant.platformFeeModel?.fee ?? '0.0') > 0.0) {
        for (var taxElement in Constant.platformTaxList ?? []) {
          platformTaxAmount.value += Constant.calculateTax(amount: Constant.platformFeeModel?.fee ?? '0.0', taxModel: taxElement);
        }
      }
      taxAmount.value = orderTaxAmount.value + platformTaxAmount.value;

      totalAmount.value = (subTotal.value - discount.value) + double.parse(Constant.platformFeeModel?.fee ?? '0.0') + taxAmount.value;
    } catch (e) {
      ShowToastDialog.showToast("Failed to calculate total: $e");
    }
  }

  Future<void> completeOrder() async {
    if (selectedPaymentMethod.value == PaymentGateway.cod.name) {
      selectedOrder.value.paymentMethod = selectedPaymentMethod.value;
      await FireStoreUtils.cabOrderPlace(selectedOrder.value).then((value) {
        ShowToastDialog.showToast("Payment method changed".tr);
        Get.back();
      });
    } else {
      selectedOrder.value.paymentMethod = selectedPaymentMethod.value;
      userModel.value.inProgressOrderID ??= [];
      userModel.value.inProgressOrderID!.clear();
      await FireStoreUtils.updateUser(userModel.value);
      if (selectedPaymentMethod.value == PaymentGateway.wallet.name) {
        WalletTransactionModel transactionModel = WalletTransactionModel(
          id: Constant.getUuid(),
          amount: double.parse(totalAmount.toString()),
          date: Timestamp.now(),
          paymentMethod: PaymentGateway.wallet.name,
          transactionUser: "customer",
          userId: FireStoreUtils.getCurrentUid(),
          isTopup: false,
          orderId: selectedOrder.value.id,
          note: "Cab Amount debited".tr,
          paymentStatus: "success".tr,
          serviceType: Constant.parcelServiceType,
        );

        await FireStoreUtils.setWalletTransaction(transactionModel).then((value) async {
          await FireStoreUtils.updateUserWallet(amount: "-${totalAmount.value.toString()}", userId: FireStoreUtils.getCurrentUid());
        });
      }
      selectedOrder.value.paymentStatus = true;
      await FireStoreUtils.cabOrderPlace(selectedOrder.value).then((value) {
        ShowToastDialog.showToast("Payment successfully".tr);
        Get.back();
      });
    }
  }

  Future<void> getPaymentSettings() async {
    await FireStoreUtils.getPaymentSettingsData().then((value) {
      walletSettingModel.value = WalletSettingModel.fromJson(jsonDecode(Preferences.getString(Preferences.walletSettings)));
      cashOnDeliverySettingModel.value = CodSettingModel.fromJson(jsonDecode(Preferences.getString(Preferences.codSettings)));

      if (walletSettingModel.value.isEnabled == true) {
        selectedPaymentMethod.value = PaymentGateway.wallet.name;
      } else if (cashOnDeliverySettingModel.value.isEnabled == true) {
        selectedPaymentMethod.value = PaymentGateway.cod.name;
      }
    });
  }

  bool isCurrentDateInRange(DateTime startDate, DateTime endDate) {
    final currentDate = DateTime.now();
    return currentDate.isAfter(startDate) && currentDate.isBefore(endDate);
  }
}
