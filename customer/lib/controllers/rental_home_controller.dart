// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/models/rental_order_model.dart';
import 'package:customer/models/rental_package_model.dart';
import 'package:customer/models/user_model.dart';
import 'package:customer/models/vendor_model.dart';
import 'package:customer/screen_ui/rental_service/rental_conformation_screen.dart';
import 'package:customer/widget/geoflutterfire/src/geoflutterfire.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as latlong;
import 'package:image_picker/image_picker.dart';
import '../constant/constant.dart';
import '../models/banner_model.dart';
import '../models/rental_vehicle_type.dart';
import '../service/fire_store_utils.dart';
import '../themes/show_toast_dialog.dart';
import '../utils/utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

class RentalHomeController extends GetxController {
  RxBool isLoading = false.obs;
  RxBool isUploadingDocuments = false.obs;
  RxList<BannerModel> bannerTopHome = <BannerModel>[].obs;

  // Location input
  final Rx<TextEditingController> sourceTextEditController =
      TextEditingController().obs;
  final Rx<TextEditingController> dropoffTextEditController =
      TextEditingController().obs;

  // Selected date
  Rx<DateTime> selectedDate = DateTime.now().obs;
  Rx<DateTime> returnDate = DateTime.now().add(const Duration(days: 1)).obs;

  // Vehicle list + selected vehicle
  RxList<RentalVehicleType> vehicleTypes = <RentalVehicleType>[].obs;
  Rx<RentalVehicleType?> selectedVehicleType = Rx<RentalVehicleType?>(null);

  RxList<RentalPackageModel> rentalPackages = <RentalPackageModel>[].obs;
  Rx<RentalPackageModel?> selectedPackage = Rx<RentalPackageModel?>(null);

  Rx<UserModel> userModel = UserModel().obs;

  final RxString driverLicensePath = ''.obs;
  final RxString identityDocumentPath = ''.obs;
  final RxBool cgvAccepted = false.obs;
  final ImagePicker _imagePicker = ImagePicker();

  final Rx<gmaps.LatLng> departureLatLong = gmaps.LatLng(0.0, 0.0).obs;
  final Rx<latlong.LatLng> departureLatLongOsm = latlong.LatLng(0.0, 0.0).obs;
  final Rx<gmaps.LatLng> dropoffLatLong = gmaps.LatLng(0.0, 0.0).obs;
  final Rx<latlong.LatLng> dropoffLatLongOsm = latlong.LatLng(0.0, 0.0).obs;

  @override
  void onInit() {
    super.onInit();
    if (Constant.userModel != null) {
      userModel.value = Constant.userModel!;
    }
    reloadForSection();
    fetchCurrentLocation();
  }

  Future<void> reloadForSection() async {
    final section = Constant.sectionConstantModel;
    // ignore: avoid_print
    print(
      "[SECTION_RECEIVED] screen=Rental sectionId=${section?.id} sectionName=${section?.name} type=${section?.serviceType}",
    );
    // ignore: avoid_print
    print("[SECTION_LOAD] screen=Rental sectionId=${section?.id}");
    vehicleTypes.clear();
    rentalPackages.clear();
    bannerTopHome.clear();
    selectedVehicleType.value = null;
    selectedPackage.value = null;
    await FireStoreUtils.getHomeTopBanner().then((value) {
      bannerTopHome.value = value;
    });
    await getVehicleType();
  }

  void fetchCurrentLocation() async {
    try {
      Position? position = await Utils.getCurrentLocation();
      if (position != null) {
        Constant.currentLocation = position;

        // Set default coordinates for Google or OSM
        departureLatLong.value = gmaps.LatLng(
          position.latitude,
          position.longitude,
        );
        departureLatLongOsm.value = latlong.LatLng(
          position.latitude,
          position.longitude,
        );
        dropoffLatLong.value = gmaps.LatLng(
          position.latitude,
          position.longitude,
        );
        dropoffLatLongOsm.value = latlong.LatLng(
          position.latitude,
          position.longitude,
        );

        // Get readable address
        String address = await Utils.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
        sourceTextEditController.value.text = address;
        dropoffTextEditController.value.text = address;
      }
    } catch (e) {
      ShowToastDialog.showToast("Unable to fetch current location".tr);
    }
  }

  /// Fetch Vehicle Types
  Future<void> getVehicleType() async {
    isLoading.value = true;
    await FireStoreUtils.getRentalVehicleType().then((value) async {
      vehicleTypes.value = value;
      if (vehicleTypes.isNotEmpty) {
        selectedVehicleType.value = vehicleTypes[0];
        await getRentalPackage();
      }
    });
    isLoading.value = false;
  }

