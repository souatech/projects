import 'package:latlong2/latlong.dart';

class PlaceModel {
  final LatLng coordinates;
  final String address;
  final String? fullAddress;

  PlaceModel({
    required this.coordinates,
    required this.address,
    this.fullAddress,
  });

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    return PlaceModel(
      coordinates: LatLng(json['lat'], json['lng']),
      address: json['address'],
      fullAddress: json['fullAddress'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': coordinates.latitude,
      'lng': coordinates.longitude,
      'address': address,
      'fullAddress': fullAddress,
    };
  }

  @override
  String toString() {
    return 'Place(lat: ${coordinates.latitude}, lng: ${coordinates.longitude}, address: $address)';
  }
}
