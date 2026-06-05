import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../../models/onprovider_order_model.dart';
import '../constant/constant.dart';
import '../models/payment_model/cod_setting_model.dart';
import '../models/payment_model/paydunya_config_model.dart';
import '../models/payment_model/wallet_setting_model.dart';
import '../models/wallet_transaction_model.dart';
import '../payment/paydunya_screen.dart';
import '../screen_ui/multi_vendor_service/wallet_screen/wallet_screen.dart';
import '../screen_ui/on_demand_service/on_demand_dashboard_screen.dart';
import '../service/fire_store_utils.dart';
import '../service/send_notification.dart';
import '../themes/show_toast_dialog.dart';
import '../utils/preferences.dart';
import 'on_demand_dashboard_controller.dart';

class OnDemandPaymentController extends GetxController {
  Rx<OnProviderOrderModel?> onDemandOrderModel = Rx<OnProviderOrderModel?>(null);
  RxDouble totalAmount = 0.0.obs;
  late bool isExtra;

  RxBool isLoading = false.obs;
  RxString selectedPaymentMethod = ''.obs;
  RxBool isOrderPlaced = false.obs;

  Rx<WalletSettingModel> walletSettingModel = WalletSettingModel().obs;
  Rx<CodSettingModel> cashOnDeliverySettingModel = CodSettingModel().obs;
  Rx<PaydunyaConfigModel> paydunyaConfig = PaydunyaConfigModel().obs;

  @override
  void onInit() {
    super.onInit();
    isLoading.value = true;
    final args = Get.arguments as Map<String, dynamic>;
    onDemandOrderModel = args['onDemandOrderModel'];
    totalAmount = (args['totalAmount'] as double).obs;
    isExtra = args['isExtra'];
    getPaymentSettings();
  }

  Future<void> getPaymentSettings() async {
    isLoading.value = true;
    await FireStoreUtils.getPaymentSettingsData();
    walletSettingModel.value = WalletSettingModel.fromJson(
      jsonDecode(Preferences.getString(Preferences.walletSettings, defaultValue: '{}')),
    );
    cashOnDeliverySettingModel.value = CodSettingModel.fromJson(
      jsonDecode(Preferences.getString(Preferences.codSettings, defaultValue: '{}')),
    );

    if (walletSettingModel.value.isEnabled == true) {
      selectedPaymentMethod.value = PaymentGateway.wallet.name;
    } else if (cashOnDeliverySettingModel.value.isEnabled == true) {
      selectedPaymentMethod.value = PaymentGateway.cod.name;
    }

    // Primary: Firestore (consistent with wallet/COD pattern)
    final paydunyaPrefs = Preferences.getString(Preferences.paydunyaSettings, defaultValue: '');
    if (paydunyaPrefs.isNotEmpty) {
      paydunyaConfig.value = PaydunyaConfigModel.fromJson(jsonDecode(paydunyaPrefs));
      if (paydunyaConfig.value.isEnabled && selectedPaymentMethod.value.isEmpty) {
        selectedPaymentMethod.value = PaymentGateway.paydunya.name;
      }
    }

    // Fallback: REST API (overrides Firestore if endpoint responds)
    try {
      final response = await http.get(
        Uri.parse('${Constant.globalUrl}payments/paydunya/config'),
      );
      if (response.statusCode == 200) {
        paydunyaConfig.value = PaydunyaConfigModel.fromJson(jsonDecode(response.body));
        if (paydunyaConfig.value.isEnabled && selectedPaymentMethod.value.isEmpty) {
          selectedPaymentMethod.value = PaymentGateway.paydunya.name;
        }
      }
    } catch (e) {
      log('PayDunya config fetch failed: $e');
    }

    isLoading.value = false;
  }

  // ─── COD ──────────────────────────────────────────────────────────────────

  Future<void> placeOrderCOD() async {
    if (isExtra) {
      await _placeExtraChargeCOD();
    } else {
      await _placeNormalOrderCOD();
    }
  }

  Future<void> _placeNormalOrderCOD() async {
    ShowToastDialog.showLoader("Please wait...".tr);
    onDemandOrderModel.value?.payment_method = PaymentGateway.cod.name;
    onDemandOrderModel.value?.paymentStatus = false;
    onDemandOrderModel.value?.extraPaymentStatus = true;
    await FireStoreUtils.onDemandOrderPlace(onDemandOrderModel.value!, totalAmount.value);
    await _notifyProvider();
    ShowToastDialog.showToast("OnDemand Service successfully booked".tr);
    ShowToastDialog.closeLoader();
    _goToDashboard();
  }

  Future<void> _placeExtraChargeCOD() async {
    onDemandOrderModel.value?.createdAt = Timestamp.now();
    onDemandOrderModel.value?.extraPaymentStatus = true;
    await FireStoreUtils.updateOnDemandOrder(onDemandOrderModel.value!);
    ShowToastDialog.closeLoader();
    _goToDashboard();
  }

  // ─── Wallet ───────────────────────────────────────────────────────────────

  Future<void> placeOrderWallet() async {
    if (isExtra) {
      await _placeExtraChargeWallet();
    } else {
      await _placeNormalOrderWallet();
    }
  }

