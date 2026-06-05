import 'package:customer/constant/constant.dart';
import 'package:customer/utils/address_formatter.dart';
import 'package:customer/widget/place_picker/selected_location_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:map_launcher/map_launcher.dart';
import '../themes/show_toast_dialog.dart';
import 'package:geocoding/geocoding.dart';
import 'package:location/location.dart' as loc;

class Utils {
  static String? detectedCountryCode;
  static String? detectedCity;
  static Position? lastKnownPosition;
  static double? _lastReverseLat;
  static double? _lastReverseLng;
  static String? _lastReverseShortAddress;
  static String? _lastReverseFullAddress;

  static String? activeCountryCode({bool allowAdminFallback = true}) {
    return AddressFormatter.countryCode(detectedCountryCode) ??
        AddressFormatter.countryCode(Constant.userModel?.countryISOCode) ??
        (allowAdminFallback
            ? AddressFormatter.countryCode(Constant.defaultCountryCode) ??
                AddressFormatter.countryCode(Constant.country)
            : null);
  }

  static bool _movedLessThan(double lat, double lng, double meters) {
    if (_lastReverseLat == null || _lastReverseLng == null) return false;
    return Geolocator.distanceBetween(
          _lastReverseLat!,
          _lastReverseLng!,
          lat,
          lng,
        ) <
        meters;
  }

  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      await loc.Location().requestService();
      ShowToastDialog.showToast("Service localisation désactivé".tr);
      return null;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        ShowToastDialog.showToast("Choisir une adresse".tr);
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      ShowToastDialog.showToast("Choisir une adresse".tr);
      return null;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    try {
      Position? position;
      for (var attempt = 0; attempt < 3; attempt++) {
        final current = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 15),
          ),
        );
        position = current;
        if (current.accuracy <= 50) {
          break;
        }
      }
      if (position == null) return null;
      lastKnownPosition = position;
      // ignore: avoid_print
      print(
        "[LOCATION] lat=${position.latitude} lng=${position.longitude} accuracy=${position.accuracy}",
      );
      return position;
    } catch (e) {
      ShowToastDialog.showToast("Choisir une adresse".tr);
      return null;
    }
  }

  static Future<String> getAddressFromCoordinates(
    double lat,
    double lng,
  ) async {
    if (_movedLessThan(lat, lng, 10) &&
        (_lastReverseShortAddress ?? '').isNotEmpty) {
      return _lastReverseShortAddress!;
    }
    try {
      List<Placemark> placemarks = [];
      for (var attempt = 0; attempt < 3; attempt++) {
        placemarks = await placemarkFromCoordinates(lat, lng);
        if (placemarks.isNotEmpty) break;
        await Future.delayed(const Duration(milliseconds: 350));
      }
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        final fullAddress = fullAddressFromPlacemark(place);
        final shortAddress = shortAddressFromPlacemark(place);
        detectedCountryCode =
            AddressFormatter.countryCode(place.isoCountryCode) ??
            AddressFormatter.countryCode(place.country) ??
            detectedCountryCode;
        detectedCity =
            place.locality?.trim().isNotEmpty == true
                ? place.locality!.trim()
                : place.subAdministrativeArea?.trim();
        _lastReverseLat = lat;
        _lastReverseLng = lng;
        _lastReverseShortAddress = AddressFormatter.shortAddress(
          shortAddress,
          fallback: "Position actuelle".tr,
        );
        _lastReverseFullAddress = fullAddress;
        // ignore: avoid_print
        print(
          "[REVERSE_GEOCODE] lat=$lat lng=$lng country=$detectedCountryCode city=$detectedCity full=$fullAddress short=$_lastReverseShortAddress",
        );
        return _lastReverseShortAddress!;
      }
      return "Position actuelle".tr;
    } catch (e) {
      if (_lastReverseFullAddress != null &&
          _lastReverseFullAddress!.isNotEmpty) {
        return _lastReverseShortAddress ?? "Position actuelle".tr;
      }
      return "Position actuelle".tr;
    }
  }

  static Future<void> redirectMap({
    required String name,
    required double latitude,
    required double longLatitude,
  }) async {
    if (Constant.mapType == "google") {
      bool? isAvailable = await MapLauncher.isMapAvailable(MapType.google);
      if (isAvailable == true) {
        await MapLauncher.showDirections(
          mapType: MapType.google,
          directionsMode: DirectionsMode.driving,
          destinationTitle: name,
          destination: Coords(latitude, longLatitude),
        );
      } else {
        ShowToastDialog.showToast("Google map is not installed".tr);
      }
    } else if (Constant.mapType == "googleGo") {
      bool? isAvailable = await MapLauncher.isMapAvailable(MapType.googleGo);
      if (isAvailable == true) {
        await MapLauncher.showDirections(
          mapType: MapType.googleGo,
          directionsMode: DirectionsMode.driving,
          destinationTitle: name,
          destination: Coords(latitude, longLatitude),
        );
      } else {
        ShowToastDialog.showToast("Google Go map is not installed".tr);
      }
    } else if (Constant.mapType == "waze") {
      bool? isAvailable = await MapLauncher.isMapAvailable(MapType.waze);
      if (isAvailable == true) {
        await MapLauncher.showDirections(
          mapType: MapType.waze,
          directionsMode: DirectionsMode.driving,
          destinationTitle: name,
          destination: Coords(latitude, longLatitude),
        );
      } else {
        ShowToastDialog.showToast("Waze is not installed".tr);
      }
    } else if (Constant.mapType == "mapswithme") {
      bool? isAvailable = await MapLauncher.isMapAvailable(MapType.mapswithme);
      if (isAvailable == true) {
        await MapLauncher.showDirections(
          mapType: MapType.mapswithme,
          directionsMode: DirectionsMode.driving,
          destinationTitle: name,
          destination: Coords(latitude, longLatitude),
        );
      } else {
        ShowToastDialog.showToast("Mapswithme is not installed".tr);
      }
    } else if (Constant.mapType == "yandexNavi") {
      bool? isAvailable = await MapLauncher.isMapAvailable(MapType.yandexNavi);
      if (isAvailable == true) {
        await MapLauncher.showDirections(
          mapType: MapType.yandexNavi,
          directionsMode: DirectionsMode.driving,
          destinationTitle: name,
          destination: Coords(latitude, longLatitude),
        );
      } else {
        ShowToastDialog.showToast("YandexNavi is not installed".tr);
      }
    } else if (Constant.mapType == "yandexMaps") {
      bool? isAvailable = await MapLauncher.isMapAvailable(MapType.yandexMaps);
      if (isAvailable == true) {
        await MapLauncher.showDirections(
          mapType: MapType.yandexMaps,
          directionsMode: DirectionsMode.driving,
          destinationTitle: name,
          destination: Coords(latitude, longLatitude),
        );
      } else {
        ShowToastDialog.showToast("yandexMaps map is not installed".tr);
      }
    }
  }

  static String formatAddress({
    required SelectedLocationModel selectedLocation,
  }) {
    if ((selectedLocation.shortAddress ?? '').trim().isNotEmpty) {
      return AddressFormatter.shortAddress(selectedLocation.shortAddress);
    }
    return AddressFormatter.shortAddress(selectedLocation.address);
  }

  static String fullAddressFromPlacemark(Placemark? place) {
    return AddressFormatter.fullAddressFromPlacemark(place);
  }

  static String shortAddressFromPlacemark(Placemark? place) {
    return AddressFormatter.shortAddress(place);
  }

  static String shortAddressFromText(
    String? raw, {
    String fallback = AddressFormatter.defaultFallback,
  }) {
    return AddressFormatter.shortAddress(raw, fallback: fallback);
  }
}
