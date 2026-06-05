import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/models/rental_package_model.dart';
import 'package:customer/models/rental_vehicle_type.dart';
import 'package:customer/models/tax_model.dart';
import 'package:customer/models/user_model.dart';
import 'package:customer/models/vendor_model.dart';

class RentalOrderModel {
  String? status;
  List<dynamic>? rejectedByDrivers;
  String? couponId;
  Timestamp? bookingDateTime;
  Timestamp? pickupDateTime;
  Timestamp? returnDateTime;
  Timestamp? expectedReturnDateTime;
  Timestamp? actualReturnDateTime;
  bool? paymentStatus;
  String? discount;
  String? authorID;
  Timestamp? createdAt;
  String? adminCommissionType;
  String? sourceLocationName;
  String? dropoffLocationName;
  List<TaxModel>? taxSetting;
  String? id;
  String? adminCommission;
  String? couponCode;
  String? sectionId;
  String? tipAmount;
  String? vehicleId;
  String? paymentMethod;
  String? paymentStatusDeposit;
  String? paymentStatusRemaining;
  String? totalPrice;
  String? bookingTotal;
  String? depositAmount;
  String? remainingAmount;
  String? cashDepositAmount;
  String? packageId;
  String? packageName;
  String? vehicleTypeId;
  String? vehicleTypeName;
  String? ownerId;
  String? ownerName;
  String? ownerAcceptanceStatus;
  String? basePrice;
  int? reservedDays;
  int? gracePeriodMinutes;
  String? includedHours;
  String? includedDistance;
  String? extraMinutePrice;
  String? driverLicenseUrl;
  String? identityDocumentUrl;
  bool? cgvAccepted;
  int? includedKmPerDay;
  num? extraKmPrice;
  bool? originalDocumentsVerified;
  bool? cashDepositReceived;
  bool? customerSignature;
  bool? cashDepositReturned;
  double? startKm;
  double? returnKm;
  double? usedKm;
  double? includedKm;
  double? extraKm;
  double? extraKmFee;
  double? lateMinutes;
  double? extraMinutesFee;
  double? fuelFee;
  double? finalAmountDue;
  double? alreadyPaidAmount;
  double? remainingDueAmount;
  String? startFuelLevel;
  String? returnFuelLevel;
  String? vehicleCondition;
  String? startOdometerPhoto;
  String? returnOdometerPhoto;
  Timestamp? depositConfirmedAt;
  Timestamp? remainingConfirmedAt;
  Timestamp? ownerAcceptedAt;
  Timestamp? ownerRejectedAt;
  Timestamp? vehicleReleasedAt;
  Timestamp? completedAt;
  List<dynamic>? startPhotos;
  List<dynamic>? returnPhotos;
  RentalVehicleType? rentalVehicleType;
  RentalPackageModel? rentalPackageModel;
  String? otpCode;
  DestinationLocation? sourceLocation;
  DestinationLocation? dropoffLocation;
  UserModel? author;
  UserModel? driver;
  String? driverId;
  String? subTotal;
  Timestamp? startTime;
  Timestamp? endTime;
  String? startKitoMetersReading;
  String? endKitoMetersReading;
  String? zoneId;
  G? sourcePoint;
  String? platformFee;
  List<TaxModel>? platformTax;

