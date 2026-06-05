import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/models/payment_model/cod_setting_model.dart';
import 'package:customer/models/payment_model/wallet_setting_model.dart';
import 'package:customer/models/rating_model.dart';
import 'package:customer/models/rental_order_model.dart';
import 'package:customer/models/wallet_transaction_model.dart';
import 'package:customer/screen_ui/multi_vendor_service/wallet_screen/wallet_screen.dart';
import 'package:customer/themes/show_toast_dialog.dart';
import 'package:customer/utils/preferences.dart';
import 'package:get/get.dart';

import '../constant/constant.dart';
import '../models/tax_model.dart';
import '../models/user_model.dart';
import '../service/fire_store_utils.dart';

class RentalOrderDetailsController extends GetxController {
  Rx<RentalOrderModel> order = RentalOrderModel().obs;
  RxBool isLoading = true.obs;

  Rx<UserModel?> driverUser = Rx<UserModel?>(null);

  RxDouble subTotal = 0.0.obs;
  RxDouble discount = 0.0.obs;
  RxDouble taxAmount = 0.0.obs;
  RxDouble totalAmount = 0.0.obs;
  RxDouble extraKilometerCharge = 0.0.obs;
  RxDouble extraMinutesCharge = 0.0.obs;
  RxDouble orderTaxAmount = 0.0.obs;
  RxDouble platformTaxAmount = 0.0.obs;

  final RxString selectedPaymentMethod = ''.obs;
  Rx<RatingModel> ratingModel = RatingModel().obs;

  @override
  void onInit() {
    getData();
    super.onInit();
  }

  Future<void> getData() async {
    final args = Get.arguments;
    if (args != null) {
      order.value = args as RentalOrderModel;
      calculateTotalAmount();
      await fetchDriverDetails();
      await getPaymentSettings();
    }
    isLoading.value = false;
  }

  Future<void> fetchDriverDetails() async {
    if (order.value.driverId != null) {
      await FireStoreUtils.getUserProfile(order.value.driverId ?? '').then((
        value,
      ) {
        if (value != null) {
          driverUser.value = value;
        }
      });

      await FireStoreUtils.getReviewsbyID(order.value.id.toString()).then((
        value,
      ) {
        if (value != null) {
          ratingModel.value = value;
        }
      });
    }
  }

  String getExtraKm() {
    try {
      final double start =
          double.tryParse(order.value.startKitoMetersReading ?? '0') ?? 0.0;
      final double end =
          double.tryParse(order.value.endKitoMetersReading ?? '0') ?? 0.0;
      final double included =
          double.tryParse(
            order.value.includedDistance?.toString() ??
                order.value.rentalPackageModel?.includedDistance?.toString() ??
                '0',
          ) ??
          0.0;
      if (included == -1) {
        return "0 ${Constant.distanceType}";
      }

      // Calculate extra km safely
      final double extra = (end - start - included);
      final double validExtra = extra > 0 ? extra : 0;

      return "${validExtra.toStringAsFixed(2)} ${Constant.distanceType}";
    } catch (e) {
      return "0 ${Constant.distanceType}";
    }
  }

  ///Safe calculation after order is loaded
  void calculateTotalAmount() {
    try {
      subTotal.value =
          double.tryParse(order.value.subTotal?.toString() ?? "0") ?? 0.0;
      discount.value =
          double.tryParse(order.value.discount?.toString() ?? "0") ?? 0.0;
      taxAmount.value = 0.0;

      if (order.value.endTime != null) {
        DateTime start = order.value.startTime!.toDate();
        DateTime end = order.value.endTime!.toDate();

        // Total rented minutes
        int totalMinutes = end.difference(start).inMinutes;

        int includedMinutes =
            (int.tryParse(
                  order.value.includedHours?.toString() ??
                      order.value.rentalPackageModel?.includedHours
                          .toString() ??
                      "0",
                ) ??
                0) *
            60;

        if (totalMinutes > includedMinutes) {
          int extraMinutes = totalMinutes - includedMinutes;

          double minuteFare =
              double.tryParse(
                order.value.extraMinutePrice?.toString() ??
                    order.value.rentalPackageModel?.extraMinuteFare
                        ?.toString() ??
                    "0",
              ) ??
              0.0;

          extraMinutesCharge.value = extraMinutes * minuteFare;
        } else {
          extraMinutesCharge.value = 0;
        }
      }

      if (order.value.startKitoMetersReading != null &&
          order.value.endKitoMetersReading != null) {
        double startKm =
            double.tryParse(
              order.value.startKitoMetersReading?.toString() ?? "0",
            ) ??
            0.0;
        double endKm =
            double.tryParse(
              order.value.endKitoMetersReading?.toString() ?? "0",
            ) ??
            0.0;
        if (endKm > startKm) {
          double totalKm = endKm - startKm;
          final includedDistance =
              double.tryParse(
                order.value.includedDistance?.toString() ??
                    order.value.rentalPackageModel?.includedDistance
                        ?.toString() ??
                    "0",
              ) ??
              0.0;
          if (includedDistance != -1 && totalKm > includedDistance) {
            totalKm = totalKm - includedDistance;
            double extraKmRate =
                double.tryParse(
                  order.value.extraKmPrice?.toString() ??
                      order.value.rentalPackageModel?.extraKmFare?.toString() ??
                      "0",
                ) ??
                0.0;
            extraKilometerCharge.value = totalKm * extraKmRate;
          }
        }
      }

      subTotal.value =
          subTotal.value +
          extraKilometerCharge.value +
          extraMinutesCharge.value;

      for (var taxElement in order.value.taxSetting ?? []) {
        orderTaxAmount.value += Constant.calculateTax(
          amount: (subTotal.value - discount.value).toString(),
          taxModel: taxElement,
        );
      }

      if (double.parse(order.value.platformFee ?? '0.0') > 0.0) {
        for (var taxElement in order.value.platformTax ?? []) {
          platformTaxAmount.value += Constant.calculateTax(
            amount: order.value.platformFee ?? '0.0',
            taxModel: taxElement,
          );
        }
      }
      taxAmount.value = orderTaxAmount.value + platformTaxAmount.value;

      totalAmount.value =
          (subTotal.value - discount.value) +
          double.parse(order.value.platformFee ?? '0.0') +
          taxAmount.value;
    } catch (e) {
      ShowToastDialog.showToast("${'Failed to calculate total:'.tr} $e");
    }
  }

