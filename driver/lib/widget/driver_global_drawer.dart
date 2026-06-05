// ignore_for_file: deprecated_member_use

import 'package:driver/app/auth_screen/login_screen.dart';
import 'package:driver/app/change%20langauge/change_language_screen.dart';
import 'package:driver/app/change_password_screen/change_password_screen.dart';
import 'package:driver/app/chat_screens/driver_inbox_screen.dart';
import 'package:driver/app/edit_profile_screen/edit_profile_screen.dart';
import 'package:driver/app/help_support_screen/help_support_screen.dart';
import 'package:driver/app/multi_service/multi_service_dashboard_screen.dart';
import 'package:driver/app/order_list_screen/order_list_screen.dart';
import 'package:driver/app/terms_and_condition/terms_and_condition_screen.dart';
import 'package:driver/app/verification_screen/verification_screen.dart';
import 'package:driver/app/wallet_screen/wallet_screen.dart';
import 'package:driver/app/withdraw_method_setup_screens/withdraw_method_setup_screen.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/services/audio_player_service.dart';
import 'package:driver/themes/app_them_data.dart';
import 'package:driver/themes/custom_dialog_box.dart';
import 'package:driver/themes/theme_controller.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:driver/utils/network_image_widget.dart';
import 'package:driver/utils/preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

