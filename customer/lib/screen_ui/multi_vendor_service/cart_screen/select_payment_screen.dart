import 'package:customer/constant/constant.dart';
import 'package:customer/controllers/cart_controller.dart';
import 'package:customer/themes/app_them_data.dart';
import 'package:customer/themes/round_button_fill.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/theme_controller.dart';
import '../wallet_screen/wallet_screen.dart';

class SelectPaymentScreen extends StatelessWidget {
  const SelectPaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDark.value;

    return GetX(
      init: CartController(),
      builder: (CartController controller) {
        return Scaffold(
          backgroundColor:
              isDark ? AppThemeData.surfaceDark : AppThemeData.surface,
          appBar: AppBar(
            backgroundColor:
                isDark ? AppThemeData.surfaceDark : AppThemeData.surface,
            centerTitle: false,
            titleSpacing: 0,
            title: Text(
              "Mode de paiement".tr,
              style: TextStyle(
                fontFamily: AppThemeData.medium,
                fontSize: 16,
                color: isDark ? AppThemeData.grey50 : AppThemeData.grey900,
              ),
            ),
          ),
          body:
              controller.isLoading.value
                  ? Align(
                    alignment: Alignment.center,
                    child: Text(
                      "Loading, please wait...".tr,
                      style: TextStyle(
                        fontFamily: AppThemeData.semiBold,
                        fontSize: 16,
                        color:
                            isDark ? AppThemeData.grey50 : AppThemeData.grey900,
                      ),
                    ),
                  )
                  : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Payer à la livraison".tr,
                            style: TextStyle(
                              fontFamily: AppThemeData.semiBold,
                              fontSize: 16,
                              color:
                                  isDark
                                      ? AppThemeData.grey50
                                      : AppThemeData.grey900,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: ShapeDecoration(
                              color:
                                  isDark
                                      ? AppThemeData.grey900
                                      : AppThemeData.grey50,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              shadows: const [
                                BoxShadow(
                                  color: Color(0x07000000),
                                  blurRadius: 20,
                                  offset: Offset(0, 0),
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  // JOXMAKO: wallet et gateways legacy masqués
                                  Offstage(
                                    offstage: true,
                                    child: cardDecoration(
                                      controller,
                                      PaymentGateway.wallet,
                                      isDark,
                                      "assets/images/ic_wallet.png",
                                    ),
                                  ),
                                  Offstage(
                                    offstage: true,
                                    child: cardDecoration(
                                      controller,
                                      PaymentGateway.paydunya,
                                      isDark,
                                      "assets/images/ic_cash.png",
                                    ),
                                  ),
                                  cardDecoration(
                                    controller,
                                    PaymentGateway.cod,
                                    isDark,
                                    "assets/images/ic_cash.png",
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: isDark ? AppThemeData.grey900 : AppThemeData.grey50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: RoundedButtonFill(
                title:
                    "${'Pay Now'.tr} | ${Constant.amountShow(amount: controller.totalAmount.value.toString())}",
                height: 5,
                color: AppThemeData.primary300,
                textColor: AppThemeData.grey50,
                fontSizes: 16,
                onPress: () async {
                  if (controller.selectedPaymentMethod.value ==
                      PaymentGateway.paydunya.name) {
                    await controller.initiatePaydunyaPayment(context);
                  } else {
                    Get.back();
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget cardDecoration(
    CartController controller,
    PaymentGateway value,
    bool isDark,
    String image,
  ) {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Column(
          children: [
            InkWell(
              onTap: () => controller.selectedPaymentMethod.value = value.name,
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: ShapeDecoration(
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(
                          width: 1,
                          color: Color(0xFFE5E7EB),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(image),
                    ),
                  ),
                  const SizedBox(width: 10),
                  value == PaymentGateway.wallet
                      ? Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              value.name.capitalizeString(),
                              style: TextStyle(
                                fontFamily: AppThemeData.medium,
                                fontSize: 16,
                                color:
                                    isDark
                                        ? AppThemeData.grey50
                                        : AppThemeData.grey900,
                              ),
                            ),
                            Text(
                              Constant.amountShow(
                                amount:
                                    controller.userModel.value.walletAmount
                                        ?.toString() ??
                                    '0.0',
                              ),
                              style: TextStyle(
                                fontFamily: AppThemeData.semiBold,
                                fontSize: 16,
                                color: AppThemeData.primary300,
                              ),
                            ),
                          ],
                        ),
                      )
                      : Expanded(
                        child: Text(
                          value == PaymentGateway.cod
                              ? 'Paiement à la livraison (Wave / Orange Money / Espèces)'
                                  .tr
                              : value.name.capitalizeString(),
                          style: TextStyle(
                            fontFamily: AppThemeData.medium,
                            fontSize: 16,
                            color:
                                isDark
                                    ? AppThemeData.grey50
                                    : AppThemeData.grey900,
                          ),
                        ),
                      ),
                  const Expanded(child: SizedBox()),
                  // ignore: deprecated_member_use
                  Radio(
                    value: value.name,
                    // ignore: deprecated_member_use
                    groupValue: controller.selectedPaymentMethod.value,
                    activeColor: AppThemeData.primary300,
                    // ignore: deprecated_member_use
                    onChanged:
                        (v) =>
                            controller.selectedPaymentMethod.value =
                                v.toString(),
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
