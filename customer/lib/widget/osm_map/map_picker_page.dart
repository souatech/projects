import 'package:customer/themes/app_them_data.dart';
import 'package:customer/themes/round_button_fill.dart';
import 'package:customer/utils/address_formatter.dart';
import 'package:customer/widget/osm_map/map_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/theme_controller.dart';

const Color _pickerBg = Color(0xFFF8F9FB);
const Color _pickerAccent = Color(0xFFFF4B12);
const Color _pickerInk = Color(0xFF111827);
const Color _pickerMuted = Color(0xFF6B7280);

class MapPickerPage extends StatelessWidget {
  final OSMMapController controller = Get.put(OSMMapController());
  final TextEditingController searchController = TextEditingController();

  MapPickerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDark.value;
    return Scaffold(
      backgroundColor: isDark ? AppThemeData.grey900 : _pickerBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Column(
            children: [
              Row(
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
                    onTap: controller.getCurrentLocation,
                  ),
                ],
              ),
              const SizedBox(height: 26),
              _SearchBox(
                controller: searchController,
                isDark: isDark,
                onChanged: controller.searchPlace,
              ),
              const SizedBox(height: 18),
              Obx(() {
                if (controller.searchResults.isEmpty) {
                  return const SizedBox.shrink();
                }
                return _SearchResults(
                  isDark: isDark,
                  controller: controller,
                  searchController: searchController,
                );
              }),
              const SizedBox(height: 18),
              Obx(() {
                final picked = controller.pickedPlace.value;
                return _SelectedAddressCard(
                  isDark: isDark,
                  title:
                      picked == null
                          ? "Choisir une adresse".tr
                          : picked.address,
                  subtitle:
                      picked == null
                          ? "Recherchez une adresse ou utilisez votre position."
                              .tr
                          : AddressFormatter.shortAddress(
                            picked.fullAddress ?? picked.address,
                          ),
                );
              }),
              const Spacer(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
          child: Row(
            children: [
              Expanded(
                child: RoundedButtonFill(
                  title: "Confirmer cette adresse".tr,
                  color: _pickerAccent,
                  textColor: AppThemeData.grey50,
                  height: 5.5,
                  onPress: () async {
                    final selected = controller.pickedPlace.value;
                    if (selected != null) {
                      Get.back(result: selected);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              _CircleButton(
                icon: Icons.delete_outline_rounded,
                isDark: isDark,
                onTap: controller.clearAll,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _SearchBox({
    required this.controller,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: AppThemeData.mediumTextStyle(
        color: isDark ? Colors.white : _pickerInk,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: 'Rechercher une adresse'.tr,
        hintStyle: AppThemeData.mediumTextStyle(
          color: isDark ? AppThemeData.grey300 : _pickerMuted,
          fontSize: 15,
        ),
        filled: true,
        fillColor: isDark ? AppThemeData.grey800 : Colors.white,
        prefixIcon: const Icon(Icons.search_rounded, color: _pickerAccent),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
      ),
      onChanged: onChanged,
    );
  }
}

class _SearchResults extends StatelessWidget {
  final bool isDark;
  final OSMMapController controller;
  final TextEditingController searchController;

  const _SearchResults({
    required this.isDark,
    required this.controller,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.grey800 : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: controller.searchResults.length,
        separatorBuilder:
            (context, index) => Divider(
              height: 1,
              color: isDark ? AppThemeData.grey700 : const Color(0xFFE8EAEE),
            ),
        itemBuilder: (context, index) {
          final place = controller.searchResults[index];
          final title = AddressFormatter.shortAddress(
            place['display_name']?.toString(),
            addressDetails:
                place['address'] is Map<String, dynamic>
                    ? place['address'] as Map<String, dynamic>
                    : null,
          );
          return ListTile(
            leading: const Icon(Icons.place_outlined, color: _pickerAccent),
            title: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppThemeData.mediumTextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : _pickerInk,
              ),
            ),
            onTap: () {
              controller.selectSearchResult(place);
              searchController.text =
                  controller.pickedPlace.value?.address ?? '';
            },
          );
        },
      ),
    );
  }
}

class _SelectedAddressCard extends StatelessWidget {
  final bool isDark;
  final String title;
  final String subtitle;

  const _SelectedAddressCard({
    required this.isDark,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.grey800 : Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isDark ? AppThemeData.grey700 : const Color(0xFFE8EAEE),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF1E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.place_rounded, color: _pickerAccent),
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppThemeData.mediumTextStyle(
                    fontSize: 13,
                    color: isDark ? AppThemeData.grey300 : _pickerMuted,
                  ),
                ),
              ],
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(icon, color: isDark ? Colors.white : _pickerInk),
        ),
      ),
    );
  }
}
