import 'package:customer/constant/collection_name.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/models/cab_order_model.dart';
import 'package:customer/models/order_model.dart';
import 'package:customer/models/parcel_order_model.dart';
import 'package:customer/models/rental_order_model.dart';
import 'package:customer/screen_ui/cab_service_screens/cab_booking_screen.dart';
import 'package:customer/screen_ui/cab_service_screens/cab_order_details.dart';
import 'package:customer/screen_ui/multi_vendor_service/order_list_screen/live_tracking_screen.dart';
import 'package:customer/screen_ui/multi_vendor_service/order_list_screen/order_details_screen.dart';
import 'package:customer/screen_ui/parcel_service/parcel_order_details.dart';
import 'package:customer/screen_ui/rental_service/rental_order_details_screen.dart';
import 'package:customer/service/fire_store_utils.dart';
import 'package:customer/themes/show_toast_dialog.dart';
import 'package:get/get.dart';

class TrackingNavigation {
  static Future<void> openFood({
    OrderModel? order,
    String? orderId,
    bool preferLiveTracking = true,
  }) async {
    final resolvedOrder = order ?? await _loadFoodOrder(orderId);
    final resolvedOrderId = resolvedOrder?.id ?? orderId ?? '';
    _debug(
      orderId: resolvedOrderId,
      serviceType: 'food',
      route:
          preferLiveTracking
              ? 'LiveTrackingScreen/OrderDetailsScreen'
              : 'OrderDetailsScreen',
    );

    if (resolvedOrder == null || (resolvedOrder.id ?? '').isEmpty) {
      _unavailable();
      return;
    }

    _setSectionContextById(resolvedOrder.sectionId);

    if (preferLiveTracking && _canOpenFoodLiveTracking(resolvedOrder)) {
      Get.to(
        const LiveTrackingScreen(),
        arguments: {'orderModel': resolvedOrder},
      );
      return;
    }

    Get.to(
      const OrderDetailsScreen(),
      arguments: {'orderModel': resolvedOrder},
    );
  }

  static Future<void> openParcel({
    ParcelOrderModel? order,
    String? orderId,
  }) async {
    final resolvedOrder = order ?? await _loadParcelOrder(orderId);
    final resolvedOrderId = resolvedOrder?.id ?? orderId ?? '';
    _debug(
      orderId: resolvedOrderId,
      serviceType: 'parcel',
      route: 'ParcelOrderDetails',
    );

    if (resolvedOrder == null || (resolvedOrder.id ?? '').isEmpty) {
      _unavailable();
      return;
    }

    _setSectionContextById(resolvedOrder.sectionId);
    Get.to(const ParcelOrderDetails(), arguments: resolvedOrder);
  }

  static Future<void> openRental({
    RentalOrderModel? order,
    String? orderId,
  }) async {
    final resolvedOrder = order ?? await _loadRentalOrder(orderId);
    final resolvedOrderId = resolvedOrder?.id ?? orderId ?? '';
    _debug(orderId: resolvedOrderId, serviceType: 'rental', route: 'RentalOrderDetailsScreen');

    if (resolvedOrder == null || (resolvedOrder.id ?? '').isEmpty) {
      _unavailable();
      return;
    }

    _setSectionContextById(resolvedOrder.sectionId);
    Get.to(const RentalOrderDetailsScreen(), arguments: resolvedOrder);
  }

  static Future<void> openCab({
    CabOrderModel? order,
    String? orderId,
    bool preferLiveTracking = true,
  }) async {
    final resolvedOrder = order ?? await _loadCabOrder(orderId);
    final resolvedOrderId = resolvedOrder?.id ?? orderId ?? '';
    _debug(
      orderId: resolvedOrderId,
      serviceType: 'cab',
      route:
          preferLiveTracking
              ? 'CabBookingScreen/CabOrderDetails'
              : 'CabOrderDetails',
    );

    if (resolvedOrder == null || (resolvedOrder.id ?? '').isEmpty) {
      _unavailable();
      return;
    }

    _setSectionContextById(resolvedOrder.sectionId);

    if (preferLiveTracking && _isActiveCabOrder(resolvedOrder)) {
      Get.to(
        const CabBookingScreen(),
        arguments: {'cabOrderModel': resolvedOrder},
      );
      return;
    }

    Get.to(
      const CabOrderDetails(),
      arguments: {'cabOrderModel': resolvedOrder},
    );
  }

