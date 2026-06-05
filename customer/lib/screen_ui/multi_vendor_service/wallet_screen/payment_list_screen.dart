import 'package:customer/constant/constant.dart';
import 'package:customer/controllers/wallet_controller.dart';
import 'package:customer/screen_ui/multi_vendor_service/wallet_screen/wallet_screen.dart';
import 'package:customer/themes/app_them_data.dart';
import 'package:customer/themes/round_button_fill.dart';
import 'package:customer/themes/text_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../controllers/theme_controller.dart';
import '../../../themes/show_toast_dialog.dart';

class PaymentListScreen extends StatelessWidget {
  const PaymentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDark.value;
    return GetX(
      init: WalletController(),
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: isDark ? AppThemeData.surfaceDark : AppThemeData.surface,
            centerTitle: false,
            titleSpacing: 0,
            title: Text("Top up Wallet".tr, style: TextStyle(fontSize: 16, color: isDark ? AppThemeData.grey50 : AppThemeData.grey900, fontFamily: AppThemeData.medium, fontWeight: FontWeight.w500)),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextFieldWidget(
                    title: 'Amount'.tr,
                    hintText: 'Enter Amount'.tr,
                    controller: controller.topUpAmountController.value,
                    textInputType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    prefix: Padding(padding: const EdgeInsets.all(12.0), child: Text(Constant.currencyModel!.symbol.toString(), style: const TextStyle(fontSize: 20, color: AppThemeData.grey800))),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9]'))],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text(
                    "Select Top up Options".tr,
                    style: TextStyle(fontSize: 16, color: isDark ? AppThemeData.grey50 : AppThemeData.grey900, fontFamily: AppThemeData.semiBold, fontWeight: FontWeight.w500),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(borderRadius: const BorderRadius.all(Radius.circular(20)), color: isDark ? AppThemeData.grey900 : AppThemeData.grey50),
                    child: const Column(children: []),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            color: isDark ? AppThemeData.grey900 : AppThemeData.grey50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: RoundedButtonFill(
                title: "Top-up".tr,
                height: 5.5,
                color: AppThemeData.primary300,
                textColor: AppThemeData.grey50,
                fontSizes: 16,
                onPress: () async {
                  if (controller.topUpAmountController.value.text.isEmpty) {
                    ShowToastDialog.showToast("Please Enter Amount".tr);
                  } else {
                    if (double.parse(controller.topUpAmountController.value.text) >= double.parse(Constant.minimumAmountToDeposit.toString())) {
                      ShowToastDialog.showToast("Please select payment method".tr);
                    } else {
                      ShowToastDialog.showToast("${'Please Enter minimum amount of'.tr} ${Constant.amountShow(amount: Constant.minimumAmountToDeposit)}");
                    }
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Obx cardDecoration(WalletController controller, PaymentGateway value, isDark, String image) {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: InkWell(
          onTap: () {
            controller.selectedPaymentMethod.value = value.name;
          },
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: ShapeDecoration(shape: RoundedRectangleBorder(side: const BorderSide(width: 1, color: Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(8))),
                child: Padding(padding: EdgeInsets.all(value.name == "payFast" ? 0 : 8.0), child: Image.asset(image)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value.name.capitalizeString(),
                  textAlign: TextAlign.start,
                  style: TextStyle(fontFamily: AppThemeData.medium, fontSize: 16, color: isDark ? AppThemeData.grey50 : AppThemeData.grey900),
                ),
              ),
              const Expanded(child: SizedBox()),
              Radio(
                value: value.name,
                groupValue: controller.selectedPaymentMethod.value,
                activeColor: isDark ? AppThemeData.primary300 : AppThemeData.primary300,
                onChanged: (value) {
                  controller.selectedPaymentMethod.value = value.toString();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
