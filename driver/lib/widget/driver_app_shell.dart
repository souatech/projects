import 'package:driver/widget/driver_global_drawer.dart';
import 'package:driver/app/chat_screens/driver_inbox_screen.dart';
import 'package:driver/app/edit_profile_screen/edit_profile_screen.dart';
import 'package:driver/app/wallet_screen/wallet_screen.dart';
import 'package:driver/themes/app_them_data.dart';
import 'package:driver/themes/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class DriverAppShell extends StatelessWidget {
  const DriverAppShell({
    super.key,
    required this.child,
    this.title,
    this.backgroundColor,
    this.bottomNavigationBar,
  });

  final Widget child;
  final String? title;
  final Color? backgroundColor;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDark.value;
    final bg = backgroundColor ??
        (isDark ? AppThemeData.surfaceDark : AppThemeData.surface);

    return Scaffold(
      drawerEnableOpenDragGesture: true,
      backgroundColor: bg,
      drawer: const DriverGlobalDrawer(),
      appBar: AppBar(
        backgroundColor: bg,
        centerTitle: false,
        titleSpacing: 0,
        elevation: 0,
        leading: Builder(
          builder: (context) => InkWell(
            onTap: () => Scaffold.of(context).openDrawer(),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: SvgPicture.asset(
                "assets/icons/ic_drawer_open.svg",
                colorFilter: ColorFilter.mode(
                  isDark ? AppThemeData.grey50 : AppThemeData.grey900,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            if (Navigator.of(context).canPop())
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => Get.back(),
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  size: 18,
                  color: isDark ? AppThemeData.grey50 : AppThemeData.grey900,
                ),
              ),
            Expanded(
              child: Text(
                (title ?? "Dashboard").tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? AppThemeData.grey50 : AppThemeData.grey900,
                  fontSize: 18,
                  fontFamily: AppThemeData.medium,
                ),
              ),
            ),
          ],
        ),
        actions: [
          InkWell(
            onTap: () => Get.to(const DriverInboxScreen()),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: SvgPicture.asset(
                "assets/icons/ic_message.svg",
                height: 24,
                width: 24,
              ),
            ),
          ),
          InkWell(
            onTap: () => Get.to(const WalletScreen(isAppBarShow: true)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: SvgPicture.asset(
                "assets/icons/ic_wallet_home.svg",
                height: 24,
                width: 24,
              ),
            ),
          ),
          InkWell(
            onTap: () => Get.to(const EditProfileScreen()),
            child: Padding(
              padding: const EdgeInsets.only(left: 6, right: 16),
              child: SvgPicture.asset(
                "assets/icons/ic_user.svg",
                height: 24,
                width: 24,
              ),
            ),
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
