import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/app/auth_screen/login_screen.dart';
import 'package:driver/app/multi_service/multi_service_dashboard_screen.dart';
import 'package:driver/app/owner_screen/owner_dashboard_screen.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/models/car_makes.dart';
import 'package:driver/models/car_model.dart';
import 'package:driver/models/section_model.dart';
import 'package:driver/models/user_model.dart';
import 'package:driver/models/vehicle_type.dart';
import 'package:driver/models/zone_model.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SignupController extends GetxController {
  static const String driverRoleDelivery = 'delivery';
  static const String driverRoleCab = 'cab';
  static const String driverRoleCabRental = 'cab_rental';

  Rx<TextEditingController> firstNameEditingController =
      TextEditingController().obs;
  Rx<TextEditingController> lastNameEditingController =
      TextEditingController().obs;
  Rx<TextEditingController> emailEditingController =
      TextEditingController().obs;
  Rx<TextEditingController> phoneNUmberEditingController =
      TextEditingController().obs;
  Rx<TextEditingController> countryCodeEditingController =
      TextEditingController(text: Constant.defaultCountryCode).obs;
  Rx<TextEditingController> countryISOCodeEditingController =
      TextEditingController(text: Constant.defaultCountryCode).obs;
  Rx<TextEditingController> passwordEditingController =
      TextEditingController().obs;
  Rx<TextEditingController> conformPasswordEditingController =
      TextEditingController().obs;
  Rx<TextEditingController> carPlatNumberEditingController =
      TextEditingController().obs;

  RxBool passwordVisible = true.obs;
  RxBool conformPasswordVisible = true.obs;

  RxString type = "".obs;
  Rx<UserModel> userModel = UserModel().obs;

  RxList<ZoneModel> zoneList = <ZoneModel>[].obs;
  Rx<ZoneModel> selectedZone = ZoneModel().obs;

  /// All active sections loaded from Firestore (no service filter)
  RxList<SectionModel> allSections = <SectionModel>[].obs;

  /// Sections the driver has selected during registration
  RxList<SectionModel> selectedSections = <SectionModel>[].obs;

  /// Vehicle types per section (loaded only for cab-service / rental-service sections)
  RxMap<String, List<VehicleType>> vehicleTypesPerSection =
      <String, List<VehicleType>>{}.obs;
  RxMap<String, VehicleType> selectedVehiclePerSection =
      <String, VehicleType>{}.obs;

  /// Shared car makes list (loaded once from Firestore)
  RxList<CarMakes> carMakesList = <CarMakes>[].obs;

  /// Per-section car details
  final Map<String, Rx<CarMakes>> selectedCarMakesPerSection = {};
  final Map<String, RxList<CarModel>> carModelListPerSection = {};
  final Map<String, Rx<CarModel>> selectedCarModelPerSection = {};
  final Map<String, Rx<TextEditingController>> carPlatePerSection = {};

  RxString selectedValue = "Individual".obs;
  RxString selectedDriverRole = driverRoleDelivery.obs;

  // ── Helpers ────────────────────────────────────────────────────────────────

  bool sectionNeedsVehicle(SectionModel section) =>
      section.serviceTypeFlag == 'cab-service' ||
      section.serviceTypeFlag == 'rental-service';

  bool get hasVehicleBasedSection => selectedSections.any(sectionNeedsVehicle);

  bool isSectionSelected(SectionModel section) =>
      selectedSections.any((s) => s.id == section.id);

  bool isDeliveryLike(SectionModel section) =>
      section.serviceTypeFlag != 'cab-service' &&
      section.serviceTypeFlag != 'rental-service';

  /// Sections visible based on role selection.
  /// Company/Owner cannot register for delivery-service — only cab, parcel, rental.
  List<SectionModel> get visibleSections {
    if (selectedValue.value == 'Company') {
      return allSections
          .where((s) => s.serviceTypeFlag != 'delivery-service')
          .toList();
    }
    return allSections;
  }

  /// Called when switching between Individual / Company to deselect
  /// any sections that are no longer visible (delivery-service for Company).
  void onRoleChanged(String role) {
    selectedValue.value = role;
    if (role == 'Company') {
      // Remove any delivery-service sections from selection
      final deliverySections = selectedSections
          .where((s) => s.serviceTypeFlag == 'delivery-service')
          .toList();
      for (final s in deliverySections) {
        selectedSections.removeWhere((sec) => sec.id == s.id);
      }
    } else {
      applyDriverRole(selectedDriverRole.value);
    }
    update();
  }

  Future<void> onDriverRoleChanged(String role) async {
    selectedDriverRole.value = role;
    await applyDriverRole(role);
  }

  Future<void> applyDriverRole(String role) async {
    final sections = _sectionsForDriverRole(role);
    await _replaceSelectedSections(sections);
  }

  List<SectionModel> _sectionsForDriverRole(String role) {
    switch (role) {
      case driverRoleCab:
        return allSections
            .where((s) => s.serviceTypeFlag == 'cab-service')
            .toList();
      case driverRoleCabRental:
        return allSections
            .where((s) =>
                s.serviceTypeFlag == 'cab-service' ||
                s.serviceTypeFlag == 'rental-service')
            .toList();
      case driverRoleDelivery:
      default:
        return allSections.where(isDeliveryLike).toList();
    }
  }

  Future<void> _replaceSelectedSections(List<SectionModel> sections) async {
    final nextIds = sections.map((s) => s.id).whereType<String>().toSet();
    selectedSections
      ..clear()
      ..addAll(sections);

    vehicleTypesPerSection.removeWhere((key, _) => !nextIds.contains(key));
    selectedVehiclePerSection.removeWhere((key, _) => !nextIds.contains(key));
    selectedCarMakesPerSection.removeWhere((key, _) => !nextIds.contains(key));
    carModelListPerSection.removeWhere((key, _) => !nextIds.contains(key));
    selectedCarModelPerSection.removeWhere((key, _) => !nextIds.contains(key));
    carPlatePerSection.removeWhere((key, _) => !nextIds.contains(key));

    for (final section in sections.where(sectionNeedsVehicle)) {
      final sid = section.id;
      if (sid != null && !vehicleTypesPerSection.containsKey(sid)) {
        await _loadVehicleTypesForSection(section);
      }
    }
    update();
  }

  /// Returns a human-readable label for a section's serviceTypeFlag.
  String serviceFlagLabel(String? flag) {
    switch (flag) {
      case 'cab-service':
        return 'Cab';
      case 'parcel_delivery':
        return 'Parcel';
      case 'rental-service':
        return 'Rental';
      default:
        return 'Delivery';
    }
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void onInit() {
    getArgument();
    super.onInit();
  }

  Future<void> getArgument() async {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      type.value = argumentData['type'];
      userModel.value = argumentData['userModel'];
      if (type.value == "mobileNumber") {
        phoneNUmberEditingController.value.text =
            userModel.value.phoneNumber ?? "";
        countryCodeEditingController.value.text =
            userModel.value.countryCode ?? Constant.defaultCountryCode;
        countryISOCodeEditingController.value.text =
            userModel.value.countryISOCode ?? Constant.defaultCountryCode;
      } else if (type.value == "google" || type.value == "apple") {
        emailEditingController.value.text = userModel.value.email ?? "";
        firstNameEditingController.value.text = userModel.value.firstName ?? "";
        lastNameEditingController.value.text = userModel.value.lastName ?? "";
      }
    }

    await Future.wait([
      FireStoreUtils.getZone().then((v) {
        if (v != null) zoneList.value = v;
      }),
      FireStoreUtils.getCarMakes().then((v) => carMakesList.value = v),
      FireStoreUtils.getAllActiveSections().then((v) => allSections.value = v),
    ]);

    if (selectedValue.value == 'Individual') {
      await applyDriverRole(selectedDriverRole.value);
    }
  }

  // ── Section toggle ─────────────────────────────────────────────────────────

  Future<void> toggleSection(SectionModel section) async {
    if (isSectionSelected(section)) {
      if (selectedSections.length == 1) {
        ShowToastDialog.showToast("At least one section must be selected.".tr);
        return;
      }
      selectedSections.removeWhere((s) => s.id == section.id);
      vehicleTypesPerSection.remove(section.id);
      selectedVehiclePerSection.remove(section.id);
      selectedCarMakesPerSection.remove(section.id);
      carModelListPerSection.remove(section.id);
      selectedCarModelPerSection.remove(section.id);
      carPlatePerSection.remove(section.id);
    } else {
      selectedSections.add(section);
      if (sectionNeedsVehicle(section)) {
        await _loadVehicleTypesForSection(section);
        // Init per-section car details
        selectedCarMakesPerSection[section.id!] = Rx<CarMakes>(CarMakes());
        carModelListPerSection[section.id!] = <CarModel>[].obs;
        selectedCarModelPerSection[section.id!] = Rx<CarModel>(CarModel());
        carPlatePerSection[section.id!] =
            Rx<TextEditingController>(TextEditingController());
      }
    }
    update();
  }

  Future<void> _loadVehicleTypesForSection(SectionModel section) async {
    ShowToastDialog.showLoader("Please wait".tr);
    List<VehicleType> types;
    if (section.serviceTypeFlag == 'cab-service') {
      types = await FireStoreUtils.getCabVehicleType(section.id.toString());
    } else {
      types = await FireStoreUtils.getRentalVehicleType(section.id.toString());
    }
    vehicleTypesPerSection[section.id!] = types;
    if (types.isNotEmpty) selectedVehiclePerSection[section.id!] = types.first;
    ShowToastDialog.closeLoader();
    update();
  }

  Future<void> getCarModelForSection(String sectionId) async {
    ShowToastDialog.showLoader("Please wait".tr);
    final carMakes = selectedCarMakesPerSection[sectionId]?.value;
    carModelListPerSection[sectionId]?.clear();
    selectedCarModelPerSection[sectionId]?.value = CarModel();
    if (carMakes?.name != null) {
      await FireStoreUtils.getCarModel(carMakes!.name.toString()).then((v) {
        carModelListPerSection[sectionId]?.value = v;
      });
    }
    ShowToastDialog.closeLoader();
  }

  // ── Sign up ────────────────────────────────────────────────────────────────

  Future<void> signUpWithEmailAndPassword() async {
    await signUp();
  }

  Future<void> signUp() async {
    if (selectedSections.isEmpty) {
      ShowToastDialog.showToast("Please select at least one section.".tr);
      return;
    }
    ShowToastDialog.showLoader("Please wait".tr);

    if (type.value == "google" ||
        type.value == "apple" ||
        type.value == "mobileNumber") {
      _populateUserModel();
      await FireStoreUtils.updateUser(userModel.value);
      _navigateAfterSignup(userModel.value);
    } else {
      try {
        final credential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailEditingController.value.text.trim(),
          password: passwordEditingController.value.text.trim(),
        );
        if (credential.user != null) {
          userModel.value.id = credential.user!.uid;
          _populateUserModel();
          await FireStoreUtils.updateUser(userModel.value);
          _navigateAfterSignup(userModel.value);
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'weak-password') {
          ShowToastDialog.showToast("The password provided is too weak.".tr);
        } else if (e.code == 'email-already-in-use') {
          ShowToastDialog.showToast(
              "The account already exists for that email.".tr);
        } else if (e.code == 'invalid-email') {
          ShowToastDialog.showToast("Enter email is Invalid".tr);
        }
        // print(e);
      } catch (e) {
        // print(e);
        ShowToastDialog.showToast(e.toString());
      }
    }

    ShowToastDialog.closeLoader();
  }

  void _populateUserModel() {
    userModel.value.firstName = firstNameEditingController.value.text;
    userModel.value.lastName = lastNameEditingController.value.text;
    userModel.value.email = emailEditingController.value.text.toLowerCase();
    userModel.value.phoneNumber = phoneNUmberEditingController.value.text;
    userModel.value.role = Constant.userRoleDriver;
    userModel.value.isActive = false;
    userModel.value.active = Constant.autoApproveDriver == true ? true : false;
    userModel.value.isDocumentVerify = selectedValue.value == "Company"
        ? Constant.isOwnerVerification == true
            ? false
            : true
        : Constant.isDriverVerification == true
            ? false
            : true;
    userModel.value.countryCode = countryCodeEditingController.value.text;
    userModel.value.countryISOCode = countryISOCodeEditingController.value.text;
    userModel.value.createdAt = Timestamp.now();
    userModel.value.zoneId = selectedZone.value.id;
    userModel.value.appIdentifier = Platform.isAndroid ? 'android' : 'ios';
    userModel.value.provider = type.value.isEmpty ? 'email' : type.value;
    userModel.value.isOwner = selectedValue.value == "Company" ? true : false;
    userModel.value.driverRole =
        selectedValue.value == "Individual" ? selectedDriverRole.value : null;
    userModel.value.isAutoVerify = selectedValue.value == "Company"
        ? Constant.isOwnerVerification == false
            ? true
            : false
        : Constant.isDriverVerification == false
            ? true
            : false;

    // ── Section IDs ──────────────────────────────────────────────────────────
    userModel.value.sectionIds = selectedSections.map((s) => s.id!).toList();

    // ── Derive serviceTypes from unique serviceTypeFlags of selected sections ─
    final uniqueFlags = selectedSections
        .map((s) => s.serviceTypeFlag ?? 'delivery-service')
        .toSet()
        .toList();
    userModel.value.serviceTypes = uniqueFlags;

    // ── sectionNames: simple {sectionId → sectionName} lookup ────────────────
    userModel.value.sectionNames = {
      for (final s in selectedSections) s.id!: s.name ?? s.id!,
    };

    // ── vehicleDetails: {sectionId → {vehicleId, vehicleType, carBrand, carModel, carPlateNumber}} ─
    // Skip for Company users — they register their own drivers separately.
    final Map<String, dynamic> vDetails = {};
    final bool isCompany = selectedValue.value == "Company";
    for (final section in selectedSections) {
      if (!isCompany && sectionNeedsVehicle(section)) {
        final vehicle = selectedVehiclePerSection[section.id];
        final carMakes = selectedCarMakesPerSection[section.id]?.value;
        final carModel = selectedCarModelPerSection[section.id]?.value;
        final carPlate = carPlatePerSection[section.id]?.value.text ?? '';
        vDetails[section.id!] = {
          'vehicleId': vehicle?.id ?? '',
          'vehicleType': vehicle?.name ?? '',
          'carBrand': carMakes?.name ?? '',
          'carModel': carModel?.name ?? '',
          'carPlateNumber': carPlate,
          if (section.serviceTypeFlag == 'cab-service')
            'rideType': section.rideType ?? 'ride',
        };
      }
    }
    if (vDetails.isNotEmpty) userModel.value.vehicleDetails = vDetails;

    log(userModel.value.toJson().toString());
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _navigateAfterSignup(UserModel user) {
    if (!(Constant.autoApproveDriver ?? false)) {
      ShowToastDialog.showToast(
          "Thank you for sign up, your application is under approval so please wait till that approve."
              .tr);
      Get.offAll(const LoginScreen());
      return;
    }
    navigateByUserModel(user);
  }

  static void navigateByUserModel(UserModel user) {
    if (user.isOwner == true) {
      Get.offAll(OwnerDashboardScreen());
    } else {
      debugPrint("[DRIVER_DASHBOARD] using unified dashboard");
      Get.offAll(const MultiServiceDashboardScreen());
    }
  }

  @override
  void onClose() {
    firstNameEditingController.value.dispose();
    lastNameEditingController.value.dispose();
    emailEditingController.value.dispose();
    phoneNUmberEditingController.value.dispose();
    countryCodeEditingController.value.dispose();
    countryISOCodeEditingController.value.dispose();
    passwordEditingController.value.dispose();
    conformPasswordEditingController.value.dispose();
    carPlatNumberEditingController.value.dispose();
    for (final ctrl in carPlatePerSection.values) {
      ctrl.value.dispose();
    }
    super.onClose();
  }
}