  /// Date Picker
  Future<void> pickDateTime(
    BuildContext context, {
    bool isReturn = false,
  }) async {
    final DateTime now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isReturn ? returnDate.value : selectedDate.value,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return;
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime == null) return;
    final DateTime pickedDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    if (!pickedDateTime.isAfter(now)) {
      ShowToastDialog.showToast("Please select a future date & time".tr);
      return;
    }

    if (isReturn) {
      if (!pickedDateTime.isAfter(selectedDate.value)) {
        ShowToastDialog.showToast(
          "La date de retour doit être après la récupération".tr,
        );
        return;
      }
      returnDate.value = pickedDateTime;
    } else {
      selectedDate.value = pickedDateTime;
      if (!returnDate.value.isAfter(selectedDate.value)) {
        returnDate.value = selectedDate.value.add(const Duration(days: 1));
      }
    }
  }

  Future<void> getRentalPackage() async {
    await FireStoreUtils.getRentalPackage(
      selectedVehicleType.value!.id.toString(),
    ).then((value) {
      rentalPackages.value = value;
      if (rentalPackages.isNotEmpty) {
        selectedPackage.value = rentalPackages[0];
      }
    });
  }

  Future<void> pickRentalDocument({required bool isLicense}) async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );
    if (image == null) return;
    if (isLicense) {
      driverLicensePath.value = image.path;
    } else {
      identityDocumentPath.value = image.path;
    }
  }

  double getTotalPrice() {
    return packageBasePrice() * getRentalDays();
  }

  double getDepositAmount() => getTotalPrice() * 0.5;

  double getRemainingAmount() => getTotalPrice() * 0.5;

  double packageBasePrice() {
    return double.tryParse(
          selectedPackage.value?.baseFare?.toString() ?? '0',
        ) ??
        0;
  }

  double packageIncludedHours() {
    return double.tryParse(
          selectedPackage.value?.includedHours?.toString() ?? '0',
        ) ??
        0;
  }

  double packageIncludedDistance() {
    return double.tryParse(
          selectedPackage.value?.includedDistance?.toString() ?? '0',
        ) ??
        0;
  }

  double packageExtraKmPrice() {
    return double.tryParse(
          selectedPackage.value?.extraKmFare?.toString() ?? '0',
        ) ??
        0;
  }

  double packageExtraMinutePrice() {
    return double.tryParse(
          selectedPackage.value?.extraMinuteFare?.toString() ?? '0',
        ) ??
        0;
  }

  String includedDistanceLabel() {
    final includedDistance = packageIncludedDistance();
    if (includedDistance == -1) {
      return "Kilométrage illimité".tr;
    }
    return "${includedDistance.toStringAsFixed(includedDistance.truncateToDouble() == includedDistance ? 0 : 1)} ${Constant.distanceType} inclus";
  }

  int getRentalDays() {
    final minutes = returnDate.value.difference(selectedDate.value).inMinutes;
    if (minutes <= 0) {
      return 1;
    }
    return (minutes / (24 * 60)).ceil().clamp(1, 9999);
  }

  Future<String> _uploadRentalDocument(String path, String type) async {
    final file = File(path);
    final fileName = file.path.split('/').last;
    return Constant.uploadUserImageToFireStorage(
      file,
      "rentalDocuments/${FireStoreUtils.getCurrentUid()}/${DateTime.now().millisecondsSinceEpoch}_$type",
      fileName,
    );
  }

  Future<void> completeOrder() async {
    DestinationLocation sourceLocation = DestinationLocation(
      latitude:
          Constant.selectedMapType == 'osm'
              ? departureLatLongOsm.value.latitude
              : departureLatLong.value.latitude,
      longitude:
          Constant.selectedMapType == 'osm'
              ? departureLatLongOsm.value.longitude
              : departureLatLong.value.longitude,
    );
    DestinationLocation dropLocation = DestinationLocation(
      latitude:
          Constant.selectedMapType == 'osm'
              ? dropoffLatLongOsm.value.latitude
              : dropoffLatLong.value.latitude,
      longitude:
          Constant.selectedMapType == 'osm'
              ? dropoffLatLongOsm.value.longitude
              : dropoffLatLong.value.longitude,
    );

    // ignore: avoid_print
    print("=====>");
    // ignore: avoid_print
    print(sourceTextEditController.value.text);

    isUploadingDocuments.value = true;
    ShowToastDialog.showLoader("Envoi des documents...".tr);
    String licenseUrl = '';
    String identityUrl = '';
    try {
      licenseUrl = await _uploadRentalDocument(
        driverLicensePath.value,
        'license',
      );
      identityUrl = await _uploadRentalDocument(
        identityDocumentPath.value,
        'identity',
      );
    } catch (e) {
      ShowToastDialog.closeLoader();
      isUploadingDocuments.value = false;
      ShowToastDialog.showToast(
        "Impossible d'envoyer les documents. Réessayez.".tr,
      );
      return;
    }
    ShowToastDialog.closeLoader();
    isUploadingDocuments.value = false;

    RentalOrderModel rentalOrderModel = RentalOrderModel();
    rentalOrderModel.id = Constant.getUuid();
    rentalOrderModel.authorID = userModel.value.id;
    rentalOrderModel.author = userModel.value;
    rentalOrderModel.rentalVehicleType = selectedVehicleType.value;
    rentalOrderModel.vehicleId = selectedVehicleType.value!.id;
    rentalOrderModel.sectionId = Constant.sectionConstantModel!.id;
    rentalOrderModel.sourceLocationName = sourceTextEditController.value.text;
    rentalOrderModel.dropoffLocationName = dropoffTextEditController.value.text;
    rentalOrderModel.bookingDateTime = Timestamp.fromDate(selectedDate.value);
    rentalOrderModel.pickupDateTime = Timestamp.fromDate(selectedDate.value);
    rentalOrderModel.returnDateTime = Timestamp.fromDate(returnDate.value);
    rentalOrderModel.expectedReturnDateTime = Timestamp.fromDate(
      returnDate.value,
    );
    rentalOrderModel.paymentMethod = 'manual_wave_orange_money';
    rentalOrderModel.paymentStatus = false;
    rentalOrderModel.paymentStatusDeposit = 'PENDING';
    rentalOrderModel.paymentStatusRemaining = 'PENDING';
    rentalOrderModel.status = 'EN_ATTENTE_PROPRIETAIRE';
    rentalOrderModel.ownerAcceptanceStatus = 'pending';
    rentalOrderModel.subTotal = getTotalPrice().toStringAsFixed(2);
    rentalOrderModel.totalPrice = getTotalPrice().toStringAsFixed(2);
    rentalOrderModel.bookingTotal = getTotalPrice().toStringAsFixed(2);
    rentalOrderModel.depositAmount = getDepositAmount().toStringAsFixed(2);
    rentalOrderModel.remainingAmount = getRemainingAmount().toStringAsFixed(2);
    rentalOrderModel.cashDepositAmount = '0';
    rentalOrderModel.packageId = selectedPackage.value!.id;
    rentalOrderModel.packageName = selectedPackage.value!.name;
    rentalOrderModel.vehicleTypeId = selectedVehicleType.value!.id;
    rentalOrderModel.vehicleTypeName = selectedVehicleType.value!.name;
    rentalOrderModel.basePrice = packageBasePrice().toStringAsFixed(2);
    rentalOrderModel.reservedDays = getRentalDays();
    rentalOrderModel.gracePeriodMinutes = 30;
    rentalOrderModel.includedHours = packageIncludedHours().toStringAsFixed(2);
    rentalOrderModel.includedDistance = packageIncludedDistance()
        .toStringAsFixed(2);
    rentalOrderModel.extraKmPrice = packageExtraKmPrice();
    rentalOrderModel.extraMinutePrice = packageExtraMinutePrice()
        .toStringAsFixed(2);
    rentalOrderModel.driverLicenseUrl = licenseUrl;
    rentalOrderModel.identityDocumentUrl = identityUrl;
    rentalOrderModel.cgvAccepted = cgvAccepted.value;
    rentalOrderModel.rentalPackageModel = selectedPackage.value;
    rentalOrderModel.taxSetting = Constant.orderProductTaxList;
    rentalOrderModel.createdAt = Timestamp.now();
    rentalOrderModel.sourceLocation = sourceLocation;
    rentalOrderModel.dropoffLocation = dropLocation;
    rentalOrderModel.adminCommission =
        Constant.sectionConstantModel!.adminCommision!.amount;
    rentalOrderModel.adminCommissionType =
        Constant.sectionConstantModel!.adminCommision!.commissionType;
    rentalOrderModel.sourcePoint = G(
      geopoint: GeoPoint(
        sourceLocation.latitude ?? 0.0,
        sourceLocation.longitude ?? 0.0,
      ),
      geohash:
          Geoflutterfire()
              .point(
                latitude: sourceLocation.latitude ?? 0.0,
                longitude: sourceLocation.longitude ?? 0.0,
              )
              .hash,
    );
    rentalOrderModel.zoneId = Constant.getZoneId(
      sourceLocation.latitude ?? 0.0,
      sourceLocation.longitude ?? 0.0,
    );

    Get.back();

    Get.to(
      () => RentalConformationScreen(),
      arguments: {"rentalOrderModel": rentalOrderModel},
    );
  }

  void setDepartureMarker(double lat, double lng) {
    if (Constant.selectedMapType == 'osm') {
      departureLatLongOsm.value = latlong.LatLng(lat, lng);
    } else {
      departureLatLong.value = gmaps.LatLng(lat, lng);
    }
  }
}
