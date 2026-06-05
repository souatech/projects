import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/models/user_model.dart';
import 'package:customer/models/wallet_transaction_model.dart';
import 'package:customer/themes/app_them_data.dart';
import '../service/fire_store_utils.dart';
import 'package:customer/utils/preferences.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../themes/show_toast_dialog.dart';

class WalletController extends GetxController {
  RxBool isLoading = true.obs;

  Rx<TextEditingController> topUpAmountController = TextEditingController().obs;

  RxList<WalletTransactionModel> walletTransactionList = <WalletTransactionModel>[].obs;

  Rx<UserModel> userModel = UserModel().obs;
  RxString selectedPaymentMethod = "".obs;

  @override
  void onInit() {
    // TODO: implement onInit
    getPaymentSettings();
    getWalletTransaction();
    super.onInit();
  }

  Future<void> getPaymentSettings() async {
    await FireStoreUtils.getPaymentSettingsData().then((value) {
    });
  }

  Future<void> getWalletTransaction() async {
    if (Constant.userModel != null) {
      await FireStoreUtils.getWalletTransaction().then((value) {
        if (value != null) {
          walletTransactionList.value = value;
        }
      });
      await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid()).then((value) {
        if (value != null) {
          userModel.value = value;
        }
      });
    }
    isLoading.value = false;
  }

  Future<void> walletTopUp() async {
    WalletTransactionModel transactionModel = WalletTransactionModel(
      id: Constant.getUuid(),
      amount: double.parse(topUpAmountController.value.text),
      date: Timestamp.now(),
      paymentMethod: selectedPaymentMethod.value,
      transactionUser: "user",
      userId: FireStoreUtils.getCurrentUid(),
      isTopup: true,
      note: "Wallet Top-up",
      paymentStatus: "success",
    );

    await FireStoreUtils.setWalletTransaction(transactionModel).then((value) async {
      if (value == true) {
        await FireStoreUtils.updateUserWallet(amount: topUpAmountController.value.text, userId: FireStoreUtils.getCurrentUid()).then((value) {
          getWalletTransaction();
          Get.back();
        });
      }
    });

    ShowToastDialog.showToast("Amount Top-up successfully".tr);
  }
}
