import 'package:customer/constant/constant.dart';
import 'package:customer/controllers/theme_controller.dart';
import 'package:customer/themes/app_them_data.dart';
import 'package:customer/widget/service_switch_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../controllers/cab_rental_dashboard_controllers.dart';

class RentalDashboardScreen extends StatelessWidget {
  const RentalDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return Obx(() {
      final isDark = themeController.isDark.value;
      return GetX(
        init: CabRentalDashboardControllers(),
        builder: (controller) {
          final showBar =
              controller.selectedIndex.value == 0 &&
              Constant.sectionList.length > 1;
          final page = controller.pageList[controller.selectedIndex.value];
          return Scaffold(
            body: Column(
              children: [
                if (controller.selectedIndex.value == 0)
                  const ServiceSwitchBar(),
                Expanded(
                  child:
                      showBar
                          ? MediaQuery.removePadding(
                            context: context,
                            removeTop: true,
                            child: page,
                          )
                          : page,
                ),
              ],
            ),
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              showUnselectedLabels: true,
              showSelectedLabels: true,
              selectedFontSize: 12,
              selectedLabelStyle: const TextStyle(
                fontFamily: AppThemeData.bold,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: AppThemeData.bold,
              ),
              currentIndex: controller.selectedIndex.value,
              backgroundColor:
                  isDark ? AppThemeData.grey900 : AppThemeData.grey50,
              selectedItemColor:
                  isDark ? AppThemeData.primary300 : AppThemeData.primary300,
              unselectedItemColor:
                  isDark ? AppThemeData.grey300 : AppThemeData.grey600,
              onTap: (int index) {
                controller.selectedIndex.value = index;
              },
              items:
                  Constant.walletSetting == false
                      ? [
                        navigationBarItem(
                          isDark,
                          index: 0,
                          assetIcon: "assets/icons/ic_home_cab.svg",
                          label: 'Home'.tr,
                          controller: controller,
                        ),
                        navigationBarItem(
                          isDark,
                          index: 1,
                          assetIcon: "assets/icons/ic_booking_cab.svg",
                          label: 'My Bookings'.tr,
                          controller: controller,
                        ),
                        navigationBarItem(
                          isDark,
                          index: 2,
                          assetIcon: "assets/icons/ic_profile.svg",
                          label: 'Profile'.tr,
                          controller: controller,
                        ),
                      ]
                      : [
                        navigationBarItem(
                          isDark,
                          index: 0,
                          assetIcon: "assets/icons/ic_home_cab.svg",
                          label: 'Home'.tr,
                          controller: controller,
                        ),
                        navigationBarItem(
                          isDark,
                          index: 1,
                          assetIcon: "assets/icons/ic_booking_cab.svg",
                          label: 'My Bookings'.tr,
                          controller: controller,
                        ),
                        navigationBarItem(
                          isDark,
                          index: 2,
                          assetIcon: "assets/icons/ic_wallet_cab.svg",
                          label: 'Wallet'.tr,
                          controller: controller,
                        ),
                        navigationBarItem(
                          isDark,
                          index: 3,
                          assetIcon: "assets/icons/ic_profile.svg",
                          label: 'Profile'.tr,
                          controller: controller,
                        ),
                      ],
            ),
          );
        },
      );
    });
  }

  BottomNavigationBarItem navigationBarItem(
    bool isDark, {
    required int index,
    required String label,
    required String assetIcon,
    required CabRentalDashboardControllers controller,
  }) {
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: SvgPicture.asset(
          assetIcon,
          height: 22,
          width: 22,
          colorFilter: ColorFilter.mode(
            controller.selectedIndex.value == index
                ? AppThemeData.primary300
                : isDark
                ? AppThemeData.grey300
                : AppThemeData.grey600,
            BlendMode.srcIn,
          ),
        ),
      ),
      label: label,
    );
  }
}
