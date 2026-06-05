import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/controllers/bank_details_controller.dart';
import 'package:driver/themes/app_them_data.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/themes/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BankDetailsScreen extends StatefulWidget {
  const BankDetailsScreen({super.key});

  @override
  State<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends State<BankDetailsScreen> {
  String _selectedMethod = 'Wave';
  final TextEditingController _numberController = TextEditingController();

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDark.value;
    return GetX(
        init: BankDetailsController(),
        builder: (controller) {
          // Pré-remplir si données existantes
          if (controller.isLoading.value == false &&
              _numberController.text.isEmpty &&
              controller.accountNoController.value.text.isNotEmpty) {
            _numberController.text = controller.accountNoController.value.text;
            if (controller.bankNameController.value.text == 'Orange Money') {
              _selectedMethod = 'Orange Money';
            } else {
              _selectedMethod = 'Wave';
            }
          }

          return Scaffold(
            backgroundColor: isDark ? AppThemeData.surfaceDark : AppThemeData.surface,
            appBar: AppBar(
              backgroundColor: isDark ? AppThemeData.surfaceDark : AppThemeData.surface,
              centerTitle: false,
              title: Text(
                "Mode de paiement".tr,
                style: TextStyle(
                    color: isDark ? AppThemeData.grey50 : AppThemeData.grey900,
                    fontSize: 18,
                    fontFamily: AppThemeData.medium),
              ),
            ),
            body: controller.isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Choisissez votre mode de paiement".tr,
                          style: TextStyle(
                            color: isDark ? AppThemeData.grey50 : AppThemeData.grey900,
                            fontSize: 14,
                            fontFamily: AppThemeData.medium,
                          ),
                        ),
                        const SizedBox(height: 16),
                        StatefulBuilder(builder: (context, setRadioState) {
                          return Column(
                            children: [
                              RadioListTile<String>(
                                value: 'Wave',
                                groupValue: _selectedMethod,
                                activeColor: AppThemeData.primary300,
                                title: Text(
                                  'Wave',
                                  style: TextStyle(
                                    color: isDark ? AppThemeData.grey50 : AppThemeData.grey900,
                                    fontSize: 16,
                                    fontFamily: AppThemeData.medium,
                                  ),
                                ),
                                onChanged: (value) {
                                  setRadioState(() => _selectedMethod = value!);
                                  setState(() => _selectedMethod = value!);
                                },
                              ),
                              RadioListTile<String>(
                                value: 'Orange Money',
                                groupValue: _selectedMethod,
                                activeColor: AppThemeData.primary300,
                                title: Text(
                                  'Orange Money',
                                  style: TextStyle(
                                    color: isDark ? AppThemeData.grey50 : AppThemeData.grey900,
                                    fontSize: 16,
                                    fontFamily: AppThemeData.medium,
                                  ),
                                ),
                                onChanged: (value) {
                                  setRadioState(() => _selectedMethod = value!);
                                  setState(() => _selectedMethod = value!);
                                },
                              ),
                            ],
                          );
                        }),
                        const SizedBox(height: 24),
                        Text(
                          "Numéro $_selectedMethod".tr,
                          style: TextStyle(
                            color: isDark ? AppThemeData.grey300 : AppThemeData.grey700,
                            fontSize: 13,
                            fontFamily: AppThemeData.medium,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _numberController,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(
                            color: isDark ? AppThemeData.grey50 : AppThemeData.grey900,
                          ),
                          decoration: InputDecoration(
                            hintText: "+221 XX XXX XX XX",
                            hintStyle: TextStyle(
                              color: isDark ? AppThemeData.grey600 : AppThemeData.grey400,
                            ),
                            filled: true,
                            fillColor: isDark ? AppThemeData.grey900 : AppThemeData.grey50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: isDark ? AppThemeData.grey700 : AppThemeData.grey200,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: isDark ? AppThemeData.grey700 : AppThemeData.grey200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: AppThemeData.primary300),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
            bottomNavigationBar: InkWell(
              onTap: () {
                if (_numberController.text.trim().isEmpty) {
                  ShowToastDialog.showToast("Veuillez entrer votre numéro de paiement".tr);
                } else {
                  // Réutilise les champs existants du controller
                  controller.bankNameController.value.text = _selectedMethod;
                  controller.accountNoController.value.text = _numberController.text.trim();
                  controller.branchNameController.value.text = '';
                  controller.holderNameController.value.text = '';
                  controller.otherInfoController.value.text = '';
                  controller.saveBank();
                }
              },
              child: Container(
                color: AppThemeData.primary300,
                width: Responsive.width(100, context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    "Enregistrer".tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppThemeData.grey50,
                      fontSize: 16,
                      fontFamily: AppThemeData.medium,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          );
        });
  }
}