  Future<void> completeOrder() async {
    if (selectedPaymentMethod.value == PaymentGateway.cod.name) {
      order.value.paymentMethod = selectedPaymentMethod.value;
      await FireStoreUtils.rentalOrderPlace(order.value).then((value) {
        ShowToastDialog.showToast("Payment method changed".tr);
        Get.back();
        Get.back();
      });
    } else {
      order.value.paymentStatus = true;
      order.value.paymentMethod = selectedPaymentMethod.value;
      if (selectedPaymentMethod.value == PaymentGateway.wallet.name) {
        WalletTransactionModel transactionModel = WalletTransactionModel(
          id: Constant.getUuid(),
          amount: double.parse(totalAmount.toString()),
          date: Timestamp.now(),
          paymentMethod: PaymentGateway.wallet.name,
          transactionUser: "customer",
          userId: FireStoreUtils.getCurrentUid(),
          isTopup: false,
          orderId: order.value.id,
          note: "Rental Amount debited",
          paymentStatus: "success",
          serviceType: Constant.parcelServiceType,
        );

        await FireStoreUtils.setWalletTransaction(transactionModel).then((
          value,
        ) async {
          if (value == true) {
            await FireStoreUtils.updateUserWallet(
              amount: "-${totalAmount.toString()}",
              userId: FireStoreUtils.getCurrentUid(),
            );
          }
        });
      }

      await FireStoreUtils.rentalOrderPlace(order.value).then((value) {
        ShowToastDialog.showToast("Payment successfully".tr);
        Get.back();
        Get.back();
      });
    }
  }

  Future<void> cancelRentalRequest(
    RentalOrderModel order, {
    List<TaxModel>? taxList,
  }) async {
    try {
      if (!_canCancelRental(order.status)) {
        ShowToastDialog.showToast("This booking can no longer be cancelled".tr);
        return;
      }
      isLoading.value = true;

      order.status = Constant.orderCancelled;
      await FireStoreUtils.rentalOrderPlace(order);

      if (order.paymentMethod?.toLowerCase() != "cod") {
        double refundAmount = totalAmount.value;

        WalletTransactionModel walletTransaction = WalletTransactionModel(
          id: Constant.getUuid(),
          amount: refundAmount,
          date: Timestamp.now(),
          paymentMethod: PaymentGateway.wallet.name,
          transactionUser: "customer",
          userId: FireStoreUtils.getCurrentUid(),
          isTopup: true,
          // refund
          orderId: order.id,
          note: "Refund for cancelled booking",
          paymentStatus: "success",
          serviceType: Constant.parcelServiceType,
        );

        await FireStoreUtils.setWalletTransaction(walletTransaction);
        await FireStoreUtils.updateUserWallet(
          amount: refundAmount.toString(),
          userId: FireStoreUtils.getCurrentUid(),
        );
      }
      ShowToastDialog.showToast("Booking cancelled successfully".tr);
      Get.back();
    } catch (e) {
      ShowToastDialog.showToast("${'Failed to cancel booking:'.tr} $e".tr);
    } finally {
      isLoading.value = false;
    }
  }

  bool _canCancelRental(String? status) {
    return status == Constant.orderPlaced ||
        status == Constant.driverAccepted ||
        status == 'EN_ATTENTE_PROPRIETAIRE' ||
        status == 'EN_ATTENTE_PAIEMENT' ||
        status == 'CONFIRMED';
  }

  Rx<WalletSettingModel> walletSettingModel = WalletSettingModel().obs;
  Rx<CodSettingModel> cashOnDeliverySettingModel = CodSettingModel().obs;

  Future<void> getPaymentSettings() async {
    await FireStoreUtils.getPaymentSettingsData().then((value) {
      walletSettingModel.value = WalletSettingModel.fromJson(
        jsonDecode(Preferences.getString(Preferences.walletSettings)),
      );
      cashOnDeliverySettingModel.value = CodSettingModel.fromJson(
        jsonDecode(Preferences.getString(Preferences.codSettings)),
      );

      if (walletSettingModel.value.isEnabled == true) {
        selectedPaymentMethod.value = PaymentGateway.wallet.name;
      } else if (cashOnDeliverySettingModel.value.isEnabled == true) {
        selectedPaymentMethod.value = PaymentGateway.cod.name;
      }
    });
  }
}
