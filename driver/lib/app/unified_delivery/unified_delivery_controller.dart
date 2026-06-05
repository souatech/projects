import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/collection_name.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/send_notification.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/models/order_model.dart';
import 'package:driver/models/parcel_order_model.dart';
import 'package:driver/models/user_model.dart';
import 'package:driver/services/audio_player_service.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

enum DeliveryJobKind { vendor, parcel }

class DeliveryJob {
  DeliveryJob({
    required this.id,
    required this.kind,
    required this.title,
    required this.badge,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.status,
    required this.createdAt,
    required this.amount,
    required this.distanceKm,
    required this.canAccept,
    this.vendorOrder,
    this.parcelOrder,
  });

  final String id;
  final DeliveryJobKind kind;
  final String title;
  final String badge;
  final String pickupAddress;
  final String dropoffAddress;
  final String status;
  final DateTime? createdAt;
  final String amount;
  final double? distanceKm;
  final bool canAccept;
  final OrderModel? vendorOrder;
  final ParcelOrderModel? parcelOrder;
}

class UnifiedDeliveryController extends GetxController {
  StreamSubscription? _driverSubscription;

  RxBool isLoading = true.obs;
  Rx<UserModel> driverModel = UserModel().obs;
  RxList<DeliveryJob> jobs = <DeliveryJob>[].obs;

  @override
  void onInit() {
    driverModel.value = Constant.userModel ?? UserModel();
    _listenDriver();
    super.onInit();
  }

  @override
  void onClose() {
    _driverSubscription?.cancel();
    super.onClose();
  }

  void _listenDriver() {
    _driverSubscription = FireStoreUtils.fireStore
        .collection(CollectionName.users)
        .doc(FireStoreUtils.getCurrentUid())
        .snapshots()
        .listen((event) async {
      if (!event.exists || event.data() == null) return;
      driverModel.value = UserModel.fromJson(event.data()!);
      Constant.userModel = driverModel.value;
      await reloadJobs();
    }, onError: (e) {
      log('[UNIFIED_DELIVERY_DRIVER_ERROR] $e');
      isLoading.value = false;
    });
  }

  Future<void> reloadJobs() async {
    isLoading.value = true;
    final nextJobs = <DeliveryJob>[];

    await _loadVendorJobs(nextJobs);
    await _loadParcelJobs(nextJobs);

    nextJobs.sort((a, b) {
      final distanceA = a.distanceKm;
      final distanceB = b.distanceKm;
      if (distanceA != null && distanceB != null) {
        return distanceA.compareTo(distanceB);
      }
      if (distanceA != null) return -1;
      if (distanceB != null) return 1;
      final createdA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final createdB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return createdB.compareTo(createdA);
    });

    jobs.assignAll(nextJobs);
    if (jobs.any((job) => job.canAccept)) {
      await AudioPlayerService.playSound(true);
    } else {
      await AudioPlayerService.playSound(false);
    }
    isLoading.value = false;
    update();
  }

  Future<void> _loadVendorJobs(List<DeliveryJob> output) async {
    final refs = <dynamic>[
      ...?driverModel.value.orderRequestData,
      ...?driverModel.value.inProgressOrderID,
    ];
    final seen = <String>{};
    for (final ref in refs) {
      final orderId = _orderIdFromRef(ref);
      if (orderId.isEmpty || !seen.add(orderId)) continue;
      final order = await FireStoreUtils.getOrderById(orderId);
      if (order == null ||
          order.status == Constant.orderCancelled ||
          order.status == Constant.driverRejected) {
        continue;
      }
      output.add(_vendorJob(order));
    }
  }

  Future<void> _loadParcelJobs(List<DeliveryJob> output) async {
    final pending = driverModel.value.orderParcelRequestData;
    if (pending != null) {
      final orderId = _orderIdFromRef(pending);
      if (orderId.isNotEmpty) {
        final order = await _getParcelById(orderId);
        if (order != null) {
          output.add(_parcelJob(order, forceCanAccept: true));
        } else {
          output.add(_parcelJob(ParcelOrderModel.fromJson(pending),
              forceCanAccept: true));
        }
      }
    }

    final ongoing = await FireStoreUtils.getOnGoingParcelList();
    final existing = output.map((job) => job.id).toSet();
    for (final order in ongoing) {
      final id = order.id ?? '';
      if (id.isEmpty || existing.contains(id)) continue;
      output.add(_parcelJob(order));
    }
  }

