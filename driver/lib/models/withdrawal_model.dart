import 'package:cloud_firestore/cloud_firestore.dart';

class WithdrawalModel {
  String? amount;
  String? adminNote;
  String? note;
  String? id;
  Timestamp? paidDate;
  String? paymentStatus;
  String? vendorID;
  String? driverID;
  String? withdrawMethod;
  Timestamp? requestedAt;
  Timestamp? processedAt;
  String? reference;

  WithdrawalModel({
    this.amount,
    this.adminNote,
    this.note,
    this.id,
    this.paidDate,
    this.driverID,
    this.paymentStatus,
    this.vendorID,
    this.withdrawMethod,
    this.requestedAt,
    this.processedAt,
    this.reference,
  });

  WithdrawalModel.fromJson(Map<String, dynamic> json) {
    amount = (json['amount'] ?? json['amount_requested'] ?? "0.0").toString();
    adminNote = json['adminNote'];
    note = json['note'];
    id = json['id'];
    paidDate = json['paidDate'] ?? json['processed_at'] ?? json['processedAt'];
    requestedAt = json['requested_at'] ?? json['requestedAt'];
    processedAt =
        json['processed_at'] ?? json['processedAt'] ?? json['paidDate'];
    paymentStatus = json['paymentStatus'] ?? json['status'];
    vendorID = json['vendorID'];
    withdrawMethod = json['withdrawMethod'] ?? json['payout_method'];
    driverID = json['driverID'] ?? json['beneficiary_id'];
    reference = json['reference'] ?? json['ref'] ?? json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['amount'] = amount;
    data['adminNote'] = adminNote;
    data['note'] = note;
    data['id'] = id;
    data['paidDate'] = paidDate;
    data['paymentStatus'] = paymentStatus;
    data['vendorID'] = vendorID;
    data['driverID'] = driverID;
    data['withdrawMethod'] = withdrawMethod;
    data['requested_at'] = requestedAt;
    data['processed_at'] = processedAt;
    data['reference'] = reference;
    return data;
  }
}
