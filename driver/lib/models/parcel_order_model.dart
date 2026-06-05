import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/models/tax_model.dart';
import 'package:driver/models/user_model.dart';
import 'package:driver/models/vendor_model.dart';

class ParcelOrderModel {
  UserModel? author;
  UserModel? driver;

  LocationInformation? sender;
  Timestamp? senderPickupDateTime;
  String? id;
  String? driverId;

  UserLocation? receiverLatLong;
  bool? paymentCollectByReceiver;
  String? adminCommissionType;
  List<dynamic>? rejectedByDrivers;
  String? adminCommission;
  List<dynamic>? parcelImages;
  String? parcelWeight;
  String? discountType;
  String? discountLabel;
  LocationInformation? receiver;
  String? paymentMethod;
  String? distance;
  Timestamp? createdAt;
  bool? isSchedule;
  String? subTotal;
  Timestamp? triggerDelevery;
  String? status;
  String? parcelType;
  bool? sendToDriver;
  String? sectionId;
  UserLocation? senderLatLong;
  String? authorID;
  String? parcelWeightCharge;
  String? parcelCategoryID;
  String? discount;
  Timestamp? receiverPickupDateTime;
  String? note;
  String? receiverNote;
  String? senderZoneId;
  String? receiverZoneId;
  G? sourcePoint;
  G? destinationPoint;
  List<ParcelStatus>? statusHistory;
  String? platformFee;
  List<TaxModel>? taxSetting;
  List<TaxModel>? platformTax;
  String? collectedPaymentMethod;
  String? collectedByDriverId;
  Timestamp? collectedAt;
  String? collectedPaymentStatus;
  double? driverEarning;
  String? driverPayoutStatus;
  double? cashToRemit;
  String? cashRemittanceStatus;
  String? collectionFee;
  bool? customerPaysFullAmountToDriver;
  String? gpAdminCommission;
  String? gpAdminCommissionType;
  double? gpEarning;
  double? gpAmountCollectedByDriver;
  double? gpCashToRemit;
  String? gpPaymentStatus;
  String? gpPayoutStatus;
  double? driverAdminCommAmount;
  double? gpAdminCommAmount;

  ParcelOrderModel({
    this.author,
    this.sender,
    this.senderPickupDateTime,
    this.id,
    this.driverId,
    this.receiverLatLong,
    this.paymentCollectByReceiver,
    this.adminCommissionType,
    this.rejectedByDrivers,
    this.adminCommission,
    this.parcelImages,
    this.parcelWeight,
    this.discountType,
    this.discountLabel,
    this.receiver,
    this.paymentMethod,
    this.distance,
    this.createdAt,
    this.isSchedule,
    this.subTotal,
    this.triggerDelevery,
    this.status,
    this.parcelType,
    this.sendToDriver,
    this.sectionId,
    this.senderLatLong,
    this.authorID,
    this.parcelWeightCharge,
    this.parcelCategoryID,
    this.discount,
    this.receiverPickupDateTime,
    this.note,
    this.receiverNote,
    this.senderZoneId,
    this.sourcePoint,
    this.destinationPoint,
    this.receiverZoneId,
    this.driver,
    this.statusHistory,
    this.platformFee,
    this.taxSetting,
    this.platformTax,
    this.collectedPaymentMethod,
    this.collectedByDriverId,
    this.collectedAt,
    this.collectedPaymentStatus,
    this.driverEarning,
    this.driverPayoutStatus,
    this.cashToRemit,
    this.cashRemittanceStatus,
    this.collectionFee,
    this.customerPaysFullAmountToDriver,
    this.gpAdminCommission,
    this.gpAdminCommissionType,
    this.gpEarning,
    this.gpAmountCollectedByDriver,
    this.gpCashToRemit,
    this.gpPaymentStatus,
    this.gpPayoutStatus,
    this.driverAdminCommAmount,
    this.gpAdminCommAmount,
  });

