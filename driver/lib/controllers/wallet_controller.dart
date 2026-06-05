// ignore_for_file: library_prefixes, depend_on_referenced_packages, strict_top_level_inference, use_build_context_synchronously

import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as maths;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/collection_name.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/models/cab_order_model.dart';
import 'package:driver/models/order_model.dart';
import 'package:driver/models/parcel_order_model.dart';
import 'package:driver/models/payment_model/flutter_wave_model.dart';
import 'package:driver/models/payment_model/mercado_pago_model.dart';
import 'package:driver/models/payment_model/mid_trans.dart';
import 'package:driver/models/payment_model/orange_money.dart';
import 'package:driver/models/payment_model/pay_fast_model.dart';
import 'package:driver/models/payment_model/pay_stack_model.dart';
import 'package:driver/models/payment_model/paypal_model.dart';
import 'package:driver/models/payment_model/razorpay_model.dart';
import 'package:driver/models/payment_model/stripe_model.dart';
import 'package:driver/models/payment_model/xendit.dart';
import 'package:driver/models/rental_order_model.dart';
import 'package:driver/models/user_model.dart';
import 'package:driver/models/wallet_transaction_model.dart';
import 'package:driver/models/withdraw_method_model.dart';
import 'package:driver/models/withdrawal_model.dart';
import 'package:driver/payment/MercadoPagoScreen.dart';
import 'package:driver/payment/PayFastScreen.dart';
import 'package:driver/payment/midtrans_screen.dart';
import 'package:driver/payment/orangePayScreen.dart';
import 'package:driver/payment/paystack/pay_stack_screen.dart';
import 'package:driver/payment/paystack/pay_stack_url_model.dart';
import 'package:driver/payment/paystack/paystack_url_genrater.dart';
import 'package:driver/payment/stripe_failed_model.dart';
import 'package:driver/payment/xenditModel.dart';
import 'package:driver/payment/xenditScreen.dart';
import 'package:driver/themes/app_them_data.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:driver/utils/preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_paypal/flutter_paypal.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as flutterStipe;
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:uuid/uuid.dart';

class DriverDailyDeliveryItem {
  final String id;
  final String sourceCollection;
  final String serviceType;
  final double totalCollected;
  final double driverEarning;
  final String paymentMethod;
  final String status;
  final Timestamp? activityAt;

  DriverDailyDeliveryItem({
    required this.id,
    required this.sourceCollection,
    required this.serviceType,
    required this.totalCollected,
    required this.driverEarning,
    required this.paymentMethod,
    required this.status,
    required this.activityAt,
  });
}

class WalletController extends GetxController {
  RxBool isLoading = true.obs;

  Rx<TextEditingController> topUpAmountController = TextEditingController().obs;
  RxString selectedPaymentMethod = "".obs;

  Rx<TextEditingController> amountTextFieldController =
      TextEditingController().obs;
  Rx<TextEditingController> noteTextFieldController =
      TextEditingController().obs;

  Rx<UserModel> userModel = UserModel().obs;
  RxList<WalletTransactionModel> walletTopTransactionList =
      <WalletTransactionModel>[].obs;
  RxList<WithdrawalModel> withdrawalList = <WithdrawalModel>[].obs;
  RxList<DriverDailyDeliveryItem> todayDeliveryHistory =
      <DriverDailyDeliveryItem>[].obs;

  RxList<OrderModel> dailyEarningList = <OrderModel>[].obs;
  RxList<OrderModel> monthlyEarningList = <OrderModel>[].obs;
  RxList<OrderModel> yearlyEarningList = <OrderModel>[].obs;

  RxList<ParcelOrderModel> dailyParcelEarningList = <ParcelOrderModel>[].obs;
  RxList<ParcelOrderModel> monthlyParcelEarningList = <ParcelOrderModel>[].obs;
  RxList<ParcelOrderModel> yearlyParcelEarningList = <ParcelOrderModel>[].obs;

  RxList<RentalOrderModel> dailyRentalEarningList = <RentalOrderModel>[].obs;
  RxList<RentalOrderModel> monthlyRentalEarningList = <RentalOrderModel>[].obs;
  RxList<RentalOrderModel> yearlyRentalEarningList = <RentalOrderModel>[].obs;

  RxList<CabOrderModel> dailyCabEarningList = <CabOrderModel>[].obs;
  RxList<CabOrderModel> monthlyCabEarningList = <CabOrderModel>[].obs;
  RxList<CabOrderModel> yearlyCabEarningList = <CabOrderModel>[].obs;

  RxList<String> dropdownValue = ["Daily", "Monthly", "Yearly"].obs;
  RxString selectedDropDownValue = "Daily".obs;

  RxInt selectedTabIndex = 0.obs;
  RxInt selectedValue = 0.obs;

  Rx<WithdrawMethodModel> withdrawMethodModel = WithdrawMethodModel().obs;
  RxDouble pendingCashToRemit = 0.0.obs;
  RxDouble cashCollectedAmount = 0.0.obs;
  RxDouble unpaidEarnings = 0.0.obs;
  RxDouble paidEarnings = 0.0.obs;

  @override
  void onInit() {
    getWalletTransaction();
    getPaymentSettings();
    loadPendingCash();
    loadEarningsBreakdown();
    loadTodayDeliveryHistory();
    super.onInit();
  }

