import 'package:cloud_firestore/cloud_firestore.dart';

class RentalPackageModel {
  String? id;
  String? vehicleTypeId;
  String? description;
  String? ordering;
  bool? published;
  String? extraKmFare;
  String? extraKmPrice;
  String? includedHours;
  String? extraMinuteFare;
  String? extraMinutePrice;
  String? baseFare;
  String? price;
  Timestamp? createdAt;
  String? name;
  String? includedDistance;

  RentalPackageModel({
    this.id,
    this.vehicleTypeId,
    this.description,
    this.ordering,
    this.published,
    this.extraKmFare,
    this.extraKmPrice,
    this.includedHours,
    this.extraMinuteFare,
    this.extraMinutePrice,
    this.baseFare,
    this.price,
    this.createdAt,
    this.name,
    this.includedDistance,
  });

  RentalPackageModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    vehicleTypeId = json['vehicleTypeId'];
    description = json['description'];
    ordering = json['ordering'];
    published = json['published'];
    extraKmFare =
        json['extraKmFare']?.toString() ?? json['extraKmPrice']?.toString();
    extraKmPrice =
        json['extraKmPrice']?.toString() ?? json['extraKmFare']?.toString();
    includedHours = json['includedHours'];
    extraMinuteFare =
        json['extraMinuteFare']?.toString() ??
        json['extraMinutePrice']?.toString();
    extraMinutePrice =
        json['extraMinutePrice']?.toString() ??
        json['extraMinuteFare']?.toString();
    baseFare = json['baseFare']?.toString() ?? json['price']?.toString();
    price = json['price']?.toString() ?? json['baseFare']?.toString();
    createdAt = json['createdAt'];
    name = json['name'];
    includedDistance = json['includedDistance'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['vehicleTypeId'] = vehicleTypeId;
    data['description'] = description;
    data['ordering'] = ordering;
    data['published'] = published;
    data['extraKmFare'] = extraKmFare;
    data['extraKmPrice'] = extraKmPrice ?? extraKmFare;
    data['includedHours'] = includedHours;
    data['extraMinuteFare'] = extraMinuteFare;
    data['extraMinutePrice'] = extraMinutePrice ?? extraMinuteFare;
    data['baseFare'] = baseFare;
    data['price'] = price ?? baseFare;
    data['createdAt'] = createdAt;
    data['name'] = name;
    data['includedDistance'] = includedDistance;
    return data;
  }
}