  RentalOrderModel({
    this.status,
    this.rejectedByDrivers,
    this.bookingDateTime,
    this.pickupDateTime,
    this.returnDateTime,
    this.expectedReturnDateTime,
    this.actualReturnDateTime,
    this.paymentStatus,
    this.discount,
    this.authorID,
    this.createdAt,
    this.adminCommissionType,
    this.sourceLocationName,
    this.dropoffLocationName,
    this.id,
    this.adminCommission,
    this.couponCode,
    this.couponId,
    this.sectionId,
    this.tipAmount,
    this.vehicleId,
    this.paymentMethod,
    this.paymentStatusDeposit,
    this.paymentStatusRemaining,
    this.totalPrice,
    this.bookingTotal,
    this.depositAmount,
    this.remainingAmount,
    this.cashDepositAmount,
    this.packageId,
    this.packageName,
    this.vehicleTypeId,
    this.vehicleTypeName,
    this.ownerId,
    this.ownerName,
    this.ownerAcceptanceStatus,
    this.basePrice,
    this.reservedDays,
    this.gracePeriodMinutes,
    this.includedHours,
    this.includedDistance,
    this.extraMinutePrice,
    this.driverLicenseUrl,
    this.identityDocumentUrl,
    this.cgvAccepted,
    this.includedKmPerDay,
    this.extraKmPrice,
    this.originalDocumentsVerified,
    this.cashDepositReceived,
    this.customerSignature,
    this.cashDepositReturned,
    this.startKm,
    this.returnKm,
    this.usedKm,
    this.includedKm,
    this.extraKm,
    this.extraKmFee,
    this.lateMinutes,
    this.extraMinutesFee,
    this.fuelFee,
    this.finalAmountDue,
    this.alreadyPaidAmount,
    this.remainingDueAmount,
    this.startFuelLevel,
    this.returnFuelLevel,
    this.vehicleCondition,
    this.startOdometerPhoto,
    this.returnOdometerPhoto,
    this.depositConfirmedAt,
    this.remainingConfirmedAt,
    this.ownerAcceptedAt,
    this.ownerRejectedAt,
    this.vehicleReleasedAt,
    this.completedAt,
    this.startPhotos,
    this.returnPhotos,
    this.rentalVehicleType,
    this.rentalPackageModel,
    this.otpCode,
    this.sourceLocation,
    this.dropoffLocation,
    this.author,
    this.subTotal,
    this.driver,
    this.driverId,
    this.startTime,
    this.endTime,
    this.startKitoMetersReading,
    this.endKitoMetersReading,
    this.zoneId,
    this.sourcePoint,
    this.platformFee,
    this.taxSetting,
    this.platformTax,
  });

  RentalOrderModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    rejectedByDrivers = json['rejectedByDrivers'] ?? [];
    couponId = json['couponId'];
    bookingDateTime = json['bookingDateTime'];
    pickupDateTime = json['pickupDateTime'];
    returnDateTime = json['returnDateTime'];
    expectedReturnDateTime = json['expectedReturnDateTime'];
    actualReturnDateTime = json['actualReturnDateTime'];
    paymentStatus = json['paymentStatus'];
    discount = json['discount'] == null ? "0.0" : json['discount'].toString();
    authorID = json['authorID'];
    createdAt = json['createdAt'];
    adminCommissionType = json['adminCommissionType'];
    sourceLocationName = json['sourceLocationName'];
    dropoffLocationName = json['dropoffLocationName'];
    id = json['id'];
    adminCommission = json['adminCommission'];
    couponCode = json['couponCode'];
    sectionId = json['sectionId'];
    tipAmount = json['tip_amount'];
    vehicleId = json['vehicleId'];
    paymentMethod = json['paymentMethod'];
    paymentStatusDeposit = json['paymentStatusDeposit'];
    paymentStatusRemaining = json['paymentStatusRemaining'];
    totalPrice = json['totalPrice']?.toString();
    bookingTotal = json['bookingTotal']?.toString();
    depositAmount = json['depositAmount']?.toString();
    remainingAmount = json['remainingAmount']?.toString();
    cashDepositAmount = json['cashDepositAmount']?.toString();
    packageId = json['packageId'];
    packageName = json['packageName'];
    vehicleTypeId = json['vehicleTypeId'];
    vehicleTypeName = json['vehicleTypeName'];
    ownerId = json['ownerId'];
    ownerName = json['ownerName'];
    ownerAcceptanceStatus = json['ownerAcceptanceStatus'];
    basePrice = json['basePrice']?.toString();
    reservedDays = int.tryParse(json['reservedDays']?.toString() ?? '');
    gracePeriodMinutes = int.tryParse(
      json['gracePeriodMinutes']?.toString() ?? '',
    );
    includedHours = json['includedHours']?.toString();
    includedDistance = json['includedDistance']?.toString();
    extraMinutePrice = json['extraMinutePrice']?.toString();
    driverLicenseUrl = json['driverLicenseUrl'];
    identityDocumentUrl = json['identityDocumentUrl'];
    cgvAccepted = json['cgvAccepted'];
    includedKmPerDay = int.tryParse(json['includedKmPerDay']?.toString() ?? '');
    extraKmPrice = num.tryParse(json['extraKmPrice']?.toString() ?? '');
    originalDocumentsVerified = json['originalDocumentsVerified'];
    cashDepositReceived = json['cashDepositReceived'];
    customerSignature = json['customerSignature'];
    cashDepositReturned = json['cashDepositReturned'];
    startKm = double.tryParse(json['startKm']?.toString() ?? '');
    returnKm = double.tryParse(json['returnKm']?.toString() ?? '');
    usedKm = double.tryParse(json['usedKm']?.toString() ?? '');
    includedKm = double.tryParse(json['includedKm']?.toString() ?? '');
    extraKm = double.tryParse(json['extraKm']?.toString() ?? '');
    extraKmFee = double.tryParse(json['extraKmFee']?.toString() ?? '');
    lateMinutes = double.tryParse(json['lateMinutes']?.toString() ?? '');
    extraMinutesFee = double.tryParse(
      json['extraMinutesFee']?.toString() ?? '',
    );
    fuelFee = double.tryParse(json['fuelFee']?.toString() ?? '');
    finalAmountDue = double.tryParse(json['finalAmountDue']?.toString() ?? '');
    alreadyPaidAmount = double.tryParse(
      json['alreadyPaidAmount']?.toString() ?? '',
    );
    remainingDueAmount = double.tryParse(
      json['remainingDueAmount']?.toString() ?? '',
    );
    startFuelLevel = json['startFuelLevel'];
    returnFuelLevel = json['returnFuelLevel'];
    vehicleCondition = json['vehicleCondition'];
    startOdometerPhoto = json['startOdometerPhoto'];
    returnOdometerPhoto = json['returnOdometerPhoto'];
    depositConfirmedAt = json['depositConfirmedAt'];
    remainingConfirmedAt = json['remainingConfirmedAt'];
    ownerAcceptedAt = json['ownerAcceptedAt'];
    ownerRejectedAt = json['ownerRejectedAt'];
    vehicleReleasedAt = json['vehicleReleasedAt'];
    completedAt = json['completedAt'];
    startPhotos = json['startPhotos'] ?? [];
    returnPhotos = json['returnPhotos'] ?? [];
    rentalVehicleType =
        json['rentalVehicleType'] != null
            ? RentalVehicleType.fromJson(json['rentalVehicleType'])
            : null;
    rentalPackageModel =
        json['rentalPackageModel'] != null
            ? RentalPackageModel.fromJson(json['rentalPackageModel'])
            : null;
    otpCode = json['otpCode'];
    sourceLocation =
        json['sourceLocation'] != null
            ? DestinationLocation.fromJson(json['sourceLocation'])
            : null;
    dropoffLocation =
        json['dropoffLocation'] != null
            ? DestinationLocation.fromJson(json['dropoffLocation'])
            : null;
    author = json['author'] != null ? UserModel.fromJson(json['author']) : null;
    subTotal = json['subTotal'];
    driver = json['driver'] != null ? UserModel.fromJson(json['driver']) : null;
    driverId = json['driverId'];
    startTime = json['startTime'];
    endTime = json['endTime'];
    startKitoMetersReading = json['startKitoMetersReading'] ?? "0.0";
    endKitoMetersReading = json['endKitoMetersReading'] ?? "0.0";
    zoneId = json['zoneId'];
    sourcePoint =
        json['sourcePoint'] != null ? G.fromJson(json['sourcePoint']) : null;
    if (json['taxSetting'] != null) {
      taxSetting = <TaxModel>[];
      json['taxSetting'].forEach((v) {
        taxSetting!.add(TaxModel.fromJson(v));
      });
    }
    platformFee = json['platformFee'];
    if (json['platformTax'] != null) {
      platformTax = <TaxModel>[];
      json['platformTax'].forEach((v) {
        platformTax!.add(TaxModel.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    if (rejectedByDrivers != null) {
      data['rejectedByDrivers'] =
          rejectedByDrivers!.map((v) => v.toJson()).toList();
    }
    data['couponId'] = couponId;
    data['bookingDateTime'] = bookingDateTime;
    data['pickupDateTime'] = pickupDateTime;
    data['returnDateTime'] = returnDateTime;
    data['expectedReturnDateTime'] = expectedReturnDateTime;
    data['actualReturnDateTime'] = actualReturnDateTime;
    data['paymentStatus'] = paymentStatus;
    data['discount'] = discount;
    data['authorID'] = authorID;
    data['createdAt'] = createdAt;
    data['adminCommissionType'] = adminCommissionType;
    data['sourceLocationName'] = sourceLocationName;
    data['dropoffLocationName'] = dropoffLocationName;
    if (taxSetting != null) {
      data['taxSetting'] = taxSetting!.map((v) => v.toJson()).toList();
    }
    data['id'] = id;
    data['adminCommission'] = adminCommission;
    data['couponCode'] = couponCode;
    data['sectionId'] = sectionId;
    data['tip_amount'] = tipAmount;
    data['vehicleId'] = vehicleId;
    data['paymentMethod'] = paymentMethod;
    data['paymentStatusDeposit'] = paymentStatusDeposit;
    data['paymentStatusRemaining'] = paymentStatusRemaining;
    data['totalPrice'] = totalPrice;
    data['bookingTotal'] = bookingTotal;
    data['depositAmount'] = depositAmount;
    data['remainingAmount'] = remainingAmount;
    data['cashDepositAmount'] = cashDepositAmount;
    data['packageId'] = packageId;
    data['packageName'] = packageName;
    data['vehicleTypeId'] = vehicleTypeId;
    data['vehicleTypeName'] = vehicleTypeName;
    data['ownerId'] = ownerId;
    data['ownerName'] = ownerName;
    data['ownerAcceptanceStatus'] = ownerAcceptanceStatus;
    data['basePrice'] = basePrice;
    data['reservedDays'] = reservedDays;
    data['gracePeriodMinutes'] = gracePeriodMinutes;
    data['includedHours'] = includedHours;
    data['includedDistance'] = includedDistance;
    data['extraMinutePrice'] = extraMinutePrice;
    data['driverLicenseUrl'] = driverLicenseUrl;
    data['identityDocumentUrl'] = identityDocumentUrl;
    data['cgvAccepted'] = cgvAccepted;
    data['includedKmPerDay'] = includedKmPerDay;
    data['extraKmPrice'] = extraKmPrice;
    data['originalDocumentsVerified'] = originalDocumentsVerified;
    data['cashDepositReceived'] = cashDepositReceived;
    data['customerSignature'] = customerSignature;
    data['cashDepositReturned'] = cashDepositReturned;
    data['startKm'] = startKm;
    data['returnKm'] = returnKm;
    data['usedKm'] = usedKm;
    data['includedKm'] = includedKm;
    data['extraKm'] = extraKm;
    data['extraKmFee'] = extraKmFee;
    data['lateMinutes'] = lateMinutes;
    data['extraMinutesFee'] = extraMinutesFee;
    data['fuelFee'] = fuelFee;
    data['finalAmountDue'] = finalAmountDue;
    data['alreadyPaidAmount'] = alreadyPaidAmount;
    data['remainingDueAmount'] = remainingDueAmount;
    data['startFuelLevel'] = startFuelLevel;
    data['returnFuelLevel'] = returnFuelLevel;
    data['vehicleCondition'] = vehicleCondition;
    data['startOdometerPhoto'] = startOdometerPhoto;
    data['returnOdometerPhoto'] = returnOdometerPhoto;
    data['depositConfirmedAt'] = depositConfirmedAt;
    data['remainingConfirmedAt'] = remainingConfirmedAt;
    data['ownerAcceptedAt'] = ownerAcceptedAt;
    data['ownerRejectedAt'] = ownerRejectedAt;
    data['vehicleReleasedAt'] = vehicleReleasedAt;
    data['completedAt'] = completedAt;
    data['startPhotos'] = startPhotos;
    data['returnPhotos'] = returnPhotos;
    data['driverId'] = driverId;
    if (driver != null) {
      data['driver'] = driver!.toJson();
    }

    if (rentalVehicleType != null) {
      data['rentalVehicleType'] = rentalVehicleType!.toJson();
    }

    if (rentalPackageModel != null) {
      data['rentalPackageModel'] = rentalPackageModel!.toJson();
    }
    data['otpCode'] = otpCode;
    if (sourceLocation != null) {
      data['sourceLocation'] = sourceLocation!.toJson();
    }
    if (dropoffLocation != null) {
      data['dropoffLocation'] = dropoffLocation!.toJson();
    }
    if (author != null) {
      data['author'] = author!.toJson();
    }
    data['subTotal'] = subTotal;
    data['startTime'] = startTime;
    data['endTime'] = endTime;
    data['startKitoMetersReading'] = startKitoMetersReading;
    data['endKitoMetersReading'] = endKitoMetersReading;
    data['zoneId'] = zoneId;
    if (sourcePoint != null) {
      data['sourcePoint'] = sourcePoint!.toJson();
    }
    data['platformFee'] = platformFee;
    if (taxSetting != null) {
      data['taxSetting'] = taxSetting!.map((v) => v.toJson()).toList();
    }
    if (platformTax != null) {
      data['platformTax'] = platformTax!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class DestinationLocation {
  double? longitude;
  double? latitude;

  DestinationLocation({this.longitude, this.latitude});

  DestinationLocation.fromJson(Map<String, dynamic> json) {
    longitude = json['longitude'];
    latitude = json['latitude'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['longitude'] = longitude;
    data['latitude'] = latitude;
    return data;
  }
}
