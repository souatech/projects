// ignore_for_file: library_prefixes, curly_braces_in_flow_control_structures, deprecated_member_use, use_build_context_synchronously

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:customer/models/coupon_model.dart';
import 'package:customer/models/vehicle_type.dart';
import 'package:customer/screen_ui/cab_service_screens/cab_coupon_code_screen.dart';
import 'package:customer/screen_ui/help_support_screen/help_support_screen.dart';
import 'package:customer/screen_ui/multi_vendor_service/chat_screens/chat_screen.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/themes/round_button_border.dart';
import 'package:customer/utils/network_image_widget.dart';
import 'package:customer/utils/utils.dart';
import 'package:customer/widget/my_separator.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_map/flutter_map.dart' as flutterMap;
import 'package:latlong2/latlong.dart' as latlong;
import '../../constant/constant.dart';
import '../../controllers/cab_booking_controller.dart';
import '../../controllers/cab_dashboard_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../models/user_model.dart';
import '../../service/fire_store_utils.dart';
import '../../themes/app_them_data.dart';
import '../../themes/round_button_fill.dart';
import '../../themes/show_toast_dialog.dart';
import '../../themes/text_field_widget.dart';
import '../../widget/osm_map/map_picker_page.dart';
import '../../widget/place_picker/location_picker_screen.dart';
import '../../widget/place_picker/selected_location_model.dart';
import 'package:location/location.dart';

const Color _cabOrange = Color(0xFFFF4B12);
const Color _cabInk = Color(0xFF111111);

class _CabTopChrome extends StatelessWidget {
  final bool isDark;
  final VoidCallback onBack;
  final VoidCallback onNotification;

  const _CabTopChrome({
    required this.isDark,
    required this.onBack,
    required this.onNotification,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 14,
      left: 24,
      right: 24,
      child: Row(
        children: [
          _CabFloatingButton(
            icon: Icons.menu_rounded,
            isDark: isDark,
            onTap: onBack,
          ),
          const Spacer(),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/icons/joxmako_icon.png',
                width: 92,
                height: 52,
                fit: BoxFit.contain,
              ),
              Text(
                'DRIVE',
                style: AppThemeData.boldTextStyle(
                  fontSize: 16,
                  color: _cabInk,
                ).copyWith(letterSpacing: 1.6),
              ),
            ],
          ),
          const Spacer(),
          _CabFloatingButton(
            icon: Icons.notifications_none_rounded,
            isDark: isDark,
            onTap: onNotification,
            showDot: true,
          ),
        ],
      ),
    );
  }
}

