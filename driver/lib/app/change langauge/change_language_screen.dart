import 'dart:convert';

import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/controllers/change_language_controller.dart';
import 'package:driver/services/localization_service.dart';
import 'package:driver/themes/app_them_data.dart';
import 'package:driver/themes/theme_controller.dart';
import 'package:driver/utils/network_image_widget.dart';
import 'package:driver/utils/preferences.dart';
import 'package:driver/app/multi_service/multi_service_dashboard_screen.dart';
import 'package:driver/widget/driver_app_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChangeLanguageScreen extends StatelessWidget {
  const ChangeLanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return Obx(() {
      final isDark = themeController.isDark.value;
      return GetX(
          init: ChangeLanguageController(),
          builder: (controller) {
            return DriverAppShell(
              title: "Change Language".tr,
              child: controller.isLoading.value
                  ? Constant.loader()
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            height: 20,
                          ),
                          Expanded(
                            child: GridView.count(
                              crossAxisCount: 2,
                              childAspectRatio: (1.1 / 1),
                              crossAxisSpacing: 5,
                              mainAxisSpacing: 1,
                              children: controller.languageList
                                  .map(
                                    (data) => GestureDetector(
                                      onTap: () {
                                        LocalizationService()
                                            .changeLocale(data.slug.toString());
                                        Preferences.setString(
                                            Preferences.languageCodeKey,
                                            jsonEncode(data));
                                        controller.selectedLanguage.value =
                                            data;
                                        ShowToastDialog.showToast(
                                            "Langue mise à jour".tr);
                                        Get.offAll(() => const MultiServiceDashboardScreen());
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          children: [
                                            NetworkImageWidget(
                                              imageUrl: data.image.toString(),
                                              height: 80,
                                              width: 80,
                                            ),
                                            const SizedBox(
                                              height: 5,
                                            ),
                                            Text(
                                              "${data.title}",
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: controller
                                                            .selectedLanguage
                                                            .value
                                                            .slug ==
                                                        data.slug
                                                    ? AppThemeData.primary300
                                                    : isDark
                                                        ? AppThemeData.grey400
                                                        : AppThemeData.grey500,
                                                fontFamily: AppThemeData.medium,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
            );
          });
    });
  }
}