  Future<void> _placeNormalOrderWallet() async {
    ShowToastDialog.showLoader("Please wait...".tr);
    onDemandOrderModel.value?.payment_method = PaymentGateway.wallet.name;
    onDemandOrderModel.value?.paymentStatus = true;
    onDemandOrderModel.value?.extraPaymentStatus = true;
    await FireStoreUtils.onDemandOrderPlace(onDemandOrderModel.value!, totalAmount.value);

    final txn = WalletTransactionModel(
      id: Constant.getUuid(),
      amount: totalAmount.value,
      date: Timestamp.now(),
      paymentMethod: PaymentGateway.wallet.name,
      transactionUser: "customer",
      userId: FireStoreUtils.getCurrentUid(),
      isTopup: false,
      orderId: onDemandOrderModel.value!.id,
      note: "Booking Amount debited".tr,
      paymentStatus: "success".tr,
    );
    await FireStoreUtils.setWalletTransaction(txn).then((ok) async {
      if (ok == true) {
        await FireStoreUtils.updateUserWallet(
          amount: "-${totalAmount.value}",
          userId: FireStoreUtils.getCurrentUid(),
        );
      }
    });

    await _notifyProvider();
    ShowToastDialog.showToast("OnDemand Service successfully booked".tr);
    ShowToastDialog.closeLoader();
    _goToDashboard();
  }

  Future<void> _placeExtraChargeWallet() async {
    onDemandOrderModel.value?.createdAt = Timestamp.now();
    onDemandOrderModel.value?.extraPaymentStatus = true;

    final customerTxn = WalletTransactionModel(
      id: Constant.getUuid(),
      amount: totalAmount.value,
      date: Timestamp.now(),
      paymentMethod: PaymentGateway.wallet.name,
      transactionUser: "customer",
      userId: FireStoreUtils.getCurrentUid(),
      isTopup: false,
      orderId: onDemandOrderModel.value!.id,
      note: "Booking Extra charge debited",
      paymentStatus: "success".tr,
    );
    await FireStoreUtils.setWalletTransaction(customerTxn).then((ok) async {
      if (ok == true) {
        await FireStoreUtils.updateUserWallet(
          amount: "-${totalAmount.value}",
          userId: FireStoreUtils.getCurrentUid(),
        );
      }
    });

    final providerTxn = WalletTransactionModel(
      id: Constant.getUuid(),
      serviceType: 'ondemand-service',
      amount: totalAmount.value,
      date: Timestamp.now(),
      paymentMethod: PaymentGateway.wallet.name,
      transactionUser: "provider",
      userId: onDemandOrderModel.value?.provider.author,
      isTopup: true,
      orderId: onDemandOrderModel.value?.id,
      note: 'Extra Charge Amount Credited',
      paymentStatus: "success".tr,
    );
    await FireStoreUtils.setWalletTransaction(providerTxn).then((ok) async {
      if (ok == true) {
        await FireStoreUtils.updateUserWallet(
          amount: "-${totalAmount.value}",
          userId: FireStoreUtils.getCurrentUid(),
        );
      }
    });

    await FireStoreUtils.updateOnDemandOrder(onDemandOrderModel.value!);
    ShowToastDialog.closeLoader();
    _goToDashboard();
  }

  // ─── PayDunya ─────────────────────────────────────────────────────────────

  Future<void> initiatePaydunyaPayment(BuildContext context) async {
    ShowToastDialog.showLoader("Please wait...".tr);

    final orderId = onDemandOrderModel.value?.id ?? const Uuid().v4();

    try {
      log('[PayDunya] config: isEnabled=${paydunyaConfig.value.isEnabled}, mode=${paydunyaConfig.value.mode}');

      final createBody = jsonEncode({
        'amount': totalAmount.value,
        'order_id': orderId,
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

      // Persist order as PENDING before opening WebView
      onDemandOrderModel.value?.id = orderId;
      onDemandOrderModel.value?.payment_method = PaymentGateway.paydunya.name;
      onDemandOrderModel.value?.paymentStatus = false;
      onDemandOrderModel.value?.status = Constant.paymentPending;
      onDemandOrderModel.value?.extraPaymentStatus = isExtra ? true : false;
      await FireStoreUtils.onDemandOrderPlace(onDemandOrderModel.value!, totalAmount.value);

      // Open PayDunya WebView
      final result = await Get.to(() => PaydunyaScreen(
        paymentUrl: paymentUrl,
        token: paydunyaToken,
        orderId: orderId,
      ));

      if (result == true) {
        onDemandOrderModel.value?.paymentStatus = true;
        onDemandOrderModel.value?.status = Constant.orderPlaced;
        await FireStoreUtils.updateOnDemandOrder(onDemandOrderModel.value!);
        await _notifyProvider();
        ShowToastDialog.showToast("Réservation confirmée !".tr);
        _goToDashboard();
      } else if (result == 'expired') {
        onDemandOrderModel.value?.status = Constant.orderCancelled;
        await FireStoreUtils.updateOnDemandOrder(onDemandOrderModel.value!);
        ShowToastDialog.showToast("Délai de paiement dépassé. Commande annulée.".tr);
      } else {
        onDemandOrderModel.value?.status = Constant.orderCancelled;
        await FireStoreUtils.updateOnDemandOrder(onDemandOrderModel.value!);
        ShowToastDialog.showToast("Paiement annulé.".tr);
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Une erreur est survenue. Veuillez réessayer.".tr);
      log('PayDunya payment error: $e');
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Future<void> _notifyProvider() async {
    if (onDemandOrderModel.value?.provider.author == null) return;
    final providerUser = await FireStoreUtils.getUserProfile(
      onDemandOrderModel.value!.provider.author!,
    );
    if (providerUser != null) {
      final payload = {"type": 'provider_order', "orderId": onDemandOrderModel.value?.id};
      await SendNotification.sendFcmMessage(
        Constant.bookingPlaced,
        providerUser.fcmToken ?? '',
        payload,
      );
    }
  }

  void _goToDashboard() {
    Get.offAll(const OnDemandDashboardScreen());
    final controller = Get.put(OnDemandDashboardController());
    controller.selectedIndex.value = 2;
  }
}
