// ignore_for_file: deprecated_member_use

import 'package:driver/app/edit_profile_screen/edit_profile_screen.dart';
import 'package:driver/app/home_screen/home_screen.dart';
import 'package:driver/app/parcel_screen/parcel_dashboard_screen.dart';
import 'package:driver/app/parcel_screen/parcel_order_details.dart';
import 'package:driver/app/unified_delivery/unified_delivery_controller.dart';
import 'package:driver/app/wallet_screen/wallet_screen.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/themes/app_them_data.dart';
import 'package:driver/themes/round_button_fill.dart';
import 'package:driver/themes/theme_controller.dart';
import 'package:driver/widget/driver_global_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class UnifiedDeliveryHomeScreen extends StatelessWidget {
  const UnifiedDeliveryHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return GetX(
      init: UnifiedDeliveryController(),
      builder: (controller) {
        final isDark = themeController.isDark.value;
        return Scaffold(
          backgroundColor: isDark ? AppThemeData.grey900 : AppThemeData.grey50,
          drawerEnableOpenDragGesture: false,
          appBar: AppBar(
            titleSpacing: 5,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back 👋'.tr,
                  style: TextStyle(
                    color: isDark ? AppThemeData.grey50 : AppThemeData.grey900,
                    fontSize: 12,
                    fontFamily: AppThemeData.medium,
                  ),
                ),
                Text(
                  Constant.userModel != null
                      ? Constant.userModel!.fullName().tr
                      : "",
                  style: TextStyle(
                    color: isDark ? AppThemeData.grey50 : AppThemeData.grey900,
                    fontSize: 14,
                    fontFamily: AppThemeData.semiBold,
                  ),
                ),
              ],
            ),
            actions: [
              Visibility(
                visible: Constant.userModel?.vendorID?.isEmpty == true,
                child: InkWell(
                  onTap: () {
                    Get.to(const WalletScreen(isAppBarShow: true));
                  },
                  child: SvgPicture.asset("assets/icons/ic_wallet_home.svg"),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: () {
                  Get.to(const EditProfileScreen());
                },
                child: SvgPicture.asset("assets/icons/ic_user_business.svg"),
              ),
              const SizedBox(width: 10),
            ],
            leading: Builder(
              builder: (context) {
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
                          "assets/icons/ic_drawer_open.svg",
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          drawer: const DriverGlobalDrawer(),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: controller.reloadJobs,
              color: AppThemeData.primary300,
              child: controller.isLoading.value
                  ? Constant.loader()
                  : controller.jobs.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.24),
                            Constant.showEmptyView(
                                message: "New Order not found.".tr,
                                isDark: isDark),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: controller.jobs.length + 1,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return _DeliveryHeader(
                                  count: controller.jobs.length,
                                  isDark: isDark);
                            }
                            final job = controller.jobs[index - 1];
                            return _DeliveryJobCard(
                              job: job,
                              isDark: isDark,
                              onAccept: () => _acceptAndOpenFlow(
                                  controller: controller, job: job),
                              onReject: () => controller.rejectJob(job),
                              onDetails: () => _openDetails(job),
                            );
                          },
                        ),
            ),
          ),
        );
      },
    );
  }

  void _openDetails(DeliveryJob job) {
    if (job.kind == DeliveryJobKind.vendor && job.vendorOrder != null) {
      Get.to(
        const HomeScreen(isAppBarShow: true),
        arguments: {"orderModel": job.vendorOrder},
      );
    } else if (job.kind == DeliveryJobKind.parcel && job.parcelOrder != null) {
      Get.to(() => const ParcelOrderDetails(), arguments: job.parcelOrder);
    }
  }

  Future<void> _acceptAndOpenFlow({
    required UnifiedDeliveryController controller,
    required DeliveryJob job,
  }) async {
    await controller.acceptJob(job);
    if (job.kind == DeliveryJobKind.vendor) {
      Get.to(
        const HomeScreen(isAppBarShow: true),
        arguments: {"orderModel": job.vendorOrder},
      );
    } else if (job.kind == DeliveryJobKind.parcel) {
      Get.to(() => const ParcelDashboardScreen());
    }
  }
}

class _DeliveryHeader extends StatelessWidget {
  const _DeliveryHeader({
    required this.count,
    required this.isDark,
  });

  final int count;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Livraisons".tr,
          style: TextStyle(
            color: isDark ? AppThemeData.grey50 : AppThemeData.grey900,
            fontSize: 22,
            fontFamily: AppThemeData.semiBold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "$count ${"commande(s) autour de vous".tr}",
          style: TextStyle(
            color: isDark ? AppThemeData.grey400 : AppThemeData.grey600,
            fontSize: 13,
            fontFamily: AppThemeData.regular,
          ),
        ),
      ],
    );
  }
}

class _DeliveryJobCard extends StatelessWidget {
  const _DeliveryJobCard({
    required this.job,
    required this.isDark,
    required this.onAccept,
    required this.onReject,
    required this.onDetails,
  });

  final DeliveryJob job;
  final bool isDark;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.grey900 : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: isDark ? AppThemeData.grey800 : AppThemeData.grey200),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppThemeData.primary300.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    job.badge,
                    style: TextStyle(
                      color: AppThemeData.primary300,
                      fontSize: 12,
                      fontFamily: AppThemeData.semiBold,
                    ),
                  ),
                ),
                const Spacer(),
                if (job.distanceKm != null)
                  Text(
                    "${job.distanceKm!.toStringAsFixed(1)} km",
                    style: TextStyle(
                      color:
                          isDark ? AppThemeData.grey300 : AppThemeData.grey700,
                      fontSize: 13,
                      fontFamily: AppThemeData.medium,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              job.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark ? AppThemeData.grey50 : AppThemeData.grey900,
                fontSize: 17,
                fontFamily: AppThemeData.semiBold,
              ),
            ),
            const SizedBox(height: 12),
            _AddressRow(
                icon: Icons.radio_button_checked,
                label: job.pickupAddress,
                isDark: isDark),
            const SizedBox(height: 8),
            _AddressRow(
                icon: Icons.location_on,
                label: job.dropoffAddress,
                isDark: isDark),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  job.amount,
                  style: TextStyle(
                    color: isDark ? AppThemeData.grey50 : AppThemeData.grey900,
                    fontSize: 15,
                    fontFamily: AppThemeData.semiBold,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    job.status.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                          isDark ? AppThemeData.grey400 : AppThemeData.grey600,
                      fontSize: 12,
                      fontFamily: AppThemeData.regular,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (job.canAccept)
              Row(
                children: [
                  Expanded(
                    child: RoundedButtonFill(
                      title: "Refuser".tr,
                      color: Colors.red.withValues(alpha: 0.12),
                      textColor: Colors.red,
                      height: 5,
                      onPress: onReject,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RoundedButtonFill(
                      title: "Accepter".tr,
                      color: AppThemeData.primary300,
                      textColor: Colors.white,
                      height: 5,
                      onPress: onAccept,
                    ),
                  ),
                ],
              )
            else
              RoundedButtonFill(
                title: "Détail".tr,
                color: AppThemeData.primary300,
                textColor: Colors.white,
                height: 5,
                onPress: onDetails,
              ),
          ],
        ),
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: AppThemeData.primary300),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? AppThemeData.grey300 : AppThemeData.grey700,
              fontSize: 13,
              fontFamily: AppThemeData.regular,
            ),
          ),
        ),
      ],
    );
  }
}
