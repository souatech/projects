import 'dart:async';
import 'dart:developer';

import 'package:driver/app/auth_screen/login_screen.dart';
import 'package:driver/app/maintenance_mode_screen/maintenance_mode_screen.dart';
import 'package:driver/app/on_boarding_screen.dart';
import 'package:driver/app/owner_screen/owner_dashboard_screen.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/controllers/signup_controller.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:driver/utils/notification_service.dart';
import 'package:driver/utils/preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    Timer(const Duration(seconds: 3), () => redirectScreen());
    super.onInit();
  }

  Future<void> redirectScreen() async {
    try {
      if (await FireStoreUtils.isMaintenanceMode() == true) {
        Get.offAll(() => MaintenanceModeScreen());
        return;
      }

      if (Preferences.getBoolean(Preferences.isFinishOnBoardingKey) == false) {
        Get.offAll(const OnboardingScreen());
        return;
      }

      final isLogin = await FireStoreUtils.isLogin();
      if (!isLogin) {
        await FirebaseAuth.instance.signOut();
        Get.offAll(const LoginScreen());
        return;
      }

      final userModel = await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid());
      if (userModel == null) {
        log('[SPLASH] getUserProfile returned null — redirecting to login');
        await FirebaseAuth.instance.signOut();
        Get.offAll(const LoginScreen());
        return;
      }

      log(userModel.toJson().toString());

      if (userModel.role != Constant.userRoleDriver || userModel.active != true) {
        await FirebaseAuth.instance.signOut();
        Get.offAll(const LoginScreen());
        return;
      }

      final token = await NotificationService.getToken();
      if (token.isNotEmpty) {
        userModel.fcmToken = token;
        await FireStoreUtils.updateUser(userModel);
      }

      if (userModel.isOwner == true) {
        Get.offAll(OwnerDashboardScreen());
      } else {
        SignupController.navigateByUserModel(userModel);
      }
    } catch (e, stack) {
      log('[SPLASH] redirectScreen error — navigating to login: $e\n$stack');
      try {
        Get.offAll(const LoginScreen());
      } catch (_) {}
    }
  }
}