class _CabFloatingButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;
  final bool showDot;

  const _CabFloatingButton({
    required this.icon,
    required this.isDark,
    required this.onTap,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Ink(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: isDark ? AppThemeData.grey800 : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, color: isDark ? Colors.white : _cabInk, size: 28),
              if (showDot)
                Positioned(
                  right: 14,
                  top: 13,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: _cabOrange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CabMapButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _CabMapButton({
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _CabFloatingButton(icon: icon, isDark: isDark, onTap: onTap);
  }
}

class _VehicleOptionSkeleton extends StatelessWidget {
  final bool isDark;

  const _VehicleOptionSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: 3,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.45, end: 1),
          duration: Duration(milliseconds: 600 + (index * 120)),
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            return Opacity(opacity: value, child: child);
          },
          child: Container(
            height: 82,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppThemeData.grey800 : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? AppThemeData.grey700 : const Color(0xFFEDEFF3),
              ),
            ),
            child: Row(
              children: [
                _SkeletonBlock(width: 74, height: 54, isDark: isDark),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SkeletonBlock(width: 120, height: 14, isDark: isDark),
                      const SizedBox(height: 10),
                      _SkeletonBlock(width: 82, height: 12, isDark: isDark),
                    ],
                  ),
                ),
                _SkeletonBlock(width: 70, height: 14, isDark: isDark),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  final double width;
  final double height;
  final bool isDark;

  const _SkeletonBlock({
    required this.width,
    required this.height,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.grey700 : AppThemeData.grey200,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class _VehicleOptionEmptyState extends StatelessWidget {
  final bool isDark;
  final Future<void> Function() onRetry;

  const _VehicleOptionEmptyState({required this.isDark, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppThemeData.grey800 : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppThemeData.grey700 : const Color(0xFFEDEFF3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.no_crash_outlined, color: _cabOrange, size: 34),
            const SizedBox(height: 10),
            Text(
              "Aucune option véhicule disponible".tr,
              textAlign: TextAlign.center,
              style: AppThemeData.semiBoldTextStyle(
                color: isDark ? Colors.white : _cabInk,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Les options actives configurées par l’admin apparaîtront ici."
                  .tr,
              textAlign: TextAlign.center,
              style: AppThemeData.mediumTextStyle(
                color: isDark ? AppThemeData.grey300 : AppThemeData.grey600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: onRetry,
              child: Text(
                "Réessayer".tr,
                style: AppThemeData.boldTextStyle(
                  color: _cabOrange,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CabLocationPanel extends StatelessWidget {
  final bool isDark;
  final TextEditingController sourceController;
  final TextEditingController destinationController;
  final VoidCallback onSourceTap;
  final VoidCallback onDestinationTap;

  const _CabLocationPanel({
    required this.isDark,
    required this.sourceController,
    required this.destinationController,
    required this.onSourceTap,
    required this.onDestinationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.grey800 : const Color(0xFFFCFCFD),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppThemeData.grey700 : const Color(0xFFF0F1F4),
        ),
      ),
      child: Column(
        children: [
          _CabLocationRow(
            icon: Icons.circle,
            iconColor: isDark ? Colors.white : _cabInk,
            title: 'Ma position'.tr,
            controller: sourceController,
            hint: 'Pickup Location'.tr,
            onTap: onSourceTap,
            isDark: isDark,
          ),
          Divider(
            height: 1,
            indent: 70,
            color: isDark ? AppThemeData.grey700 : const Color(0xFFEDEFF3),
          ),
          _CabLocationRow(
            icon: Icons.location_on_rounded,
            iconColor: _cabOrange,
            title: 'Où allez-vous ?'.tr,
            controller: destinationController,
            hint: 'Destination Location'.tr,
            onTap: onDestinationTap,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _CabLocationRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final TextEditingController controller;
  final String hint;
  final VoidCallback onTap;
  final bool isDark;

  const _CabLocationRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.controller,
    required this.hint,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final value = controller.text.trim();
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppThemeData.boldTextStyle(
                      fontSize: 18,
                      color: isDark ? Colors.white : _cabInk,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value.isEmpty ? hint : value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppThemeData.mediumTextStyle(
                      fontSize: 14,
                      color:
                          isDark ? AppThemeData.grey300 : AppThemeData.grey600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.favorite_border_rounded,
              color: isDark ? AppThemeData.grey300 : AppThemeData.grey600,
            ),
          ],
        ),
      ),
    );
  }
}

class _CabSavedAddressStrip extends StatelessWidget {
  final bool isDark;
  final List<ShippingAddress> addresses;
  final ValueChanged<ShippingAddress> onTap;

  const _CabSavedAddressStrip({
    required this.isDark,
    required this.addresses,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.grey800 : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppThemeData.grey700 : const Color(0xFFEDEFF3),
        ),
      ),
      child: Row(
        children:
            addresses.map((address) {
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(address),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          color: isDark ? Colors.white : _cabInk,
                          size: 25,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                (address.addressAs ?? '').trim().isEmpty
                                    ? 'Adresse'.tr
                                    : address.addressAs!.trim(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppThemeData.boldTextStyle(
                                  fontSize: 14,
                                  color: isDark ? Colors.white : _cabInk,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                Utils.shortAddressFromText(
                                  address.getFullAddress(),
                                  fallback: 'Choisir une adresse'.tr,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppThemeData.mediumTextStyle(
                                  fontSize: 12,
                                  color:
                                      isDark
                                          ? AppThemeData.grey300
                                          : AppThemeData.grey600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}

class CabBookingScreen extends StatelessWidget {
  const CabBookingScreen({super.key});

  void _handleBack(CabBookingController controller) {
    if (controller.bottomSheetType.value == "vehicleSelection") {
      controller.bottomSheetType.value = "location";
    } else if (controller.bottomSheetType.value == "payment") {
      controller.bottomSheetType.value = "vehicleSelection";
    } else if (controller.bottomSheetType.value == "conformRide") {
      controller.bottomSheetType.value = "payment";
    } else if (controller.bottomSheetType.value == "waitingDriver" ||
        controller.bottomSheetType.value == "driverDetails") {
      Get.back(result: true);
    } else {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDark.value;
    return GetX(
      init: CabBookingController(),
      builder: (controller) {
        return Scaffold(
          body:
              controller.isLoading.value
                  ? Constant.loader()
                  : Stack(
                    children: [
                      Constant.selectedMapType == "osm"
                          ? flutterMap.FlutterMap(
                            mapController: controller.mapOsmController,
                            options: flutterMap.MapOptions(
                              initialCenter:
                                  Constant.currentLocation != null
                                      ? latlong.LatLng(
                                        Constant.currentLocation!.latitude,
                                        Constant.currentLocation!.longitude,
                                      )
                                      : controller.currentOrder.value.id != null
                                      ? latlong.LatLng(
                                        double.parse(
                                          controller
                                              .currentOrder
                                              .value
                                              .sourceLocation!
                                              .latitude
                                              .toString(),
                                        ),
                                        double.parse(
                                          controller
                                              .currentOrder
                                              .value
                                              .sourceLocation!
                                              .longitude
                                              .toString(),
                                        ),
                                      )
                                      : latlong.LatLng(
                                        41.4219057,
                                        -102.0840772,
                                      ),
                              initialZoom: 10,
                            ),
                            children: [
                              flutterMap.TileLayer(
                                urlTemplate:
                                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName:
                                    Platform.isAndroid
                                        ? "com.joxmako.customer"
                                        : "com.joxmako.customer.ios",
                              ),
                              flutterMap.MarkerLayer(
                                markers: controller.osmMarker,
                              ),
                              if (controller.routePoints.isNotEmpty)
                                flutterMap.PolylineLayer(
                                  polylines: [
                                    flutterMap.Polyline(
                                      points: controller.routePoints,
                                      strokeWidth: 5.0,
                                      color: Colors.blue,
                                    ),
                                  ],
                                ),
                            ],
                          )
                          : GoogleMap(
                            onMapCreated: (googleMapController) {
                              controller.mapController = googleMapController;

                              if (Constant.currentLocation != null) {
                                controller.setDepartureMarker(
                                  Constant.currentLocation!.latitude,
                                  Constant.currentLocation!.longitude,
                                );
                                controller.searchPlaceNameGoogle();
                              }
                            },
                            initialCameraPosition: CameraPosition(
                              target: controller.currentPosition.value,
                              zoom: 14,
                            ),
                            myLocationEnabled: true,
                            zoomControlsEnabled: true,
                            zoomGesturesEnabled: true,
                            polylines: Set<Polyline>.of(
                              controller.polyLines.values,
                            ),
                            markers:
                                controller.markers
                                    .toSet(), // reactive marker set
                          ),
                      _CabTopChrome(
                        isDark: isDark,
                        onBack: () => _handleBack(controller),
                        onNotification:
                            () => Get.to(
                              HelpSupportScreen(
                                isNavigateViaNotification: true,
                              ),
                            ),
                      ),
                      Positioned(
                        left: Constant.isRtl ? null : 24,
                        right: Constant.isRtl ? 24 : null,
                        bottom: MediaQuery.of(context).size.height * 0.35,
                        child: _CabMapButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          isDark: isDark,
                          onTap: () => _handleBack(controller),
                        ),
                      ),
                      Positioned(
                        right: Constant.isRtl ? null : 24,
                        left: Constant.isRtl ? 24 : null,
                        bottom: MediaQuery.of(context).size.height * 0.35,
                        child: _CabMapButton(
                          icon: Icons.my_location_rounded,
                          isDark: isDark,
                          onTap: () {
                            if (Constant.currentLocation != null) {
                              controller.setDepartureMarker(
                                Constant.currentLocation!.latitude,
                                Constant.currentLocation!.longitude,
                              );
                              controller.searchPlaceNameGoogle();
                            }
                          },
                        ),
                      ),
                      controller.bottomSheetType.value == "location"
                          ? searchLocationBottomSheet(
                            context,
                            controller,
                            isDark,
                          )
                          : controller.bottomSheetType.value ==
                              "vehicleSelection"
                          ? vehicleSelection(context, controller, isDark)
                          : controller.bottomSheetType.value == "payment"
                          ? paymentBottomSheet(context, controller, isDark)
                          : controller.bottomSheetType.value == "conformRide"
                          ? conformBottomSheet(context, controller, isDark)
                          : controller.bottomSheetType.value ==
                              "waitingForDriver"
                          ? waitingDialog(context, controller, isDark)
                          : controller.bottomSheetType.value == "driverDetails"
                          ? driverDialog(context, controller, isDark)
                          : SizedBox(),
                    ],
                  ),
        );
      },
    );
  }

  Widget searchLocationBottomSheet(
    BuildContext context,
    CabBookingController controller,
    bool isDark,
  ) {
    final savedAddresses =
        (Constant.userModel?.shippingAddress ?? [])
            .where(
              (address) =>
                  address.location != null &&
                  address.getFullAddress().isNotEmpty,
            )
            .take(3)
            .toList();
    return Positioned.fill(
      child: DraggableScrollableSheet(
        initialChildSize: savedAddresses.isEmpty ? 0.36 : 0.46,
        // Start height
        minChildSize: savedAddresses.isEmpty ? 0.36 : 0.46,
        // Minimum height
        maxChildSize: 0.8,
        // Maximum height
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: EdgeInsets.fromLTRB(
              20,
              10,
              20,
              18 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppThemeData.grey900 : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(34),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.12),
                  blurRadius: 28,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: AppThemeData.grey300,
                  ),
                  height: 5,
                  width: 58,
                ),
                const SizedBox(height: 18),
                _CabLocationPanel(
                  isDark: isDark,
                  sourceController: controller.sourceTextEditController.value,
                  destinationController:
                      controller.destinationTextEditController.value,
                  onSourceTap: () => _pickSourceLocation(controller),
                  onDestinationTap: () => _pickDestinationLocation(controller),
                ),
                if (savedAddresses.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _CabSavedAddressStrip(
                    isDark: isDark,
                    addresses: savedAddresses,
                    onTap: (address) {
                      controller.destinationTextEditController.value.text =
                          address.getFullAddress();
                      controller.setDestinationMarker(
                        address.location!.latitude ?? 0,
                        address.location!.longitude ?? 0,
                      );
                    },
                  ),
                ],
                const SizedBox(height: 16),
                RoundedButtonFill(
                  title: "Commander un chauffeur".tr,
                  onPress: () {
                    if (controller
                        .sourceTextEditController
                        .value
                        .text
                        .isEmpty) {
                      ShowToastDialog.showToast(
                        "Please select source location".tr,
                      );
                    } else if (controller
                        .destinationTextEditController
                        .value
                        .text
                        .isEmpty) {
                      ShowToastDialog.showToast(
                        "Please select destination location".tr,
                      );
                    } else {
                      controller.prepareVehicleSelection();
                    }
                  },
                  color: AppThemeData.primary300,
                  textColor: Colors.white,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickSourceLocation(CabBookingController controller) async {
    if (Constant.selectedMapType == 'osm') {
      final result = await Get.to(() => MapPickerPage());
      if (result != null) {
        controller.sourceTextEditController.value.text = '';
        final firstPlace = result;
        if (Constant.checkZoneCheck(
              firstPlace.coordinates.latitude,
              firstPlace.coordinates.longitude,
            ) ==
            true) {
          final lat = firstPlace.coordinates.latitude;
          final lng = firstPlace.coordinates.longitude;
          final address = firstPlace.address;
          controller.sourceTextEditController.value.text = address.toString();
          controller.setDepartureMarker(lat, lng);
        } else {
          ShowToastDialog.showToast(
            "Service is unavailable at the selected address.".tr,
          );
        }
      }
    } else {
      Get.to(LocationPickerScreen())!.then((value) async {
        if (value != null) {
          SelectedLocationModel selectedLocationModel = value;

          if (Constant.checkZoneCheck(
                selectedLocationModel.latLng!.latitude,
                selectedLocationModel.latLng!.longitude,
              ) ==
              true) {
            controller.sourceTextEditController.value.text =
                Utils.formatAddress(selectedLocation: selectedLocationModel);
            controller.setDepartureMarker(
              selectedLocationModel.latLng!.latitude,
              selectedLocationModel.latLng!.longitude,
            );
          } else {
            ShowToastDialog.showToast(
              "Service is unavailable at the selected address.".tr,
            );
          }
        }
      });
    }
  }

  Future<void> _pickDestinationLocation(CabBookingController controller) async {
    if (Constant.selectedMapType == 'osm') {
      final result = await Get.to(() => MapPickerPage());
      if (result != null) {
        controller.destinationTextEditController.value.text = '';
        final firstPlace = result;
        final lat = firstPlace.coordinates.latitude;
        final lng = firstPlace.coordinates.longitude;
        final address = firstPlace.address;
        controller.destinationTextEditController.value.text =
            address.toString();
        controller.setDestinationMarker(lat, lng);
      }
    } else {
      Get.to(LocationPickerScreen())!.then((value) async {
        if (value != null) {
          SelectedLocationModel selectedLocationModel = value;
          controller.destinationTextEditController.value.text =
              Utils.formatAddress(selectedLocation: selectedLocationModel);
          controller.setDestinationMarker(
            selectedLocationModel.latLng!.latitude,
            selectedLocationModel.latLng!.longitude,
          );
        }
      });
    }
  }

  void _ensureAllowedCustomerPayment(CabBookingController controller) {
    if (controller.selectedPaymentMethod.value != PaymentGateway.wallet.name) {
      return;
    }
    if (controller.cashOnDeliverySettingModel.value.isEnabled == true) {
      controller.selectedPaymentMethod.value = PaymentGateway.cod.name;
    } else if (controller.paydunyaConfig.value.isEnabled) {
      controller.selectedPaymentMethod.value = PaymentGateway.paydunya.name;
    } else {
      controller.selectedPaymentMethod.value = '';
    }
  }

  Widget vehicleSelection(
    BuildContext context,
    CabBookingController controller,
    bool isDark,
  ) {
    return Positioned.fill(
      child: DraggableScrollableSheet(
        initialChildSize: 0.56,
        minChildSize: 0.42,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppThemeData.grey900 : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(34),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.12),
                  blurRadius: 28,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                10,
                20,
                18 + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: AppThemeData.grey300,
                    ),
                    height: 5,
                    width: 58,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Choisissez votre option".tr,
                            style: AppThemeData.boldTextStyle(
                              fontSize: 21,
                              color: isDark ? Colors.white : _cabInk,
                            ),
                            textAlign: TextAlign.start,
                          ),
                        ),
                        Text(
                          "Voir plus".tr,
                          style: AppThemeData.boldTextStyle(
                            fontSize: 14,
                            color: _cabOrange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Obx(() {
                      if (controller.isVehicleLoading.value) {
                        return _VehicleOptionSkeleton(isDark: isDark);
                      }
                      if (controller.vehicleTypes.isEmpty) {
                        return _VehicleOptionEmptyState(
                          isDark: isDark,
                          onRetry: controller.getVehicleType,
                        );
                      }
                      return ListView.builder(
                        itemCount: controller.vehicleTypes.length,
                        shrinkWrap: true,
                        padding: EdgeInsets.only(bottom: 20),
                        controller: scrollController,
                        scrollDirection: Axis.vertical,
                        itemBuilder: (context, index) {
                          VehicleType vehicleType =
                              controller.vehicleTypes[index];
                          return Obx(
                            () => InkWell(
                              onTap: () {
                                controller.selectedVehicleType.value =
                                    controller.vehicleTypes[index];
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color:
                                          controller
                                                      .selectedVehicleType
                                                      .value
                                                      .id ==
                                                  vehicleType.id
                                              ? _cabOrange
                                              : isDark
                                              ? AppThemeData.grey700
                                              : const Color(0xFFEDEFF3),
                                      width: 1,
                                    ),
                                    color:
                                        isDark
                                            ? AppThemeData.grey800
                                            : Colors.white,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          //borderRadius: BorderRadius.circular(10),
                                          child: CachedNetworkImage(
                                            imageUrl:
                                                vehicleType.vehicleIcon
                                                    .toString(),
                                            height: 56,
                                            width: 74,
                                            imageBuilder:
                                                (
                                                  context,
                                                  imageProvider,
                                                ) => Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                    image: DecorationImage(
                                                      image: imageProvider,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                            placeholder:
                                                (context, url) => Center(
                                                  child: CircularProgressIndicator.adaptive(
                                                    valueColor:
                                                        AlwaysStoppedAnimation(
                                                          AppThemeData
                                                              .primary300,
                                                        ),
                                                  ),
                                                ),
                                            errorWidget:
                                                (
                                                  context,
                                                  url,
                                                  error,
                                                ) => ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  child: Image.network(
                                                    Constant.placeHolderImage,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        vehicleType.name
                                                            .toString(),
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                        style:
                                                            AppThemeData.boldTextStyle(
                                                              fontSize: 17,
                                                              color:
                                                                  isDark
                                                                      ? Colors
                                                                          .white
                                                                      : _cabInk,
                                                            ),
                                                      ),
                                                    ),
                                                    if ((vehicleType.capacity ??
                                                            '')
                                                        .toString()
                                                        .isNotEmpty) ...[
                                                      const SizedBox(width: 8),
                                                      Icon(
                                                        Icons.person_rounded,
                                                        size: 15,
                                                        color:
                                                            isDark
                                                                ? AppThemeData
                                                                    .grey300
                                                                : AppThemeData
                                                                    .grey500,
                                                      ),
                                                      const SizedBox(width: 2),
                                                      Text(
                                                        vehicleType.capacity
                                                            .toString(),
                                                        style: AppThemeData.mediumTextStyle(
                                                          fontSize: 13,
                                                          color:
                                                              isDark
                                                                  ? AppThemeData
                                                                      .grey300
                                                                  : AppThemeData
                                                                      .grey500,
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 2.0,
                                                      ),
                                                  child: Text(
                                                    controller
                                                            .duration
                                                            .value
                                                            .isEmpty
                                                        ? "${controller.distance.toStringAsFixed(2)}${'km'.tr}"
                                                        : controller
                                                            .duration
                                                            .value,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style:
                                                        AppThemeData.mediumTextStyle(
                                                          fontSize: 14,
                                                          color:
                                                              isDark
                                                                  ? AppThemeData
                                                                      .grey300
                                                                  : AppThemeData
                                                                      .grey600,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              Constant.amountShow(
                                                amount:
                                                    controller
                                                        .getAmount(vehicleType)
                                                        .toString(),
                                              ),
                                              style: AppThemeData.boldTextStyle(
                                                fontSize: 16,
                                                color:
                                                    isDark
                                                        ? Colors.white
                                                        : _cabInk,
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            if (controller
                                                    .selectedVehicleType
                                                    .value
                                                    .id ==
                                                vehicleType.id)
                                              Container(
                                                width: 31,
                                                height: 31,
                                                decoration: const BoxDecoration(
                                                  color: _cabOrange,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.check_rounded,
                                                  color: Colors.white,
                                                  size: 19,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                  RoundedButtonFill(
                    title: "Commander un chauffeur".tr,
                    onPress: () async {
                      if (controller.selectedVehicleType.value.id != null) {
                        controller.calculateTotalAmount();
                        controller.bottomSheetType.value = "payment";
                      } else {
                        ShowToastDialog.showToast(
                          "Please select a vehicle type first.".tr,
                        );
                      }
                    },
                    color: AppThemeData.primary300,
                    textColor: Colors.white,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget paymentBottomSheet(
    BuildContext context,
    CabBookingController controller,
    bool isDark,
  ) {
    _ensureAllowedCustomerPayment(controller);
    return Positioned.fill(
      child: DraggableScrollableSheet(
        initialChildSize: 0.70,
        minChildSize: 0.30,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: isDark ? AppThemeData.grey700 : Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Select Payment Method".tr,
                      style: AppThemeData.mediumTextStyle(
                        fontSize: 18,
                        color:
                            isDark
                                ? AppThemeData.greyDark900
                                : AppThemeData.grey900,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Get.back();
                      },
                      child: Icon(
                        Icons.close,
                        color:
                            isDark
                                ? AppThemeData.greyDark900
                                : AppThemeData.grey900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    controller: scrollController,
                    children: [
                      Text(
                        "Preferred Payment".tr,
                        textAlign: TextAlign.start,
                        style: AppThemeData.boldTextStyle(
                          fontSize: 15,
                          color:
                              isDark
                                  ? AppThemeData.greyDark500
                                  : AppThemeData.grey500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (controller
                              .cashOnDeliverySettingModel
                              .value
                              .isEnabled ==
                          true)
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color:
                                isDark
                                    ? AppThemeData.greyDark100
                                    : AppThemeData.grey50,
                            border: Border.all(
                              color:
                                  isDark
                                      ? AppThemeData.greyDark200
                                      : AppThemeData.grey200,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Visibility(
                                  visible:
                                      controller
                                          .cashOnDeliverySettingModel
                                          .value
                                          .isEnabled ==
                                      true,
                                  child: cardDecoration(
                                    controller,
                                    PaymentGateway.cod,
                                    isDark,
                                    "assets/images/ic_cash.png",
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (controller
                              .cashOnDeliverySettingModel
                              .value
                              .isEnabled ==
                          true)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            Text(
                              "Other Payment Options".tr,
                              textAlign: TextAlign.start,
                              style: AppThemeData.boldTextStyle(
                                fontSize: 15,
                                color:
                                    isDark
                                        ? AppThemeData.greyDark500
                                        : AppThemeData.grey500,
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      if (controller.paydunyaConfig.value.isEnabled)
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color:
                                isDark
                                    ? AppThemeData.greyDark100
                                    : AppThemeData.grey50,
                            border: Border.all(
                              color:
                                  isDark
                                      ? AppThemeData.greyDark200
                                      : AppThemeData.grey200,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                cardDecoration(
                                  controller,
                                  PaymentGateway.paydunya,
                                  isDark,
                                  "assets/images/ic_cash.png",
                                ),
                              ],
                            ),
                          ),
                        ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
                RoundedButtonFill(
                  title: "Continue".tr,
                  color: AppThemeData.primary300,
                  textColor: AppThemeData.grey900,
                  onPress: () async {
                    if (controller.selectedPaymentMethod.value.isEmpty) {
                      ShowToastDialog.showToast(
                        "Please select a payment method".tr,
                      );
                      return;
                    }

                    if (controller.currentOrder.value.id != null) {
                      controller.bottomSheetType.value = "driverDetails";
                    } else {
                      controller.bottomSheetType.value = "conformRide";
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget conformBottomSheet(
    BuildContext context,
    CabBookingController controller,
    bool isDark,
  ) {
    return Positioned.fill(
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) {
          return Obx(() {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppThemeData.grey700 : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15.0,
                  vertical: 10,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: AppThemeData.grey400,
                      ),
                      height: 4,
                      width: 33,
                    ),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: EdgeInsets.zero,
                        children: [
                          const SizedBox(height: 10),
                          Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color:
                                      isDark
                                          ? Colors.transparent
                                          : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Pickup Location
                                    InkWell(
                                      onTap: () async {
                                        if (Constant.selectedMapType == 'osm') {
                                          final result = await Get.to(
                                            () => MapPickerPage(),
                                          );
                                          if (result != null) {
                                            controller
                                                .sourceTextEditController
                                                .value
                                                .text = '';
                                            final firstPlace = result;
                                            final lat =
                                                firstPlace.coordinates.latitude;
                                            final lng =
                                                firstPlace
                                                    .coordinates
                                                    .longitude;
                                            final address = firstPlace.address;
                                            controller
                                                .sourceTextEditController
                                                .value
                                                .text = address.toString();
                                            controller.setDepartureMarker(
                                              lat,
                                              lng,
                                            );
                                          }
                                        } else {
                                          Get.to(LocationPickerScreen())!.then((
                                            value,
                                          ) async {
                                            if (value != null) {
                                              SelectedLocationModel
                                              selectedLocationModel = value;

                                              controller
                                                  .sourceTextEditController
                                                  .value
                                                  .text = Utils.formatAddress(
                                                selectedLocation:
                                                    selectedLocationModel,
                                              );
                                              controller.setDepartureMarker(
                                                selectedLocationModel
                                                    .latLng!
                                                    .latitude,
                                                selectedLocationModel
                                                    .latLng!
                                                    .longitude,
                                              );
                                            }
                                          });
                                        }
                                      },
                                      child: TextFieldWidget(
                                        controller:
                                            controller
                                                .sourceTextEditController
                                                .value,
                                        hintText: "Pickup Location".tr,
                                        enable: false,
                                        prefix: const Padding(
                                          padding: EdgeInsets.only(
                                            left: 10,
                                            right: 10,
                                          ),
                                          child: Icon(
                                            Icons.stop_circle_outlined,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    // Destination Location
                                    InkWell(
                                      onTap: () async {
                                        if (Constant.selectedMapType == 'osm') {
                                          final result = await Get.to(
                                            () => MapPickerPage(),
                                          );
                                          if (result != null) {
                                            controller
                                                .destinationTextEditController
                                                .value
                                                .text = '';
                                            final firstPlace = result;
                                            final lat =
                                                firstPlace.coordinates.latitude;
                                            final lng =
                                                firstPlace
                                                    .coordinates
                                                    .longitude;
                                            final address = firstPlace.address;
                                            controller
                                                .destinationTextEditController
                                                .value
                                                .text = address.toString();
                                            controller.setDestinationMarker(
                                              lat,
                                              lng,
                                            );
                                          }
                                        } else {
                                          Get.to(LocationPickerScreen())!.then((
                                            value,
                                          ) async {
                                            if (value != null) {
                                              SelectedLocationModel
                                              selectedLocationModel = value;

                                              controller
                                                  .destinationTextEditController
                                                  .value
                                                  .text = Utils.formatAddress(
                                                selectedLocation:
                                                    selectedLocationModel,
                                              );
                                              controller.setDestinationMarker(
                                                selectedLocationModel
                                                    .latLng!
                                                    .latitude,
                                                selectedLocationModel
                                                    .latLng!
                                                    .longitude,
                                              );
                                            }
                                          });
                                        }
                                      },
                                      child: TextFieldWidget(
                                        controller:
                                            controller
                                                .destinationTextEditController
                                                .value,
                                        // backgroundColor: AppThemeData.grey50,
                                        // borderColor: AppThemeData.grey50,
                                        hintText: "Destination Location".tr,
                                        enable: false,
                                        prefix: const Padding(
                                          padding: EdgeInsets.only(
                                            left: 10,
                                            right: 10,
                                          ),
                                          child: Icon(
                                            Icons.radio_button_checked,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                left: 10,
                                top: 33,
                                child: DottedBorder(
                                  options: CustomPathDottedBorderOptions(
                                    color: Colors.grey.shade400,
                                    strokeWidth: 2,
                                    dashPattern: [4, 4],
                                    customPath:
                                        (size) =>
                                            Path()
                                              ..moveTo(size.width / 2, 0)
                                              ..lineTo(
                                                size.width / 2,
                                                size.height,
                                              ),
                                  ),
                                  child: const SizedBox(width: 20, height: 40),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "Promo code".tr,
                                  style: AppThemeData.boldTextStyle(
                                    fontSize: 16,
                                    color:
                                        isDark
                                            ? AppThemeData.greyDark900
                                            : AppThemeData.grey900,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  Get.to(CabCouponCodeScreen())!.then((value) {
                                    if (value != null) {
                                      controller
                                          .couponCodeTextEditController
                                          .value
                                          .text = value.code ?? '';
                                      double couponAmount =
                                          Constant.calculateDiscount(
                                            amount:
                                                controller.subTotal.value
                                                    .toString(),
                                            offerModel: value,
                                          );
                                      if (couponAmount <
                                          controller.subTotal.value) {
                                        controller.selectedCouponModel.value =
                                            value;
                                        controller.calculateTotalAmount();
                                      } else {
                                        ShowToastDialog.showToast(
                                          "This offer not eligible for this booking"
                                              .tr,
                                        );
                                      }
                                    }
                                  });
                                },
                                child: Text(
                                  "View All".tr,
                                  style: AppThemeData.boldTextStyle(
                                    decoration: TextDecoration.underline,
                                    fontSize: 14,
                                    color:
                                        isDark
                                            ? AppThemeData.primary300
                                            : AppThemeData.primary300,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: Responsive.width(100, context),
                              height: Responsive.height(6, context),
                              color: AppThemeData.carRent50,
                              child: DottedBorder(
                                options: RectDottedBorderOptions(
                                  dashPattern: [10, 5],
                                  strokeWidth: 1,
                                  padding: EdgeInsets.all(0),
                                  color: AppThemeData.carRent400,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      SvgPicture.asset(
                                        "assets/icons/ic_coupon.svg",
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                          ),
                                          child: TextFormField(
                                            controller:
                                                controller
                                                    .couponCodeTextEditController
                                                    .value,
                                            style:
                                                AppThemeData.semiBoldTextStyle(
                                                  color:
                                                      AppThemeData
                                                          .parcelService500,
                                                  fontSize: 16,
                                                ),
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                              hintText: 'Write coupon Code'.tr,
                                              contentPadding: EdgeInsets.only(
                                                bottom: 10,
                                              ),
                                              hintStyle:
                                                  AppThemeData.semiBoldTextStyle(
                                                    color:
                                                        AppThemeData
                                                            .parcelService500,
                                                    fontSize: 16,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      RoundedButtonFill(
                                        title: "Redeem now".tr,
                                        width: 27,
                                        borderRadius: 10,
                                        fontSizes: 14,
                                        onPress: () async {
                                          if (controller
                                              .couponCodeTextEditController
                                              .value
                                              .text
                                              .trim()
                                              .isEmpty) {
                                            ShowToastDialog.showToast(
                                              "Please enter a coupon code".tr,
                                            );
                                            return;
                                          }

                                          List matchedCoupons =
                                              controller.cabCouponList
                                                  .where(
                                                    (element) =>
                                                        element.code!
                                                            .toLowerCase()
                                                            .trim() ==
                                                        controller
                                                            .couponCodeTextEditController
                                                            .value
                                                            .text
                                                            .toLowerCase()
                                                            .trim(),
                                                  )
                                                  .toList();

                                          if (matchedCoupons.isNotEmpty) {
                                            CouponModel couponModel =
                                                matchedCoupons.first;

                                            if (couponModel.expiresAt != null &&
                                                couponModel.expiresAt!
                                                    .toDate()
                                                    .isAfter(DateTime.now())) {
                                              double couponAmount =
                                                  Constant.calculateDiscount(
                                                    amount:
                                                        controller
                                                            .subTotal
                                                            .value
                                                            .toString(),
                                                    offerModel: couponModel,
                                                  );

                                              if (couponAmount <
                                                  controller.subTotal.value) {
                                                controller
                                                    .selectedCouponModel
                                                    .value = couponModel;
                                                controller.discount.value =
                                                    couponAmount;
                                                controller
                                                    .calculateTotalAmount();
                                                ShowToastDialog.showToast(
                                                  "Coupon applied successfully"
                                                      .tr,
                                                );
                                                controller.update();
                                              } else {
                                                ShowToastDialog.showToast(
                                                  "This offer not eligible for this booking"
                                                      .tr,
                                                );
                                              }
                                            } else {
                                              ShowToastDialog.showToast(
                                                "This coupon code has been expired"
                                                    .tr,
                                              );
                                            }
                                          } else {
                                            ShowToastDialog.showToast(
                                              "Invalid coupon code".tr,
                                            );
                                          }
                                        },
                                        color: AppThemeData.parcelService300,
                                        textColor: AppThemeData.grey50,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color:
                                  isDark
                                      ? AppThemeData.greyDark50
                                      : AppThemeData.grey50,
                              border: Border.all(
                                color:
                                    isDark
                                        ? AppThemeData.greyDark200
                                        : AppThemeData.grey200,
                              ),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Order Summary".tr,
                                  style: AppThemeData.boldTextStyle(
                                    fontSize: 14,
                                    color:
                                        isDark
                                            ? AppThemeData.greyDark500
                                            : AppThemeData.grey500,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Subtotal".tr,
                                        style: AppThemeData.mediumTextStyle(
                                          fontSize: 16,
                                          color:
                                              isDark
                                                  ? AppThemeData.greyDark800
                                                  : AppThemeData.grey800,
                                        ),
                                      ),
                                      Text(
                                        Constant.amountShow(
                                          amount:
                                              controller.subTotal.value
                                                  .toString(),
                                        ),
                                        style: AppThemeData.semiBoldTextStyle(
                                          fontSize: 16,
                                          color:
                                              isDark
                                                  ? AppThemeData.greyDark900
                                                  : AppThemeData.grey900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            "Discount".tr,
                                            style: AppThemeData.mediumTextStyle(
                                              fontSize: 16,
                                              color:
                                                  isDark
                                                      ? AppThemeData.greyDark900
                                                      : AppThemeData.grey900,
                                            ),
                                          ),
                                          SizedBox(width: 5),
                                          Text(
                                            controller
                                                        .selectedCouponModel
                                                        .value
                                                        .id ==
                                                    null
                                                ? ""
                                                : "(${controller.selectedCouponModel.value.code})",
                                            style: AppThemeData.mediumTextStyle(
                                              fontSize: 16,
                                              color: AppThemeData.primary300,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        Constant.amountShow(
                                          amount:
                                              controller.discount.value
                                                  .toString(),
                                        ),
                                        style: AppThemeData.semiBoldTextStyle(
                                          fontSize: 16,
                                          color: AppThemeData.danger300,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (Constant.platformFeeModel?.enable == true)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Platform fee".tr,
                                          style: AppThemeData.mediumTextStyle(
                                            fontSize: 16,
                                            color:
                                                isDark
                                                    ? AppThemeData.greyDark900
                                                    : AppThemeData.grey900,
                                          ),
                                        ),
                                        Text(
                                          Constant.amountShow(
                                            amount:
                                                Constant.platformFeeModel?.fee
                                                    .toString(),
                                          ),
                                          style: AppThemeData.semiBoldTextStyle(
                                            fontSize: 16,
                                            color:
                                                isDark
                                                    ? AppThemeData.greyDark900
                                                    : AppThemeData.grey900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                InkWell(
                                  onTap: () {
                                    showBillBifurcationDialog(
                                      context,
                                      isDark,
                                      controller,
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Tax amount".tr,
                                          style: AppThemeData.mediumTextStyle(
                                            fontSize: 16,
                                            color:
                                                isDark
                                                    ? AppThemeData.greyDark900
                                                    : AppThemeData.grey900,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                        Text(
                                          Constant.amountShow(
                                            amount:
                                                controller.taxAmount.value
                                                    .toString(),
                                          ),
                                          style: AppThemeData.semiBoldTextStyle(
                                            fontSize: 16,
                                            color:
                                                isDark
                                                    ? AppThemeData.greyDark900
                                                    : AppThemeData.grey900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Tax List
                                const Divider(),

                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Order Total".tr,
                                        style: AppThemeData.mediumTextStyle(
                                          fontSize: 16,
                                          color:
                                              isDark
                                                  ? AppThemeData.greyDark900
                                                  : AppThemeData.grey900,
                                        ),
                                      ),
                                      Text(
                                        Constant.amountShow(
                                          amount:
                                              controller.totalAmount.value
                                                  .toString(),
                                        ),
                                        style: AppThemeData.semiBoldTextStyle(
                                          fontSize: 16,
                                          color:
                                              isDark
                                                  ? AppThemeData.greyDark900
                                                  : AppThemeData.grey900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color:
                                  isDark
                                      ? AppThemeData.greyDark50
                                      : AppThemeData.grey50,
                              border: Border.all(
                                color:
                                    isDark
                                        ? AppThemeData.greyDark200
                                        : AppThemeData.grey200,
                              ),
                            ),
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                controller.selectedPaymentMethod.value == ''
                                    ? cardDecorationScreen(
                                      controller,
                                      PaymentGateway.cod,
                                      isDark,
                                      "",
                                    )
                                    : controller.selectedPaymentMethod.value ==
                                        PaymentGateway.wallet.name
                                    ? cardDecorationScreen(
                                      controller,
                                      PaymentGateway.cod,
                                      isDark,
                                      "assets/images/ic_cash.png",
                                    )
                                    : controller.selectedPaymentMethod.value ==
                                        PaymentGateway.cod.name
                                    ? cardDecorationScreen(
                                      controller,
                                      PaymentGateway.cod,
                                      isDark,
                                      "assets/images/ic_cash.png",
                                    )
                                    : cardDecorationScreen(
                                      controller,
                                      PaymentGateway.paydunya,
                                      isDark,
                                      "assets/images/paydunya.png",
                                    ),
                                SizedBox(width: 22),
                                Text(
                                  controller.selectedPaymentMethod.value.tr,
                                  textAlign: TextAlign.start,
                                  style: AppThemeData.boldTextStyle(
                                    fontSize: 16,
                                    color:
                                        isDark
                                            ? AppThemeData.greyDark900
                                            : AppThemeData.grey900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    RoundedButtonFill(
                      title: "Confirm Booking".tr,
                      onPress: () async {
                        controller.placeOrder();
                      },
                      color: AppThemeData.primary300,
                      textColor: AppThemeData.grey900,
                    ),
                  ],
                ),
              ),
            );
          });
        },
      ),
    );
  }

  Widget waitingDialog(
    BuildContext context,
    CabBookingController controller,
    bool isDark,
  ) {
    return Positioned.fill(
      child: DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.4,
        maxChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          return Obx(() {
            final hasTimedOut = controller.driverSearchTimedOut.value;
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15.0,
                  vertical: 10,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: AppThemeData.grey400,
                      ),
                      height: 4,
                      width: 33,
                    ),
                    SizedBox(height: hasTimedOut ? 26 : 30),
                    Text(
                      hasTimedOut
                          ? "Aucun chauffeur disponible pour le moment. Veuillez réessayer dans quelques minutes."
                              .tr
                          : "Waiting for driver....".tr,
                      textAlign: TextAlign.center,
                      style: AppThemeData.mediumTextStyle(
                        fontSize: hasTimedOut ? 17 : 18,
                        color: AppThemeData.grey900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (hasTimedOut)
                      Icon(
                        Icons.search_off_rounded,
                        size: 78,
                        color: AppThemeData.primary300,
                      )
                    else
                      Image.asset('assets/loader.gif', width: 250),
                    const SizedBox(height: 12),
                    if (hasTimedOut) ...[
                      RoundedButtonFill(
                        title: "Réessayer".tr,
                        color: AppThemeData.primary300,
                        textColor: AppThemeData.surface,
                        onPress: () async {
                          try {
                            await controller.retryDriverSearch();
                          } catch (e) {
                            ShowToastDialog.showToast(
                              "Something went wrong. Please try again.".tr,
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      RoundedButtonBorder(
                        title: "Modifier l’adresse".tr,
                        color: AppThemeData.grey900,
                        onPress: () => controller.modifySearchAddress(),
                      ),
                      const SizedBox(height: 10),
                    ],
                    RoundedButtonFill(
                      title: hasTimedOut ? "Annuler".tr : "Cancel Ride".tr,
                      color: AppThemeData.danger300,
                      textColor: AppThemeData.surface,
                      onPress: () async {
                        try {
                          await controller.cancelCurrentDriverSearch();
                          final cabDashboardController =
                              Get.isRegistered<CabDashboardController>()
                                  ? Get.find<CabDashboardController>()
                                  : Get.put(CabDashboardController());
                          cabDashboardController.selectedIndex.value = 0;
                        } catch (e) {
                          ShowToastDialog.showToast("Failed to cancel ride".tr);
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          });
        },
      ),
    );
  }

  Widget driverDialog(
    BuildContext context,
    CabBookingController controller,
    bool isDark,
  ) {
    return Positioned.fill(
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppThemeData.grey700 : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 15.0,
                vertical: 10,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: AppThemeData.grey400,
                    ),
                    height: 4,
                    width: 33,
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: EdgeInsets.zero,
                      children: [
                        const SizedBox(height: 10),
                        Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color:
                                    isDark ? Colors.transparent : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () async {
                                      // if (Constant.selectedMapType == 'osm') {
                                      //   final result = await Get.to(() => MapPickerPage());
                                      //   if (result != null) {
                                      //     controller.sourceTextEditController.value.text = '';
                                      //     final firstPlace = result;
                                      //     final lat = firstPlace.coordinates.latitude;
                                      //     final lng = firstPlace.coordinates.longitude;
                                      //     final address = firstPlace.address;
                                      //     controller.sourceTextEditController.value.text = address.toString();
                                      //     controller.setDepartureMarker(lat, lng);
                                      //   }
                                      // } else {
                                      //   Get.to(LocationPickerScreen())!.then((value) async {
                                      //     if (value != null) {
                                      //       SelectedLocationModel selectedLocationModel = value;
                                      //
                                      //       controller.sourceTextEditController.value.text = Utils.formatAddress(selectedLocation: selectedLocationModel);
                                      //       controller.setDepartureMarker(selectedLocationModel.latLng!.latitude, selectedLocationModel.latLng!.longitude);
                                      //     }
                                      //   });
                                      // }
                                    },
                                    child: TextFieldWidget(
                                      controller:
                                          controller
                                              .sourceTextEditController
                                              .value,
                                      hintText: "Pickup Location".tr,
                                      enable: false,
                                      readOnly: true,
                                      prefix: const Padding(
                                        padding: EdgeInsets.only(
                                          left: 10,
                                          right: 10,
                                        ),
                                        child: Icon(
                                          Icons.stop_circle_outlined,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  InkWell(
                                    onTap: () async {
                                      // if (Constant.selectedMapType == 'osm') {
                                      //   final result = await Get.to(() => MapPickerPage());
                                      //   if (result != null) {
                                      //     controller.destinationTextEditController.value.text = '';
                                      //     final firstPlace = result;
                                      //     final lat = firstPlace.coordinates.latitude;
                                      //     final lng = firstPlace.coordinates.longitude;
                                      //     final address = firstPlace.address;
                                      //     controller.destinationTextEditController.value.text = address.toString();
                                      //     controller.setDestinationMarker(lat, lng);
                                      //   }
                                      // } else {
                                      //   Get.to(LocationPickerScreen())!.then((value) async {
                                      //     if (value != null) {
                                      //       SelectedLocationModel selectedLocationModel = value;
                                      //
                                      //       controller.destinationTextEditController.value.text = Utils.formatAddress(selectedLocation: selectedLocationModel);
                                      //       controller.setDestinationMarker(selectedLocationModel.latLng!.latitude, selectedLocationModel.latLng!.longitude);
                                      //     }
                                      //   });
                                      // }
                                    },
                                    child: TextFieldWidget(
                                      controller:
                                          controller
                                              .destinationTextEditController
                                              .value,
                                      // backgroundColor: AppThemeData.grey50,
                                      // borderColor: AppThemeData.grey50,
                                      hintText: "Destination Location".tr,
                                      enable: false,
                                      readOnly: true,
                                      prefix: const Padding(
                                        padding: EdgeInsets.only(
                                          left: 10,
                                          right: 10,
                                        ),
                                        child: Icon(
                                          Icons.radio_button_checked,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              left: 10,
                              top: 33,
                              child: DottedBorder(
                                options: CustomPathDottedBorderOptions(
                                  color: Colors.grey.shade400,
                                  strokeWidth: 2,
                                  dashPattern: [4, 4],
                                  customPath:
                                      (size) =>
                                          Path()
                                            ..moveTo(size.width / 2, 0)
                                            ..lineTo(
                                              size.width / 2,
                                              size.height,
                                            ),
                                ),
                                child: const SizedBox(width: 20, height: 40),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Constant.isEnableOTPTripStart == true
                            ? Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Otp :".tr,
                                    style: AppThemeData.mediumTextStyle(
                                      fontSize: 16,
                                      color:
                                          isDark
                                              ? AppThemeData.greyDark800
                                              : AppThemeData.grey800,
                                    ),
                                  ),
                                  Text(
                                    controller.currentOrder.value.otpCode ?? '',
                                    style: AppThemeData.semiBoldTextStyle(
                                      fontSize: 16,
                                      color:
                                          isDark
                                              ? AppThemeData.greyDark900
                                              : AppThemeData.grey900,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : SizedBox.shrink(),
                        if (Constant.isEnableOTPTripStart == true)
                          SizedBox(height: 14),
                        controller.currentOrder.value.driver != null
                            ? Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadiusGeometry.circular(
                                    10,
                                  ),
                                  child: NetworkImageWidget(
                                    imageUrl:
                                        controller
                                            .currentOrder
                                            .value
                                            .driver
                                            ?.profilePictureURL ??
                                        '',
                                    height: 70,
                                    width: 70,
                                    borderRadius: 35,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        controller.currentOrder.value.driver
                                                ?.fullName() ??
                                            '',
                                        style: AppThemeData.boldTextStyle(
                                          color:
                                              isDark
                                                  ? AppThemeData.greyDark900
                                                  : AppThemeData.grey900,
                                          fontSize: 18,
                                        ),
                                      ),
                                      Builder(
                                        builder: (_) {
                                          final sid =
                                              controller
                                                  .currentOrder
                                                  .value
                                                  .sectionId ??
                                              '';
                                          final vehicle =
                                              controller
                                                  .currentOrder
                                                  .value
                                                  .driver
                                                  ?.vehicleDetails?[sid];
                                          if (vehicle == null)
                                            return const SizedBox.shrink();
                                          final vType =
                                              vehicle['vehicleType']
                                                  ?.toString() ??
                                              '';
                                          final brand =
                                              vehicle['carBrand']?.toString() ??
                                              '';
                                          final carModel =
                                              vehicle['carModel']?.toString() ??
                                              '';
                                          final plate =
                                              vehicle['carPlateNumber']
                                                  ?.toString() ??
                                              '';
                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (vType.isNotEmpty)
                                                Text(
                                                  vType,
                                                  style: TextStyle(
                                                    fontFamily:
                                                        AppThemeData.medium,
                                                    color:
                                                        isDark
                                                            ? AppThemeData
                                                                .greyDark700
                                                            : AppThemeData
                                                                .grey700,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              if (brand.isNotEmpty ||
                                                  carModel.isNotEmpty)
                                                Text(
                                                  "$brand $carModel".trim(),
                                                  style: TextStyle(
                                                    fontFamily:
                                                        AppThemeData.medium,
                                                    color:
                                                        isDark
                                                            ? AppThemeData
                                                                .greyDark700
                                                            : AppThemeData
                                                                .grey700,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              if (plate.isNotEmpty)
                                                Text(
                                                  plate.toUpperCase(),
                                                  style:
                                                      AppThemeData.boldTextStyle(
                                                        color:
                                                            isDark
                                                                ? AppThemeData
                                                                    .greyDark700
                                                                : AppThemeData
                                                                    .grey700,
                                                        fontSize: 16,
                                                      ),
                                                ),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    RoundedButtonBorder(
                                      title: controller
                                          .driverModel
                                          .value
                                          .averageRating
                                          .toStringAsFixed(1),
                                      width: 20,
                                      height: 3.5,
                                      radius: 10,
                                      isRight: false,
                                      isCenter: true,
                                      textColor: AppThemeData.warning400,
                                      borderColor: AppThemeData.warning400,
                                      color: AppThemeData.warning50,
                                      icon: SvgPicture.asset(
                                        "assets/icons/ic_start.svg",
                                      ),
                                      onPress: () {},
                                    ),
                                    SizedBox(height: 10),
                                    Row(
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            Constant.makePhoneCall(
                                              controller
                                                  .currentOrder
                                                  .value
                                                  .driver!
                                                  .phoneNumber
                                                  .toString(),
                                            );
                                          },
                                          child: Container(
                                            width: 38,
                                            height: 38,
                                            decoration: ShapeDecoration(
                                              shape: RoundedRectangleBorder(
                                                side: BorderSide(
                                                  width: 1,
                                                  color:
                                                      isDark
                                                          ? AppThemeData.grey200
                                                          : AppThemeData
                                                              .grey200,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(120),
                                              ),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              child: SvgPicture.asset(
                                                "assets/icons/ic_phone_call.svg",
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        InkWell(
                                          onTap: () async {
                                            ShowToastDialog.showLoader(
                                              "Please wait...".tr,
                                            );

                                            UserModel? customer =
                                                await FireStoreUtils.getUserProfile(
                                                  controller
                                                          .currentOrder
                                                          .value
                                                          .authorID ??
                                                      '',
                                                );
                                            UserModel? driverUser =
                                                await FireStoreUtils.getUserProfile(
                                                  controller
                                                          .currentOrder
                                                          .value
                                                          .driverId ??
                                                      '',
                                                );

                                            ShowToastDialog.closeLoader();

                                            Get.to(
                                              const ChatScreen(),
                                              arguments: {
                                                "senderName":
                                                    customer?.fullName(),
                                                "receivedName":
                                                    driverUser?.fullName(),
                                                "orderId":
                                                    controller
                                                        .currentOrder
                                                        .value
                                                        .id,
                                                "receivedId": driverUser?.id,
                                                "senderId": customer?.id,
                                                "senderProfileUrl":
                                                    customer?.profilePictureURL,
                                                "receivedProfileUrl":
                                                    driverUser
                                                        ?.profilePictureURL,
                                                "token": driverUser?.fcmToken,
                                                "chatType":
                                                    Constant.userRoleDriver,
                                              },
                                            );
                                          },
                                          child: Container(
                                            width: 42,
                                            height: 42,
                                            decoration: ShapeDecoration(
                                              shape: RoundedRectangleBorder(
                                                side: BorderSide(
                                                  width: 1,
                                                  color:
                                                      isDark
                                                          ? AppThemeData.grey200
                                                          : AppThemeData
                                                              .grey200,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(120),
                                              ),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              child: SvgPicture.asset(
                                                "assets/icons/ic_wechat.svg",
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            )
                            : SizedBox(),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color:
                                isDark
                                    ? AppThemeData.greyDark50
                                    : AppThemeData.grey50,
                            border: Border.all(
                              color:
                                  isDark
                                      ? AppThemeData.greyDark200
                                      : AppThemeData.grey200,
                            ),
                          ),
                          padding: const EdgeInsets.all(10),
                          child: InkWell(
                            onTap: () {
                              controller.bottomSheetType.value = 'payment';
                            },
                            child: Row(
                              children: [
                                controller.selectedPaymentMethod.value ==
                                        PaymentGateway.wallet.name
                                    ? cardDecorationScreen(
                                      controller,
                                      PaymentGateway.cod,
                                      isDark,
                                      "assets/images/ic_cash.png",
                                    )
                                    : controller.selectedPaymentMethod.value ==
                                        PaymentGateway.cod.name
                                    ? cardDecorationScreen(
                                      controller,
                                      PaymentGateway.cod,
                                      isDark,
                                      "assets/images/ic_cash.png",
                                    )
                                    : cardDecorationScreen(
                                      controller,
                                      PaymentGateway.paydunya,
                                      isDark,
                                      "assets/images/paydunya.png",
                                    ),
                                SizedBox(width: 22),
                                Expanded(
                                  child: Text(
                                    controller.selectedPaymentMethod.value.tr,
                                    textAlign: TextAlign.start,
                                    style: AppThemeData.boldTextStyle(
                                      fontSize: 16,
                                      color:
                                          isDark
                                              ? AppThemeData.greyDark900
                                              : AppThemeData.grey900,
                                    ),
                                  ),
                                ),
                                Text(
                                  "Change".tr,
                                  textAlign: TextAlign.start,
                                  style: AppThemeData.boldTextStyle(
                                    fontSize: 16,
                                    color:
                                        isDark
                                            ? AppThemeData.primary300
                                            : AppThemeData.primary300,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color:
                                isDark
                                    ? AppThemeData.greyDark50
                                    : AppThemeData.grey50,
                            border: Border.all(
                              color:
                                  isDark
                                      ? AppThemeData.greyDark200
                                      : AppThemeData.grey200,
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Order Summary".tr,
                                style: AppThemeData.boldTextStyle(
                                  fontSize: 14,
                                  color:
                                      isDark
                                          ? AppThemeData.greyDark500
                                          : AppThemeData.grey500,
                                ),
                              ),
                              const SizedBox(height: 8),

                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Subtotal".tr,
                                      style: AppThemeData.mediumTextStyle(
                                        fontSize: 16,
                                        color:
                                            isDark
                                                ? AppThemeData.greyDark800
                                                : AppThemeData.grey800,
                                      ),
                                    ),
                                    Text(
                                      Constant.amountShow(
                                        amount:
                                            controller.subTotal.value
                                                .toString(),
                                      ),
                                      style: AppThemeData.semiBoldTextStyle(
                                        fontSize: 16,
                                        color:
                                            isDark
                                                ? AppThemeData.greyDark900
                                                : AppThemeData.grey900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Discount".tr,
                                      style: AppThemeData.mediumTextStyle(
                                        fontSize: 16,
                                        color:
                                            isDark
                                                ? AppThemeData.greyDark900
                                                : AppThemeData.grey900,
                                      ),
                                    ),
                                    Text(
                                      Constant.amountShow(
                                        amount:
                                            controller.discount.value
                                                .toString(),
                                      ),
                                      style: AppThemeData.semiBoldTextStyle(
                                        fontSize: 16,
                                        color: AppThemeData.danger300,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              if (Constant.platformFeeModel?.enable == true)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Platform fee".tr,
                                        style: AppThemeData.mediumTextStyle(
                                          fontSize: 16,
                                          color:
                                              isDark
                                                  ? AppThemeData.greyDark900
                                                  : AppThemeData.grey900,
                                        ),
                                      ),
                                      Text(
                                        Constant.amountShow(
                                          amount:
                                              Constant.platformFeeModel?.fee
                                                  .toString(),
                                        ),
                                        style: AppThemeData.semiBoldTextStyle(
                                          fontSize: 16,
                                          color:
                                              isDark
                                                  ? AppThemeData.greyDark900
                                                  : AppThemeData.grey900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              InkWell(
                                onTap: () {
                                  showBillBifurcationDialog(
                                    context,
                                    isDark,
                                    controller,
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Tax amount".tr,
                                        style: AppThemeData.mediumTextStyle(
                                          fontSize: 16,
                                          color:
                                              isDark
                                                  ? AppThemeData.greyDark900
                                                  : AppThemeData.grey900,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                      Text(
                                        Constant.amountShow(
                                          amount:
                                              controller.taxAmount.value
                                                  .toString(),
                                        ),
                                        style: AppThemeData.semiBoldTextStyle(
                                          fontSize: 16,
                                          color:
                                              isDark
                                                  ? AppThemeData.greyDark900
                                                  : AppThemeData.grey900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Divider(),

                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Order Total".tr,
                                      style: AppThemeData.mediumTextStyle(
                                        fontSize: 16,
                                        color:
                                            isDark
                                                ? AppThemeData.greyDark900
                                                : AppThemeData.grey900,
                                      ),
                                    ),
                                    Text(
                                      Constant.amountShow(
                                        amount:
                                            controller.totalAmount.value
                                                .toString(),
                                      ),
                                      style: AppThemeData.semiBoldTextStyle(
                                        fontSize: 16,
                                        color:
                                            isDark
                                                ? AppThemeData.greyDark900
                                                : AppThemeData.grey900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                  Obx(() {
                    if (controller.currentOrder.value.status ==
                        Constant.orderInTransit) {
                      return Column(
                        children: [
                          RoundedButtonFill(
                            title: "SOS".tr,
                            color: Colors.red.withOpacity(0.50),
                            textColor: AppThemeData.grey50,
                            isCenter: true,
                            icon: const Icon(Icons.call, color: Colors.white),
                            onPress: () async {
                              ShowToastDialog.showLoader("Please wait...".tr);

                              LocationData location =
                                  await controller.currentLocation.value
                                      .getLocation();

                              await FireStoreUtils.getSOS(
                                controller.currentOrder.value.id ?? '',
                              ).then((value) async {
                                if (value == false) {
                                  await FireStoreUtils.setSos(
                                    controller.currentOrder.value.id ?? '',
                                    UserLocation(
                                      latitude: location.latitude!,
                                      longitude: location.longitude!,
                                    ),
                                  ).then((_) {
                                    ShowToastDialog.closeLoader();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Your SOS request has been submitted to admin"
                                              .tr,
                                        ),
                                        backgroundColor: Colors.green,
                                        duration: Duration(seconds: 3),
                                      ),
                                    );
                                  });
                                } else {
                                  ShowToastDialog.closeLoader();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Your SOS request is already submitted"
                                            .tr,
                                      ),
                                      backgroundColor: Colors.red,
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                        ],
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  }),
                  Obx(() {
                    if (controller.currentOrder.value.status ==
                            Constant.orderInTransit &&
                        controller.currentOrder.value.paymentStatus == false) {
                      return RoundedButtonFill(
                        title: "Pay Now".tr,
                        onPress: () async {
                          if (controller.selectedPaymentMethod.value ==
                              PaymentGateway.cod.name) {
                            controller.completeOrder();
                          } else if (controller.selectedPaymentMethod.value ==
                              PaymentGateway.paydunya.name) {
                            controller.initiatePaydunyaPayment(context);
                          } else {
                            ShowToastDialog.showToast(
                              "Please select payment method".tr,
                            );
                          }
                        },
                        color: AppThemeData.primary300,
                        textColor: AppThemeData.grey900,
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Padding cardDecorationScreen(
    CabBookingController controller,
    PaymentGateway value,
    isDark,
    String image,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Container(
        width: 40,
        height: 40,
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            side: const BorderSide(width: 1, color: Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(value.name == "payFast" ? 0 : 8.0),
          child:
              image == ''
                  ? Container(
                    color: isDark ? AppThemeData.grey800 : AppThemeData.grey100,
                  )
                  : Image.asset(image),
        ),
      ),
    );
  }

  Obx cardDecoration(
    CabBookingController controller,
    PaymentGateway value,
    isDark,
    String image,
  ) {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Column(
          children: [
            InkWell(
              onTap: () {
                controller.selectedPaymentMethod.value = value.name;
              },
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: ShapeDecoration(
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(
                          width: 1,
                          color: Color(0xFFE5E7EB),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(
                        value.name == "payFast" ? 0 : 8.0,
                      ),
                      child: Image.asset(image),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      value == PaymentGateway.cod
                          ? 'Paiement à la livraison (Wave / Orange Money / Espèces)'
                              .tr
                          : value.name.capitalizeString(),
                      textAlign: TextAlign.start,
                      style: AppThemeData.semiBoldTextStyle(
                        fontSize: 16,
                        color:
                            isDark ? AppThemeData.grey50 : AppThemeData.grey900,
                      ),
                    ),
                  ),
                  const Expanded(child: SizedBox()),
                  Radio(
                    value: value.name,
                    groupValue: controller.selectedPaymentMethod.value,
                    activeColor:
                        isDark
                            ? AppThemeData.primary300
                            : AppThemeData.primary300,
                    onChanged: (value) {
                      controller.selectedPaymentMethod.value = value.toString();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showBillBifurcationDialog(
    BuildContext context,
    bool isDark,
    CabBookingController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: isDark ? AppThemeData.grey900 : AppThemeData.grey50,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 10,
          ), // 🔥 KEY FIX
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: SizedBox(
            width: Responsive.width(100, context), // ✅ 90% width
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 10),
                  Text(
                    "Tax Details".tr,
                    style: TextStyle(
                      fontFamily: AppThemeData.medium,
                      fontSize: 18,
                      color:
                          isDark ? AppThemeData.grey50 : AppThemeData.grey900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  sectionDivider(isDark),
                  const SizedBox(height: 5),
                  amountRow(
                    title: "Tax on Order Total".tr,
                    amount: Constant.amountShow(
                      amount: controller.orderTaxAmount.value.toString(),
                    ),
                    isDark: isDark,
                  ),
                  sectionDivider(isDark),
                  amountRow(
                    title: "Tax on Platform Fee".tr,
                    amount: Constant.amountShow(
                      amount: controller.platformTaxAmount.value.toString(),
                    ),
                    isDark: isDark,
                  ),
                  sectionDivider(isDark),
                  amountRow(
                    title: "Total Tax Amount".tr,
                    amount: Constant.amountShow(
                      amount: controller.taxAmount.value.toString(),
                    ),
                    amountColor: AppThemeData.primary300,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Close".tr),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget amountRow({
    required String title,
    required String amount,
    required bool isDark,
    Color? textColour,
    Color? amountColor,
    bool? underline,
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title.tr,
            style: TextStyle(
              fontFamily: AppThemeData.regular,
              color:
                  textColour ??
                  (isDark ? AppThemeData.grey300 : AppThemeData.grey600),
              fontSize: 16,
              decoration:
                  underline == true
                      ? TextDecoration.underline
                      : TextDecoration.none,
            ),
          ),
        ),
        trailing ??
            Text(
              amount,
              style: TextStyle(
                fontFamily: AppThemeData.regular,
                color:
                    amountColor ??
                    (isDark ? AppThemeData.grey50 : AppThemeData.grey900),
                fontSize: 16,
              ),
            ),
      ],
    );
  }

  Widget sectionDivider(bool isDark) {
    return Column(
      children: [
        const SizedBox(height: 10),
        MySeparator(
          color: isDark ? AppThemeData.grey700 : AppThemeData.grey200,
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

enum PaymentGateway { cod, wallet, paydunya }
