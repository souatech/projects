import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/models/cart_product_model.dart';
import 'package:customer/models/coupon_model.dart';
import 'package:customer/models/order_model.dart';
import 'package:customer/models/product_model.dart';
import 'package:customer/models/user_model.dart';
import 'package:customer/models/vendor_model.dart';
import 'package:customer/themes/app_them_data.dart';
import 'package:customer/utils/preferences.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/cashback_model.dart';
import '../models/cashback_redeem_model.dart';
import '../models/payment_model/cod_setting_model.dart';
import '../models/payment_model/paydunya_config_model.dart';
import '../models/payment_model/wallet_setting_model.dart';
import '../models/wallet_transaction_model.dart';
import '../payment/paydunya_screen.dart';
import '../screen_ui/multi_vendor_service/cart_screen/oder_placing_screens.dart';
import '../screen_ui/multi_vendor_service/wallet_screen/wallet_screen.dart';
import '../service/cart_provider.dart';
import '../service/fire_store_utils.dart';
import '../service/send_notification.dart';
import '../themes/show_toast_dialog.dart';

class CartController extends GetxController {
  RxBool isCashbackApply = false.obs;
  Rx<CashbackModel> bestCashback = CashbackModel().obs;

  final CartProvider cartProvider = CartProvider();
  StreamSubscription? _cartSub;
  Rx<TextEditingController> reMarkController = TextEditingController().obs;
  Rx<TextEditingController> couponCodeController = TextEditingController().obs;
  Rx<TextEditingController> tipsController = TextEditingController().obs;

  Rx<ShippingAddress> selectedAddress = ShippingAddress().obs;
  Rx<VendorModel> vendorModel = VendorModel().obs;
  Rx<DeliveryCharge> deliveryChargeModel = DeliveryCharge().obs;
  Rx<UserModel> userModel = UserModel().obs;
  RxList<CouponModel> couponList = <CouponModel>[].obs;
  RxList<CouponModel> allCouponList = <CouponModel>[].obs;
  RxString selectedFoodType = "Delivery".obs;

  RxString selectedPaymentMethod = ''.obs;
  RxBool isOrderPlaced = false.obs;

  RxString deliveryType = "instant".obs;
  Rx<DateTime> scheduleDateTime = DateTime.now().obs;
  RxDouble totalDistance = 0.0.obs;
  RxDouble deliveryCharges = 0.0.obs;
  RxDouble subTotal = 0.0.obs;
  RxDouble couponAmount = 0.0.obs;

  RxDouble specialDiscountAmount = 0.0.obs;
  RxDouble specialDiscount = 0.0.obs;
  RxString specialType = "".obs;

  RxDouble deliveryTips = 0.0.obs;
  RxDouble taxAmount = 0.0.obs;
  RxDouble totalAmount = 0.0.obs;
  Rx<CouponModel> selectedCouponModel = CouponModel().obs;

  RxDouble packagingCharge = 0.0.obs;
  RxDouble platformFee = 0.0.obs;
  RxDouble productTaxAmount = 0.0.obs;
  RxDouble orderTaxAmount = 0.0.obs;
  RxDouble driverDeliveryTaxAmount = 0.0.obs;
  RxDouble packagingTaxAmount = 0.0.obs;
  RxDouble platformTaxAmount = 0.0.obs;
  RxDouble totalTaxAmount = 0.0.obs;

  @override
  void onInit() {
    // TODO: implement onInit
    selectedAddress.value = Constant.selectedLocation;
    getCartData();
    getPaymentSettings();
    super.onInit();
  }

  @override
  void onClose() {
    _cartSub?.cancel();
    reMarkController.value.dispose();
    couponCodeController.value.dispose();
    tipsController.value.dispose();
    super.onClose();
  }

  Future<void> getCartData() async {
    _cartSub?.cancel();
    _cartSub = cartProvider.cartStream.listen((event) async {
      cartItem.clear();
      cartItem.addAll(event);
      if (cartItem.isNotEmpty) {
        await FireStoreUtils.getVendorById(cartItem.first.vendorID.toString()).then((value) {
          if (value != null) {
            vendorModel.value = value;
          }
        });
      }
      calculatePrice();
    });
    final rawType = Preferences.getString(Preferences.foodDeliveryType, defaultValue: "Delivery");
    const typeMap = {'Livraison': 'Delivery', 'À emporter': 'TakeAway', 'توصيل': 'Delivery', 'استلام': 'TakeAway'};
    selectedFoodType.value = typeMap[rawType] ?? rawType;

    await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid()).then((value) {
      if (value != null) {
        userModel.value = value;
      }
    });

