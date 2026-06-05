// ignore_for_file: deprecated_member_use, curly_braces_in_flow_control_structures, strict_top_level_inference

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/controllers/wallet_controller.dart';
import 'package:driver/models/cab_order_model.dart';
import 'package:driver/models/order_model.dart';
import 'package:driver/models/parcel_order_model.dart';
import 'package:driver/models/rental_order_model.dart';
import 'package:driver/models/wallet_transaction_model.dart';
import 'package:driver/models/withdrawal_model.dart';
import 'package:driver/themes/app_them_data.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/themes/round_button_fill.dart';
import 'package:driver/themes/text_field_widget.dart';
import 'package:driver/themes/theme_controller.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:driver/widget/my_separator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../constant/collection_name.dart';
import '../cab_screen/cab_order_details.dart';
import 'package:driver/widget/driver_global_drawer.dart';
import '../order_list_screen/order_details_screen.dart';
import '../parcel_screen/parcel_order_details.dart';
import '../rental_service/rental_order_details_screen.dart';

class WalletScreen extends StatelessWidget {
  final bool? isAppBarShow;

  const WalletScreen({super.key, required this.isAppBarShow});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return Obx(() {
      final isDark = themeController.isDark.value;
      return GetX(
          init: WalletController(),
          builder: (controller) {
            return Scaffold(
              drawer: isAppBarShow == true ? const DriverGlobalDrawer() : null,
              appBar: isAppBarShow == true
                  ? AppBar(
                      backgroundColor:
                          isDark ? AppThemeData.grey900 : AppThemeData.grey50,
                      centerTitle: false,
                      leading: Builder(
                        builder: (context) => IconButton(
                          onPressed: () => Scaffold.of(context).openDrawer(),
                          icon: Icon(
                            Icons.menu,
                            color: isDark
                                ? AppThemeData.grey50
                                : AppThemeData.grey900,
                          ),
                        ),
                      ),
                      iconTheme: IconThemeData(
                          color: isDark
                              ? AppThemeData.grey50
                              : AppThemeData.grey900,
                          size: 20),
                      title: Text(
                        "Mes gains".tr,
                        style: TextStyle(
                            color: isDark
                                ? AppThemeData.grey50
                                : AppThemeData.grey900,
                            fontSize: 18,
                            fontFamily: AppThemeData.medium),
                      ),
                    )
                  : null,
              body: controller.isLoading.value
                  ? Constant.loader()
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          child: Container(
                            width: Responsive.width(100, context),
                            decoration: const BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(20)),
                              image: DecorationImage(
                                image: AssetImage("assets/images/wallet.png"),
                                fit: BoxFit.fill,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 20),
                              child: Column(
                                children: [
                                  Text(
                                    "Mes gains".tr,
                                    maxLines: 1,
                                    style: TextStyle(
                                      color: isDark
                                          ? AppThemeData.grey900
                                          : AppThemeData.grey900,
                                      fontSize: 16,
                                      overflow: TextOverflow.ellipsis,
                                      fontFamily: AppThemeData.regular,
                                    ),
                                  ),
                                  Obx(() => Text(
                                        Constant.amountShow(
                                            amount: controller
                                                .unpaidEarnings.value
                                                .toString()),
                                        maxLines: 1,
                                        style: TextStyle(
                                          color: isDark
                                              ? AppThemeData.grey900
                                              : AppThemeData.grey900,
                                          fontSize: 40,
                                          overflow: TextOverflow.ellipsis,
                                          fontFamily: AppThemeData.bold,
                                        ),
                                      )),
                                  Obx(() => Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "En attente".tr,
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontFamily:
                                                    AppThemeData.regular,
                                                color: AppThemeData.grey700),
                                          ),
                                          const SizedBox(width: 16),
                                          Text(
                                            "${"Payé".tr}: ${Constant.amountShow(amount: controller.paidEarnings.value.toString())}",
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontFamily: AppThemeData.medium,
                                                color: AppThemeData.success400),
                                          ),
                                        ],
                                      )),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: RoundedButtonFill(
                                            title: "Withdraw".tr,
                                            width: 24,
                                            height: 5.5,
                                            color: AppThemeData.grey50,
                                            textColor: AppThemeData.grey900,
                                            borderRadius: 200,
                                            onPress: () {
                                              withdrawalCardBottomSheet(
                                                  context, controller);
                                            },
                                          ),
                                        ),
                                        // Top up masqué — modèle gains JOXMAKO
                                        const SizedBox.shrink(),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          child: Obx(
                            () => Row(
                              children: [
                                Expanded(
                                  child: walletMetricCard(
                                    isDark: isDark,
                                    icon: Icons.payments_outlined,
                                    title: "Total collecté".tr,
                                    amount:
                                        controller.cashCollectedAmount.value,
                                    iconColor: AppThemeData.success400,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: walletMetricCard(
                                    isDark: isDark,
                                    icon: Icons.account_balance_wallet_outlined,
                                    title: "Espèces à remettre".tr,
                                    amount: controller.pendingCashToRemit.value,
                                    iconColor: Colors.orange.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: DefaultTabController(
                            length: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TabBar(
                                  onTap: (value) {
                                    controller.selectedTabIndex.value = value;
                                  },
                                  tabAlignment: TabAlignment.start,
                                  labelStyle: const TextStyle(
                                      fontFamily: AppThemeData.semiBold),
                                  labelColor: isDark
                                      ? AppThemeData.primary300
                                      : AppThemeData.primary300,
                                  unselectedLabelStyle: const TextStyle(
                                      fontFamily: AppThemeData.medium),
                                  unselectedLabelColor: isDark
                                      ? AppThemeData.grey400
                                      : AppThemeData.grey500,
                                  indicatorColor: AppThemeData.primary300,
                                  indicatorWeight: 1,
                                  isScrollable: true,
                                  dividerColor: Colors.transparent,
                                  tabs: [
                                    Tab(
                                      text: "Historique des livraisons du jour"
                                          .tr,
                                    ),
                                    Tab(
                                      text: "Retraits".tr,
                                    ),
                                  ],
                                ),
                                Expanded(
                                  child: TabBarView(
                                    children: [
                                      // Padding(
                                      //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      //   child: Column(
                                      //     crossAxisAlignment: CrossAxisAlignment.start,
                                      //     children: [
                                      //       SizedBox(
                                      //         width: 130,
                                      //         child: DropdownButtonFormField<String>(
                                      //             borderRadius: const BorderRadius.all(Radius.circular(0)),
                                      //             hint: Text(
                                      //               'Select zone'.tr,
                                      //               style: TextStyle(
                                      //                 fontSize: 14,
                                      //                 color: isDark ? AppThemeData.grey700 : AppThemeData.grey700,
                                      //                 fontFamily: AppThemeData.regular,
                                      //               ),
                                      //             ),
                                      //             decoration: InputDecoration(
                                      //               errorStyle: const TextStyle(color: Colors.red),
                                      //               isDense: true,
                                      //               filled: true,
                                      //               fillColor: isDark ? AppThemeData.grey900 : AppThemeData.grey50,
                                      //               disabledBorder: UnderlineInputBorder(
                                      //                 borderRadius: const BorderRadius.all(Radius.circular(400)),
                                      //                 borderSide:
                                      //                     BorderSide(color: isDark ? AppThemeData.grey900 : AppThemeData.grey50, width: 1),
                                      //               ),
                                      //               focusedBorder: OutlineInputBorder(
                                      //                 borderRadius: const BorderRadius.all(Radius.circular(400)),
                                      //                 borderSide: BorderSide(
                                      //                     color: isDark ? AppThemeData.secondary300 : AppThemeData.secondary300, width: 1),
                                      //               ),
                                      //               enabledBorder: OutlineInputBorder(
                                      //                 borderRadius: const BorderRadius.all(Radius.circular(400)),
                                      //                 borderSide:
                                      //                     BorderSide(color: isDark ? AppThemeData.grey900 : AppThemeData.grey50, width: 1),
                                      //               ),
                                      //               errorBorder: OutlineInputBorder(
                                      //                 borderRadius: const BorderRadius.all(Radius.circular(400)),
                                      //                 borderSide:
                                      //                     BorderSide(color: isDark ? AppThemeData.grey900 : AppThemeData.grey50, width: 1),
                                      //               ),
                                      //               border: OutlineInputBorder(
                                      //                 borderRadius: const BorderRadius.all(Radius.circular(400)),
                                      //                 borderSide:
                                      //                     BorderSide(color: isDark ? AppThemeData.grey900 : AppThemeData.grey50, width: 1),
                                      //               ),
                                      //             ),
                                      //             initialValue: controller.selectedDropDownValue.value,
                                      //             onChanged: (value) {
                                      //               controller.selectedDropDownValue.value = value!;
                                      //               controller.update();
                                      //             },
                                      //             style: TextStyle(
                                      //                 fontSize: 14,
                                      //                 color: isDark ? AppThemeData.grey50 : AppThemeData.grey900,
                                      //                 fontFamily: AppThemeData.medium),
                                      //             items: controller.dropdownValue.map((item) {
                                      //               return DropdownMenuItem<String>(
                                      //                 value: item,
                                      //                 child: Text(item.toString()),
                                      //               );
                                      //             }).toList()),
                                      //       ),
                                      //       const SizedBox(
                                      //         height: 10,
                                      //       ),
                                      //       Expanded(
                                      //         child: Container(
                                      //           decoration: ShapeDecoration(
                                      //             color: isDark ? AppThemeData.grey900 : AppThemeData.grey50,
                                      //             shape: RoundedRectangleBorder(
                                      //               borderRadius: BorderRadius.circular(12),
                                      //             ),
                                      //           ),
                                      //           child: Padding(
                                      //             padding: const EdgeInsets.all(8.0),
                                      //             child: controller.userModel.value.serviceType == "cab-service"
                                      //                 ? cabTransactionCardForOrder(
                                      //                     isDark,
                                      //                     controller.selectedDropDownValue.value == "Daily"
                                      //                         ? controller.dailyCabEarningList
                                      //                         : controller.selectedDropDownValue.value == "Monthly"
                                      //                             ? controller.monthlyCabEarningList
                                      //                             : controller.yearlyCabEarningList,
                                      //                   )
                                      //                 : controller.userModel.value.serviceType == "parcel_delivery"
                                      //                     ? parcelTransactionCardForOrder(
                                      //                         isDark,
                                      //                         controller.selectedDropDownValue.value == "Daily"
                                      //                             ? controller.dailyParcelEarningList
                                      //                             : controller.selectedDropDownValue.value == "Monthly"
                                      //                                 ? controller.monthlyParcelEarningList
                                      //                                 : controller.yearlyParcelEarningList,
                                      //                       )
                                      //                     : controller.userModel.value.serviceType == "rental-service"
                                      //                         ? rentalTransactionCardForOrder(
                                      //                             isDark,
                                      //                             controller.selectedDropDownValue.value == "Daily"
                                      //                                 ? controller.dailyRentalEarningList
                                      //                                 : controller.selectedDropDownValue.value == "Monthly"
                                      //                                     ? controller.monthlyRentalEarningList
                                      //                                     : controller.yearlyRentalEarningList,
                                      //                           )
                                      //                         : transactionCardForOrder(
                                      //                             isDark,
                                      //                             controller.selectedDropDownValue.value == "Daily"
                                      //                                 ? controller.dailyEarningList
                                      //                                 : controller.selectedDropDownValue.value == "Monthly"
                                      //                                     ? controller.monthlyEarningList
                                      //                                     : controller.yearlyEarningList,
                                      //                           ),
                                      //           ),
                                      //         ),
                                      //       )
                                      //     ],
                                      //   ),
                                      // ),
                                      controller.todayDeliveryHistory.isEmpty
                                          ? Constant.showEmptyView(
                                              message:
                                                  "Aucune livraison aujourd’hui"
                                                      .tr,
                                              isDark: isDark)
                                          : Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 10),
                                              child: Container(
                                                decoration: ShapeDecoration(
                                                  color: isDark
                                                      ? AppThemeData.grey900
                                                      : AppThemeData.grey50,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                ),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: ListView.separated(
                                                    padding: EdgeInsets.zero,
                                                    shrinkWrap: true,
                                                    itemCount: controller
                                                        .todayDeliveryHistory
                                                        .length,
                                                    itemBuilder:
                                                        (context, index) {
                                                      DriverDailyDeliveryItem
                                                          deliveryItem =
                                                          controller
                                                                  .todayDeliveryHistory[
                                                              index];
                                                      return todayDeliveryCard(
                                                          isDark, deliveryItem);
                                                    },
                                                    separatorBuilder:
                                                        (BuildContext context,
                                                            int index) {
                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical: 5),
                                                        child: MySeparator(
                                                            color: isDark
                                                                ? AppThemeData
                                                                    .grey700
                                                                : AppThemeData
                                                                    .grey200),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ),
                                      controller.withdrawalList.isEmpty
                                          ? Constant.showEmptyView(
                                              message:
                                                  "Withdrawal history not found"
                                                      .tr,
                                              isDark: isDark)
                                          : Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 10),
                                              child: Container(
                                                decoration: ShapeDecoration(
                                                  color: isDark
                                                      ? AppThemeData.grey900
                                                      : AppThemeData.grey50,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                ),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: ListView.separated(
                                                    padding: EdgeInsets.zero,
                                                    shrinkWrap: true,
                                                    itemCount: controller
                                                        .withdrawalList.length,
                                                    itemBuilder:
                                                        (context, index) {
                                                      WithdrawalModel
                                                          walletTractionModel =
                                                          controller
                                                                  .withdrawalList[
                                                              index];
                                                      return transactionCardWithdrawal(
                                                          controller,
                                                          isDark,
                                                          walletTractionModel);
                                                    },
                                                    separatorBuilder:
                                                        (BuildContext context,
                                                            int index) {
                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical: 5),
                                                        child: MySeparator(
                                                            color: isDark
                                                                ? AppThemeData
                                                                    .grey700
                                                                : AppThemeData
                                                                    .grey200),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            );
          });
    });
  }

  Widget walletMetricCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required double amount,
    required Color iconColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.grey900 : AppThemeData.grey50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppThemeData.grey800 : AppThemeData.grey200,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? AppThemeData.grey300 : AppThemeData.grey600,
              fontSize: 12,
              fontFamily: AppThemeData.medium,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            Constant.amountShow(amount: amount.toString()),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? AppThemeData.grey50 : AppThemeData.grey900,
              fontSize: 18,
              fontFamily: AppThemeData.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget todayDeliveryCard(bool isDark, DriverDailyDeliveryItem item) {
    final date = item.activityAt == null
        ? '-'
        : Constant.timestampToDateTime(item.activityAt!);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: ShapeDecoration(
              color: isDark ? AppThemeData.grey800 : AppThemeData.grey100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Icon(
                Icons.local_shipping_outlined,
                color: AppThemeData.primary300,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.serviceType,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontFamily: AppThemeData.semiBold,
                          color: isDark
                              ? AppThemeData.grey100
                              : AppThemeData.grey900,
                        ),
                      ),
                    ),
                    Text(
                      Constant.amountShow(
                          amount: item.totalCollected.toString()),
                      style: TextStyle(
                        fontSize: 15,
                        fontFamily: AppThemeData.bold,
                        color:
                            isDark ? AppThemeData.grey50 : AppThemeData.grey900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      "${"Gain driver".tr}: ${Constant.amountShow(amount: item.driverEarning.toString())}",
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: AppThemeData.medium,
                        color: isDark
                            ? AppThemeData.grey300
                            : AppThemeData.grey600,
                      ),
                    ),
                    Text(
                      "${"Méthode de paiement".tr}: ${item.paymentMethod}",
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: AppThemeData.medium,
                        color: isDark
                            ? AppThemeData.grey300
                            : AppThemeData.grey600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        date,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: AppThemeData.medium,
                          color: isDark
                              ? AppThemeData.grey300
                              : AppThemeData.grey600,
                        ),
                      ),
                    ),
                    Text(
                      item.status,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: AppThemeData.semiBold,
                        color: AppThemeData.success400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future withdrawalCardBottomSheet(
      BuildContext context, WalletController controller) {
    if (controller.unpaidEarnings.value < 5000) {
      ShowToastDialog.showToast(
          "Le montant minimum pour demander un paiement est de 5 000 FCFA.".tr);
      return Future.value();
    }
    // Pre-fill method and phone from driver profile
    final bankDetails = Constant.userModel?.userBankDetails;
    String selectedMethod = 'wave';
    if (bankDetails != null && bankDetails.bankName.isNotEmpty) {
      if (bankDetails.bankName.toLowerCase().contains('orange')) {
        selectedMethod = 'orange_money';
      }
    }
    final phoneCtrl =
        TextEditingController(text: bankDetails?.accountNumber ?? '');
    final amountCtrl = TextEditingController(
      text: controller.unpaidEarnings.value > 0
          ? controller.unpaidEarnings.value.toStringAsFixed(0)
          : '',
    );
    final noteCtrl = TextEditingController();
    bool isSubmitting = false;

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.8,
        child: StatefulBuilder(builder: (ctx, setState) {
          final themeController = Get.find<ThemeController>();
          final isDark = themeController.isDark.value;
          return Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Demande de paiement".tr,
                              style: TextStyle(
                                color: isDark
                                    ? AppThemeData.grey100
                                    : AppThemeData.grey800,
                                fontSize: 18,
                                fontFamily: AppThemeData.semiBold,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => Get.back(),
                            child: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        "${"Disponible".tr} : ${Constant.amountShow(amount: controller.unpaidEarnings.value.toString())}",
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: AppThemeData.medium,
                          color: isDark
                              ? AppThemeData.grey400
                              : AppThemeData.grey600,
                        ),
                      ),
                    ),
                    TextFieldWidget(
                      title: 'Montant demandé'.tr,
                      controller: amountCtrl,
                      hintText: '0',
                      textInputType: const TextInputType.numberWithOptions(
                          signed: true, decimal: true),
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp('[0-9]'))
                      ],
                      prefix: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Text(
                          "${Constant.currencyModel!.symbol}",
                          style: TextStyle(
                            color: isDark
                                ? AppThemeData.grey50
                                : AppThemeData.grey900,
                            fontFamily: AppThemeData.semiBold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Méthode de paiement".tr,
                      style: TextStyle(
                        color: isDark
                            ? AppThemeData.grey100
                            : AppThemeData.grey800,
                        fontSize: 16,
                        fontFamily: AppThemeData.medium,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(16)),
                        color:
                            isDark ? AppThemeData.grey900 : AppThemeData.grey50,
                      ),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () =>
                                setState(() => selectedMethod = 'wave'),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "Wave",
                                      style: TextStyle(
                                        color: isDark
                                            ? AppThemeData.grey50
                                            : AppThemeData.grey900,
                                        fontSize: 16,
                                        fontFamily: AppThemeData.medium,
                                      ),
                                    ),
                                  ),
                                  Radio<String>(
                                    value: 'wave',
                                    groupValue: selectedMethod,
                                    activeColor: AppThemeData.primary300,
                                    onChanged: (v) =>
                                        setState(() => selectedMethod = v!),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Divider(
                              height: 1,
                              color: isDark
                                  ? AppThemeData.grey700
                                  : AppThemeData.grey200),
                          InkWell(
                            onTap: () =>
                                setState(() => selectedMethod = 'orange_money'),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "Orange Money",
                                      style: TextStyle(
                                        color: isDark
                                            ? AppThemeData.grey50
                                            : AppThemeData.grey900,
                                        fontSize: 16,
                                        fontFamily: AppThemeData.medium,
                                      ),
                                    ),
                                  ),
                                  Radio<String>(
                                    value: 'orange_money',
                                    groupValue: selectedMethod,
                                    activeColor: AppThemeData.primary300,
                                    onChanged: (v) =>
                                        setState(() => selectedMethod = v!),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFieldWidget(
                      title: 'Numéro de paiement'.tr,
                      controller: phoneCtrl,
                      hintText: 'Ex: 77xxxxxxx'.tr,
                      textInputType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 4),
                    TextFieldWidget(
                      title: 'Note'.tr,
                      controller: noteCtrl,
                      hintText: 'Optionnel'.tr,
                    ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: Container(
              color: isDark ? AppThemeData.grey900 : AppThemeData.grey50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: RoundedButtonFill(
                  title: isSubmitting ? "Envoi…".tr : "Envoyer la demande".tr,
                  height: 5.5,
                  color: AppThemeData.primary300,
                  textColor: AppThemeData.grey50,
                  fontSizes: 16,
                  onPress: isSubmitting
                      ? () {}
                      : () async {
                          final amountStr = amountCtrl.text.trim();
                          final phone = phoneCtrl.text.trim();
                          if (amountStr.isEmpty ||
                              (double.tryParse(amountStr) ?? 0) <= 0) {
                            ShowToastDialog.showToast(
                                "Entrer un montant valide".tr);
                            return;
                          }
                          final amount = double.tryParse(amountStr) ?? 0;
                          if (amount < 5000 ||
                              controller.unpaidEarnings.value < 5000) {
                            ShowToastDialog.showToast(
                                "Le montant minimum pour demander un paiement est de 5 000 FCFA."
                                    .tr);
                            return;
                          }
                          if (amount > controller.unpaidEarnings.value) {
                            ShowToastDialog.showToast(
                                "Montant supérieur aux gains disponibles".tr);
                            return;
                          }
                          if (phone.isEmpty) {
                            ShowToastDialog.showToast(
                                "Entrer le numéro de paiement".tr);
                            return;
                          }
                          setState(() => isSubmitting = true);
                          try {
                            final uid = FireStoreUtils.getCurrentUid();
                            final driverName =
                                Constant.userModel?.fullName().trim() ?? uid;
                            final reqId = Constant.getUuid();
                            final now = FieldValue.serverTimestamp();
                            await FireStoreUtils.fireStore
                                .collection(CollectionName.payoutRequests)
                                .doc(reqId)
                                .set({
                              'id': reqId,
                              'beneficiary_id': uid,
                              'beneficiary_type': 'driver',
                              'beneficiary_name': driverName,
                              'amount_requested': double.parse(amountStr),
                              'available_balance':
                                  controller.unpaidEarnings.value,
                              'payout_method': selectedMethod,
                              'payout_number': phone,
                              'payout_holder_name': '',
                              'status': 'pending',
                              'requested_at': now,
                              'source': 'driver_app',
                              'note': noteCtrl.text.trim(),
                            });
                            Get.back();
                            await controller.getWalletTransaction();
                            ShowToastDialog.showToast("Demande envoyée".tr);
                          } catch (e) {
                            setState(() => isSubmitting = false);
                            ShowToastDialog.showToast(
                                "Erreur : ${e.toString()}");
                          }
                        },
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  InkWell transactionCardWithdrawal(
      WalletController controller, isDark, WithdrawalModel transactionModel) {
    final method = transactionModel.withdrawMethod?.capitalizeString() ?? '-';
    final status = transactionModel.paymentStatus ?? '-';
    final date = transactionModel.requestedAt ??
        transactionModel.paidDate ??
        transactionModel.processedAt;
    final ref = transactionModel.reference ?? transactionModel.id ?? '-';
    return InkWell(
      onTap: () async {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Container(
              decoration: ShapeDecoration(
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                      width: 1,
                      color:
                          isDark ? AppThemeData.grey800 : AppThemeData.grey100),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SvgPicture.asset(
                  "assets/icons/ic_debit.svg",
                  height: 16,
                  width: 16,
                ),
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (transactionModel.note?.isNotEmpty ?? false)
                                  ? transactionModel.note.toString()
                                  : "Demande de paiement".tr,
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: AppThemeData.semiBold,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppThemeData.grey100
                                    : AppThemeData.grey800,
                              ),
                            ),
                            Text(
                              "($method)",
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: AppThemeData.medium,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppThemeData.grey100
                                    : AppThemeData.grey800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "-${Constant.amountShow(amount: transactionModel.amount.toString())}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: AppThemeData.medium,
                          color: AppThemeData.danger300,
                        ),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 2,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "$status • Ref: $ref",
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: AppThemeData.semiBold,
                            fontWeight: FontWeight.w600,
                            color: status.toLowerCase() == "success" ||
                                    status.toLowerCase() == "paid"
                                ? AppThemeData.success400
                                : status.toLowerCase() == "pending"
                                    ? AppThemeData.primary300
                                    : AppThemeData.danger300,
                          ),
                        ),
                      ),
                      Text(
                        date == null ? '-' : Constant.timestampToDateTime(date),
                        style: TextStyle(
                            fontSize: 12,
                            fontFamily: AppThemeData.medium,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppThemeData.grey200
                                : AppThemeData.grey700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget transactionCardForOrder(isDark, List<OrderModel> list) {
    return list.isEmpty
        ? Constant.showEmptyView(
            message: "Transaction history not found".tr, isDark: isDark)
        : ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: list.length,
            itemBuilder: (context, index) {
              OrderModel walletTractionModel = list[index];

              double amount = 0;
              if (walletTractionModel.deliveryCharge != null &&
                  walletTractionModel.deliveryCharge!.isNotEmpty) {
                amount += double.parse(walletTractionModel.deliveryCharge!);
              }

              if (walletTractionModel.tipAmount != null &&
                  walletTractionModel.tipAmount!.isNotEmpty) {
                amount += double.parse(walletTractionModel.tipAmount!);
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Container(
                      decoration: ShapeDecoration(
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                              width: 1,
                              color: isDark
                                  ? AppThemeData.grey800
                                  : AppThemeData.grey100),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SvgPicture.asset(
                          "assets/icons/ic_credit.svg",
                          height: 16,
                          width: 16,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "Completed Delivery".tr,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: AppThemeData.semiBold,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppThemeData.grey100
                                        : AppThemeData.grey800,
                                  ),
                                ),
                              ),
                              Text(
                                Constant.amountShow(amount: amount.toString()),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontFamily: AppThemeData.medium,
                                  color: AppThemeData.success400,
                                ),
                              )
                            ],
                          ),
                          const SizedBox(
                            height: 2,
                          ),
                          Text(
                            Constant.timestampToDateTime(
                                walletTractionModel.createdAt!),
                            style: TextStyle(
                                fontSize: 12,
                                fontFamily: AppThemeData.medium,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppThemeData.grey200
                                    : AppThemeData.grey700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            separatorBuilder: (BuildContext context, int index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: MySeparator(
                    color:
                        isDark ? AppThemeData.grey700 : AppThemeData.grey200),
              );
            },
          );
  }

  Widget parcelTransactionCardForOrder(isDark, List<ParcelOrderModel> list) {
    return list.isEmpty
        ? Constant.showEmptyView(
            message: "Transaction history not found".tr, isDark: isDark)
        : ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: list.length,
            itemBuilder: (context, index) {
              ParcelOrderModel orderModel = list[index];

              double totalAmount = 0.0;
              double totalTax = 0.0;
              double subTotal = double.parse(orderModel.subTotal ?? '0.0') -
                  double.parse(orderModel.discount ?? '0.0');

              if (orderModel.taxSetting != null) {
                for (var element in orderModel.taxSetting!) {
                  totalTax = totalTax +
                      Constant.calculateTax(
                          amount: subTotal.toString(), taxModel: element);
                }
              }
              totalAmount = subTotal + totalTax;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Container(
                      decoration: ShapeDecoration(
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                              width: 1,
                              color: isDark
                                  ? AppThemeData.grey800
                                  : AppThemeData.grey100),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SvgPicture.asset(
                          "assets/icons/ic_credit.svg",
                          height: 16,
                          width: 16,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "Parcel Amount credited".tr,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: AppThemeData.semiBold,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppThemeData.grey100
                                        : AppThemeData.grey800,
                                  ),
                                ),
                              ),
                              Text(
                                Constant.amountShow(
                                    amount: totalAmount.toString()),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontFamily: AppThemeData.medium,
                                  color: AppThemeData.success400,
                                ),
                              )
                            ],
                          ),
                          const SizedBox(
                            height: 2,
                          ),
                          Text(
                            Constant.timestampToDateTime(orderModel.createdAt!),
                            style: TextStyle(
                                fontSize: 12,
                                fontFamily: AppThemeData.medium,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppThemeData.grey200
                                    : AppThemeData.grey700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            separatorBuilder: (BuildContext context, int index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: MySeparator(
                    color:
                        isDark ? AppThemeData.grey700 : AppThemeData.grey200),
              );
            },
          );
  }

  Widget rentalTransactionCardForOrder(isDark, List<RentalOrderModel> list) {
    return list.isEmpty
        ? Constant.showEmptyView(
            message: "Transaction history not found".tr, isDark: isDark)
        : ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: list.length,
            itemBuilder: (context, index) {
              RentalOrderModel orderModel = list[index];
              RxDouble subTotal = 0.0.obs;
              RxDouble discount = 0.0.obs;
              RxDouble taxAmount = 0.0.obs;
              RxDouble totalAmount = 0.0.obs;
              RxDouble extraKilometerCharge = 0.0.obs;
              RxDouble extraMinutesCharge = 0.0.obs;

              subTotal.value =
                  double.tryParse(orderModel.subTotal?.toString() ?? "0") ??
                      0.0;
              discount.value =
                  double.tryParse(orderModel.discount?.toString() ?? "0") ??
                      0.0;

              if (orderModel.endTime != null) {
                DateTime start = orderModel.startTime!.toDate();
                DateTime end = orderModel.endTime!.toDate();
                int hours = end.difference(start).inHours;
                if (hours >=
                    int.parse(orderModel.rentalPackageModel!.includedHours
                        .toString())) {
                  hours = hours -
                      int.parse(orderModel.rentalPackageModel!.includedHours
                          .toString());
                  double hourlyRate = double.tryParse(orderModel
                              .rentalPackageModel?.extraMinuteFare
                              ?.toString() ??
                          "0") ??
                      0.0;
                  extraMinutesCharge.value = (hours * 60) * hourlyRate;
                }
              }

              if (orderModel.startKitoMetersReading != null &&
                  orderModel.endKitoMetersReading != null) {
                double startKm = double.tryParse(
                        orderModel.startKitoMetersReading?.toString() ?? "0") ??
                    0.0;
                double endKm = double.tryParse(
                        orderModel.endKitoMetersReading?.toString() ?? "0") ??
                    0.0;
                if (endKm > startKm) {
                  double totalKm = endKm - startKm;
                  if (totalKm >
                      double.parse(
                          orderModel.rentalPackageModel!.includedDistance!)) {
                    totalKm = totalKm -
                        double.parse(
                            orderModel.rentalPackageModel!.includedDistance!);
                    double extraKmRate = double.tryParse(orderModel
                                .rentalPackageModel?.extraKmFare
                                ?.toString() ??
                            "0") ??
                        0.0;
                    extraKilometerCharge.value = totalKm * extraKmRate;
                  }
                }
              }
              subTotal.value = subTotal.value +
                  extraKilometerCharge.value +
                  extraMinutesCharge.value;

              if (orderModel.taxSetting != null) {
                for (var element in orderModel.taxSetting!) {
                  taxAmount.value += Constant.calculateTax(
                      amount: (subTotal.value - discount.value).toString(),
                      taxModel: element);
                }
              }

              totalAmount.value =
                  (subTotal.value - discount.value) + taxAmount.value;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Container(
                      decoration: ShapeDecoration(
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                              width: 1,
                              color: isDark
                                  ? AppThemeData.grey800
                                  : AppThemeData.grey100),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SvgPicture.asset(
                          "assets/icons/ic_credit.svg",
                          height: 16,
                          width: 16,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "Completed Delivery".tr,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: AppThemeData.semiBold,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppThemeData.grey100
                                        : AppThemeData.grey800,
                                  ),
                                ),
                              ),
                              Text(
                                Constant.amountShow(
                                    amount: totalAmount.toString()),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontFamily: AppThemeData.medium,
                                  color: AppThemeData.success400,
                                ),
                              )
                            ],
                          ),
                          const SizedBox(
                            height: 2,
                          ),
                          Text(
                            Constant.timestampToDateTime(orderModel.createdAt!),
                            style: TextStyle(
                                fontSize: 12,
                                fontFamily: AppThemeData.medium,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppThemeData.grey200
                                    : AppThemeData.grey700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            separatorBuilder: (BuildContext context, int index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: MySeparator(
                    color:
                        isDark ? AppThemeData.grey700 : AppThemeData.grey200),
              );
            },
          );
  }

  Widget cabTransactionCardForOrder(isDark, List<CabOrderModel> list) {
    return list.isEmpty
        ? Constant.showEmptyView(
            message: "Transaction history not found".tr, isDark: isDark)
        : ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: list.length,
            itemBuilder: (context, index) {
              CabOrderModel orderModel = list[index];

              double totalAmount = 0.0;
              double totalTax = 0.0;
              double subTotal = double.parse(orderModel.subTotal ?? '0.0') -
                  double.parse(orderModel.discount ?? '0.0');

              if (orderModel.taxSetting != null) {
                for (var element in orderModel.taxSetting!) {
                  totalTax = totalTax +
                      Constant.calculateTax(
                          amount: subTotal.toString(), taxModel: element);
                }
              }
              totalAmount = subTotal + totalTax;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Container(
                      decoration: ShapeDecoration(
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                              width: 1,
                              color: isDark
                                  ? AppThemeData.grey800
                                  : AppThemeData.grey100),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SvgPicture.asset(
                          "assets/icons/ic_credit.svg",
                          height: 16,
                          width: 16,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "Completed Delivery".tr,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: AppThemeData.semiBold,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppThemeData.grey100
                                        : AppThemeData.grey800,
                                  ),
                                ),
                              ),
                              Text(
                                Constant.amountShow(
                                    amount: totalAmount.toString()),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontFamily: AppThemeData.medium,
                                  color: AppThemeData.success400,
                                ),
                              )
                            ],
                          ),
                          const SizedBox(
                            height: 2,
                          ),
                          Text(
                            Constant.timestampToDateTime(orderModel.createdAt!),
                            style: TextStyle(
                                fontSize: 12,
                                fontFamily: AppThemeData.medium,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppThemeData.grey200
                                    : AppThemeData.grey700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            separatorBuilder: (BuildContext context, int index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: MySeparator(
                    color:
                        isDark ? AppThemeData.grey700 : AppThemeData.grey200),
              );
            },
          );
  }

  InkWell transactionCard(WalletController controller, isDark,
      WalletTransactionModel transactionModel) {
    return InkWell(
      onTap: () async {
        final orderId = transactionModel.orderId.toString();
        final orderData =
            await FireStoreUtils.getOrderByIdFromAllCollections(orderId);

        if (orderData != null) {
          final collection = orderData['collection_name'];

          switch (collection) {
            case CollectionName.parcelOrders:
              Get.to(const ParcelOrderDetails(),
                  arguments: ParcelOrderModel.fromJson(orderData));
              break;
            case CollectionName.rentalOrders:
              Get.to(() => RentalOrderDetailsScreen(),
                  arguments: {"rentalOrder": orderId});
              break;
            case CollectionName.ridesBooking:
              Get.to(const CabOrderDetails(), arguments: {
                "cabOrderModel": CabOrderModel.fromJson(orderData)
              });
              break;
            case CollectionName.vendorOrders:
              Get.to(const OrderDetailsScreen(),
                  arguments: {"orderModel": OrderModel.fromJson(orderData)});
              break;
            default:
              ShowToastDialog.showToast("Order details not available");
          }
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Container(
              decoration: ShapeDecoration(
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                      width: 1,
                      color:
                          isDark ? AppThemeData.grey800 : AppThemeData.grey100),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: transactionModel.isTopup == false
                    ? SvgPicture.asset(
                        "assets/icons/ic_debit.svg",
                        height: 16,
                        width: 16,
                      )
                    : SvgPicture.asset(
                        "assets/icons/ic_credit.svg",
                        height: 16,
                        width: 16,
                      ),
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          transactionModel.note.toString(),
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: AppThemeData.semiBold,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppThemeData.grey100
                                : AppThemeData.grey800,
                          ),
                        ),
                      ),
                      Text(
                        transactionModel.isTopup == false
                            ? "-${Constant.amountShow(amount: transactionModel.amount.toString())}"
                            : Constant.amountShow(
                                amount: transactionModel.amount.toString()),
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: AppThemeData.medium,
                          color: transactionModel.isTopup == true
                              ? AppThemeData.success400
                              : AppThemeData.danger300,
                        ),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 2,
                  ),
                  Text(
                    Constant.timestampToDateTime(transactionModel.date!),
                    style: TextStyle(
                        fontSize: 12,
                        fontFamily: AppThemeData.medium,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppThemeData.grey200
                            : AppThemeData.grey700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