  ParcelOrderModel.fromJson(Map<String, dynamic> json) {
    author = json['author'] != null ? UserModel.fromJson(json['author']) : null;
    driver = json['driver'] != null ? UserModel.fromJson(json['driver']) : null;
    sender = json['sender'] != null ? LocationInformation.fromJson(json['sender']) : null;
    senderPickupDateTime = json['senderPickupDateTime'];
    id = json['id'];
    driverId = json['driverId'];
    receiverLatLong = json['receiverLatLong'] != null ? UserLocation.fromJson(json['receiverLatLong']) : null;
    paymentCollectByReceiver = json['paymentCollectByReceiver'];
    adminCommissionType = json['adminCommissionType'];
    rejectedByDrivers = json['rejectedByDrivers'] ?? [];
    adminCommission = json['adminCommission'];
    parcelImages = json['parcelImages'] ?? [];
    parcelWeight = json['parcelWeight'];
    discountType = json['discountType'];
    discountLabel = json['discountLabel'];
    receiver = json['receiver'] != null ? LocationInformation.fromJson(json['receiver']) : null;
    paymentMethod = json['payment_method'];
    distance = json['distance'];
    createdAt = json['createdAt'];
    isSchedule = json['isSchedule'];
    subTotal = json['subTotal'];
    triggerDelevery = json['trigger_delevery'];
    status = json['status'];
    parcelType = json['parcelType'];
    sendToDriver = json['sendToDriver'];
    sectionId = json['sectionId'];
    senderLatLong = json['senderLatLong'] != null ? UserLocation.fromJson(json['senderLatLong']) : null;
    authorID = json['authorID'];
    parcelWeightCharge = json['parcelWeightCharge'];
    parcelCategoryID = json['parcelCategoryID'];
    discount = json['discount'];
    receiverPickupDateTime = json['receiverPickupDateTime'];
    note = json['note'];
    senderZoneId = json['senderZoneId'];
    receiverZoneId = json['receiverZoneId'];
    receiverNote = json['receiverNote'];
    sourcePoint = json['sourcePoint'] != null ? G.fromJson(json['sourcePoint']) : null;
    destinationPoint = json['destinationPoint'] != null ? G.fromJson(json['destinationPoint']) : null;
    platformFee = json['platformFee'];
    if (json['taxSetting'] != null) {
      taxSetting = <TaxModel>[];
      json['taxSetting'].forEach((v) {
        taxSetting!.add(TaxModel.fromJson(v));
      });
    }
    if (json['platformTax'] != null) {
      platformTax = <TaxModel>[];
      json['platformTax'].forEach((v) {
        platformTax!.add(TaxModel.fromJson(v));
      });
    }
    collectedPaymentMethod = json['collected_payment_method'];
    collectedByDriverId = json['collected_by_driver_id'];
    collectedAt = json['collected_at'];
    collectedPaymentStatus = json['collected_payment_status'];
    driverEarning = (json['driver_earning'] as num?)?.toDouble();
    driverPayoutStatus = json['driver_payout_status'];
    cashToRemit = (json['cash_to_remit'] as num?)?.toDouble();
    cashRemittanceStatus = json['cash_remittance_status'];
    collectionFee = json['collectionFee'];
    customerPaysFullAmountToDriver = json['customerPaysFullAmountToDriver'];
    gpAdminCommission = json['gpAdminCommission'];
    gpAdminCommissionType = json['gpAdminCommissionType'];
    gpEarning = (json['gp_earning'] as num?)?.toDouble();
    gpAmountCollectedByDriver = (json['gp_amount_collected_by_driver'] as num?)?.toDouble();
    gpCashToRemit = (json['gp_cash_to_remit'] as num?)?.toDouble();
    gpPaymentStatus = json['gp_payment_status'];
    gpPayoutStatus = json['gp_payout_status'];
    driverAdminCommAmount = (json['driver_admin_comm_amount'] as num?)?.toDouble();
    gpAdminCommAmount = (json['gp_admin_comm_amount'] as num?)?.toDouble();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (author != null) {
      data['author'] = author!.toJson();
    }
    if (driver != null) {
      data['driver'] = driver!.toJson();
    }
    if (sender != null) {
      data['sender'] = sender!.toJson();
    }
    data['senderPickupDateTime'] = senderPickupDateTime;
    data['id'] = id;
    if (receiverLatLong != null) {
      data['receiverLatLong'] = receiverLatLong!.toJson();
    }
    data['paymentCollectByReceiver'] = paymentCollectByReceiver;
    data['driverId'] = driverId;
    data['adminCommissionType'] = adminCommissionType;
    data['rejectedByDrivers'] = rejectedByDrivers;
    data['adminCommission'] = adminCommission;
    data['parcelImages'] = parcelImages;
    data['parcelWeight'] = parcelWeight;
    data['discountType'] = discountType;
    data['discountLabel'] = discountLabel;
    if (receiver != null) {
      data['receiver'] = receiver!.toJson();
    }
    data['payment_method'] = paymentMethod;
    data['distance'] = distance;
    data['createdAt'] = createdAt;
    data['isSchedule'] = isSchedule;
    data['subTotal'] = subTotal;
    data['trigger_delevery'] = triggerDelevery;
    data['status'] = status;
    data['parcelType'] = parcelType;
    data['sendToDriver'] = sendToDriver;
    data['sectionId'] = sectionId;
    if (senderLatLong != null) {
      data['senderLatLong'] = senderLatLong!.toJson();
    }
    if (sourcePoint != null) {
      data['sourcePoint'] = sourcePoint!.toJson();
    }
    if (destinationPoint != null) {
      data['destinationPoint'] = destinationPoint!.toJson();
    }
    data['authorID'] = authorID;
    data['parcelWeightCharge'] = parcelWeightCharge;
    data['parcelCategoryID'] = parcelCategoryID;
    data['discount'] = discount;
    data['receiverPickupDateTime'] = receiverPickupDateTime;
    data['note'] = note;
    data['senderZoneId'] = senderZoneId;
    data['receiverZoneId'] = receiverZoneId;
    data['receiverNote'] = receiverNote;
    data['platformFee'] = platformFee;
    if (taxSetting != null) {
      data['taxSetting'] = taxSetting!.map((v) => v.toJson()).toList();
    }
    if (platformTax != null) {
      data['platformTax'] = platformTax!.map((v) => v.toJson()).toList();
    }
    data['collected_payment_method'] = collectedPaymentMethod;
    data['collected_by_driver_id'] = collectedByDriverId;
    data['collected_at'] = collectedAt;
    data['collected_payment_status'] = collectedPaymentStatus;
    data['driver_earning'] = driverEarning;
    data['driver_payout_status'] = driverPayoutStatus;
    data['cash_to_remit'] = cashToRemit;
    data['cash_remittance_status'] = cashRemittanceStatus;
    data['collectionFee'] = collectionFee;
    data['customerPaysFullAmountToDriver'] = customerPaysFullAmountToDriver;
    data['gpAdminCommission'] = gpAdminCommission;
    data['gpAdminCommissionType'] = gpAdminCommissionType;
    data['gp_earning'] = gpEarning;
    data['gp_amount_collected_by_driver'] = gpAmountCollectedByDriver;
    data['gp_cash_to_remit'] = gpCashToRemit;
    data['gp_payment_status'] = gpPaymentStatus;
    data['gp_payout_status'] = gpPayoutStatus;
    data['driver_admin_comm_amount'] = driverAdminCommAmount;
    data['gp_admin_comm_amount'] = gpAdminCommAmount;

    return data;
  }
}

class LocationInformation {
  String? address;
  String? name;
  String? phone;

  LocationInformation({this.address, this.name, this.phone});

  LocationInformation.fromJson(Map<String, dynamic> json) {
    address = json['address'];
    name = json['name'];
    phone = json['phone'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['address'] = address;
    data['name'] = name;
    data['phone'] = phone;
    return data;
  }
}

class ParcelStatus {
  final String? status;
  final DateTime? time;

  ParcelStatus({this.status, this.time});

  factory ParcelStatus.fromMap(Map<String, dynamic> map) {
    return ParcelStatus(status: map['status'] as String?, time: map['time'] != null ? (map['time'] as Timestamp).toDate() : null);
  }

  Map<String, dynamic> toMap() {
    return {'status': status, 'time': time != null ? Timestamp.fromDate(time!) : null};
  }
}
