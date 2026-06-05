import 'dart:convert';
import 'dart:developer';
import 'dart:math' hide log;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/models/gift_cards_model.dart';
import 'package:http/http.dart' as http;
import '../models/gift_cards_order_model.dart';
import '../models/payment_model/cod_setting_model.dart';
import '../models/payment_model/paydunya_config_model.dart';
import '../models/payment_model/wallet_setting_model.dart';
import '../models/user_model.dart';
import '../models/wallet_transaction_model.dart';
import '../payment/paydunya_screen.dart';
import '../screen_ui/multi_vendor_service/gift_card/history_gift_card.dart';
import '../screen_ui/multi_vendor_service/wallet_screen/wallet_screen.dart';
import '../service/fire_store_utils.dart';
import 'package:customer/utils/preferences.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../themes/show_toast_dialog.dart';

class GiftCardController extends GetxController {
  RxBool isLoading = true.obs;
  RxString selectedPaymentMethod = ''.obs;
  var pageController = PageController();

  @override
  void onInit() {
    // TODO: implement onInit
    getGiftCard();
    super.onInit();
  }

  List<GiftCardsModel> giftCardList = [];
  Rx<GiftCardsModel> selectedGiftCard = GiftCardsModel().obs;

  List amountList = ["1000", "2000", "5000"];
  RxString selectedAmount = "1000".obs;
  var selectedPageIndex = 0.obs;

  Rx<TextEditingController> amountController = TextEditingController().obs;
  Rx<TextEditingController> messageController = TextEditingController().obs;
  Rx<UserModel> userModel = UserModel().obs;

  Future<void> getGiftCard() async {
    await FireStoreUtils.getGiftCard().then((value) {
      giftCardList = value;
      if (giftCardList.isNotEmpty) {
        selectedGiftCard.value = giftCardList.first;
        messageController.value.text = selectedGiftCard.value.message.toString();
      }
    });

    isLoading.value = false;
    await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid()).then((value) {
      if (value != null) {
        userModel.value = value;
      }
    });
    await getPaymentSettings();
  }

  Future<void> placeOrder() async {
    if (selectedPaymentMethod.value == PaymentGateway.wallet.name) {
      if (double.parse(userModel.value.walletAmount.toString()) >= double.parse(amountController.value.text)) {
        setOrder();
      } else {
        ShowToastDialog.showToast("You don't have sufficient wallet balance to purchase gift card".tr);
      }
    } else {
      setOrder();
    }
  }

  Future<void> setOrder() async {
    ShowToastDialog.showLoader("Please wait...".tr);
    GiftCardsOrderModel giftCardsOrderModel = GiftCardsOrderModel();
    giftCardsOrderModel.id = const Uuid().v4();
    giftCardsOrderModel.giftId = selectedGiftCard.value.id.toString();
    giftCardsOrderModel.giftTitle = selectedGiftCard.value.title.toString();
    giftCardsOrderModel.price = amountController.value.text;
    giftCardsOrderModel.redeem = false;
    giftCardsOrderModel.message = messageController.value.text;
    giftCardsOrderModel.giftPin = generateGiftPin();
    giftCardsOrderModel.giftCode = generateGiftCode();
    giftCardsOrderModel.paymentType = selectedPaymentMethod.value;
    giftCardsOrderModel.createdDate = Timestamp.now();
    DateTime dateTime = DateTime.now().add(Duration(days: int.parse(selectedGiftCard.value.expiryDay ?? "2")));
    giftCardsOrderModel.expireDate = Timestamp.fromDate(dateTime);
    giftCardsOrderModel.userid = FireStoreUtils.getCurrentUid();

    if (selectedPaymentMethod.value == PaymentGateway.wallet.name) {
      WalletTransactionModel transactionModel = WalletTransactionModel(
        id: Constant.getUuid(),
        amount: double.parse(amountController.value.text),
        date: Timestamp.now(),
        paymentMethod: PaymentGateway.wallet.name,
        transactionUser: "user",
        userId: FireStoreUtils.getCurrentUid(),
        isTopup: false,
        orderId: giftCardsOrderModel.id,
        note: "Gift card purchase amount debited".tr,
        paymentStatus: "success".tr,
      );

      await FireStoreUtils.setWalletTransaction(transactionModel).then((value) async {
        if (value == true) {
          await FireStoreUtils.updateUserWallet(amount: "-${amountController.value.text.toString()}", userId: FireStoreUtils.getCurrentUid()).then((value) {});
        }
      });
    }
    await FireStoreUtils.placeGiftCardOrder(giftCardsOrderModel);
    ShowToastDialog.closeLoader();
    Get.off(const HistoryGiftCard());
    ShowToastDialog.showToast("Gift card Purchases successfully".tr);
  }

  String generateGiftCode() {
    var rng = Random();
    String generatedNumber = '';
    for (int i = 0; i < 16; i++) {
      generatedNumber += (rng.nextInt(9) + 1).toString();
    }
    return generatedNumber;
  }

  String generateGiftPin() {
    var rng = Random();
    String generatedNumber = '';
    for (int i = 0; i < 6; i++) {
      generatedNumber += (rng.nextInt(9) + 1).toString();
    }
    return generatedNumber;
  }

  Future<void> initiatePaydunyaPayment(BuildContext context) async {
    ShowToastDialog.showLoader("Please wait...".tr);
    try {
      log('[PayDunya] config: isEnabled=${paydunyaConfig.value.isEnabled}, mode=${paydunyaConfig.value.mode}');

      final amount = double.tryParse(amountController.value.text) ?? 0.0;
      final tempOrderId = const Uuid().v4();

      final createBody = jsonEncode({
        'amount': amount,
        'order_id': tempOrderId,
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
        orderId: tempOrderId,
      ));

      if (result == true) {
        await setOrder();
      } else if (result == 'expired') {
        ShowToastDialog.showToast("Délai de paiement dépassé.".tr);
      } else {
        ShowToastDialog.showToast("Paiement annulé.".tr);
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Une erreur est survenue. Veuillez réessayer.".tr);
      log('PayDunya gift card payment error: $e');
    }
  }

  Rx<WalletSettingModel> walletSettingModel = WalletSettingModel().obs;
  Rx<CodSettingModel> cashOnDeliverySettingModel = CodSettingModel().obs;
  Rx<PaydunyaConfigModel> paydunyaConfig = PaydunyaConfigModel().obs;

  Future<void> getPaymentSettings() async {
    await FireStoreUtils.getPaymentSettingsData().then((value) {
      cashOnDeliverySettingModel.value = CodSettingModel.fromJson(jsonDecode(Preferences.getString(Preferences.codSettings)));
      walletSettingModel.value = WalletSettingModel.fromJson(jsonDecode(Preferences.getString(Preferences.walletSettings)));
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
