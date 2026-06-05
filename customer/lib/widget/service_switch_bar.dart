import 'package:customer/constant/constant.dart';
import 'package:customer/models/section_model.dart';
import 'package:customer/service/cart_provider.dart';
import 'package:customer/service/database_helper.dart';
import 'package:customer/service/fire_store_utils.dart';
import 'package:customer/themes/app_them_data.dart';
import 'package:customer/themes/round_button_fill.dart';
import 'package:customer/themes/show_toast_dialog.dart';
import 'package:customer/utils/notification_service.dart';
import 'package:customer/utils/service_section_router.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ServiceSwitchBar extends StatelessWidget {
  const ServiceSwitchBar({super.key});

  static IconData _iconFor(String? flag) {
    switch (flag) {
      case 'cab-service':
      case 'rental-service':
        return Icons.local_taxi_rounded;
      case 'ecommerce-service':
        return Icons.storefront_rounded;
      case 'parcel_delivery':
        return Icons.local_shipping_rounded;
      case 'ondemand-service':
        return Icons.build_circle_rounded;
      default:
        return Icons.restaurant_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sections = _visibleSections(Constant.sectionList);
    if (sections.length <= 1) return const SizedBox.shrink();

    final statusBarH = MediaQuery.viewPaddingOf(context).top;
    final currentId = Constant.sectionConstantModel?.id;

    return Container(
      color: AppThemeData.primary300,
      // extends behind the status bar; padding pushes content below it
      height: statusBarH + 48,
      padding: EdgeInsets.only(top: statusBarH),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children:
            sections.map((section) {
              final isActive = section.id == currentId;
              final label = _publicLabelFor(section);
              return SizedBox(
                width: 112,
                child: InkWell(
                  onTap: isActive ? null : () => _handleTap(section),
                  highlightColor: Colors.white.withValues(alpha: 0.12),
                  splashColor: Colors.white.withValues(alpha: 0.20),
                  child: SizedBox(
                    height: 48,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _iconFor(section.serviceTypeFlag),
                                size: 15,
                                color:
                                    isActive
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.60),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight:
                                      isActive
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                  color:
                                      isActive
                                          ? Colors.white
                                          : Colors.white.withValues(
                                            alpha: 0.60,
                                          ),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (isActive)
                          Container(height: 2.5, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  List<SectionModel> _visibleSections(List<SectionModel> sections) {
    final seenIds = <String>{};
    final visible = <SectionModel>[];
    for (final section in sections) {
      final publicLabel = _publicLabelFor(section);
      if (section.isActive != true || publicLabel.isEmpty) {
        continue;
      }
      final key = (section.id ?? '').trim();
      if (key.isNotEmpty && seenIds.contains(key)) {
        continue;
      }
      if (key.isNotEmpty) {
        seenIds.add(key);
      }
      visible.add(section);
    }
    return visible;
  }

  String _publicLabelFor(SectionModel section) {
    final name = (section.name ?? '').trim();
    if (name.isEmpty) {
      return '';
    }
    return Constant.translateServiceName(name);
  }

  void _handleTap(SectionModel section) {
    if (cartItem.isNotEmpty) {
      Get.defaultDialog(
        title: 'Alert!'.tr,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'If you select this Section/Service, your previously added items will be removed from the cart.'
                  .tr,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: RoundedButtonFill(
                    height: 5.5,
                    title: 'Cancel'.tr,
                    onPress: () => Get.back(),
                    color: AppThemeData.grey900,
                    textColor: AppThemeData.surface,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: RoundedButtonFill(
                    title: 'OK'.tr,
                    height: 5.5,
                    onPress: () async {
                      await DatabaseHelper.instance.deleteAllCartProducts();
                      CartProvider().clearDatabase();
                      Get.back();
                      await _doSwitch(section);
                    },
                    color: AppThemeData.primary300,
                    textColor: AppThemeData.surface,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [],
      );
    } else {
      _doSwitch(section);
    }
  }

  Future<void> _doSwitch(SectionModel section) async {
    ShowToastDialog.showLoader('Please wait...'.tr);

    if (auth.FirebaseAuth.instance.currentUser != null) {
      final uid = auth.FirebaseAuth.instance.currentUser!.uid;
      final user = await FireStoreUtils.getUserProfile(uid);
      if (user != null) {
        user.fcmToken = await NotificationService.getToken();
        await FireStoreUtils.updateUser(user);
      }
    }

    ShowToastDialog.closeLoader();
    await ServiceSectionRouter.open(section, replace: true);
  }
}