  static Future<void> openFromPayload(Map<String, dynamic> data) async {
    final String orderId = _firstValue(data, [
      'orderId',
      'order_id',
      'bookingId',
      'rideId',
      'parcelId',
      'id',
    ]);
    final String serviceType =
        _firstValue(data, [
          'serviceType',
          'service_type',
          'type',
          'orderType',
        ]).toLowerCase();

    _debug(orderId: orderId, serviceType: serviceType, route: 'payload');

    if (orderId.isEmpty) {
      _unavailable();
      return;
    }

    if (serviceType.contains('rental') || serviceType.contains('location')) {
      await openRental(orderId: orderId);
      return;
    }
    if (serviceType.contains('parcel') || serviceType.contains('colis')) {
      await openParcel(orderId: orderId);
      return;
    }
    if (serviceType.contains('cab') ||
        serviceType.contains('ride') ||
        serviceType.contains('trajet')) {
      await openCab(orderId: orderId);
      return;
    }
    if (serviceType.contains('food') ||
        serviceType.contains('vendor') ||
        serviceType.contains('restaurant') ||
        serviceType.contains('grocery')) {
      await openFood(orderId: orderId);
      return;
    }

    await _openUnknownOrder(orderId);
  }

  static Future<OrderModel?> _loadFoodOrder(String? orderId) async {
    if (orderId == null || orderId.isEmpty) {
      return null;
    }
    final order = await FireStoreUtils.getOrderByOrderId(orderId);
    if (order != null) {
      return order;
    }
    final data = await FireStoreUtils.getOrderByIdFromAllCollections(orderId);
    if (data is Map && data['collection_name'] == CollectionName.vendorOrders) {
      return OrderModel.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  static Future<ParcelOrderModel?> _loadParcelOrder(String? orderId) async {
    if (orderId == null || orderId.isEmpty) {
      return null;
    }
    final order = await FireStoreUtils.getParcelOrder(orderId);
    if (order != null) {
      return order;
    }
    final data = await FireStoreUtils.getOrderByIdFromAllCollections(orderId);
    if (data is Map && data['collection_name'] == CollectionName.parcelOrders) {
      return ParcelOrderModel.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  static Future<RentalOrderModel?> _loadRentalOrder(String? orderId) async {
    if (orderId == null || orderId.isEmpty) {
      return null;
    }
    return await FireStoreUtils.getRentalOrderById(orderId);
  }

  static Future<CabOrderModel?> _loadCabOrder(String? orderId) async {
    if (orderId == null || orderId.isEmpty) {
      return null;
    }
    final order = await FireStoreUtils.getCabOrderById(orderId);
    if (order != null) {
      return order;
    }
    final data = await FireStoreUtils.getOrderByIdFromAllCollections(orderId);
    if (data is Map && data['collection_name'] == CollectionName.rides) {
      return CabOrderModel.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  static Future<void> _openUnknownOrder(String orderId) async {
    final data = await FireStoreUtils.getOrderByIdFromAllCollections(orderId);
    if (data is! Map) {
      _unavailable();
      return;
    }

    final collection = data['collection_name'];
    if (collection == CollectionName.rentalOrders) {
      await openRental(
        order: RentalOrderModel.fromJson(Map<String, dynamic>.from(data)),
      );
    } else if (collection == CollectionName.parcelOrders) {
      await openParcel(
        order: ParcelOrderModel.fromJson(Map<String, dynamic>.from(data)),
      );
    } else if (collection == CollectionName.rides) {
      await openCab(
        order: CabOrderModel.fromJson(Map<String, dynamic>.from(data)),
      );
    } else if (collection == CollectionName.vendorOrders) {
      await openFood(
        order: OrderModel.fromJson(Map<String, dynamic>.from(data)),
      );
    } else {
      _unavailable();
    }
  }

  static bool _canOpenFoodLiveTracking(OrderModel order) {
    final status = (order.status ?? '').toLowerCase();
    final serviceType =
        (Constant.sectionConstantModel?.serviceTypeFlag ?? '').toLowerCase();
    return serviceType != 'ecommerce-service' &&
        order.driverID != null &&
        order.driverID.toString().isNotEmpty &&
        (status == Constant.orderShipped.toLowerCase() ||
            status == Constant.orderInTransit.toLowerCase());
  }

  static bool _isActiveCabOrder(CabOrderModel order) {
    final status = (order.status ?? '').toLowerCase();
    return status == Constant.orderPlaced.toLowerCase() ||
        status == Constant.driverPending.toLowerCase() ||
        status == Constant.driverAccepted.toLowerCase() ||
        status == Constant.orderAccepted.toLowerCase() ||
        status == Constant.orderInTransit.toLowerCase();
  }

  static void _setSectionContextById(String? sectionId) {
    if (sectionId == null || sectionId.isEmpty) {
      return;
    }
    for (final section in Constant.sectionList) {
      if (section.id == sectionId) {
        Constant.sectionConstantModel = section;
        return;
      }
    }
  }

  static String _firstValue(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return '';
  }

  static void _debug({
    required String orderId,
    required String serviceType,
    required String route,
  }) {
    // ignore: avoid_print
    print('TRACKING ORDER ID: $orderId');
    // ignore: avoid_print
    print('SERVICE TYPE: $serviceType');
    // ignore: avoid_print
    print('TARGET ROUTE: $route');
  }

  static void _unavailable() {
    ShowToastDialog.showToast('Commande indisponible'.tr);
  }
}