class DriverGlobalDrawer extends StatelessWidget {
  const DriverGlobalDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return Obx(() {
      final isDark = themeController.isDark.value;
      return Drawer(
        backgroundColor: isDark ? AppThemeData.grey900 : AppThemeData.grey50,
        child: Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).viewPadding.top + 20,
            left: 16,
            right: 16,
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Row(
                children: [
                  ClipOval(
                    child: NetworkImageWidget(
                      imageUrl: Constant.userModel?.profilePictureURL?.toString() ?? "",
                      height: 55,
                      width: 55,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Constant.userModel?.fullName() ?? "",
                          style: TextStyle(
                            color: isDark ? AppThemeData.grey50 : AppThemeData.grey900,
                            fontSize: 18,
                            fontFamily: AppThemeData.semiBold,
                          ),
                        ),
                        Text(
                          Constant.userModel?.email ?? "",
                          style: TextStyle(
                            color: isDark ? AppThemeData.grey50 : AppThemeData.grey900,
                            fontSize: 14,
                            fontFamily: AppThemeData.regular,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _AvailabilitySwitch(isDark: isDark),
              const SizedBox(height: 10),
              _SectionTitle(title: 'Navigation'.tr, isDark: isDark),
              _DrawerNavItem(
                icon: "assets/icons/ic_home_add.svg",
                title: "Home".tr,
                isDark: isDark,
                onTap: () {
                  Get.back();
                  Get.offAll(() => const MultiServiceDashboardScreen());
                },
              ),
              _DrawerNavItem(
                icon: "assets/icons/ic_user.svg",
                title: "Profile".tr,
                isDark: isDark,
                onTap: () {
                  Get.back();
                  Get.to(() => const EditProfileScreen());
                },
              ),
              _DrawerNavItem(
                icon: "assets/icons/ic_shoping_cart.svg",
                title: "Orders".tr,
                isDark: isDark,
                onTap: () {
                  Get.back();
                  Get.to(() => const OrderListScreen());
                },
              ),
              if (Constant.userModel?.vendorID?.isEmpty == true) ...[
                _DrawerNavItem(
                  icon: "assets/icons/ic_wallet.svg",
                  title: "Wallet".tr,
                  isDark: isDark,
                  onTap: () {
                    Get.back();
                    Get.to(() => const WalletScreen(isAppBarShow: true));
                  },
                ),
                _DrawerNavItem(
                  icon: "assets/icons/ic_settings.svg",
                  title: "Withdrawal Method".tr,
                  isDark: isDark,
                  onTap: () {
                    Get.back();
                    Get.to(() => const WithdrawMethodSetupScreen());
                  },
                ),
              ],
              if (Constant.userModel?.isAutoVerify == false)
                _DrawerNavItem(
                  icon: "assets/icons/ic_notes.svg",
                  title: "Document Verification".tr,
                  isDark: isDark,
                  onTap: () {
                    Get.back();
                    Get.to(() => const VerificationScreen());
                  },
                ),
              _DrawerNavItem(
                icon: "assets/icons/ic_chat.svg",
                title: "Inbox".tr,
                isDark: isDark,
                onTap: () {
                  Get.back();
                  Get.to(() => const DriverInboxScreen());
                },
              ),
              const SizedBox(height: 10),
              _SectionTitle(title: 'App Preferences'.tr, isDark: isDark),
              _DrawerNavItem(
                icon: "assets/icons/ic_change_language.svg",
                title: "Change Language".tr,
                isDark: isDark,
                onTap: () {
                  Get.back();
                  Get.to(() => const ChangeLanguageScreen());
                },
              ),
              _DarkModeNavItem(isDark: isDark, themeController: themeController),
              _DrawerNavItem(
                icon: "assets/icons/ic_help_support.svg",
                title: "Help & Support".tr,
                isDark: isDark,
                onTap: () {
                  Get.back();
                  Get.to(() => HelpSupportScreen());
                },
              ),
              const SizedBox(height: 10),
              _SectionTitle(title: 'Social'.tr, isDark: isDark),
              _DrawerNavItem(
                icon: "assets/icons/ic_share.svg",
                title: "Share app".tr,
                isDark: isDark,
                onTap: () {
                  Get.back();
                  Share.share(
                    '${'Check out JOXMAKO, your ultimate delivery application!'.tr} \n\n${'Google Play:'.tr} ${Constant.googlePlayLink} \n\n${'App Store:'.tr} ${Constant.appStoreLink}',
                    subject: 'Look what I made!'.tr,
                  );
                },
              ),
              const SizedBox(height: 10),
              _SectionTitle(title: 'Legal'.tr, isDark: isDark),
              _DrawerNavItem(
                icon: "assets/icons/ic_terms_condition.svg",
                title: "Terms and Conditions".tr,
                isDark: isDark,
                onTap: () {
                  Get.back();
                  Get.to(() => const TermsAndConditionScreen(type: "temsandcondition"));
                },
              ),
              _DrawerNavItem(
                icon: "assets/icons/ic_privacyPolicy.svg",
                title: "Privacy Policy".tr,
                isDark: isDark,
                isDanger: true,
                onTap: () {
                  Get.back();
                  Get.to(() => const TermsAndConditionScreen(type: "privacy"));
                },
              ),
              if (Constant.userModel?.provider != 'apple' &&
                  Constant.userModel?.provider != 'google')
                _DrawerNavItem(
                  icon: "assets/icons/ic_mail.svg",
                  title: "Change Password".tr,
                  isDark: isDark,
                  onTap: () {
                    Get.back();
                    Get.to(() => ChangePasswordScreen());
                  },
                ),
              const SizedBox(height: 10),
              _DrawerNavItem(
                icon: "assets/icons/ic_logout.svg",
                title: "Log out".tr,
                isDark: isDark,
                isDanger: true,
                onTap: () => _showLogoutDialog(context),
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: () => _showDeleteAccountDialog(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      "assets/icons/ic_delete.svg",
                      colorFilter: const ColorFilter.mode(
                          AppThemeData.danger300, BlendMode.srcIn),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Delete Account'.tr,
                      style: const TextStyle(
                        color: AppThemeData.danger300,
                        fontFamily: AppThemeData.semiBold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  "V : ${Constant.appVersion}",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppThemeData.medium,
                    fontSize: 14,
                    color: isDark ? AppThemeData.grey50 : AppThemeData.grey900,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    });
  }

  void _showLogoutDialog(BuildContext context) {
    Get.back();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomDialogBox(
          title: "Log out".tr,
          descriptions:
              "Are you sure you want to log out? You will need to enter your credentials to log back in."
                  .tr,
          positiveString: "Log out".tr,
          negativeString: "Cancel".tr,
          positiveClick: () async {
            await AudioPlayerService.playSound(false);
            Constant.userModel!.fcmToken = "";
            await FireStoreUtils.updateUser(Constant.userModel!);
            await FirebaseAuth.instance.signOut();
            Get.offAll(const LoginScreen());
          },
          negativeClick: () => Get.back(),
          img: Image.asset('assets/images/ic_logout.gif', height: 50, width: 50),
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomDialogBox(
          title: "Delete Account".tr,
          descriptions:
              "Are you sure you want to delete your account? This action is irreversible and will permanently remove all your data."
                  .tr,
          positiveString: "Delete".tr,
          negativeString: "Cancel".tr,
          positiveClick: () async {
            ShowToastDialog.showLoader("Please wait".tr);
            await FireStoreUtils.deleteUser().then((value) {
              ShowToastDialog.closeLoader();
              if (value == true) {
                ShowToastDialog.showToast("Account deleted successfully".tr);
                Get.offAll(const LoginScreen());
              } else {
                ShowToastDialog.showToast("Contact Administrator".tr);
              }
            });
          },
          negativeClick: () => Get.back(),
          img: Image.asset('assets/icons/delete_dialog.gif', height: 50, width: 50),
        );
      },
    );
  }
}

class _AvailabilitySwitch extends StatefulWidget {
  const _AvailabilitySwitch({required this.isDark});
  final bool isDark;

  @override
  State<_AvailabilitySwitch> createState() => _AvailabilitySwitchState();
}

class _AvailabilitySwitchState extends State<_AvailabilitySwitch> {
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _isActive = Constant.userModel?.isActive ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
      contentPadding: const EdgeInsets.only(left: 0.0, right: 0.0),
      trailing: Transform.scale(
        scale: 0.8,
        child: CupertinoSwitch(
          value: _isActive,
          activeTrackColor: AppThemeData.primary300,
          onChanged: (value) async {
            final user = Constant.userModel;
            if (user == null) return;
            if (user.isAutoVerify == false && user.isDocumentVerify != true) {
              ShowToastDialog.showToast(
                  "Document verification is pending. Please proceed to set up your document verification."
                      .tr);
              return;
            }
            setState(() => _isActive = value);
            user.isActive = value;
            user.inProgressOrderID = Constant.userModel?.inProgressOrderID;
            user.orderRequestData = Constant.userModel?.orderRequestData;
            await FireStoreUtils.updateUser(user);
          },
        ),
      ),
      dense: true,
      title: Text(
        'Available Status'.tr,
        style: TextStyle(
          color: widget.isDark ? AppThemeData.grey100 : AppThemeData.grey800,
          fontFamily: AppThemeData.semiBold,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.isDark});
  final String title;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: TextStyle(
          color: isDark ? AppThemeData.grey400 : AppThemeData.grey500,
          fontSize: 12,
          fontFamily: AppThemeData.medium,
        ),
      ),
    );
  }
}

class _DrawerNavItem extends StatelessWidget {
  const _DrawerNavItem({
    required this.icon,
    required this.title,
    required this.isDark,
    required this.onTap,
    this.isDanger = false,
  });

  final String icon;
  final String title;
  final bool isDark;
  final VoidCallback onTap;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final color = isDanger
        ? AppThemeData.danger300
        : isDark
            ? AppThemeData.grey100
            : AppThemeData.grey800;
    return ListTile(
      visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
      contentPadding: const EdgeInsets.only(left: 0.0, right: 0.0),
      leading: SvgPicture.asset(
        icon,
        width: 22,
        colorFilter: isDanger
            ? const ColorFilter.mode(AppThemeData.danger300, BlendMode.srcIn)
            : null,
      ),
      trailing: Icon(Icons.keyboard_arrow_right_rounded, size: 24,
          color: isDanger ? AppThemeData.danger300 : null),
      dense: true,
      title: Text(title,
          style: TextStyle(color: color, fontFamily: AppThemeData.semiBold)),
      onTap: onTap,
    );
  }
}

class _DarkModeNavItem extends StatelessWidget {
  const _DarkModeNavItem(
      {required this.isDark, required this.themeController});
  final bool isDark;
  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
      contentPadding: const EdgeInsets.only(left: 0.0, right: 0.0),
      leading: SvgPicture.asset("assets/icons/ic_light_dark.svg"),
      trailing: Obx(
        () => Transform.scale(
          scale: 0.8,
          child: CupertinoSwitch(
            value: themeController.isDark.value,
            activeTrackColor: AppThemeData.primary300,
            onChanged: (value) {
              themeController.isDark.value = value;
              Preferences.setBoolean(Preferences.themKey, value);
            },
          ),
        ),
      ),
      dense: true,
      title: Text(
        'Dark Mode'.tr,
        style: TextStyle(
          color: isDark ? AppThemeData.grey100 : AppThemeData.grey800,
          fontFamily: AppThemeData.semiBold,
        ),
      ),
    );
  }
}
