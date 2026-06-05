import 'package:customer/constant/constant.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/0n_demand_payment_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../themes/app_them_data.dart';
import '../../themes/round_button_fill.dart';
import '../../themes/show_toast_dialog.dart';
import '../multi_vendor_service/wallet_screen/wallet_screen.dart';

class OnDemandPaymentScreen extends StatelessWidget {
  const OnDemandPaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDark.value;

    return GetX<OnDemandPaymentController>(
      init: OnDemandPaymentController(),
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: AppThemeData.primary300,
            title: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      height: 42,
                      width: 42,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: AppThemeData.grey50),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 5),
                          child: Icon(Icons.arrow_back_ios, color: AppThemeData.grey900, size: 20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text("Select Payment Method".tr, style: AppThemeData.boldTextStyle(fontSize: 18, color: AppThemeData.grey900)),
                ],
              ),
            ),
          ),
          body: controller.isLoading.value
              ? Constant.loader()
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  decoration: BoxDecoration(color: isDark ? AppThemeData.greyDark200 : Colors.white),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Preferred Payment".tr,
                          style: AppThemeData.boldTextStyle(fontSize: 15, color: isDark ? AppThemeData.greyDark500 : AppThemeData.grey500),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: isDark ? AppThemeData.greyDark50 : AppThemeData.grey50,
                            border: Border.all(color: isDark ? AppThemeData.greyDark200 : AppThemeData.grey200),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                // JOXMAKO: wallet masqué
                                Offstage(offstage: true, child: Visibility(
                                  visible: controller.walletSettingModel.value.isEnabled == true,
                                  child: _cardDecoration(controller, PaymentGateway.wallet, isDark, "assets/images/ic_wallet.png"),
                                )),
                                Visibility(
                                  visible: controller.cashOnDeliverySettingModel.value.isEnabled == true,
                                  child: _cardDecoration(controller, PaymentGateway.cod, isDark, "assets/images/ic_cash.png"),
                                ),
                                // JOXMAKO: paydunya masqué
                                Offstage(offstage: true, child: Visibility(
                                  visible: controller.paydunyaConfig.value.isEnabled == true,
                                  child: _cardDecoration(controller, PaymentGateway.paydunya, isDark, "assets/images/ic_cash.png"),
                                )),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        RoundedButtonFill(
                          title: "Continue".tr,
                          color: AppThemeData.primary300,
                          textColor: AppThemeData.grey900,
                          onPress: () async {
                            if (controller.isOrderPlaced.value) return;
                            controller.isOrderPlaced.value = true;

                            final method = controller.selectedPaymentMethod.value;

                            // JOXMAKO: paiement à la livraison uniquement
                            if (method == PaymentGateway.cod.name) {
                              await controller.placeOrderCOD();
                            } else {
                              ShowToastDialog.showToast("Please select a payment method".tr);
                            }

                            controller.isOrderPlaced.value = false;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Obx _cardDecoration(OnDemandPaymentController controller, PaymentGateway value, bool isDark, String image) {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: InkWell(
          onTap: () => controller.selectedPaymentMethod.value = value.name,
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(width: 1, color: Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Padding(padding: const EdgeInsets.all(8.0), child: Image.asset(image)),
              ),
              const SizedBox(width: 10),
              value == PaymentGateway.wallet
                  ? Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            value.name.capitalizeString(),
                            style: AppThemeData.semiBoldTextStyle(fontSize: 16, color: isDark ? AppThemeData.grey50 : AppThemeData.grey900),
                          ),
                          Text(
                            Constant.amountShow(amount: Constant.userModel?.walletAmount?.toString() ?? '0.0'),
                            style: AppThemeData.semiBoldTextStyle(fontSize: 14, color: AppThemeData.primary300),
                          ),
                        ],
                      ),
                    )
                  : Expanded(
                      child: Text(
                        value == PaymentGateway.cod ? 'Paiement à la livraison (Wave / Orange Money / Espèces)' : value.name.capitalizeString(),
                        style: AppThemeData.semiBoldTextStyle(fontSize: 16, color: isDark ? AppThemeData.grey50 : AppThemeData.grey900),
                      ),
                    ),
              const Expanded(child: SizedBox()),
              Radio(
                value: value.name,
                groupValue: controller.selectedPaymentMethod.value,
                activeColor: AppThemeData.primary300,
                onChanged: (v) => controller.selectedPaymentMethod.value = v.toString(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
