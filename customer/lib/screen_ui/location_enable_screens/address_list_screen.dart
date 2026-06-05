import 'package:customer/constant/assets.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/controllers/address_list_controller.dart';
import 'package:customer/controllers/theme_controller.dart';
import 'package:customer/models/user_model.dart';
import 'package:customer/screen_ui/location_enable_screens/enter_manually_location.dart';
import 'package:customer/themes/app_them_data.dart' show AppThemeData;
import 'package:customer/themes/round_button_fill.dart';
import 'package:customer/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class AddressListScreen extends StatelessWidget {
  const AddressListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDark.value;
    return GetX(
      init: AddressListController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor:
              isDark ? AppThemeData.grey900 : const Color(0xFFF8F9FB),
          body:
              controller.isLoading.value
                  ? Constant.loader()
                  : SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _CircleButton(
                                isDark: isDark,
                                icon: Icons.arrow_back_rounded,
                                onTap: Get.back,
                              ),
                              Expanded(
                                child: Text(
                                  "Mes adresses".tr,
                                  textAlign: TextAlign.center,
                                  style: AppThemeData.boldTextStyle(
                                    fontSize: 23,
                                    color:
                                        isDark
                                            ? Colors.white
                                            : const Color(0xFF111827),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 50),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Expanded(
                            child:
                                controller.shippingAddressList.isEmpty
                                    ? _EmptyAddressState(isDark: isDark)
                                    : ListView.separated(
                                      itemCount:
                                          controller.shippingAddressList.length,
                                      itemBuilder: (context, index) {
                                        ShippingAddress address =
                                            controller
                                                .shippingAddressList[index];
                                        return _AddressTile(
                                          address: address,
                                          isDark: isDark,
                                          onSelect:
                                              () => Get.back(result: address),
                                          onDelete:
                                              () => controller.deleteAddress(
                                                index,
                                              ),
                                          onEdit: () {
                                            Get.to(
                                              const EnterManuallyLocationScreen(),
                                              arguments: {
                                                "address": address,
                                                "mode": "Edit",
                                              },
                                            )!.then((value) {
                                              if (value == true) {
                                                controller.getUser();
                                              }
                                            });
                                          },
                                        );
                                      },
                                      separatorBuilder: (
                                        BuildContext context,
                                        int index,
                                      ) {
                                        return const SizedBox(height: 12);
                                      },
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.only(
              bottom: 30,
              left: 16,
              right: 16,
              top: 20,
            ),
            child: RoundedButtonFill(
              title: "Add New Address".tr,
              onPress: () {
                Get.to(EnterManuallyLocationScreen())!.then((value) {
                  if (value == true) {
                    controller.getUser();
                  }
                });
              },
              isRight: false,
              isCenter: true,
              icon: SvgPicture.asset(
                AppAssets.icPlus,
                width: 20,
                height: 18,
                colorFilter: ColorFilter.mode(
                  AppThemeData.greyDark900,
                  BlendMode.srcIn,
                ),
              ),
              color: isDark ? AppThemeData.primary300 : AppThemeData.primary300,
              textColor: isDark ? AppThemeData.grey50 : AppThemeData.grey50,
            ),
          ),
        );
      },
    );
  }
}

class _AddressTile extends StatelessWidget {
  final ShippingAddress address;
  final bool isDark;
  final VoidCallback onSelect;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _AddressTile({
    required this.address,
    required this.isDark,
    required this.onSelect,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final title =
        (address.addressAs ?? '').trim().isEmpty
            ? "Adresse".tr
            : address.addressAs!.trim();
    final subtitle = Utils.shortAddressFromText(
      address.getFullAddress(),
      fallback: "Choisir une adresse".tr,
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onSelect,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppThemeData.grey800 : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? AppThemeData.grey700 : const Color(0xFFE8EAEE),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF1E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFFFF4B12),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppThemeData.boldTextStyle(
                              fontSize: 17,
                              color:
                                  isDark
                                      ? Colors.white
                                      : const Color(0xFF111827),
                            ),
                          ),
                        ),
                        if (address.isDefault == true) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5F8EB),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "Default".tr,
                              style: AppThemeData.mediumTextStyle(
                                fontSize: 11,
                                color: const Color(0xFF159447),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppThemeData.mediumTextStyle(
                        fontSize: 14,
                        color:
                            isDark
                                ? AppThemeData.grey300
                                : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder:
                    (_) => [
                      PopupMenuItem(value: 'edit', child: Text('Edit'.tr)),
                      PopupMenuItem(value: 'delete', child: Text('Delete'.tr)),
                    ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyAddressState extends StatelessWidget {
  final bool isDark;

  const _EmptyAddressState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "Aucune adresse enregistrée".tr,
        style: AppThemeData.mediumTextStyle(
          fontSize: 15,
          color: isDark ? AppThemeData.grey300 : const Color(0xFF6B7280),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({
    required this.isDark,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isDark ? AppThemeData.grey800 : Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isDark ? Colors.white : const Color(0xFF111827),
        ),
      ),
    );
  }
}
