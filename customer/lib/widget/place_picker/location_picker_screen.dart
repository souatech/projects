import 'package:customer/constant/constant.dart';
import 'package:customer/controllers/theme_controller.dart';
import 'package:customer/models/user_model.dart';
import 'package:customer/screen_ui/location_enable_screens/enter_manually_location.dart';
import 'package:customer/themes/app_them_data.dart';
import 'package:customer/themes/round_button_fill.dart';
import 'package:customer/utils/utils.dart';
import 'package:customer/widget/place_picker/location_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_places_hoc081098/flutter_google_places_hoc081098.dart';
import 'package:flutter_google_places_hoc081098/google_maps_webservice_places.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

const Color _pickerBg = Color(0xFFF8F9FB);
const Color _pickerAccent = Color(0xFFFF4B12);
const Color _pickerInk = Color(0xFF111827);
const Color _pickerMuted = Color(0xFF6B7280);

class LocationPickerScreen extends StatelessWidget {
  const LocationPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDark.value;
    return GetX<LocationController>(
      init: LocationController(),
      builder: (controller) {
        final savedAddresses = Constant.userModel?.shippingAddress ?? [];
        return Scaffold(
          backgroundColor: isDark ? AppThemeData.grey900 : _pickerBg,
          body: SafeArea(
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: _PickerHeader(isDark: isDark),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 26, 24, 0),
                    child: _RouteSelectorCard(
                      isDark: isDark,
                      controller: controller,
                      onSearch: () => _openSearch(context, controller),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: _ActionRow(
                      isDark: isDark,
                      onCurrentLocation: controller.useCurrentLocation,
                      onSearch: () => _openSearch(context, controller),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _SavedAddressSection(
                    title: "Dernières destinations",
                    actionText: savedAddresses.isEmpty ? '' : "Voir tout",
                    icon: Icons.schedule_rounded,
                    isDark: isDark,
                    addresses: savedAddresses.take(3).toList(),
                    emptyText: "Aucune destination récente",
                    onTap: controller.selectSavedAddress,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _SavedAddressSection(
                    title: "Lieux favoris",
                    actionText: "Ajouter",
                    icon: Icons.favorite_border_rounded,
                    isDark: isDark,
                    addresses: savedAddresses,
                    emptyText: "Ajoutez vos adresses favorites",
                    onTap: controller.selectSavedAddress,
                    onAction: () => _openAddressForm(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      10,
                      24,
                      24 + MediaQuery.of(context).padding.bottom,
                    ),
                    child: _AddFavoriteCard(isDark: isDark),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
              child: RoundedButtonFill(
                title: "Confirmer cette adresse".tr,
                height: 5.5,
                color: _pickerAccent,
                textColor: AppThemeData.grey50,
                onPress: controller.confirmLocation,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openSearch(
    BuildContext context,
    LocationController controller,
  ) async {
    // ignore: avoid_print
    print("[ADDRESS_SEARCH] query=places_autocomplete");
    final countryCode = Utils.activeCountryCode();
    final currentPosition = controller.selectedLocation.value;
    final fallbackPosition = Utils.lastKnownPosition;
    final Prediction? prediction = await PlacesAutocomplete.show(
      context: context,
      apiKey: Constant.mapAPIKey,
      mode: Mode.overlay,
      language: "fr",
      debounce: const Duration(milliseconds: 500),
      radius: 50000,
      location:
          currentPosition != null
              ? Location(
                lat: currentPosition.latitude,
                lng: currentPosition.longitude,
              )
              : fallbackPosition != null
              ? Location(
                lat: fallbackPosition.latitude,
                lng: fallbackPosition.longitude,
              )
              : null,
      components:
          countryCode == null
              ? null
              : [Component(Component.country, countryCode)],
    );
    if (prediction == null || prediction.placeId == null) {
      return;
    }
    final places = GoogleMapsPlaces(apiKey: Constant.mapAPIKey);
    final detail = await places.getDetailsByPlaceId(prediction.placeId!);
    if (detail.result.geometry == null) {
      return;
    }
    final lat = detail.result.geometry!.location.lat;
    final lng = detail.result.geometry!.location.lng;
    final position = LatLng(lat, lng);
    final fullAddress =
        detail.result.formattedAddress ?? prediction.description ?? '';
    final shortAddress = Utils.shortAddressFromText(
      fullAddress,
      fallback: "Choisir une adresse".tr,
    );
    for (final component in detail.result.addressComponents) {
      if (component.types.contains(Component.country)) {
        Utils.detectedCountryCode =
            component.shortName.trim().isNotEmpty
                ? component.shortName
                : Utils.detectedCountryCode;
      }
      if (component.types.contains(Component.locality)) {
        Utils.detectedCity =
            component.longName.trim().isNotEmpty
                ? component.longName
                : Utils.detectedCity;
      }
    }
    // ignore: avoid_print
    print(
      "[ADDRESS_RESULT] full=$fullAddress short=$shortAddress lat=$lat lng=$lng",
    );
    controller.placeId.value = prediction.placeId;
    controller.selectedLocation.value = position;
    controller.searchController.text = shortAddress;
    await controller.getAddressFromLatLng(position);
  }
}

class _PickerHeader extends StatelessWidget {
  final bool isDark;

  const _PickerHeader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleButton(
          icon: Icons.arrow_back_rounded,
          isDark: isDark,
          onTap: () => Get.back(),
        ),
        Expanded(
          child: Text(
            "Nouvelle adresse".tr,
            textAlign: TextAlign.center,
            style: AppThemeData.boldTextStyle(
              fontSize: 23,
              color: isDark ? Colors.white : _pickerInk,
            ),
          ),
        ),
        _CircleButton(
          icon: Icons.my_location_rounded,
          isDark: isDark,
          onTap: () {
            final controller = Get.find<LocationController>();
            controller.useCurrentLocation();
          },
        ),
      ],
    );
  }
}

class _RouteSelectorCard extends StatelessWidget {
  final bool isDark;
  final LocationController controller;
  final VoidCallback onSearch;

  const _RouteSelectorCard({
    required this.isDark,
    required this.controller,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final selectedAddress = Utils.shortAddressFromText(
      controller.address.value,
      fallback: "Choisir une adresse".tr,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 18, 20),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.grey800 : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? AppThemeData.grey700 : const Color(0xFFE8EAEE),
        ),
        boxShadow: [_softShadow],
      ),
      child: Row(
        children: [
          Column(
            children: [
              const Icon(
                Icons.radio_button_checked_rounded,
                color: _pickerAccent,
                size: 25,
              ),
              Container(
                width: 2,
                height: 46,
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: AppThemeData.grey400,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                width: 19,
                height: 19,
                decoration: BoxDecoration(
                  color: _pickerAccent,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: [
                _AddressLine(
                  eyebrow: "Départ",
                  title: "Ma position",
                  subtitle: selectedAddress,
                  isDark: isDark,
                  onTap: onSearch,
                ),
                Divider(
                  height: 28,
                  color:
                      isDark ? AppThemeData.grey700 : const Color(0xFFE8EAEE),
                ),
                _AddressLine(
                  eyebrow: "Arrivée",
                  title: "Où voulez-vous aller ?",
                  subtitle: selectedAddress,
                  isDark: isDark,
                  onTap: onSearch,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? AppThemeData.grey700 : const Color(0xFFF1F2F4),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.swap_vert_rounded, color: _pickerInk),
          ),
        ],
      ),
    );
  }
}

class _AddressLine extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;

  const _AddressLine({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow.tr,
              style: AppThemeData.mediumTextStyle(
                fontSize: 14,
                color: isDark ? AppThemeData.grey300 : _pickerMuted,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle.isEmpty ? title.tr : subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppThemeData.boldTextStyle(
                fontSize: 19,
                color: isDark ? Colors.white : _pickerInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final bool isDark;
  final VoidCallback onCurrentLocation;
  final VoidCallback onSearch;

  const _ActionRow({
    required this.isDark,
    required this.onCurrentLocation,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PillAction(
            icon: Icons.search_rounded,
            label: "Rechercher",
            isDark: isDark,
            onTap: onSearch,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PillAction(
            icon: Icons.my_location_rounded,
            label: "Ma position",
            isDark: isDark,
            onTap: onCurrentLocation,
          ),
        ),
      ],
    );
  }
}

class _PillAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _PillAction({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isDark ? AppThemeData.grey800 : Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [_microShadow],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: _pickerAccent, size: 22),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppThemeData.semiBoldTextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : _pickerInk,
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

class _SavedAddressSection extends StatelessWidget {
  final String title;
  final String actionText;
  final IconData icon;
  final bool isDark;
  final List<ShippingAddress> addresses;
  final String emptyText;
  final ValueChanged<ShippingAddress> onTap;
  final VoidCallback? onAction;

  const _SavedAddressSection({
    required this.title,
    required this.actionText,
    required this.icon,
    required this.isDark,
    required this.addresses,
    required this.emptyText,
    required this.onTap,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _pickerAccent, size: 25),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title.tr,
                  style: AppThemeData.boldTextStyle(
                    fontSize: 21,
                    color: isDark ? Colors.white : _pickerInk,
                  ),
                ),
              ),
              if (actionText.isNotEmpty)
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: onAction,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 6,
                    ),
                    child: Text(
                      actionText.tr,
                      style: AppThemeData.boldTextStyle(
                        fontSize: 15,
                        color: _pickerAccent,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppThemeData.grey800 : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? AppThemeData.grey700 : const Color(0xFFE8EAEE),
              ),
            ),
            child:
                addresses.isEmpty
                    ? Padding(
                      padding: const EdgeInsets.all(18),
                      child: Text(
                        emptyText.tr,
                        style: AppThemeData.mediumTextStyle(
                          fontSize: 14,
                          color: isDark ? AppThemeData.grey300 : _pickerMuted,
                        ),
                      ),
                    )
                    : Column(
                      children: List.generate(addresses.length, (index) {
                        final address = addresses[index];
                        return _SavedAddressTile(
                          address: address,
                          isDark: isDark,
                          showDivider: index != addresses.length - 1,
                          onTap: () => onTap(address),
                        );
                      }),
                    ),
          ),
        ],
      ),
    );
  }
}

class _SavedAddressTile extends StatelessWidget {
  final ShippingAddress address;
  final bool isDark;
  final bool showDivider;
  final VoidCallback onTap;

  const _SavedAddressTile({
    required this.address,
    required this.isDark,
    required this.showDivider,
    required this.onTap,
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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1E9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_iconFor(title), color: _pickerAccent, size: 27),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppThemeData.boldTextStyle(
                          fontSize: 17,
                          color: isDark ? Colors.white : _pickerInk,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppThemeData.mediumTextStyle(
                          fontSize: 14,
                          color: isDark ? AppThemeData.grey300 : _pickerMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? AppThemeData.grey300 : _pickerInk,
                ),
              ],
            ),
            if (showDivider)
              Padding(
                padding: const EdgeInsets.only(left: 66, top: 14),
                child: Divider(
                  height: 1,
                  color:
                      isDark ? AppThemeData.grey700 : const Color(0xFFE8EAEE),
                ),
              )
            else
              const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}

class _AddFavoriteCard extends StatelessWidget {
  final bool isDark;

  const _AddFavoriteCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isDark
                  ? [AppThemeData.grey800, AppThemeData.grey800]
                  : [const Color(0xFFFFF4ED), const Color(0xFFFFE8DA)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.star_border_rounded, color: _pickerAccent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Enregistrez vos adresses préférées".tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppThemeData.boldTextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white : _pickerInk,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "Accédez rapidement à vos lieux importants".tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppThemeData.mediumTextStyle(
                    fontSize: 13,
                    color: isDark ? AppThemeData.grey300 : _pickerMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: _openAddressForm,
              child: Ink(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _pickerAccent,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  "Ajouter".tr,
                  style: AppThemeData.boldTextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _CircleButton({
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Ink(
          height: 50,
          width: 50,
          decoration: BoxDecoration(
            color: isDark ? AppThemeData.grey800 : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [_microShadow],
          ),
          child: Icon(icon, color: isDark ? Colors.white : _pickerInk),
        ),
      ),
    );
  }
}

IconData _iconFor(String value) {
  final lower = value.toLowerCase();
  if (lower.contains('bureau') || lower.contains('travail')) {
    return Icons.business_center_outlined;
  }
  if (lower.contains('boutique') || lower.contains('shop')) {
    return Icons.storefront_outlined;
  }
  if (lower.contains('maison') || lower.contains('home')) {
    return Icons.home_outlined;
  }
  return Icons.person_outline_rounded;
}

void _openAddressForm() {
  Get.to(const EnterManuallyLocationScreen());
}

final BoxShadow _softShadow = BoxShadow(
  color: Colors.black.withValues(alpha: 0.08),
  blurRadius: 26,
  offset: const Offset(0, 12),
);

final BoxShadow _microShadow = BoxShadow(
  color: Colors.black.withValues(alpha: 0.06),
  blurRadius: 18,
  offset: const Offset(0, 8),
);
