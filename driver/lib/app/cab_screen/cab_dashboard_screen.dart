// ignore_for_file: deprecated_member_use

import 'package:driver/app/edit_profile_screen/edit_profile_screen.dart';
import 'package:driver/app/wallet_screen/wallet_screen.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/controllers/cab_dashboard_controller.dart';
import 'package:driver/themes/app_them_data.dart';
import 'package:driver/themes/theme_controller.dart';
import 'package:driver/widget/driver_global_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'cab_home_screen.dart';

class CabDashboardScreen extends StatelessWidget {
  const CabDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return Obx(() {
      final isDark = themeController.isDark.value;
      return GetBuilder<CabDashBoardController>(
        init: CabDashBoardController(),
        builder: (controller) {
          return Scaffold(
            drawerEnableOpenDragGesture: false,
            appBar: AppBar(
              // backgroundColor: isDark ? AppThemeData.grey900 : AppThemeData.grey50,
              titleSpacing: 5,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome Back 👋'.tr,
                    style: TextStyle(
                      color:
                          isDark ? AppThemeData.grey50 : AppThemeData.grey900,
                      fontSize: 12,
                      fontFamily: AppThemeData.medium,
                    ),
                  ),
                  Text(
                    Constant.userModel!.fullName().tr,
                    style: TextStyle(
                      color:
                          isDark ? AppThemeData.grey50 : AppThemeData.grey900,
                      fontSize: 14,
                      fontFamily: AppThemeData.semiBold,
                    ),
                  )
                ],
              ),
              actions: [
                Constant.userModel!.ownerId != null &&
                        Constant.userModel!.ownerId!.isNotEmpty
                    ? SizedBox()
                    : InkWell(
                        onTap: () {
                          Get.to(const WalletScreen(isAppBarShow: true));
                        },
                        child: SvgPicture.asset(
                            "assets/icons/ic_wallet_home.svg")),
                const SizedBox(
                  width: 10,
                ),
                InkWell(
                    onTap: () {
                      Get.to(const EditProfileScreen());
                    },
                    child:
                        SvgPicture.asset("assets/icons/ic_user_business.svg")),
                const SizedBox(
                  width: 10,
                ),
              ],
              leading: Builder(builder: (context) {
                return InkWell(
                  onTap: () {
                    Scaffold.of(context).openDrawer();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Container(
                        decoration: ShapeDecoration(
                          color: isDark
                              ? AppThemeData.carRent600
                              : AppThemeData.carRent50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(120),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: SvgPicture.asset(
                              "assets/icons/ic_drawer_open.svg"),
                        )),
                  ),
                );
              }),
            ),
            drawer: const DriverGlobalDrawer(),
            body: const CabHomeScreen(),
          );
        },
      );
    });
  }
}