  DeliveryJob _vendorJob(OrderModel order) {
    final pickupLat = order.vendor?.latitude;
    final pickupLng = order.vendor?.longitude;
    final distance = _distanceFromDriver(pickupLat, pickupLng);
    final canAccept =
        _containsOrderRef(driverModel.value.orderRequestData, order.id);
    final badge = _sectionName(order.sectionId, fallback: 'Livraison');
    final amount = order.deliveryCharge?.toString().isNotEmpty == true
        ? order.deliveryCharge.toString()
        : '0';

    return DeliveryJob(
      id: order.id ?? '',
      kind: DeliveryJobKind.vendor,
      title: order.vendor?.title ?? badge,
      badge: badge,
      pickupAddress: order.vendor?.location ?? 'Adresse pickup',
      dropoffAddress: order.address?.getFullAddress().trim().isNotEmpty == true
          ? order.address!.getFullAddress().trim()
          : 'Adresse livraison',
      status: order.status ?? '',
      createdAt: order.createdAt?.toDate(),
      amount: Constant.amountShow(amount: amount),
      distanceKm: distance,
      canAccept: canAccept,
      vendorOrder: order,
    );
  }

  DeliveryJob _parcelJob(ParcelOrderModel order,
      {bool forceCanAccept = false}) {
    final pickupLat = order.senderLatLong?.latitude;
    final pickupLng = order.senderLatLong?.longitude;
    final distance = _distanceFromDriver(pickupLat, pickupLng);
    final canAccept = forceCanAccept ||
        order.status == Constant.orderPlaced ||
        order.status == Constant.orderAccepted;
    final badge = _sectionName(order.sectionId, fallback: 'Colis');
    final amount = order.subTotal?.toString().isNotEmpty == true
        ? order.subTotal.toString()
        : '0';

    return DeliveryJob(
      id: order.id ?? '',
      kind: DeliveryJobKind.parcel,
      title: badge,
      badge: badge,
      pickupAddress: order.sender?.address ?? 'Adresse pickup',
      dropoffAddress: order.receiver?.address ?? 'Adresse livraison',
      status: order.status ?? '',
      createdAt:
          order.createdAt?.toDate() ?? order.senderPickupDateTime?.toDate(),
      amount: Constant.amountShow(amount: amount),
      distanceKm: distance,
      canAccept: canAccept,
      parcelOrder: order,
    );
  }

  Future<void> acceptJob(DeliveryJob job) async {
    if (job.kind == DeliveryJobKind.vendor && job.vendorOrder != null) {
      await _acceptVendor(job.vendorOrder!);
    } else if (job.kind == DeliveryJobKind.parcel && job.parcelOrder != null) {
      await _acceptParcel(job.parcelOrder!);
    }
    await reloadJobs();
  }

  Future<void> rejectJob(DeliveryJob job) async {
    if (job.kind == DeliveryJobKind.vendor && job.vendorOrder != null) {
      await _rejectVendor(job.vendorOrder!);
    } else if (job.kind == DeliveryJobKind.parcel && job.parcelOrder != null) {
      await _rejectParcel(job.parcelOrder!);
    }
    await reloadJobs();
  }

  Future<void> _acceptVendor(OrderModel order) async {
    await AudioPlayerService.playSound(false);
    ShowToastDialog.showLoader("Please wait".tr);
    final orderId = order.id?.trim() ?? '';
    if (orderId.isEmpty) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Order not found".tr);
      return;
    }

    driverModel.value.orderRequestData ??= [];
    driverModel.value.inProgressOrderID ??= [];
    driverModel.value.orderRequestData!
        .removeWhere((element) => _orderIdFromRef(element) == orderId);
    if (!driverModel.value.inProgressOrderID!
        .any((element) => _orderIdFromRef(element) == orderId)) {
      driverModel.value.inProgressOrderID!.add(orderId);
    }
    await FireStoreUtils.updateUser(driverModel.value);

    order.status = Constant.driverAccepted;
    order.driverID = driverModel.value.id;
    order.driver = driverModel.value;
    await FireStoreUtils.setOrder(order);

