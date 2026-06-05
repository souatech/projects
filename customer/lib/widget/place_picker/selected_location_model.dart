import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SelectedLocationModel {
  Placemark? address;
  LatLng? latLng;
  String? fullAddress;
  String? shortAddress;
  String? placeId;

  SelectedLocationModel({
    this.address,
    this.latLng,
    this.fullAddress,
    this.shortAddress,
    this.placeId,
  });

  SelectedLocationModel.fromJson(Map<String, dynamic> json) {
    address = json['address'];
    latLng = json['latLng'];
    fullAddress = json['fullAddress'];
    shortAddress = json['shortAddress'];
    placeId = json['placeId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['address'] = address;
    data['latLng'] = latLng;
    data['fullAddress'] = fullAddress;
    data['shortAddress'] = shortAddress;
    data['placeId'] = placeId;
    return data;
  }
}