    await FireStoreUtils.getDeliveryCharge().then((value) {
      if (value != null) {
        deliveryChargeModel.value = value;
        print("===> Delivery Charge Model: ${deliveryChargeModel.value.toJson()}");
        calculatePrice();
      }
    });

    await FireStoreUtils.getAllVendorPublicCoupons(vendorModel.value.id.toString()).then((value) {
      couponList.value = value;
    });

    await FireStoreUtils.getAllVendorCoupons(vendorModel.value.id.toString()).then((value) {
      allCouponList.value = value;
    });
  }

  Future<void> calculatePrice() async {
    // Reset values
    deliveryCharges.value = 0.0;
    subTotal.value = 0.0;
    couponAmount.value = 0.0;
    specialDiscountAmount.value = 0.0;

    productTaxAmount.value = 0.0;
    orderTaxAmount.value = 0.0;
    driverDeliveryTaxAmount.value = 0.0;
    packagingTaxAmount.value = 0.0;
    platformTaxAmount.value = 0.0;
    totalTaxAmount.value = 0.0;

    totalAmount.value = 0.0;
    packagingCharge.value = 0.0;
    platformFee.value = 0.0;

    /// ---------------- DELIVERY CHARGES ----------------
    if (cartItem.isNotEmpty) {
      if (selectedFoodType.value == "Delivery") {
        totalDistance.value = double.parse(
          Constant.getDistance(
            lat1: selectedAddress.value.location!.latitude.toString(),
            lng1: selectedAddress.value.location!.longitude.toString(),
            lat2: vendorModel.value.latitude.toString(),
            lng2: vendorModel.value.longitude.toString(),
          ),
        );
        if (Constant.sectionConstantModel?.serviceType == 'Ecommerce Service') {
          deliveryCharges.value = double.parse(Constant.sectionConstantModel?.deliveryCharge ?? '0.0');
        } else if (vendorModel.value.isSelfDelivery == true && Constant.isSelfDeliveryFeature == true) {
          deliveryCharges.value = 0.0;
        } else if (deliveryChargeModel.value.vendorCanModify == false) {
          deliveryCharges.value =
              totalDistance.value > (deliveryChargeModel.value.minimumDeliveryChargesWithinKm ?? 0)
                  ? totalDistance.value * (deliveryChargeModel.value.deliveryChargesPerKm ?? 0)
                  : (deliveryChargeModel.value.minimumDeliveryCharges ?? 0).toDouble();
        } else {
          final charge = vendorModel.value.deliveryCharge ?? deliveryChargeModel.value;
          deliveryCharges.value = totalDistance.value > (charge.minimumDeliveryChargesWithinKm ?? 0) ? totalDistance.value * (charge.deliveryChargesPerKm ?? 0) : (charge.minimumDeliveryCharges ?? 0).toDouble();
        }
      }
    }

    /// ---------------- PACKAGING & PLATFORM ----------------
    if (Constant.sectionConstantModel?.packagingChargeEnable == true) {
      packagingCharge.value = vendorModel.value.packagingCharge != null ? double.parse(vendorModel.value.packagingCharge.toString()) : 0.0;
    }
    if (Constant.sectionConstantModel?.platformFee?.enable == true) {
      platformFee.value = Constant.calculatePlatFormMeModel(platFromFeeModel: Constant.platformFeeModel);
    }

    log("TaxScope :: ${Constant.taxScope}");

    /// ---------------- SUBTOTAL ----------------
    for (var element in cartItem) {
      final price = double.parse((element.discountPrice != null && double.parse(element.discountPrice.toString()) > 0) ? element.discountPrice.toString() : element.price.toString());

      final qty = double.parse(element.quantity.toString());
      final extras = double.parse(element.extrasPrice.toString());

      subTotal.value += (price * qty) + (extras * qty);
    }

    /// ---------------- COUPON ----------------
    if (selectedCouponModel.value.id != null) {
      couponAmount.value = Constant.calculateDiscount(amount: subTotal.value.toString(), offerModel: selectedCouponModel.value);
    }

    /// ---------------- SPECIAL DISCOUNT ----------------
    if (vendorModel.value.specialDiscountEnable == true && Constant.specialDiscountOffer == true) {
      final now = DateTime.now();
      final day = DateFormat('EEEE', 'en_US').format(now);
      final date = DateFormat('dd-MM-yyyy').format(now);

      for (var element in vendorModel.value.specialDiscount ?? []) {
        if (day == element.day.toString()) {
          for (var slot in element.timeslot ?? []) {
            if (slot.discountType == "delivery") {
              final start = DateFormat("dd-MM-yyyy HH:mm").parse("$date ${slot.from}");
              final end = DateFormat("dd-MM-yyyy HH:mm").parse("$date ${slot.to}");

              if (isCurrentDateInRange(start, end)) {
                specialDiscount.value = double.parse(slot.discount.toString());
                specialType.value = slot.type.toString();

                specialDiscountAmount.value = slot.type == "percentage" ? (subTotal.value * specialDiscount.value / 100) : specialDiscount.value;
              }
            }
          }
        }
      }
    }

    /// ---------------- DISCOUNT RATIO ----------------
    final totalDiscount = couponAmount.value + specialDiscountAmount.value;
    double discountRatio = 0.0;

    if (subTotal.value > 0 && totalDiscount > 0) {
      discountRatio = totalDiscount / subTotal.value;
    }

    /// ---------------- PRODUCT TAX (AFTER DISCOUNT) ----------------
    if (Constant.taxScope == "product") {
      for (var element in cartItem) {
        final price = double.parse((element.discountPrice != null && double.parse(element.discountPrice.toString()) > 0) ? element.discountPrice.toString() : element.price.toString());

        final qty = double.parse(element.quantity.toString());
        final extras = double.parse(element.extrasPrice.toString());

        final itemAmount = (price * qty) + (extras * qty);
        final discountedItemAmount = itemAmount - (itemAmount * discountRatio);

        for (var taxElement in element.taxSetting ?? []) {
          if (taxElement.type == "fix") {
            productTaxAmount.value += Constant.calculateTax(amount: discountedItemAmount.toString(), taxModel: taxElement) * qty;
          } else {
            productTaxAmount.value += Constant.calculateTax(amount: discountedItemAmount.toString(), taxModel: taxElement);
          }
        }
      }
    }

    /// ---------------- ORDER TAX ----------------
    if (Constant.taxScope == "order") {
      for (var taxElement in Constant.orderProductTaxList ?? []) {
        orderTaxAmount.value += Constant.calculateTax(amount: (subTotal.value - totalDiscount).toString(), taxModel: taxElement);
      }
    }

    /// ---------------- DELIVERY TAX ----------------
    if (selectedFoodType.value != 'TakeAway' && vendorModel.value.isSelfDelivery != true) {
      for (var taxElement in Constant.driverDeliveryTaxList ?? []) {
        driverDeliveryTaxAmount.value += Constant.calculateTax(amount: deliveryCharges.value.toString(), taxModel: taxElement);
      }
    }

    /// ---------------- PACKAGING TAX ----------------
    if (Constant.sectionConstantModel!.packagingChargeEnable == true && packagingCharge.value > 0) {
      for (var taxElement in Constant.packagingTaxList ?? []) {
        packagingTaxAmount.value += Constant.calculateTax(amount: packagingCharge.value.toString(), taxModel: taxElement);
      }
    }

    /// ---------------- PLATFORM TAX ----------------
    if (Constant.platformFeeModel?.enable == true && platformFee.value > 0) {
      for (var taxElement in Constant.platformTaxList ?? []) {
        platformTaxAmount.value += Constant.calculateTax(amount: platformFee.value.toString(), taxModel: taxElement);
      }
    }

    /// ---------------- TOTAL ----------------
    totalTaxAmount.value = productTaxAmount.value + orderTaxAmount.value + driverDeliveryTaxAmount.value + packagingTaxAmount.value + platformTaxAmount.value;
    log("totalTaxAmount.value :: ${productTaxAmount.value} + ${orderTaxAmount.value} + ${driverDeliveryTaxAmount.value} + ${packagingTaxAmount.value} + ${platformTaxAmount.value}");
    log("totalAmount.value :: ${(subTotal.value - totalDiscount)} + ${totalTaxAmount.value} + ${deliveryCharges.value} + ${deliveryTips.value} + ${packagingCharge.value} + ${platformFee.value}");
    totalAmount.value = (subTotal.value - totalDiscount) + totalTaxAmount.value + deliveryCharges.value + deliveryTips.value + packagingCharge.value + platformFee.value;

    getCashback();
  }

  Future<void> getCashback() async {
    if (Constant.isCashbackActive == true) {
      final paymentMethod = selectedPaymentMethod.value;
      final orderTotal = subTotal.value;
      final now = DateTime.now();

      List<CashbackModel> eligibleCashbacks = [];
      double maxCashbackValue = 0.0;

      final cashbackModelList = await FireStoreUtils.getAllCashbak();

      for (final cashback in cashbackModelList) {
        final startDate = cashback.startDate;
        final endDate = cashback.endDate;

        if (startDate == null || endDate == null) continue;

        final withinDateRange = startDate.toDate().isBefore(now) && endDate.toDate().isAfter(now);
        final meetsMinAmount = orderTotal >= (cashback.minimumPurchaseAmount ?? 0);
        final allPayment = cashback.allPayment ?? false;
        final paymentMatch = allPayment || (cashback.paymentMethods ?? []).contains(paymentMethod);
        final allCustomer = cashback.allCustomer ?? false;
        final customerMatch = allCustomer || (cashback.customerIds ?? []).contains(FireStoreUtils.getCurrentUid());

        final redeemData = await FireStoreUtils.getRedeemedCashbacks(cashback.id ?? '');
        final underLimit = redeemData.length < (cashback.redeemLimit ?? 0);

        if (withinDateRange && meetsMinAmount && paymentMatch && customerMatch && underLimit) {
          eligibleCashbacks.add(cashback);
        }
      }
      bestCashback.value = CashbackModel();
      for (final cashback in eligibleCashbacks) {
        double cashbackValue = 0.0;

        if (cashback.cashbackType == 'Percent') {
          final percentage = cashback.cashbackAmount ?? 0.0;
          cashbackValue = (percentage / 100.0) * orderTotal;
        } else if (cashback.cashbackType == 'Fixed') {
          cashbackValue = cashback.cashbackAmount ?? 0.0;
        }

        final maxDiscount = cashback.maximumDiscount ?? cashbackValue;
        if (cashbackValue > maxDiscount) cashbackValue = maxDiscount;

        if (cashbackValue > maxCashbackValue) {
          maxCashbackValue = cashbackValue;
          bestCashback.value = cashback;
        }
      }

      if (bestCashback.value.id != null) {
        final cashbackValue = maxCashbackValue;
        isCashbackApply.value = true;
        bestCashback.value.cashbackValue = cashbackValue;
      } else {
        bestCashback.value = CashbackModel();
        isCashbackApply.value = false;
      }
    } else {
      bestCashback.value = CashbackModel();
      isCashbackApply.value = false;
    }
  }

  Future<void> addToCart({required CartProductModel cartProductModel, required bool isIncrement, required int quantity}) async {
    if (isIncrement) {
      cartProvider.addToCart(Get.context!, cartProductModel, quantity);
    } else {
      cartProvider.removeFromCart(cartProductModel, quantity);
    }
    update();
  }

  List<CartProductModel> tempProduc = [];

  Future<void> placeOrder() async {
    // JOXMAKO: paiement à la livraison uniquement
    setOrder();
  }

  Future<void> setOrder({String? paymentMethod, String? overrideOrderId}) async {
    ShowToastDialog.showLoader("Please wait...".tr);

    if ((Constant.isSubscriptionModelApplied == true || Constant.sectionConstantModel?.adminCommision?.isEnabled == true) && vendorModel.value.subscriptionPlan != null) {
      await FireStoreUtils.getVendorById(vendorModel.value.id!).then((vender) async {
        if (vender?.subscriptionTotalOrders == '0' || vender?.subscriptionTotalOrders == null) {
          ShowToastDialog.closeLoader();
          ShowToastDialog.showToast("This vendor has reached their maximum order capacity. Please select a different vendor or try again later.".tr);
          return;
        }
      });
    }

    for (CartProductModel cartProduct in cartItem) {
      CartProductModel tempCart = cartProduct;
      if (cartProduct.extrasPrice == '0') {
        tempCart.extras = [];
      }
      tempProduc.add(tempCart);
    }

    Map<String, dynamic> specialDiscountMap = {'special_discount': specialDiscountAmount.value, 'special_discount_label': specialDiscount.value, 'specialType': specialType.value};

    OrderModel orderModel = OrderModel();
    orderModel.id = overrideOrderId ?? Constant.getUuid();
    orderModel.address = selectedAddress.value;
    orderModel.authorID = FireStoreUtils.getCurrentUid();
    orderModel.author = userModel.value;
    orderModel.vendorID = vendorModel.value.id;
    orderModel.vendor = vendorModel.value;
    orderModel.adminCommission =
        Constant.sectionConstantModel?.adminCommision?.isEnabled == false
            ? '0'
            : vendorModel.value.adminCommission != null
            ? vendorModel.value.adminCommission!.amount.toString()
            : Constant.sectionConstantModel?.adminCommision?.amount.toString();
    orderModel.adminCommissionType =
        Constant.sectionConstantModel?.adminCommision?.isEnabled == false
            ? 'fixed'
            : vendorModel.value.adminCommission != null
            ? vendorModel.value.adminCommission!.commissionType
            : Constant.sectionConstantModel?.adminCommision?.commissionType;
    orderModel.status = Constant.orderPlaced;
    orderModel.discount = couponAmount.value;
    orderModel.couponId = selectedCouponModel.value.id;
    orderModel.paymentMethod = paymentMethod ?? selectedPaymentMethod.value;
    orderModel.products = cartItem;
    orderModel.sectionId = Constant.sectionConstantModel?.id;
    orderModel.specialDiscount = specialDiscountMap;
    orderModel.couponCode = selectedCouponModel.value.code;
    orderModel.deliveryCharge = deliveryCharges.value.toString();
    orderModel.tipAmount = deliveryTips.value.toString();
    orderModel.notes = reMarkController.value.text;
    orderModel.takeAway = selectedFoodType.value == "Delivery" ? false : true;
    orderModel.createdAt = Timestamp.now();
    orderModel.scheduleTime = deliveryType.value == "schedule" ? Timestamp.fromDate(scheduleDateTime.value) : null;
    orderModel.cashback = bestCashback.value.id == null ? null : bestCashback.value;

    orderModel.taxSetting = Constant.taxScope == "order" ? Constant.orderProductTaxList : [];
    orderModel.driverDeliveryTax = Constant.driverDeliveryTaxList;
    orderModel.packagingTax = Constant.packagingTaxList;
    orderModel.platformTax = Constant.platformTaxList;
    orderModel.taxScope = Constant.taxScope;
    orderModel.platformFee = platformFee.value.toString();
    orderModel.packagingChargeEnable = Constant.sectionConstantModel?.packagingChargeEnable == true;
    if (selectedPaymentMethod.value == PaymentGateway.wallet.name) {
      WalletTransactionModel transactionModel = WalletTransactionModel(
        id: Constant.getUuid(),
        amount: double.parse(totalAmount.value.toString()),
        date: Timestamp.now(),
        paymentMethod: PaymentGateway.wallet.name,
        transactionUser: "customer",
        userId: FireStoreUtils.getCurrentUid(),
        isTopup: false,
        orderId: orderModel.id,
        note: "Order Amount debited".tr,
        paymentStatus: "success".tr,
      );

      await FireStoreUtils.setWalletTransaction(transactionModel).then((value) async {
        if (value == true) {
          await FireStoreUtils.updateUserWallet(amount: "-${totalAmount.value.toString()}", userId: FireStoreUtils.getCurrentUid()).then((value) {});
        }
      });
    }

    for (int i = 0; i < tempProduc.length; i++) {
      await FireStoreUtils.getProductById(tempProduc[i].id!.split('~').first).then((value) async {
        ProductModel? productModel = value;
        if (tempProduc[i].variantInfo != null) {
          if (productModel!.itemAttribute != null) {
            for (int j = 0; j < productModel.itemAttribute!.variants!.length; j++) {
              if (productModel.itemAttribute!.variants![j].variantId == tempProduc[i].id!.split('~').last) {
                if (productModel.itemAttribute!.variants![j].variantQuantity != "-1") {
                  productModel.itemAttribute!.variants![j].variantQuantity = (int.parse(productModel.itemAttribute!.variants![j].variantQuantity.toString()) - tempProduc[i].quantity!).toString();
                }
              }
            }
          } else {
            if (productModel.quantity != -1) {
              productModel.quantity = (productModel.quantity! - tempProduc[i].quantity!);
            }
          }
        } else {
          if (productModel!.quantity != -1) {
            productModel.quantity = (productModel.quantity! - tempProduc[i].quantity!);
          }
        }

        await FireStoreUtils.setProduct(productModel);
      });
    }
    if (Constant.isCashbackActive == true && bestCashback.value.id != null) {
      CashbackRedeemModel cashbackRedeemModel = CashbackRedeemModel(
        id: Constant.getUuid(),
        cashbackId: bestCashback.value.id,
        userId: FireStoreUtils.getCurrentUid(),
        orderId: orderModel.id,
        createdAt: Timestamp.now(),
      );
      await FireStoreUtils.setCashbackRedeemModel(cashbackRedeemModel);
    }
    await FireStoreUtils.setOrder(orderModel).then((value) async {
      await FireStoreUtils.getUserProfile(orderModel.vendor!.author.toString()).then((value) async {
        if (value != null) {
          if (orderModel.scheduleTime != null) {
            await SendNotification.sendFcmMessage(Constant.scheduleOrder, value.fcmToken ?? '', {});
          } else {
            await SendNotification.sendFcmMessage(Constant.orderPlacedNotification, value.fcmToken ?? '', {});
          }
        }
      });
      await Constant.sendOrderEmail(orderModel: orderModel);
      ShowToastDialog.closeLoader();
      Get.off(const OrderPlacingScreen(), arguments: {"orderModel": orderModel});
    });
  }

  Rx<WalletSettingModel> walletSettingModel = WalletSettingModel().obs;
  Rx<CodSettingModel> cashOnDeliverySettingModel = CodSettingModel().obs;
  Rx<PaydunyaConfigModel> paydunyaConfig = PaydunyaConfigModel().obs;
  RxBool isLoading = true.obs;

  Future<void> getPaymentSettings() async {
    isLoading.value = true;
    await FireStoreUtils.getPaymentSettingsData();
    walletSettingModel.value = WalletSettingModel.fromJson(
      jsonDecode(Preferences.getString(Preferences.walletSettings, defaultValue: '{}')),
    );
    cashOnDeliverySettingModel.value = CodSettingModel.fromJson(
      jsonDecode(Preferences.getString(Preferences.codSettings, defaultValue: '{}')),
    );

    // JOXMAKO: toujours COD — pas de wallet customer
    selectedPaymentMethod.value = PaymentGateway.cod.name;

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

  Future<void> initiatePaydunyaPayment(BuildContext context) async {
    ShowToastDialog.showLoader("Please wait...".tr);
    final orderId = const Uuid().v4();

    try {
      final createUrl = '${Uri.parse(Constant.globalUrl).origin}/process-paydunya';
      log('[PayDunya] → POST $createUrl');
      final createBody = jsonEncode({
        'amount': totalAmount.value,
        'order_id': orderId,
        'customer_name': userModel.value.fullName(),
        'customer_email': userModel.value.email ?? '',
      });
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
        orderId: orderId,
      ));

      if (result == true) {
        await setOrder(paymentMethod: PaymentGateway.paydunya.name, overrideOrderId: orderId);
      } else if (result == 'expired') {
        ShowToastDialog.showToast("Délai de paiement dépassé. Commande annulée.".tr);
      } else {
        ShowToastDialog.showToast("Paiement annulé.".tr);
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Une erreur est survenue. Veuillez réessayer.".tr);
      log('PayDunya payment error: $e');
    }
  }

  bool isCurrentDateInRange(DateTime startDate, DateTime endDate) {
    final currentDate = DateTime.now();
    return currentDate.isAfter(startDate) && currentDate.isBefore(endDate);
  }

  bool isSelectedDateRestaurantOpen({required DateTime selectedDateTime}) {
    bool isOpen = false;
    final now = selectedDateTime;
    var day = DateFormat('EEEE', 'en_US').format(now);
    var date = DateFormat('dd-MM-yyyy').format(now);
    for (var element in vendorModel.value.workingHours!) {
      if (day == element.day.toString()) {
        if (element.timeslot!.isNotEmpty) {
          for (var element in element.timeslot!) {
            var start = DateFormat("dd-MM-yyyy HH:mm").parse("$date ${element.from}");
            var end = DateFormat("dd-MM-yyyy HH:mm").parse("$date ${element.to}");
            if (isCurrentDateInRange(start, end)) {
              isOpen = true;
            }
          }
        }
      }
    }
    return isOpen;
  }
}
