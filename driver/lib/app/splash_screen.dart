import 'package:driver/controllers/splash_controller.dart';
import 'package:driver/themes/app_them_data.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SplashController>(
      init: SplashController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  "assets/images/driver_logo.png",
                  height: 150,
                ),
                const SizedBox(
                  height: 28,
                ),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppThemeData.primary300,
                    backgroundColor: AppThemeData.grey200,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