  Future<void> loadPendingCash() async {
    try {
      final uid = FireStoreUtils.getCurrentUid();
      double cashToRemit = 0.0;
      double collected = 0.0;
      final seenCollected = <String>{};
      final seenRemit = <String>{};

      Future<void> readCollection(String collection, String driverField) async {
        final assignedSnap = await FireStoreUtils.fireStore
            .collection(collection)
            .where(driverField, isEqualTo: uid)
            .get();
        for (final doc in assignedSnap.docs) {
          final data = doc.data();
          final key = '$collection/${doc.id}';
          if (_isCompletedStatus(data) && seenCollected.add(key)) {
            collected += _totalCollectedAmount(data);
          }
          if (_mustRemitCash(data) && seenRemit.add(key)) {
            cashToRemit += _cashToRemitAmount(data);
          }
        }

        final collectedSnap = await FireStoreUtils.fireStore
            .collection(collection)
            .where('collected_by_driver_id', isEqualTo: uid)
            .get();
        for (final doc in collectedSnap.docs) {
          final data = doc.data();
          final key = '$collection/${doc.id}';
          if (seenCollected.add(key)) {
            collected += _totalCollectedAmount(data);
          }
          if (_mustRemitCash(data) && seenRemit.add(key)) {
            cashToRemit += _cashToRemitAmount(data);
          }
        }
      }

      await readCollection(CollectionName.vendorOrders, 'driverID');
      await readCollection(CollectionName.ridesBooking, 'driverId');
      await readCollection(CollectionName.parcelOrders, 'driverId');
      await readCollection(CollectionName.rentalOrders, 'driverId');

      pendingCashToRemit.value = cashToRemit;
      cashCollectedAmount.value = collected;
    } catch (error) {
      log(error.toString());
    }
  }

  Future<void> loadEarningsBreakdown() async {
    try {
      final uid = FireStoreUtils.getCurrentUid();
      double unpaid = 0.0;
      double paid = 0.0;

      Future<void> readCollection(String collection, String driverField) async {
        final snap = await FireStoreUtils.fireStore
            .collection(collection)
            .where(driverField, isEqualTo: uid)
            .get();
        for (final doc in snap.docs) {
          final data = doc.data();
          if (!_isCompletedStatus(data)) {
            continue;
          }
          final earning = _driverEarningAmount(data);
          if ((data['driver_payout_status'] ?? '').toString().toLowerCase() ==
              'paid') {
            paid += earning;
          } else {
            unpaid += earning;
          }
        }
      }

      await readCollection(CollectionName.vendorOrders, 'driverID');
      await readCollection(CollectionName.ridesBooking, 'driverId');
      await readCollection(CollectionName.parcelOrders, 'driverId');
      await readCollection(CollectionName.rentalOrders, 'driverId');

      unpaidEarnings.value = unpaid;
      paidEarnings.value = paid;
    } catch (error) {
      log(error.toString());
    }
  }

  Future<void> loadTodayDeliveryHistory() async {
    try {
      final uid = FireStoreUtils.getCurrentUid();
      final items = <DriverDailyDeliveryItem>[];

      Future<void> readCollection({
        required String collection,
        required String driverField,
        required String fallbackServiceType,
      }) async {
        final snap = await FireStoreUtils.fireStore
            .collection(collection)
            .where(driverField, isEqualTo: uid)
            .get();
        for (final doc in snap.docs) {
          final data = doc.data();
          final activityAt = _activityTimestamp(data);
          if (!_isToday(activityAt)) {
            continue;
          }
          items.add(DriverDailyDeliveryItem(
            id: (data['id'] ?? doc.id).toString(),
            sourceCollection: collection,
            serviceType: _serviceLabel(data, fallbackServiceType),
            totalCollected: _totalCollectedAmount(data),
            driverEarning: _driverEarningAmount(data),
            paymentMethod: _paymentMethodLabel(data),
            status: _statusLabel(data),
            activityAt: activityAt,
          ));
        }
      }

      await readCollection(
        collection: CollectionName.vendorOrders,
        driverField: 'driverID',
        fallbackServiceType: 'Livraison',
      );
      await readCollection(
        collection: CollectionName.parcelOrders,
        driverField: 'driverId',
        fallbackServiceType: 'Colis',
      );
      await readCollection(
        collection: CollectionName.ridesBooking,
        driverField: 'driverId',
        fallbackServiceType: 'Course',
      );
      await readCollection(
        collection: CollectionName.rentalOrders,
        driverField: 'driverId',
        fallbackServiceType: 'Location',
      );

      items.sort((a, b) {
        final aDate = a.activityAt?.toDate() ?? DateTime(1970);
        final bDate = b.activityAt?.toDate() ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });
      todayDeliveryHistory.value = items;
    } catch (error) {
      log(error.toString());
    }
  }

  bool _isToday(Timestamp? timestamp) {
    if (timestamp == null) {
      return false;
    }
    final date = timestamp.toDate();
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isCompletedStatus(Map<String, dynamic> data) {
    final status = (data['status'] ?? '').toString().toLowerCase();
    return status.contains('completed') ||
        status.contains('complete') ||
        status.contains('delivered') ||
        status.contains('termin');
  }

  bool _isCashPayment(Map<String, dynamic> data) {
    final method = _paymentMethodLabel(data).toLowerCase();
    return method.contains('cash') ||
        method.contains('cod') ||
        method.contains('espèce') ||
        method.contains('espece');
  }

  bool _mustRemitCash(Map<String, dynamic> data) {
    final status = (data['cash_remittance_status'] ??
            data['remittance_status'] ??
            'pending')
        .toString()
        .toLowerCase();
    return _isCashPayment(data) && status != 'paid' && status != 'remitted';
  }

  double _cashToRemitAmount(Map<String, dynamic> data) {
    final explicit = _numberValue(data['cash_to_remit'] ?? data['cashToRemit']);
    if (explicit > 0) {
      return explicit;
    }
    return _totalCollectedAmount(data);
  }

  double _totalCollectedAmount(Map<String, dynamic> data) {
    return _firstNumber(data, [
      'total_collected',
      'totalCollected',
      'cash_collected_amount',
      'cashCollectedAmount',
      'total_amount',
      'totalAmount',
      'total_price',
      'totalPrice',
      'final_amount',
      'finalAmount',
      'booking_total',
      'bookingTotal',
      'amount',
      'sub_total',
      'subTotal',
    ]);
  }

  double _driverEarningAmount(Map<String, dynamic> data) {
    return _firstNumber(data, [
      'driver_earning',
      'driverEarning',
      'driver_amount',
      'driverAmount',
      'delivery_charge',
      'deliveryCharge',
    ]);
  }

  double _firstNumber(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = _numberValue(data[key]);
      if (value > 0) {
        return value;
      }
    }
    return 0;
  }

