import 'dart:convert';
import 'dart:async';
import 'package:customer/utils/address_formatter.dart';
import 'package:customer/widget/osm_map/place_model.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import '../../utils/utils.dart';
import 'package:latlong2/latlong.dart';

class OSMMapController extends GetxController {
  final mapController = MapController();
  // Store only one picked place instead of multiple
  var pickedPlace = Rxn<PlaceModel>(); // Use Rxn to hold a nullable value
  var searchResults = [].obs;
  Timer? _searchDebounce;

  Future<void> searchPlace(String query) async {
    if (query.length < 3) {
      _searchDebounce?.cancel();
      searchResults.clear();
      return;
    }
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _searchPlaceNow(query);
    });
  }

  Future<void> _searchPlaceNow(String query) async {
    // ignore: avoid_print
    print("[ADDRESS_SEARCH] query=$query");

    final countryCode = _activeCountryCode();
    final data = await _searchNominatim(query, countryCode: countryCode);
    if (data.isEmpty && countryCode != null) {
      searchResults.value = await _searchNominatim(query);
      return;
    }
    searchResults.value = data;
  }

  Future<List<dynamic>> _searchNominatim(
    String query, {
    String? countryCode,
  }) async {
    final params = {
      'q': query,
      'format': 'json',
      'addressdetails': '1',
      'limit': '10',
      'accept-language': 'fr',
      if (countryCode != null) 'countrycodes': countryCode,
      ..._viewBoxParams(),
    };
    final url = Uri.https('nominatim.openstreetmap.org', '/search', params);

    final response = await http.get(
      url,
      headers: {
        'User-Agent': 'FlutterMapApp/1.0 (menil.siddhiinfosoft@gmail.com)',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List) return data;
    }
    return [];
  }

  void selectSearchResult(Map<String, dynamic> place) {
    final lat = double.parse(place['lat']);
    final lon = double.parse(place['lon']);
    final fullAddress = place['display_name']?.toString() ?? '';
    final addressDetails =
        place['address'] is Map<String, dynamic>
            ? place['address'] as Map<String, dynamic>
            : null;
    final address = AddressFormatter.shortAddress(
      fullAddress,
      addressDetails: addressDetails,
    );
    Utils.detectedCountryCode =
        AddressFormatter.countryCode(
          addressDetails?['country_code']?.toString(),
        ) ??
        Utils.detectedCountryCode;
    Utils.detectedCity =
        addressDetails?['city']?.toString() ??
        addressDetails?['town']?.toString() ??
        addressDetails?['village']?.toString() ??
        Utils.detectedCity;
    // ignore: avoid_print
    print(
      "[ADDRESS_RESULT] full=$fullAddress short=$address lat=$lat lng=$lon",
    );

    // Store only the selected place
    pickedPlace.value = PlaceModel(
      coordinates: LatLng(lat, lon),
      address: address,
      fullAddress: fullAddress,
    );
    searchResults.clear();
  }

  void addLatLngOnly(LatLng coords) async {
    final result = await _getAddressFromLatLng(coords);
    final address = AddressFormatter.shortAddress(
      result.displayName,
      addressDetails: result.addressDetails,
      fallback: 'Position actuelle'.tr,
    );
    Utils.detectedCountryCode =
        AddressFormatter.countryCode(
          result.addressDetails?['country_code']?.toString(),
        ) ??
        Utils.detectedCountryCode;
    Utils.detectedCity =
        result.addressDetails?['city']?.toString() ??
        result.addressDetails?['town']?.toString() ??
        result.addressDetails?['village']?.toString() ??
        Utils.detectedCity;
    // ignore: avoid_print
    print(
      "[REVERSE_GEOCODE] lat=${coords.latitude} lng=${coords.longitude} full=${result.displayName} short=$address",
    );
    pickedPlace.value = PlaceModel(
      coordinates: coords,
      address: address,
      fullAddress: result.displayName,
    );
  }

  Future<_ReverseAddressResult> _getAddressFromLatLng(LatLng coords) async {
    final url = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'lat': coords.latitude.toString(),
      'lon': coords.longitude.toString(),
      'format': 'json',
      'addressdetails': '1',
      'accept-language': 'fr',
    });

    for (var attempt = 0; attempt < 3; attempt++) {
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'FlutterMapApp/1.0 (menil.siddhiinfosoft@gmail.com)',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final displayName = data['display_name']?.toString() ?? '';
        if (displayName.isNotEmpty || data['address'] != null) {
          return _ReverseAddressResult(
            displayName: displayName,
            addressDetails:
                data['address'] is Map<String, dynamic>
                    ? data['address'] as Map<String, dynamic>
                    : null,
          );
        }
      }
      await Future.delayed(const Duration(milliseconds: 350));
    }
    return const _ReverseAddressResult(displayName: '');
  }

  String? _activeCountryCode() {
    return Utils.activeCountryCode();
  }

  Map<String, String> _viewBoxParams() {
    final position = Utils.lastKnownPosition;
    if (position == null) return {};
    const delta = 0.45;
    final left = position.longitude - delta;
    final right = position.longitude + delta;
    final top = position.latitude + delta;
    final bottom = position.latitude - delta;
    return {'viewbox': '$left,$top,$right,$bottom', 'bounded': '0'};
  }

  void clearAll() {
    pickedPlace.value = null; // Clear the selected place
  }

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    getCurrentLocation();
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    super.onClose();
  }

  Future<void> getCurrentLocation() async {
    Position? location = await Utils.getCurrentLocation();
    if (location == null) {
      pickedPlace.value = null;
      return;
    }
    addLatLngOnly(LatLng(location.latitude, location.longitude));
  }
}

class _ReverseAddressResult {
  final String displayName;
  final Map<String, dynamic>? addressDetails;

  const _ReverseAddressResult({required this.displayName, this.addressDetails});
}
