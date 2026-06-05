import 'package:customer/widget/place_picker/selected_location_model.dart';
import 'package:customer/utils/utils.dart';
import 'package:customer/models/user_model.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/material.dart';

class LocationController extends GetxController {
  GoogleMapController? mapController;
  var selectedLocation = Rxn<LatLng>();
  var selectedPlaceAddress = Rxn<Placemark>();
  var address = "Choisir une adresse".tr.obs;
  var fullAddress = ''.obs;
  var placeId = RxnString();
  TextEditingController searchController = TextEditingController();

  RxString zipCode = ''.obs;

  @override
  void onInit() {
    super.onInit();
    getArgument();
    getCurrentLocation();
  }

  void getArgument() {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      zipCode.value = argumentData['zipCode'] ?? '';
      if (zipCode.value.isNotEmpty) {
        getCoordinatesFromZipCode(zipCode.value);
      }
    }
    update();
  }

  Future<void> getCurrentLocation() async {
    try {
      final position = await Utils.getCurrentLocation();
      if (position == null) {
        address.value = "Choisir une adresse".tr;
        fullAddress.value = '';
        return;
      }
      selectedLocation.value = LatLng(position.latitude, position.longitude);

      if (mapController != null) {
        mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(selectedLocation.value!, 15),
        );
      }

      await getAddressFromLatLng(selectedLocation.value!);
    } catch (e) {
      debugPrint("Error fetching current location: $e");
    }
  }

  Future<void> getAddressFromLatLng(LatLng latLng) async {
    try {
      List<Placemark> placemarks = [];
      for (var attempt = 0; attempt < 3; attempt++) {
        placemarks = await placemarkFromCoordinates(
          latLng.latitude,
          latLng.longitude,
        );
        if (placemarks.isNotEmpty) break;
        await Future.delayed(const Duration(milliseconds: 350));
      }
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        selectedPlaceAddress.value = place;
        Utils.detectedCountryCode =
            place.isoCountryCode?.trim().isNotEmpty == true
                ? place.isoCountryCode
                : Utils.detectedCountryCode;
        Utils.detectedCity =
            place.locality?.trim().isNotEmpty == true
                ? place.locality!.trim()
                : place.subAdministrativeArea?.trim();
        address.value = Utils.shortAddressFromPlacemark(place);
        fullAddress.value = Utils.fullAddressFromPlacemark(place);
        // ignore: avoid_print
        print(
          "[REVERSE_GEOCODE] lat=${latLng.latitude} lng=${latLng.longitude} country=${Utils.detectedCountryCode} city=${Utils.detectedCity} full=${fullAddress.value} short=${address.value}",
        );
      } else {
        address.value = "Position actuelle".tr;
        fullAddress.value = '';
      }
    } catch (e) {
      debugPrint("Error getting address: $e");
      address.value = "Position actuelle".tr;
      fullAddress.value = '';
    }
  }

  void onMapMoved(CameraPosition position) {
    selectedLocation.value = position.target;
  }

  Future<void> getCoordinatesFromZipCode(String zipCode) async {
    try {
      List<Location> locations = await locationFromAddress(zipCode);
      if (locations.isNotEmpty) {
        selectedLocation.value = LatLng(
          locations.first.latitude,
          locations.first.longitude,
        );
        // ignore: avoid_print
        print("[ADDRESS_SEARCH] query=$zipCode");
      }
    } catch (e) {
      debugPrint("Error getting coordinates for ZIP code: $e");
    }
  }

  void confirmLocation() {
    if (selectedLocation.value != null) {
      SelectedLocationModel selectedLocationModel = SelectedLocationModel(
        address: selectedPlaceAddress.value,
        latLng: selectedLocation.value,
        fullAddress:
            fullAddress.value.isNotEmpty ? fullAddress.value : address.value,
        shortAddress: address.value,
        placeId: placeId.value,
      );
      // ignore: avoid_print
      print(
        "[ADDRESS_PROPAGATED] screen=LocationPicker short=${selectedLocationModel.shortAddress} lat=${selectedLocation.value!.latitude} lng=${selectedLocation.value!.longitude}",
      );
      Get.back(result: selectedLocationModel);
    }
  }

  Future<void> useCurrentLocation() async {
    await getCurrentLocation();
  }

  void selectSavedAddress(ShippingAddress shippingAddress) {
    final latitude = shippingAddress.location?.latitude;
    final longitude = shippingAddress.location?.longitude;
    if (latitude == null || longitude == null) {
      return;
    }
    selectedLocation.value = LatLng(latitude, longitude);
    selectedPlaceAddress.value = null;
    fullAddress.value = shippingAddress.getFullAddress();
    address.value = Utils.shortAddressFromText(
      shippingAddress.getFullAddress(),
      fallback: "Choisir une adresse".tr,
    );
    // ignore: avoid_print
    print(
      "[ADDRESS_PROPAGATED] screen=SavedAddress short=${address.value} lat=$latitude lng=$longitude",
    );
    placeId.value = null;
  }
}
