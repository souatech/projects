import 'dart:async';
import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/screen_ui/service_home_screen/service_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as latlong;

import '../../controllers/rental_home_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../models/rental_vehicle_type.dart';
import '../../themes/app_them_data.dart';
import '../../themes/round_button_fill.dart';
import '../../themes/show_toast_dialog.dart';
import '../../themes/text_field_widget.dart';
import '../../models/banner_model.dart';
import '../../utils/network_image_widget.dart';
import '../../utils/utils.dart';
import '../../widget/osm_map/map_picker_page.dart';
import '../../widget/place_picker/location_picker_screen.dart';
import '../../widget/place_picker/selected_location_model.dart';
import '../auth_screens/login_screen.dart';

class RentalHomeScreen extends StatelessWidget {
  const RentalHomeScreen({super.key});

  static const Color _bg = Color(0xFFF8F9FB);
  static const Color _accent = Color(0xFFFF4A16);
  static const Color _textDark = Color(0xFF111827);
  static const Color _textMuted = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDark.value;

    return GetX(
      init: RentalHomeController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: isDark ? AppThemeData.grey900 : _bg,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            elevation: 0,
            backgroundColor: isDark ? AppThemeData.grey900 : _bg,
            title: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    log(":: Rental back to services ::");
                    Get.offAll(const ServiceListScreen());
                  },
                  child: _roundIcon(Icons.arrow_back_ios_new_rounded, isDark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Location voiture".tr,
                        style: AppThemeData.boldTextStyle(
                          fontSize: 18,
                          color: isDark ? AppThemeData.grey50 : _textDark,
                        ),
                      ),
                      Constant.userModel == null
                          ? InkWell(
                            onTap: () => Get.offAll(const LoginScreen()),
                            child: Text(
                              "Login".tr,
                              style: AppThemeData.mediumTextStyle(
                                fontSize: 12,
                                color: _accent,
                              ),
                            ),
                          )
                          : Text(
                            Constant.userModel!.fullName(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppThemeData.mediumTextStyle(
                              fontSize: 12,
                              color: _textMuted,
                            ),
                          ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body:
              controller.isLoading.value
                  ? Center(child: Constant.loader())
                  : SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (controller.bannerTopHome.isNotEmpty) ...[
                            _RentalAdminBannerCarousel(
                              banners: controller.bannerTopHome,
                            ),
                            const SizedBox(height: 18),
                          ],
                          _hero(isDark),
                          const SizedBox(height: 18),
                          _sectionTitle(
                            "Votre réservation".tr,
                            "Acompte manuel Wave / Orange Money".tr,
                            isDark,
                          ),
                          const SizedBox(height: 10),
                          _addressCard(context, controller, isDark),
                          const SizedBox(height: 14),
                          _dateCard(context, controller, isDark),
                          const SizedBox(height: 18),
                          _sectionTitle(
                            "Choisissez votre véhicule".tr,
                            null,
                            isDark,
                          ),
                          const SizedBox(height: 10),
                          _vehicleList(controller, isDark),
                          const SizedBox(height: 18),
                          _documentCard(controller, isDark),
                          const SizedBox(height: 14),
                          _cgvCard(controller, isDark),
                          const SizedBox(height: 18),
                          Obx(() => _summaryCard(controller, isDark)),
                          const SizedBox(height: 18),
                          RoundedButtonFill(
                            title: "Continuer".tr,
                            onPress: () => _continue(controller, isDark),
                            color: _accent,
                            textColor: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
        );
      },
    );
  }

  Widget _roundIcon(IconData icon, bool isDark) {
    return Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.grey800 : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(icon, size: 18, color: isDark ? Colors.white : _textDark),
    );
  }

  Widget _hero(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(isDark).copyWith(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF2EA), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Réservez votre voiture".tr,
                  style: AppThemeData.boldTextStyle(
                    fontSize: 24,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Acompte 50%, solde à la récupération, caution en espèces."
                      .tr,
                  style: AppThemeData.mediumTextStyle(
                    fontSize: 13,
                    color: _textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 82,
            width: 82,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_car_filled_rounded,
              size: 44,
              color: _accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, String? subtitle, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppThemeData.boldTextStyle(
            fontSize: 18,
            color: isDark ? AppThemeData.grey50 : _textDark,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppThemeData.mediumTextStyle(
              fontSize: 13,
              color: _textMuted,
            ),
          ),
        ],
      ],
    );
  }

  Widget _addressCard(
    BuildContext context,
    RentalHomeController controller,
    bool isDark,
  ) {
    return Container(
      decoration: _cardDecoration(isDark),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          InkWell(
            onTap: () => _pickAddress(controller, isPickup: true),
            child: TextFieldWidget(
              controller: controller.sourceTextEditController.value,
              hintText: "Adresse de récupération".tr,
              title: "Récupération".tr,
              enable: false,
              prefix: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.location_on_rounded, color: _accent),
              ),
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => _pickAddress(controller, isPickup: false),
            child: TextFieldWidget(
              controller: controller.dropoffTextEditController.value,
              hintText: "Adresse de dépôt".tr,
              title: "Dépôt".tr,
              enable: false,
              prefix: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.flag_rounded, color: _textDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateCard(
    BuildContext context,
    RentalHomeController controller,
    bool isDark,
  ) {
    return Container(
      decoration: _cardDecoration(isDark),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: _dateTile(
              title: "Récupération".tr,
              value: Constant.formatTimestamp(
                Timestamp.fromDate(controller.selectedDate.value),
              ),
              onTap: () => controller.pickDateTime(context),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _dateTile(
              title: "Retour".tr,
              value: Constant.formatTimestamp(
                Timestamp.fromDate(controller.returnDate.value),
              ),
              onTap: () => controller.pickDateTime(context, isReturn: true),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateTile({
    required String title,
    required String value,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppThemeData.grey800 : _bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: _accent,
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: AppThemeData.mediumTextStyle(
                    fontSize: 12,
                    color: _textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppThemeData.semiBoldTextStyle(
                fontSize: 13,
                color: isDark ? AppThemeData.grey50 : _textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vehicleList(RentalHomeController controller, bool isDark) {
    if (controller.vehicleTypes.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: _cardDecoration(isDark),
        child: Text(
          "Aucun véhicule disponible pour cette section.".tr,
          style: AppThemeData.mediumTextStyle(color: _textMuted),
        ),
      );
    }
    return ListView.builder(
      itemCount: controller.vehicleTypes.length,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        RentalVehicleType vehicleType = controller.vehicleTypes[index];
        return Obx(() {
          final selected =
              controller.selectedVehicleType.value?.id == vehicleType.id;
          return InkWell(
            onTap: () async {
              controller.selectedVehicleType.value =
                  controller.vehicleTypes[index];
              await controller.getRentalPackage();
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: _cardDecoration(isDark).copyWith(
                border: Border.all(
                  color: selected ? _accent : Colors.transparent,
                  width: 1.2,
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: vehicleType.rentalVehicleIcon.toString(),
                      height: 76,
                      width: 90,
                      imageBuilder:
                          (context, imageProvider) => Container(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: imageProvider,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                      placeholder:
                          (context, url) => Center(
                            child: CircularProgressIndicator.adaptive(
                              valueColor: AlwaysStoppedAnimation(
                                AppThemeData.primary300,
                              ),
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => Image.network(
                            Constant.placeHolderImage,
                            fit: BoxFit.cover,
                          ),
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicleType.name ?? "",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppThemeData.boldTextStyle(
                            fontSize: 17,
                            color: isDark ? AppThemeData.grey50 : _textDark,
                          ),
                        ),
                        if ((vehicleType.shortDescription ??
                                vehicleType.description ??
                                '')
                            .isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            vehicleType.shortDescription ??
                                vehicleType.description ??
                                "",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppThemeData.mediumTextStyle(
                              fontSize: 13,
                              color: _textMuted,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          vehicleType.capacity == null
                              ? ""
                              : "${vehicleType.capacity} places",
                          style: AppThemeData.mediumTextStyle(
                            fontSize: 12,
                            color: _accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: selected ? _accent : _textMuted,
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget _documentCard(RentalHomeController controller, bool isDark) {
    return Container(
      decoration: _cardDecoration(isDark),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Documents obligatoires".tr,
            style: AppThemeData.boldTextStyle(
              fontSize: 16,
              color: isDark ? AppThemeData.grey50 : _textDark,
            ),
          ),
          const SizedBox(height: 12),
          Obx(
            () => _uploadTile(
              title: "Permis de conduire".tr,
              value: controller.driverLicensePath.value,
              onTap: () => controller.pickRentalDocument(isLicense: true),
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 10),
          Obx(
            () => _uploadTile(
              title: "Pièce d'identité".tr,
              value: controller.identityDocumentPath.value,
              onTap: () => controller.pickRentalDocument(isLicense: false),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _uploadTile({
    required String title,
    required String value,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final hasFile = value.isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppThemeData.grey800 : _bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              hasFile ? Icons.check_circle_rounded : Icons.upload_file_rounded,
              color: hasFile ? Colors.green : _accent,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: AppThemeData.semiBoldTextStyle(
                  fontSize: 14,
                  color: isDark ? AppThemeData.grey50 : _textDark,
                ),
              ),
            ),
            Text(
              hasFile ? "Ajouté".tr : "Ajouter".tr,
              style: AppThemeData.mediumTextStyle(
                fontSize: 13,
                color: hasFile ? Colors.green : _accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cgvCard(RentalHomeController controller, bool isDark) {
    return Obx(
      () => Container(
        decoration: _cardDecoration(isDark),
        child: CheckboxListTile(
          value: controller.cgvAccepted.value,
          activeColor: _accent,
          onChanged: (value) => controller.cgvAccepted.value = value ?? false,
          title: Text(
            "J'accepte les CGV de location JOXMAKO".tr,
            style: AppThemeData.semiBoldTextStyle(
              fontSize: 14,
              color: isDark ? AppThemeData.grey50 : _textDark,
            ),
          ),
          subtitle: Text(
            "Permis et CNI originaux seront vérifiés à la récupération.".tr,
            style: AppThemeData.mediumTextStyle(
              fontSize: 12,
              color: _textMuted,
            ),
          ),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ),
    );
  }

  Widget _summaryCard(RentalHomeController controller, bool isDark) {
    final total = controller.getTotalPrice();
    final deposit = controller.getDepositAmount();
    final remaining = controller.getRemainingAmount();
    final package = controller.selectedPackage.value;
    final reservedDays = controller.getRentalDays();
    return Container(
      decoration: _cardDecoration(isDark),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Récapitulatif".tr,
            style: AppThemeData.boldTextStyle(
              fontSize: 16,
              color: isDark ? AppThemeData.grey50 : _textDark,
            ),
          ),
          const SizedBox(height: 12),
          _summaryRow(
            "Forfait".tr,
            package?.name ?? "Choisir le forfait".tr,
            isDark,
          ),
          _summaryRow(
            "Prix de base / jour".tr,
            Constant.amountShow(
              amount: controller.packageBasePrice().toStringAsFixed(2),
            ),
            isDark,
          ),
          _summaryRow(
            "Nombre de jours".tr,
            "$reservedDays ${reservedDays > 1 ? 'jours'.tr : 'jour'.tr}",
            isDark,
          ),
          _summaryRow(
            "Total réservation".tr,
            Constant.amountShow(amount: total.toStringAsFixed(2)),
            isDark,
          ),
          _summaryRow(
            "50% à régler maintenant".tr,
            Constant.amountShow(amount: deposit.toStringAsFixed(2)),
            isDark,
            accent: true,
          ),
          _summaryRow(
            "50% à la récupération".tr,
            Constant.amountShow(amount: remaining.toStringAsFixed(2)),
            isDark,
          ),
          _summaryRow(
            "Caution espèces".tr,
            "À prévoir à la récupération".tr,
            isDark,
          ),
          _summaryRow(
            "Distance incluse".tr,
            controller.includedDistanceLabel(),
            isDark,
          ),
          if (controller.packageIncludedDistance() != -1 &&
              controller.packageExtraKmPrice() > 0)
            _summaryRow(
              "Km supplémentaire".tr,
              "${Constant.amountShow(amount: controller.packageExtraKmPrice().toStringAsFixed(2))}/km",
              isDark,
            ),
          if (controller.packageExtraMinutePrice() > 0)
            _summaryRow(
              "Minute supplémentaire".tr,
              "${Constant.amountShow(amount: controller.packageExtraMinutePrice().toStringAsFixed(2))}/min",
              isDark,
            ),
          const SizedBox(height: 10),
          if (controller.packageExtraMinutePrice() > 0)
            Text(
              "Tout retard au retour au-delà de 30 minutes sera facturé @amount par minute supplémentaire."
                  .trParams({
                    'amount': Constant.amountShow(
                      amount: controller
                          .packageExtraMinutePrice()
                          .toStringAsFixed(2),
                    ),
                  }),
              style: AppThemeData.mediumTextStyle(
                fontSize: 12,
                color: _textMuted,
              ),
            ),
          if (controller.packageIncludedDistance() == -1)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                "Kilométrage illimité inclus.".tr,
                style: AppThemeData.semiBoldTextStyle(
                  fontSize: 12,
                  color: _accent,
                ),
              ),
            )
          else if (controller.packageExtraKmPrice() > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                "Tout dépassement kilométrique sera facturé ${Constant.amountShow(amount: controller.packageExtraKmPrice().toStringAsFixed(2))} par km supplémentaire."
                    .trParams({
                      'amount': Constant.amountShow(
                        amount: controller
                            .packageExtraKmPrice()
                            .toStringAsFixed(2),
                      ),
                    }),
                style: AppThemeData.mediumTextStyle(
                  fontSize: 12,
                  color: _textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value,
    bool isDark, {
    bool accent = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppThemeData.mediumTextStyle(
                fontSize: 13,
                color: _textMuted,
              ),
            ),
          ),
          Text(
            value,
            textAlign: TextAlign.end,
            style: AppThemeData.semiBoldTextStyle(
              fontSize: 14,
              color:
                  accent
                      ? _accent
                      : isDark
                      ? AppThemeData.grey50
                      : _textDark,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _continue(RentalHomeController controller, bool isDark) async {
    final pickupText = controller.sourceTextEditController.value.text.trim();
    final dropoffText = controller.dropoffTextEditController.value.text.trim();
    if (Constant.userModel == null) {
      ShowToastDialog.showToast("Please login to continue".tr);
      return;
    }
    if (pickupText.isEmpty) {
      ShowToastDialog.showToast("Please select source location".tr);
      return;
    }
    if (dropoffText.isEmpty) {
      ShowToastDialog.showToast("Veuillez sélectionner l'adresse de dépôt".tr);
      return;
    }
    if (!controller.returnDate.value.isAfter(controller.selectedDate.value)) {
      ShowToastDialog.showToast(
        "La date de retour doit être après la récupération".tr,
      );
      return;
    }
    if (controller.selectedVehicleType.value == null) {
      ShowToastDialog.showToast("Please select a vehicle type".tr);
      return;
    }
    await controller.getRentalPackage();
    if (controller.rentalPackages.isEmpty) {
      ShowToastDialog.showToast(
        "No preference available for the selected vehicle type".tr,
      );
      return;
    }
    if (controller.driverLicensePath.value.isEmpty) {
      ShowToastDialog.showToast("Veuillez ajouter votre permis de conduire".tr);
      return;
    }
    if (controller.identityDocumentPath.value.isEmpty) {
      ShowToastDialog.showToast("Veuillez ajouter votre pièce d'identité".tr);
      return;
    }
    if (!controller.cgvAccepted.value) {
      ShowToastDialog.showToast("Veuillez accepter les CGV".tr);
      return;
    }
    Get.bottomSheet(
      _packageSheet(controller, isDark),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _packageSheet(RentalHomeController controller, bool isDark) {
    return DraggableScrollableSheet(
      initialChildSize: 0.58,
      minChildSize: 0.42,
      maxChildSize: 0.82,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppThemeData.grey900 : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(26),
              topRight: Radius.circular(26),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                height: 4,
                width: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.grey.shade300,
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Choisir le forfait".tr,
                  style: AppThemeData.boldTextStyle(
                    fontSize: 18,
                    color: isDark ? AppThemeData.grey50 : _textDark,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: controller.rentalPackages.length,
                  itemBuilder: (context, index) {
                    final package = controller.rentalPackages[index];
                    return Obx(() {
                      final selected =
                          controller.selectedPackage.value?.id == package.id;
                      return InkWell(
                        onTap: () => controller.selectedPackage.value = package,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected ? _accent : Colors.transparent,
                            ),
                            color:
                                selected
                                    ? const Color(0xFFFFF2EA)
                                    : isDark
                                    ? AppThemeData.grey800
                                    : _bg,
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      package.name ?? "",
                                      style: AppThemeData.boldTextStyle(
                                        fontSize: 16,
                                        color:
                                            isDark
                                                ? AppThemeData.grey50
                                                : _textDark,
                                      ),
                                    ),
                                    if ((package.description ?? '').isNotEmpty)
                                      Text(
                                        package.description ?? "",
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppThemeData.mediumTextStyle(
                                          fontSize: 13,
                                          color: _textMuted,
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        _packageChip(
                                          "${Constant.amountShow(amount: package.baseFare.toString())}/jour",
                                          isDark,
                                          accent: true,
                                        ),
                                        _packageChip(
                                          "${package.includedHours ?? '0'} h incluses",
                                          isDark,
                                        ),
                                        _packageChip(
                                          _distanceText(package),
                                          isDark,
                                        ),
                                        if (_number(package.extraKmFare) > 0 &&
                                            _number(package.includedDistance) !=
                                                -1)
                                          _packageChip(
                                            "${Constant.amountShow(amount: package.extraKmFare.toString())}/km supp.",
                                            isDark,
                                          ),
                                        if (_number(package.extraMinuteFare) >
                                            0)
                                          _packageChip(
                                            "${Constant.amountShow(amount: package.extraMinuteFare.toString())}/min supp.",
                                            isDark,
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "Acompte".tr,
                                    style: AppThemeData.mediumTextStyle(
                                      fontSize: 11,
                                      color: _textMuted,
                                    ),
                                  ),
                                  Text(
                                    Constant.amountShow(
                                      amount: (_number(package.baseFare) *
                                              controller.getRentalDays() *
                                              0.5)
                                          .toStringAsFixed(2),
                                    ),
                                    style: AppThemeData.boldTextStyle(
                                      fontSize: 15,
                                      color: _accent,
                                    ),
                                  ),
                                  Text(
                                    "Solde 50%".tr,
                                    style: AppThemeData.mediumTextStyle(
                                      fontSize: 11,
                                      color: _textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    });
                  },
                ),
              ),
              const SizedBox(height: 12),
              RoundedButtonFill(
                title: "Voir le récapitulatif".tr,
                color: _accent,
                textColor: Colors.white,
                onPress: () async => controller.completeOrder(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _packageChip(String text, bool isDark, {bool accent = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color:
            accent
                ? _accent.withValues(alpha: 0.12)
                : isDark
                ? AppThemeData.grey700
                : Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: AppThemeData.mediumTextStyle(
          fontSize: 11,
          color: accent ? _accent : _textMuted,
        ),
      ),
    );
  }

  String _distanceText(dynamic package) {
    final includedDistance = _number(package.includedDistance);
    if (includedDistance == -1) {
      return "Kilométrage illimité".tr;
    }
    final value =
        includedDistance.truncateToDouble() == includedDistance
            ? includedDistance.toStringAsFixed(0)
            : includedDistance.toStringAsFixed(1);
    return '@distance inclus'.trParams({
      'distance': '$value ${Constant.distanceType}',
    });
  }

  double _number(dynamic value) {
    return double.tryParse(value?.toString() ?? '0') ?? 0;
  }

  Future<void> _pickAddress(
    RentalHomeController controller, {
    required bool isPickup,
  }) async {
    if (Constant.selectedMapType == 'osm') {
      final result = await Get.to(() => MapPickerPage());
      if (result == null) return;
      final firstPlace = result;
      if (Constant.checkZoneCheck(
            firstPlace.coordinates.latitude,
            firstPlace.coordinates.longitude,
          ) !=
          true) {
        ShowToastDialog.showToast(
          "Service is unavailable at the selected address.".tr,
        );
        return;
      }
      if (isPickup) {
        controller.sourceTextEditController.value.text = firstPlace.address;
        controller.departureLatLongOsm.value = latlong.LatLng(
          firstPlace.coordinates.latitude,
          firstPlace.coordinates.longitude,
        );
      } else {
        controller.dropoffTextEditController.value.text = firstPlace.address;
        controller.dropoffLatLongOsm.value = latlong.LatLng(
          firstPlace.coordinates.latitude,
          firstPlace.coordinates.longitude,
        );
      }
      return;
    }

    Get.to(LocationPickerScreen())!.then((value) async {
      if (value == null) return;
      SelectedLocationModel selectedLocationModel = value;
      if (Constant.checkZoneCheck(
            selectedLocationModel.latLng!.latitude,
            selectedLocationModel.latLng!.longitude,
          ) !=
          true) {
        ShowToastDialog.showToast(
          "Service is unavailable at the selected address.".tr,
        );
        return;
      }
      final address = Utils.formatAddress(
        selectedLocation: selectedLocationModel,
      );
      if (isPickup) {
        controller.sourceTextEditController.value.text = address;
        controller.departureLatLong.value = latlong.LatLng(
          selectedLocationModel.latLng!.latitude,
          selectedLocationModel.latLng!.longitude,
        );
      } else {
        controller.dropoffTextEditController.value.text = address;
        controller.dropoffLatLong.value = latlong.LatLng(
          selectedLocationModel.latLng!.latitude,
          selectedLocationModel.latLng!.longitude,
        );
      }
    });
  }

  BoxDecoration _cardDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? AppThemeData.grey800 : Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }
}

class _RentalAdminBannerCarousel extends StatefulWidget {
  final List<BannerModel> banners;

  const _RentalAdminBannerCarousel({required this.banners});

  @override
  State<_RentalAdminBannerCarousel> createState() =>
      _RentalAdminBannerCarouselState();
}

class _RentalAdminBannerCarouselState
    extends State<_RentalAdminBannerCarousel> {
  final PageController _pageController = PageController();
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  @override
  void didUpdateWidget(covariant _RentalAdminBannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banners.length != widget.banners.length) {
      _page = 0;
      _timer?.cancel();
      _startAutoSlide();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  List<String> get _images =>
      widget.banners
          .map((banner) => (banner.photo ?? '').trim())
          .where((photo) => photo.isNotEmpty)
          .toList();

  void _startAutoSlide() {
    if (_images.length <= 1) {
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      final count = _images.length;
      if (!mounted || !_pageController.hasClients || count <= 1) {
        return;
      }
      _pageController.animateToPage(
        (_page + 1) % count,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final images = _images;
    if (images.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: 148,
          child: PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            onPageChanged: (value) => setState(() => _page = value),
            itemBuilder:
                (context, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: NetworkImageWidget(
                    imageUrl: images[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    showShimmer: false,
                  ),
                ),
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(images.length, (index) {
              final selected = index == _page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 5,
                width: selected ? 22 : 6,
                decoration: BoxDecoration(
                  color:
                      selected
                          ? RentalHomeScreen._accent
                          : AppThemeData.grey300,
                  borderRadius: BorderRadius.circular(99),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