  double _numberValue(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  Timestamp? _activityTimestamp(Map<String, dynamic> data) {
    for (final key in [
      'completedAt',
      'completed_at',
      'deliveredAt',
      'delivered_at',
      'updatedAt',
      'updated_at',
      'createdAt',
      'created_at',
    ]) {
      final value = data[key];
      if (value is Timestamp) {
        return value;
      }
    }
    return null;
  }

  String _serviceLabel(Map<String, dynamic> data, String fallback) {
    for (final key in [
      'sectionName',
      'section_name',
      'serviceName',
      'service_name',
      'serviceType',
      'service_type',
      'type',
    ]) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return fallback;
  }

  String _paymentMethodLabel(Map<String, dynamic> data) {
    for (final key in [
      'collected_payment_method',
      'collectedPaymentMethod',
      'payment_method',
      'paymentMethod',
      'paymentType',
      'payment_type',
      'payment_mode',
      'paymentMode',
      'method',
    ]) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return _normalizePaymentMethod(value);
      }
    }
    return 'Non renseigné';
  }

  String _normalizePaymentMethod(String raw) {
    final v = raw.toLowerCase().trim();
    if (v == 'cod' ||
        v == 'cash' ||
        v == 'cash_on_delivery' ||
        v == 'cashondelivery' ||
        v.contains('espece') ||
        v.contains('espèce') ||
        v.contains('liquide')) {
      return 'Espèces';
    }
    if (v.contains('wave')) return 'Wave';
    if (v == 'om' ||
        v.contains('orange_money') ||
        v.contains('orangemoney') ||
        v.contains('orange money') ||
        v.startsWith('orange')) {
      return 'Orange Money';
    }
    if (v.isEmpty || v == '-') return 'Non renseigné';
    return raw;
  }

  String _statusLabel(Map<String, dynamic> data) {
    return (data['status'] ??
            data['orderStatus'] ??
            data['paymentStatus'] ??
            '-')
        .toString();
  }

  Rx<PayFastModel> payFastModel = PayFastModel().obs;
  Rx<MercadoPagoModel> mercadoPagoModel = MercadoPagoModel().obs;
  Rx<PayPalModel> payPalModel = PayPalModel().obs;
  Rx<StripeModel> stripeModel = StripeModel().obs;
  Rx<FlutterWaveModel> flutterWaveModel = FlutterWaveModel().obs;
  Rx<PayStackModel> payStackModel = PayStackModel().obs;
  Rx<RazorPayModel> razorPayModel = RazorPayModel().obs;

  Rx<MidTrans> midTransModel = MidTrans().obs;
  Rx<OrangeMoney> orangeMoneyModel = OrangeMoney().obs;
  Rx<Xendit> xenditModel = Xendit().obs;

  Future<void> getPaymentSettings() async {
    await FireStoreUtils.getPaymentSettingsData().then(
      (value) {
        payFastModel.value = PayFastModel.fromJson(
            jsonDecode(Preferences.getString(Preferences.payFastSettings)));
        mercadoPagoModel.value = MercadoPagoModel.fromJson(
            jsonDecode(Preferences.getString(Preferences.mercadoPago)));
        payPalModel.value = PayPalModel.fromJson(
            jsonDecode(Preferences.getString(Preferences.paypalSettings)));
        stripeModel.value = StripeModel.fromJson(
            jsonDecode(Preferences.getString(Preferences.stripeSettings)));
        flutterWaveModel.value = FlutterWaveModel.fromJson(
            jsonDecode(Preferences.getString(Preferences.flutterWave)));
        payStackModel.value = PayStackModel.fromJson(
            jsonDecode(Preferences.getString(Preferences.payStack)));
        razorPayModel.value = RazorPayModel.fromJson(
            jsonDecode(Preferences.getString(Preferences.razorpaySettings)));

        midTransModel.value = MidTrans.fromJson(
            jsonDecode(Preferences.getString(Preferences.midTransSettings)));
        orangeMoneyModel.value = OrangeMoney.fromJson(
            jsonDecode(Preferences.getString(Preferences.orangeMoneySettings)));
        xenditModel.value = Xendit.fromJson(
            jsonDecode(Preferences.getString(Preferences.xenditSettings)));

        flutterStipe.Stripe.publishableKey =
            stripeModel.value.clientpublishableKey.toString();
        flutterStipe.Stripe.merchantIdentifier = 'JOXMAKO Driver';
        flutterStipe.Stripe.instance.applySettings();
        setRef();

        razorPay.on(Razorpay.EVENT_PAYMENT_SUCCESS, handlePaymentSuccess);
        razorPay.on(Razorpay.EVENT_EXTERNAL_WALLET, handleExternalWaller);
        razorPay.on(Razorpay.EVENT_PAYMENT_ERROR, handlePaymentError);
      },
    );
  }

  Future<void> getWalletTransaction() async {
    await FireStoreUtils.getWalletTransaction().then(
      (value) {
        if (value != null) {
          walletTopTransactionList.value = value;
        }
      },
    );

    await FireStoreUtils.getWithdrawHistory().then(
      (value) {
        if (value != null) {
          withdrawalList.value = value;
        }
      },
    );

    // DateTime nowDate = DateTime.now();

    await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid()).then(
      (value) {
        if (value != null) {
          userModel.value = value;
        }
      },
    );

    // if(userModel.value.serviceType == "delivery-service"){
    //   await FireStoreUtils.fireStore
    //       .collection(CollectionName.vendorOrders)
    //       .where('driverID', isEqualTo: Constant.userModel!.id.toString())
    //       .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(nowDate.year, nowDate.month, nowDate.day)))
    //       .orderBy('createdAt', descending: true)
    //       .get()
    //       .then((value) {
    //     for (var element in value.docs) {
    //       OrderModel dailyEarningModel = OrderModel.fromJson(element.data());
    //       dailyEarningList.add(dailyEarningModel);
    //     }
    //   }).catchError((error) {
    //     log(error.toString());
    //   });
    //
    //   await FireStoreUtils.fireStore
    //       .collection(CollectionName.vendorOrders)
    //       .where('driverID', isEqualTo: Constant.userModel!.id.toString())
    //       .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(nowDate.year, nowDate.month)))
    //       .orderBy('createdAt', descending: true)
    //       .get()
    //       .then((value) {
    //     for (var element in value.docs) {
    //       OrderModel dailyEarningModel = OrderModel.fromJson(element.data());
    //       monthlyEarningList.add(dailyEarningModel);
    //     }
    //   }).catchError((error) {
    //     log(error.toString());
    //   });
    //
    //   await FireStoreUtils.fireStore
    //       .collection(CollectionName.vendorOrders)
    //       .where('driverID', isEqualTo: Constant.userModel!.id.toString())
    //       .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(nowDate.year)))
    //       .orderBy('createdAt', descending: true)
    //       .get()
    //       .then((value) {
    //     for (var element in value.docs) {
    //       OrderModel dailyEarningModel = OrderModel.fromJson(element.data());
    //       yearlyEarningList.add(dailyEarningModel);
    //     }
    //   }).catchError((error) {
    //     log(error.toString());
    //   });
    // }
    // else if(userModel.value.serviceType == "parcel_delivery"){
    //   await FireStoreUtils.fireStore
    //       .collection(CollectionName.parcelOrders)
    //       .where('driverId', isEqualTo: Constant.userModel!.id.toString())
    //       .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(nowDate.year, nowDate.month, nowDate.day)))
    //       .orderBy('createdAt', descending: true)
    //       .get()
    //       .then((value) {
    //     for (var element in value.docs) {
    //       ParcelOrderModel dailyEarningModel = ParcelOrderModel.fromJson(element.data());
    //       dailyParcelEarningList.add(dailyEarningModel);
    //     }
    //   }).catchError((error) {
    //     log(error.toString());
    //   });
    //
    //   await FireStoreUtils.fireStore
    //       .collection(CollectionName.parcelOrders)
    //       .where('driverId', isEqualTo: Constant.userModel!.id.toString())
    //       .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(nowDate.year, nowDate.month)))
    //       .orderBy('createdAt', descending: true)
    //       .get()
    //       .then((value) {
    //     for (var element in value.docs) {
    //       ParcelOrderModel dailyEarningModel = ParcelOrderModel.fromJson(element.data());
    //       monthlyParcelEarningList.add(dailyEarningModel);
    //     }
    //   }).catchError((error) {
    //     log(error.toString());
    //   });
    //
    //   await FireStoreUtils.fireStore
    //       .collection(CollectionName.parcelOrders)
    //       .where('driverId', isEqualTo: Constant.userModel!.id.toString())
    //       .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(nowDate.year)))
    //       .orderBy('createdAt', descending: true)
    //       .get()
    //       .then((value) {
    //     for (var element in value.docs) {
    //       ParcelOrderModel dailyEarningModel = ParcelOrderModel.fromJson(element.data());
    //       yearlyParcelEarningList.add(dailyEarningModel);
    //     }
    //   }).catchError((error) {
    //     log(error.toString());
    //   });
    // }
    // else if(userModel.value.serviceType == "rental-service"){
    //   await FireStoreUtils.fireStore
    //       .collection(CollectionName.rentalOrders)
    //       .where('driverId', isEqualTo: Constant.userModel!.id.toString())
    //       .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(nowDate.year, nowDate.month, nowDate.day)))
    //       .orderBy('createdAt', descending: true)
    //       .get()
    //       .then((value) {
    //     for (var element in value.docs) {
    //       RentalOrderModel dailyEarningModel = RentalOrderModel.fromJson(element.data());
    //       dailyRentalEarningList.add(dailyEarningModel);
    //     }
    //   }).catchError((error) {
    //     log(error.toString());
    //   });
    //
    //   await FireStoreUtils.fireStore
    //       .collection(CollectionName.rentalOrders)
    //       .where('driverId', isEqualTo: Constant.userModel!.id.toString())
    //       .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(nowDate.year, nowDate.month)))
    //       .orderBy('createdAt', descending: true)
    //       .get()
    //       .then((value) {
    //     for (var element in value.docs) {
    //       RentalOrderModel dailyEarningModel = RentalOrderModel.fromJson(element.data());
    //       monthlyRentalEarningList.add(dailyEarningModel);
    //     }
    //   }).catchError((error) {
    //     log(error.toString());
    //   });
    //
    //   await FireStoreUtils.fireStore
    //       .collection(CollectionName.rentalOrders)
    //       .where('driverId', isEqualTo: Constant.userModel!.id.toString())
    //       .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(nowDate.year)))
    //       .orderBy('createdAt', descending: true)
    //       .get()
    //       .then((value) {
    //     for (var element in value.docs) {
    //       RentalOrderModel dailyEarningModel = RentalOrderModel.fromJson(element.data());
    //       yearlyRentalEarningList.add(dailyEarningModel);
    //     }
    //   }).catchError((error) {
    //     log(error.toString());
    //   });
    // }
    // else if(userModel.value.serviceType == "cab-service"){
    //   await FireStoreUtils.fireStore
    //       .collection(CollectionName.ridesBooking)
    //       .where('driverId', isEqualTo: Constant.userModel!.id.toString())
    //       .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(nowDate.year, nowDate.month, nowDate.day)))
    //       .orderBy('createdAt', descending: true)
    //       .get()
    //       .then((value) {
    //     for (var element in value.docs) {
    //       CabOrderModel dailyEarningModel = CabOrderModel.fromJson(element.data());
    //       dailyCabEarningList.add(dailyEarningModel);
    //     }
    //   }).catchError((error) {
    //     log(error.toString());
    //   });
    //
    //   await FireStoreUtils.fireStore
    //       .collection(CollectionName.ridesBooking)
    //       .where('driverId', isEqualTo: Constant.userModel!.id.toString())
    //       .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(nowDate.year, nowDate.month)))
    //       .orderBy('createdAt', descending: true)
    //       .get()
    //       .then((value) {
    //     for (var element in value.docs) {
    //       CabOrderModel dailyEarningModel = CabOrderModel.fromJson(element.data());
    //       monthlyCabEarningList.add(dailyEarningModel);
    //     }
    //   }).catchError((error) {
    //     log(error.toString());
    //   });
    //
    //   await FireStoreUtils.fireStore
    //       .collection(CollectionName.ridesBooking)
    //       .where('driverId', isEqualTo: Constant.userModel!.id.toString())
    //       .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(nowDate.year)))
    //       .orderBy('createdAt', descending: true)
    //       .get()
    //       .then((value) {
    //     for (var element in value.docs) {
    //       CabOrderModel dailyEarningModel = CabOrderModel.fromJson(element.data());
    //       yearlyCabEarningList.add(dailyEarningModel);
    //     }
    //   }).catchError((error) {
    //     log(error.toString());
    //   });
    // }
    await getPaymentMethod();
    isLoading.value = false;
  }

  Future<void> getPaymentMethod() async {
    await FireStoreUtils.fireStore
        .collection(CollectionName.settings)
        .doc("razorpaySettings")
        .get()
        .then((user) {
      try {
        razorPayModel.value = RazorPayModel.fromJson(user.data() ?? {});
      } catch (e) {
        // debugPrint('FireStoreUtils.getUserByID failed to parse user object ${user.id}');
      }
    });

    await FireStoreUtils.fireStore
        .collection(CollectionName.settings)
        .doc("paypalSettings")
        .get()
        .then((paypalData) {
      try {
        payPalModel.value = PayPalModel.fromJson(paypalData.data() ?? {});
      } catch (error) {
        // debugPrint(error.toString());
      }
    });

    await FireStoreUtils.fireStore
        .collection(CollectionName.settings)
        .doc("stripeSettings")
        .get()
        .then((paypalData) {
      try {
        stripeModel.value = StripeModel.fromJson(paypalData.data() ?? {});
      } catch (error) {
        // debugPrint(error.toString());
      }
    });

    await FireStoreUtils.fireStore
        .collection(CollectionName.settings)
        .doc("flutterWave")
        .get()
        .then((paypalData) {
      try {
        flutterWaveModel.value =
            FlutterWaveModel.fromJson(paypalData.data() ?? {});
      } catch (error) {
        // debugPrint(error.toString());
      }
    });

    await FireStoreUtils.getWithdrawMethod().then(
      (value) {
        if (value != null) {
          withdrawMethodModel.value = value;
        }
      },
    );
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
        paymentStatus: "success");

    await FireStoreUtils.setWalletTransaction(transactionModel)
        .then((value) async {
      if (value == true) {
        await FireStoreUtils.updateUserWallet(
                amount: topUpAmountController.value.text,
                userId: FireStoreUtils.getCurrentUid())
            .then((value) {
          getWalletTransaction();
          Get.back();
        });
      }
    });

    ShowToastDialog.showToast("Amount Top-up successfully".tr);
  }

  // final _flutterPaypalNativePlugin = FlutterPaypalNative.instance;

  // void initPayPal() async {
  //   //set debugMode for error logging
  //   FlutterPaypalNative.isDebugMode = paytmModel.value.isSandboxEnabled == true ? true : false;

  //   //initiate payPal plugin
  //   await _flutterPaypalNativePlugin.init(
  //     //your app id !!! No Underscore!!! see readme.md for help
  //     returnUrl: "com.parkme://paypalpay",
  //     //client id from developer dashboard
  //     clientID: payPalModel.value.paypalClient.toString(),
  //     //sandbox, staging, live etc
  //     payPalEnvironment: payPalModel.value.isLive == false ? FPayPalEnvironment.sandbox : FPayPalEnvironment.live,
  //     //what currency do you plan to use? default is US dollars
  //     currencyCode: FPayPalCurrencyCode.usd,
  //     //action paynow?
  //     action: FPayPalUserAction.payNow,
  //   );

  //   //call backs for payment
  //   _flutterPaypalNativePlugin.setPayPalOrderCallback(
  //     callback: FPayPalOrderCallback(
  //       onCancel: () {
  //         //user canceled the payment
  //         ShowToastDialog.showToast("Payment canceled");
  //       },
  //       onSuccess: (data) {
  //         //successfully paid
  //         //remove all items from queue
  //         // _flutterPaypalNativePlugin.removeAllPurchaseItems();
  //         ShowToastDialog.showToast("Payment Successful!!");
  //         walletTopUp();
  //       },
  //       onError: (data) {
  //         //an error occured
  //         ShowToastDialog.showToast("error: ${data.reason}");
  //       },
  //       onShippingChange: (data) {
  //         //the user updated the shipping address
  //         ShowToastDialog.showToast("shipping change: ${data.shippingChangeAddress?.adminArea1 ?? ""}");
  //       },
  //     ),
  //   );
  // }