    ShowToastDialog.closeLoader();
    await SendNotification.sendFcmMessage(Constant.driverAcceptedNotification,
        order.author?.fcmToken.toString() ?? "", {});
    await SendNotification.sendFcmMessage(Constant.driverAcceptedNotification,
        order.vendor?.fcmToken.toString() ?? "", {});
  }

  Future<void> _rejectVendor(OrderModel order) async {
    ShowToastDialog.showLoader("Please wait".tr);
    await AudioPlayerService.playSound(false);
    final orderId = order.id?.trim() ?? '';
    if (orderId.isEmpty) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Order not found".tr);
      return;
    }
    order.rejectedByDrivers ??= [];
    if (!order.rejectedByDrivers!.contains(driverModel.value.id)) {
      order.rejectedByDrivers!.add(driverModel.value.id);
    }
    order.status = Constant.driverRejected;
    await FireStoreUtils.setOrder(order);
    driverModel.value.orderRequestData ??= [];
    driverModel.value.orderRequestData!
        .removeWhere((element) => _orderIdFromRef(element) == orderId);
    await FireStoreUtils.updateUser(driverModel.value);
    ShowToastDialog.closeLoader();
  }

  Future<void> _acceptParcel(ParcelOrderModel order) async {
    final orderId = order.id ?? '';
    ShowToastDialog.showLoader('Please wait'.tr);
    await FireStoreUtils.fireStore
        .collection(CollectionName.parcelOrders)
        .doc(orderId)
        .update({
      'status': Constant.driverAccepted,
      'driverId': FireStoreUtils.getCurrentUid(),
      'driver': driverModel.value.toJson(),
      'driverAssignedAt': Timestamp.now(),
    });
    await FireStoreUtils.fireStore
        .collection(CollectionName.users)
        .doc(FireStoreUtils.getCurrentUid())
        .update({
      'orderParcelRequestData': FieldValue.delete(),
    });
    ShowToastDialog.closeLoader();
  }

  Future<void> _rejectParcel(ParcelOrderModel order) async {
    final orderId = order.id ?? '';
    await FireStoreUtils.fireStore
        .collection(CollectionName.users)
        .doc(FireStoreUtils.getCurrentUid())
        .update({
      'orderParcelRequestData': FieldValue.delete(),
    });
    await FireStoreUtils.fireStore
        .collection(CollectionName.parcelOrders)
        .doc(orderId)
        .update({
      'status': Constant.orderAccepted,
      'rejectedByDrivers':
          FieldValue.arrayUnion([FireStoreUtils.getCurrentUid()]),
      'driverId': FieldValue.delete(),
      'driverAssignedAt': FieldValue.delete(),
    });
  }

  Future<ParcelOrderModel?> _getParcelById(String orderId) async {
    final doc = await FireStoreUtils.fireStore
        .collection(CollectionName.parcelOrders)
        .doc(orderId)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return ParcelOrderModel.fromJson(doc.data()!);
  }

  String _sectionName(String? sectionId, {required String fallback}) {
    if (sectionId == null || sectionId.isEmpty) return fallback;
    return Constant.sectionModels[sectionId]?.name ??
        driverModel.value.sectionNames?[sectionId] ??
        fallback;
  }

  double? _distanceFromDriver(double? lat, double? lng) {
    if (lat == null || lng == null || lat == 0 || lng == 0) return null;
    final driverLat = Constant.locationDataFinal?.latitude ??
        driverModel.value.location?.latitude;
    final driverLng = Constant.locationDataFinal?.longitude ??
        driverModel.value.location?.longitude;
    if (driverLat == null ||
        driverLng == null ||
        driverLat == 0 ||
        driverLng == 0) {
      return null;
    }
    return Geolocator.distanceBetween(driverLat, driverLng, lat, lng) / 1000;
  }

  bool _containsOrderRef(List<dynamic>? refs, String? orderId) {
    if (orderId == null || orderId.isEmpty) return false;
    return refs?.any((element) => _orderIdFromRef(element) == orderId) ?? false;
  }

  String _orderIdFromRef(dynamic value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    if (value is Map) {
      for (final key in ['id', 'orderId', 'orderID', 'order_id']) {
        final orderId = value[key]?.toString().trim() ?? '';
        if (orderId.isNotEmpty) return orderId;
      }
    }
    return value.toString().trim();
  }
}