//Paypal
  void paypalPaymentSheet(String amount, context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) => UsePaypal(
            sandboxMode: payPalModel.value.isLive == true ? false : true,
            clientId: payPalModel.value.paypalClient ?? '',
            secretKey: payPalModel.value.paypalSecret ?? '',
            returnURL: "com.parkme://paypalpay",
            cancelURL: "com.parkme://paypalpay",
            transactions: [
              {
                "amount": {
                  "total": amount,
                  "currency": "USD",
                  "details": {"subtotal": amount}
                },
              }
            ],
            note: "Contact us for any questions on your order.",
            onSuccess: (Map params) async {
              log("onSuccess: $params");
              getWalletTransaction();
              ShowToastDialog.showToast("Payment Successful!!".tr);
            },
            onError: (error) {
              log("onError: $error");
              Get.back();
              ShowToastDialog.showToast("Payment UnSuccessful!!".tr);
            },
            onCancel: (params) {
              log("onError: $params");
              Get.back();
              ShowToastDialog.showToast("Payment UnSuccessful!!".tr);
            }),
      ),
    );
  }

  // Strip
  Future<void> stripeMakePayment({required String amount}) async {
    log(double.parse(amount).toStringAsFixed(0));
    try {
      Map<String, dynamic>? paymentIntentData =
          await createStripeIntent(amount: amount);
      log("stripe Responce====>$paymentIntentData");
      if (paymentIntentData!.containsKey("error")) {
        Get.back();
        ShowToastDialog.showToast(
            "Something went wrong, please contact admin.".tr);
      } else {
        await flutterStipe.Stripe.instance.initPaymentSheet(
            paymentSheetParameters: flutterStipe.SetupPaymentSheetParameters(
                paymentIntentClientSecret: paymentIntentData['client_secret'],
                allowsDelayedPaymentMethods: false,
                googlePay: const flutterStipe.PaymentSheetGooglePay(
                  merchantCountryCode: 'US',
                  testEnv: true,
                  currencyCode: "USD",
                ),
                customFlow: true,
                style: ThemeMode.system,
                appearance: flutterStipe.PaymentSheetAppearance(
                  colors: flutterStipe.PaymentSheetAppearanceColors(
                    primary: AppThemeData.primary300,
                  ),
                ),
                merchantDisplayName: 'JOXMAKO'));
        displayStripePaymentSheet(amount: amount);
      }
    } catch (e, s) {
      log("$e \n$s");
      ShowToastDialog.showToast("exception:$e \n$s");
    }
  }

  Future<void> displayStripePaymentSheet({required String amount}) async {
    try {
      await flutterStipe.Stripe.instance.presentPaymentSheet().then((value) {
        ShowToastDialog.showToast("Payment successfully".tr);
        walletTopUp();
      });
    } on flutterStipe.StripeException catch (e) {
      var lo1 = jsonEncode(e);
      var lo2 = jsonDecode(lo1);
      StripePayFailedModel lom = StripePayFailedModel.fromJson(lo2);
      ShowToastDialog.showToast(lom.error.message);
    } catch (e) {
      ShowToastDialog.showToast(e.toString());
    }
  }

  Future createStripeIntent({required String amount}) async {
    try {
      Map<String, dynamic> body = {
        'amount': ((double.parse(amount) * 100).round()).toString(),
        'currency': "USD",
        'payment_method_types[]': 'card',
        "description": "Strip Payment",
        "shipping[name]": userModel.value.fullName(),
        "shipping[address][line1]": "510 Townsend St",
        "shipping[address][postal_code]": "98140",
        "shipping[address][city]": "San Francisco",
        "shipping[address][state]": "CA",
        "shipping[address][country]": "US",
      };
      var stripeSecret = stripeModel.value.stripeSecret;
      var response = await http.post(
          Uri.parse('https://api.stripe.com/v1/payment_intents'),
          body: body,
          headers: {
            'Authorization': 'Bearer $stripeSecret',
            'Content-Type': 'application/x-www-form-urlencoded'
          });

      return jsonDecode(response.body);
    } catch (e) {
      log(e.toString());
    }
  }

  //mercadoo
  Future<Null> mercadoPagoMakePayment(
      {required BuildContext context, required String amount}) async {
    ShowToastDialog.showLoader("Please wait".tr);
    final headers = {
      'Authorization': 'Bearer ${mercadoPagoModel.value.accessToken}',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      "items": [
        {
          "title": "Test",
          "description": "Test Payment",
          "quantity": 1,
          "currency_id": "BRL", // or your preferred currency
          "unit_price": double.parse(amount),
        }
      ],
      "payer": {"email": userModel.value.email},
      "back_urls": {
        "failure": "${Constant.globalUrl}payment/failure",
        "pending": "${Constant.globalUrl}payment/pending",
        "success": "${Constant.globalUrl}payment/success",
      },
      "auto_return":
          "approved" // Automatically return after payment is approved
    });

    final response = await http.post(
      Uri.parse("https://api.mercadopago.com/checkout/preferences"),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      ShowToastDialog.closeLoader();
      Get.to(MercadoPagoScreen(initialURl: data['init_point']))!.then((value) {
        if (value) {
          ShowToastDialog.showToast("Payment Successful!!".tr);
          walletTopUp();
        } else {
          ShowToastDialog.showToast("Payment UnSuccessful!!".tr);
        }
      });
    } else {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(
          "Something want wrong please contact administrator".tr);

      // print('Error creating preference: ${response.body}');
      return null;
    }
  }

  ///PayStack Payment Method
  Future<void> payStackPayment(String totalAmount) async {
    ShowToastDialog.showLoader("Please wait".tr);
    await PayStackURLGen.payStackURLGen(
            amount: (double.parse(totalAmount) * 100).toString(),
            currency: "ZAR",
            secretKey: payStackModel.value.secretKey.toString(),
            userModel: userModel.value)
        .then((value) async {
      if (value != null) {
        PayStackUrlModel payStackModel0 = value;
        ShowToastDialog.closeLoader();
        Get.to(PayStackScreen(
          secretKey: payStackModel.value.secretKey.toString(),
          callBackUrl: payStackModel.value.callbackURL.toString(),
          initialURl: payStackModel0.data.authorizationUrl,
          amount: totalAmount,
          reference: payStackModel0.data.reference,
        ))!
            .then((value) {
          if (value) {
            ShowToastDialog.showToast("Payment Successful!!".tr);
            walletTopUp();
          } else {
            ShowToastDialog.showToast("Payment UnSuccessful!!".tr);
          }
        });
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast(
            "Something went wrong, please contact admin.".tr);
      }
    });
  }

  //flutter wave Payment Method
  Future<Null> flutterWaveInitiatePayment(
      {required BuildContext context, required String amount}) async {
    ShowToastDialog.showLoader("Please wait".tr);
    final url = Uri.parse('https://api.flutterwave.com/v3/payments');
    final headers = {
      'Authorization': 'Bearer ${flutterWaveModel.value.secretKey}',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      "tx_ref": _ref,
      "amount": amount,
      "currency": "NGN",
      "redirect_url": "${Constant.globalUrl}payment/success",
      "payment_options": "ussd, card, barter, payattitude",
      "customer": {
        "email": userModel.value.email.toString(),
        "phonenumber": userModel.value.phoneNumber, // Add a real phone number
        "name": userModel.value.fullName(), // Add a real customer name
      },
      "customizations": {
        "title": "Payment for Services",
        "description": "Payment for XYZ services",
      }
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      ShowToastDialog.closeLoader();
      Get.to(MercadoPagoScreen(initialURl: data['data']['link']))!
          .then((value) {
        if (value) {
          ShowToastDialog.showToast("Payment Successful!!".tr);
          walletTopUp();
        } else {
          ShowToastDialog.showToast("Payment UnSuccessful!!".tr);
        }
      });
    } else {
      ShowToastDialog.closeLoader();
      // print('Payment initialization failed: ${response.body}');
      return null;
    }
  }

  String? _ref;

  void setRef() {
    maths.Random numRef = maths.Random();
    int year = DateTime.now().year;
    int refNumber = numRef.nextInt(20000);
    if (Platform.isAndroid) {
      _ref = "AndroidRef$year$refNumber";
    } else if (Platform.isIOS) {
      _ref = "IOSRef$year$refNumber";
    }
  }

  // payFast
  void payFastPayment({required BuildContext context, required String amount}) {
    ShowToastDialog.showLoader("Please wait".tr);
    PayStackURLGen.getPayHTML(
            payFastSettingData: payFastModel.value,
            amount: amount.toString(),
            userModel: userModel.value)
        .then((String? value) async {
      ShowToastDialog.closeLoader();
      bool isDone = await Get.to(PayFastScreen(
          htmlData: value!, payFastSettingData: payFastModel.value));
      if (isDone) {
        Get.back();
        ShowToastDialog.showToast("Payment successfully".tr);
        walletTopUp();
      } else {
        Get.back();
        ShowToastDialog.showToast("Payment Failed".tr);
      }
    });
  }

  ///RazorPay payment function
  final Razorpay razorPay = Razorpay();

  void openCheckout({required amount, required orderId}) async {
    var options = {
      'key': razorPayModel.value.razorpayKey,
      'amount': amount * 100,
      'name': 'JOXMAKO',
      'order_id': orderId,
      "currency": "INR",
      'description': 'wallet Topup',
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {
        'contact': userModel.value.phoneNumber,
        'email': userModel.value.email,
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      razorPay.open(options);
    } catch (e) {
      // debugPrint('Error: $e');
    }
  }

  void handlePaymentSuccess(PaymentSuccessResponse response) {
    Get.back();
    ShowToastDialog.showToast("Payment Successful!!".tr);
    walletTopUp();
  }

  void handleExternalWaller(ExternalWalletResponse response) {
    Get.back();
    ShowToastDialog.showToast("Payment Processing!! via".tr);
  }

  void handlePaymentError(PaymentFailureResponse response) {
    Get.back();
    ShowToastDialog.showToast("Payment Failed!!".tr);
  }

  //Midtrans payment
  Future<void> midtransMakePayment(
      {required String amount, required BuildContext context}) async {
    ShowToastDialog.showLoader("Please wait".tr);
    await createPaymentLink(amount: amount).then((url) {
      ShowToastDialog.closeLoader();
      if (url != '') {
        Get.to(() => MidtransScreen(
                  initialURl: url,
                ))!
            .then((value) {
          if (value == true) {
            ShowToastDialog.showToast("Payment Successful!!".tr);
            walletTopUp();
          } else {
            ShowToastDialog.showToast("Payment Unsuccessful!!".tr);
          }
        });
      }
    });
  }

  Future<String> createPaymentLink({required var amount}) async {
    var ordersId = const Uuid().v1();
    final url = Uri.parse(midTransModel.value.isSandbox!
        ? 'https://api.sandbox.midtrans.com/v1/payment-links'
        : 'https://api.midtrans.com/v1/payment-links');

    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization':
            generateBasicAuthHeader(midTransModel.value.serverKey!),
      },
      body: jsonEncode({
        'transaction_details': {
          'order_id': ordersId,
          'gross_amount': double.parse(amount.toString()).toInt(),
        },
        'usage_limit': 2,
        "callbacks": {
          "finish":
              "https://joxmako.com/payment/success?merchant_order_id=$ordersId"
        },
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      return responseData['payment_url'];
    } else {
      ShowToastDialog.showToast(
          "something went wrong, please contact admin.".tr);
      return '';
    }
  }

  String generateBasicAuthHeader(String apiKey) {
    String credentials = '$apiKey:';
    String base64Encoded = base64Encode(utf8.encode(credentials));
    return 'Basic $base64Encoded';
  }

  //Orangepay payment
  static String accessToken = '';
  static String payToken = '';
  static String orderId = '';
  static String amount = '';

  Future<void> orangeMakePayment(
      {required String amount, required BuildContext context}) async {
    ShowToastDialog.showLoader("Please wait".tr);
    reset();
    var id = const Uuid().v4();
    var paymentURL = await fetchToken(
        context: context, orderId: id, amount: amount, currency: 'USD');
    ShowToastDialog.closeLoader();
    if (paymentURL.toString() != '') {
      Get.to(() => OrangeMoneyScreen(
                initialURl: paymentURL,
                accessToken: accessToken,
                amount: amount,
                orangePay: orangeMoneyModel.value,
                orderId: orderId,
                payToken: payToken,
              ))!
          .then((value) {
        if (value == true) {
          ShowToastDialog.showToast("Payment Successful!!".tr);
          walletTopUp();
        }
      });
    } else {
      ShowToastDialog.showToast("Payment Unsuccessful!!".tr);
    }
  }

  Future fetchToken(
      {required String orderId,
      required String currency,
      required BuildContext context,
      required String amount}) async {
    String apiUrl = 'https://api.orange.com/oauth/v3/token';
    Map<String, String> requestBody = {
      'grant_type': 'client_credentials',
    };

    var response = await http.post(Uri.parse(apiUrl),
        headers: <String, String>{
          'Authorization': "Basic ${orangeMoneyModel.value.auth!}",
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: requestBody);

    // Handle the response

    if (response.statusCode == 200) {
      Map<String, dynamic> responseData = jsonDecode(response.body);

      accessToken = responseData['access_token'];
      return await webpayment(
          context: context,
          amountData: amount,
          currency: currency,
          orderIdData: orderId);
    } else {
      ShowToastDialog.showToast(
          "Something went wrong, please contact admin.".tr);
      return '';
    }
  }

  Future webpayment(
      {required String orderIdData,
      required BuildContext context,
      required String currency,
      required String amountData}) async {
    orderId = orderIdData;
    amount = amountData;
    String apiUrl = orangeMoneyModel.value.isSandbox! == true
        ? 'https://api.orange.com/orange-money-webpay/dev/v1/webpayment'
        : 'https://api.orange.com/orange-money-webpay/cm/v1/webpayment';
    Map<String, String> requestBody = {
      "merchant_key": orangeMoneyModel.value.merchantKey ?? '',
      "currency": orangeMoneyModel.value.isSandbox == true ? "OUV" : currency,
      "order_id": orderId,
      "amount": amount,
      "reference": 'Y-Note Test',
      "lang": "en",
      "return_url": orangeMoneyModel.value.returnUrl!.toString(),
      "cancel_url": orangeMoneyModel.value.cancelUrl!.toString(),
      "notif_url": orangeMoneyModel.value.notifUrl!.toString(),
    };

    var response = await http.post(
      Uri.parse(apiUrl),
      headers: <String, String>{
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: json.encode(requestBody),
    );

    // Handle the response
    if (response.statusCode == 201) {
      Map<String, dynamic> responseData = jsonDecode(response.body);
      if (responseData['message'] == 'OK') {
        payToken = responseData['pay_token'];
        return responseData['payment_url'];
      } else {
        return '';
      }
    } else {
      ShowToastDialog.showToast(
          "Something went wrong, please contact admin.".tr);
      return '';
    }
  }

  static void reset() {
    accessToken = '';
    payToken = '';
    orderId = '';
    amount = '';
  }

  //XenditPayment
  Future<void> xenditPayment(context, amount) async {
    ShowToastDialog.showLoader("Please wait".tr);
    await createXenditInvoice(amount: amount).then((model) {
      ShowToastDialog.closeLoader();
      if (model.id != null) {
        Get.to(() => XenditScreen(
                  initialURl: model.invoiceUrl ?? '',
                  transId: model.id ?? '',
                  apiKey: xenditModel.value.apiKey!.toString(),
                ))!
            .then((value) {
          if (value == true) {
            ShowToastDialog.showToast("Payment Successful!!".tr);
            walletTopUp();
          } else {
            ShowToastDialog.showToast("Payment Unsuccessful!!".tr);
          }
        });
      }
    });
  }

  Future<XenditModel> createXenditInvoice({required var amount}) async {
    const url = 'https://api.xendit.co/v2/invoices';
    var headers = {
      'Content-Type': 'application/json',
      'Authorization':
          generateBasicAuthHeader(xenditModel.value.apiKey!.toString()),
      // 'Cookie': '__cf_bm=yERkrx3xDITyFGiou0bbKY1bi7xEwovHNwxV1vCNbVc-1724155511-1.0.1.1-jekyYQmPCwY6vIJ524K0V6_CEw6O.dAwOmQnHtwmaXO_MfTrdnmZMka0KZvjukQgXu5B.K_6FJm47SGOPeWviQ',
    };

    final body = jsonEncode({
      'external_id': const Uuid().v1(),
      'amount': amount,
      'payer_email': 'customer@domain.com',
      'description': 'Test - VA Successful invoice payment',
      'currency': 'IDR', //IDR, PHP, THB, VND, MYR
    });

    try {
      final response =
          await http.post(Uri.parse(url), headers: headers, body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        XenditModel model = XenditModel.fromJson(jsonDecode(response.body));
        return model;
      } else {
        return XenditModel();
      }
    } catch (e) {
      return XenditModel();
    }
  }

  @override
  void onClose() {
    topUpAmountController.value.dispose();
    amountTextFieldController.value.dispose();
    noteTextFieldController.value.dispose();
    super.onClose();
  }
}
