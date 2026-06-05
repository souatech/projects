import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;
import 'dart:math' as maths;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/collection_name.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/models/cab_order_model.dart';
import 'package:customer/models/coupon_model.dart';
import 'package:customer/models/payment_model/cod_setting_model.dart';
import 'package:customer/models/payment_model/paydunya_config_model.dart';
import 'package:customer/models/payment_model/wallet_setting_model.dart';
import 'package:customer/models/popular_destination.dart';
import 'package:customer/models/tax_model.dart';
import 'package:customer/models/user_model.dart';
import 'package:customer/models/vehicle_type.dart';
import 'package:customer/models/wallet_transaction_model.dart';
import 'package:customer/service/fire_store_utils.dart';
import 'package:customer/themes/show_toast_dialog.dart';
import 'package:customer/utils/address_formatter.dart';
import 'package:customer/utils/preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as flutterMap;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as latlong;
import 'package:location/location.dart';
import 'package:uuid/uuid.dart';

import '../payment/paydunya_screen.dart';
import '../screen_ui/multi_vendor_service/wallet_screen/wallet_screen.dart';
import '../themes/app_them_data.dart';

class IntercityHomeController extends GetxController {
  RxList<PopularDestination> popularDestination = <PopularDestination>[].obs;

  late GoogleMapController mapController;
  final flutterMap.MapController mapOsmController = flutterMap.MapController();

  final Rx<TextEditingController> sourceTextEditController =
      TextEditingController().obs;
  final Rx<TextEditingController> destinationTextEditController =
      TextEditingController().obs;

  final Rx<TextEditingController> couponCodeTextEditController =
      TextEditingController().obs;

  final Rx<Location> currentLocation = Location().obs;

  final RxSet<Marker> markers = <Marker>{}.obs;
  final RxList<flutterMap.Marker> osmMarker = <flutterMap.Marker>[].obs;
  final RxList<latlong.LatLng> routePoints = <latlong.LatLng>[].obs;

  final Rx<LatLng> currentPosition = LatLng(23.0225, 72.5714).obs;

  final Rx<LatLng> departureLatLong = const LatLng(0.0, 0.0).obs;
  final Rx<LatLng> destinationLatLong = const LatLng(0.0, 0.0).obs;
  final Rx<latlong.LatLng> departureLatLongOsm = latlong.LatLng(0.0, 0.0).obs;
  final Rx<latlong.LatLng> destinationLatLongOsm = latlong.LatLng(0.0, 0.0).obs;

  final RxBool isLoading = true.obs;

  final RxDouble distance = 0.0.obs;
  final RxString duration = ''.obs;

  BitmapDescriptor? departureIcon, destinationIcon, taxiIcon, stopIcon;
  Widget? departureIconOsm, destinationIconOsm, taxiIconOsm, stopIconOsm;

  RxList<TaxModel> taxList = <TaxModel>[].obs;
  RxList<VehicleType> vehicleTypes = <VehicleType>[].obs;
  Rx<VehicleType> selectedVehicleType = VehicleType().obs;

  Rx<UserModel> userModel = UserModel().obs;
  Rx<UserModel> driverModel = UserModel().obs;
  Rx<CabOrderModel> currentOrder = CabOrderModel().obs;

  final RxString selectedPaymentMethod = ''.obs;
  final RxString bottomSheetType = 'location'.obs;

  RxDouble subTotal = 0.0.obs;
  RxDouble discount = 0.0.obs;
  RxDouble taxAmount = 0.0.obs;
  RxDouble totalAmount = 0.0.obs;
  RxDouble orderTaxAmount = 0.0.obs;
  RxDouble platformTaxAmount = 0.0.obs;

  bool isOsmMapReady = false;

  Rx<CouponModel> selectedCouponModel = CouponModel().obs;

  @override
  void onInit() {
    super.onInit();
    initData();
  }

  Future<void> initData() async {
    if (Constant.selectedMapType == 'osm') {
      mapOsmController;
    }

    await setIcons();
    await FireStoreUtils.getPopularDestination().then((value) {
      popularDestination.value = value;
    });
    await getVehicleType();
    isLoading.value = false;
  }

  RxList<CouponModel> cabCouponList = <CouponModel>[].obs;

  Future<void> getVehicleType() async {
    final vehicleList = await FireStoreUtils.getVehicleType();
    vehicleTypes.value = vehicleList;
    if (vehicleTypes.isNotEmpty) {
      selectedVehicleType.value = vehicleTypes.first;
    }

    await getPaymentSettings();

    FireStoreUtils.fireStore
        .collection(CollectionName.users)
        .doc(FireStoreUtils.getCurrentUid())
        .snapshots()
        .listen((userSnapshot) async {
          if (!userSnapshot.exists) return;

          userModel.value = UserModel.fromJson(userSnapshot.data()!);

          if (userModel.value.inProgressOrderID != null &&
              userModel.value.inProgressOrderID!.isNotEmpty) {
            String? validRideId;

            for (String id in userModel.value.inProgressOrderID!) {
              final rideDoc =
                  await FireStoreUtils.fireStore
                      .collection(CollectionName.rides)
                      .doc(id)
                      .get();

              if (rideDoc.exists &&
                  (rideDoc.data()?['rideType'] ?? '')
                          .toString()
                          .toLowerCase() ==
                      "intercity") {
                validRideId = userModel.value.inProgressOrderID!.first!;
                break;
              }
            }

            FireStoreUtils.fireStore
                .collection(CollectionName.rides)
                .doc(validRideId)
                .snapshots()
                .listen((rideSnapshot) async {
                  if (!rideSnapshot.exists) return;

                  final rideData = rideSnapshot.data()!;
                  currentOrder.value = CabOrderModel.fromJson(rideData);
                  final status = currentOrder.value.status;

                  if (status == Constant.driverAccepted ||
                      status == Constant.orderInTransit) {
                    FireStoreUtils.fireStore
                        .collection(CollectionName.users)
                        .doc(currentOrder.value.driverId)
                        .snapshots()
                        .listen((event) async {
                          if (event.exists && event.data() != null) {
                            UserModel driverModel0 = UserModel.fromJson(
                              event.data()!,
                            );
                            driverModel.value = driverModel0;
                            await updateDriverRoute(driverModel0);
                          }
                        });
                  }

                  print("Current Ride Status: $status");
                  if (status == Constant.orderPlaced ||
                      status == Constant.driverPending ||
                      status == Constant.driverRejected ||
                      (status == Constant.orderAccepted &&
                          currentOrder.value.driverId == null)) {
                    bottomSheetType.value = 'waitingForDriver';
                  } else if (status == Constant.driverAccepted ||
                      status == Constant.orderInTransit) {
                    bottomSheetType.value = 'driverDetails';
                    sourceTextEditController.value.text =
                        currentOrder.value.sourceLocationName ?? '';
                    destinationTextEditController.value.text =
                        currentOrder.value.destinationLocationName ?? '';
                    selectedPaymentMethod.value =
                        currentOrder.value.paymentMethod ?? '';
                    calculateTotalAmountAfterAccept();
                  } else if (status == Constant.orderCompleted) {
                    userModel.value.inProgressOrderID!.remove(validRideId);
                    await FireStoreUtils.updateUser(userModel.value);
                    bottomSheetType.value = 'location';
                    Get.back();
                  }
                });
          } else {
            bottomSheetType.value = 'location';
            if (Constant.currentLocation != null) {
              setDepartureMarker(
                Constant.currentLocation!.latitude,
                Constant.currentLocation!.longitude,
              );
              searchPlaceNameOSM();
            }
          }
        });

    final coupons = await FireStoreUtils.getCabCoupon();
    cabCouponList.value = coupons;
  }

  Future<void> updateDriverRoute(UserModel driverModel) async {
    try {
      final order = currentOrder.value;

      final driverLat = driverModel.location!.latitude ?? 0.0;
      final driverLng = driverModel.location!.longitude ?? 0.0;

      if (driverLat == 0.0 || driverLng == 0.0) return;

      // Get pickup and destination
      final pickupLat = order.sourceLocation?.latitude ?? 0.0;
      final pickupLng = order.sourceLocation?.longitude ?? 0.0;
      final destLat = order.destinationLocation?.latitude ?? 0.0;
      final destLng = order.destinationLocation?.longitude ?? 0.0;

      if (Constant.selectedMapType == 'osm') {
        /// For OpenStreetMap
        routePoints.clear();

        if (order.status == Constant.driverAccepted) {
          // DRIVER → PICKUP
          await fetchRouteWithWaypoints([
            latlong.LatLng(driverLat, driverLng),
            latlong.LatLng(pickupLat, pickupLng),
          ]);
        } else if (order.status == Constant.orderInTransit) {
          // PICKUP → DESTINATION
          await fetchRouteWithWaypoints([
            latlong.LatLng(pickupLat, pickupLng),
            latlong.LatLng(destLat, destLng),
          ]);
        }
        updateRouteMarkers(driverModel);
      } else {
        /// For Google Maps
        if (order.status == Constant.driverAccepted) {
          await fetchGoogleRouteBetween(
            LatLng(driverLat, driverLng),
            LatLng(pickupLat, pickupLng),
          );
        } else if (order.status == Constant.orderInTransit) {
          await fetchGoogleRouteBetween(
            LatLng(pickupLat, pickupLng),
            LatLng(destLat, destLng),
          );
        }
        updateRouteMarkers(driverModel);
      }
    } catch (e) {
      print("Error in updateDriverRoute: $e");
    }
  }

  Future<void> updateRouteMarkers(UserModel driverModel) async {
    try {
      final order = currentOrder.value;
      if (order.driver == null || driverModel.location == null) return;

      final driverLat = driverModel.location!.latitude ?? 0.0;
      final driverLng = driverModel.location!.longitude ?? 0.0;
      final pickupLat = order.sourceLocation?.latitude ?? 0.0;
      final pickupLng = order.sourceLocation?.longitude ?? 0.0;
      final destLat = order.destinationLocation?.latitude ?? 0.0;
      final destLng = order.destinationLocation?.longitude ?? 0.0;

      markers.clear();
      osmMarker.clear();

      final departureBytes = await Constant().getBytesFromAsset(
        'assets/images/location_black3x.png',
        50,
      );
      final destinationBytes = await Constant().getBytesFromAsset(
        'assets/images/location_orange3x.png',
        50,
      );
      final driverBytesRaw =
          (Constant.sectionConstantModel?.markerIcon?.isNotEmpty ?? false)
              ? await Constant().getBytesFromUrl(
                Constant.sectionConstantModel!.markerIcon!,
                width: 120,
              )
              : await Constant().getBytesFromAsset(
                'assets/images/ic_cab.png',
                50,
              );

      departureIcon = BitmapDescriptor.fromBytes(departureBytes);
      destinationIcon = BitmapDescriptor.fromBytes(destinationBytes);
      taxiIcon = BitmapDescriptor.fromBytes(driverBytesRaw);

      if (Constant.selectedMapType == 'osm') {
        if (order.status == Constant.driverAccepted) {
          osmMarker.addAll([
            flutterMap.Marker(
              point: latlong.LatLng(pickupLat, pickupLng),
              width: 40,
              height: 40,
              child: Image.asset(
                'assets/images/location_black3x.png',
                width: 40,
              ),
            ),
            flutterMap.Marker(
              point: latlong.LatLng(driverLat, driverLng),
              width: 45,
              height: 45,
              rotate: true,
              child: CachedNetworkImage(
                width: 50,
                height: 50,
                imageUrl: Constant.sectionConstantModel!.markerIcon.toString(),
                placeholder: (context, url) => Constant.loader(),
                errorWidget:
                    (context, url, error) => SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
              ),
            ),
          ]);
        } else if (order.status == Constant.orderInTransit) {
          osmMarker.addAll([
            flutterMap.Marker(
              point: latlong.LatLng(destLat, destLng),
              width: 40,
              height: 40,
              child: Image.asset(
                'assets/images/location_orange3x.png',
                width: 40,
              ),
            ),
            flutterMap.Marker(
              point: latlong.LatLng(driverLat, driverLng),
              width: 45,
              height: 45,
              rotate: true,
              child: CachedNetworkImage(
                width: 50,
                height: 50,
                imageUrl: Constant.sectionConstantModel!.markerIcon.toString(),
                placeholder: (context, url) => Constant.loader(),
                errorWidget:
                    (context, url, error) => SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
              ),
            ),
          ]);
        }
      } else {
        if (order.status == Constant.driverAccepted) {
          markers.addAll([
            Marker(
              markerId: const MarkerId("pickup"),
              position: LatLng(pickupLat, pickupLng),
              infoWindow: InfoWindow(title: "Pickup Location".tr),
              icon:
                  departureIcon ??
                  BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen,
                  ),
            ),
            Marker(
              markerId: const MarkerId("driver"),
              position: LatLng(driverLat, driverLng),
              infoWindow: InfoWindow(title: "Driver at Pickup".tr),
              icon: taxiIcon ?? BitmapDescriptor.defaultMarker,
            ),
          ]);
        } else if (order.status == Constant.orderInTransit) {
          markers.addAll([
            Marker(
              markerId: const MarkerId("destination"),
              position: LatLng(destLat, destLng),
              infoWindow: InfoWindow(title: "Destination Location".tr),
              icon:
                  destinationIcon ??
                  BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed,
                  ),
            ),
            Marker(
              markerId: const MarkerId("driver"),
              position: LatLng(driverLat, driverLng),
              infoWindow: InfoWindow(title: "Driver Location".tr),
              icon: taxiIcon ?? BitmapDescriptor.defaultMarker,
            ),
          ]);
        }
      }

      update();
    } catch (e) {
      print("❌ Error in updateRouteMarkers: $e");
    }
  }

  Future<void> fetchGoogleRouteBetween(
    LatLng originPoint,
    LatLng destPoint,
  ) async {
    final origin = '${originPoint.latitude},${originPoint.longitude}';
    final destination = '${destPoint.latitude},${destPoint.longitude}';
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=$origin&destination=$destination'
      '&mode=driving&key=${Constant.mapAPIKey}',
    );

    try {
      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        final route = data['routes'][0];
        final encodedPolyline = route['overview_polyline']['points'];
        final decodedPoints = PolylinePoints.decodePolyline(encodedPolyline);
        final coordinates =
            decodedPoints.map((e) => LatLng(e.latitude, e.longitude)).toList();

        addPolyLine(coordinates);

        // Distance + duration update
        final leg = route['legs'][0];
        final totalDistance = leg['distance']['value'] / 1000.0;
        final totalDuration = leg['duration']['value'] / 60.0;

        distance.value = totalDistance;
        duration.value = '${totalDuration.toStringAsFixed(0)} min';
      } else {
        print('Google Directions API error: ${data['status']}');
      }
    } catch (e) {
      print("Error fetching driver route: $e");
    }
  }

  void calculateTotalAmountAfterAccept() {
    taxAmount = 0.0.obs;
    discount = 0.0.obs;
    orderTaxAmount.value = 0.0;
    platformTaxAmount.value = 0.0;
    subTotal.value = double.parse(currentOrder.value.subTotal.toString());
    discount.value = double.parse(currentOrder.value.discount ?? '0.0');

    for (var taxElement in Constant.orderProductTaxList ?? []) {
      orderTaxAmount.value += Constant.calculateTax(
        amount: (subTotal.value - discount.value).toString(),
        taxModel: taxElement,
      );
    }

    if (double.parse(Constant.platformFeeModel?.fee ?? '0.0') > 0.0) {
      for (var taxElement in Constant.platformTaxList ?? []) {
        platformTaxAmount.value += Constant.calculateTax(
          amount: Constant.platformFeeModel?.fee ?? '0.0',
          taxModel: taxElement,
        );
      }
    }
    taxAmount.value = orderTaxAmount.value + platformTaxAmount.value;
    totalAmount.value =
        (subTotal.value - discount.value) +
        double.parse(Constant.platformFeeModel?.fee ?? '0.0') +
        taxAmount.value;
    update();
  }

  void calculateTotalAmount() {
    subTotal = 0.0.obs;
    taxAmount = 0.0.obs;
    discount = 0.0.obs;
    totalAmount = 0.0.obs;
    platformTaxAmount.value = 0.0;
    taxAmount.value = 0.0;
    subTotal.value = getAmount(selectedVehicleType.value);

    for (var taxElement in Constant.orderProductTaxList ?? []) {
      orderTaxAmount.value += Constant.calculateTax(
        amount: (subTotal.value - discount.value).toString(),
        taxModel: taxElement,
      );
    }

    if (double.parse(Constant.platformFeeModel?.fee ?? '0.0') > 0.0) {
      for (var taxElement in Constant.platformTaxList ?? []) {
        platformTaxAmount.value += Constant.calculateTax(
          amount: Constant.platformFeeModel?.fee ?? '0.0',
          taxModel: taxElement,
        );
      }
    }
    taxAmount.value = orderTaxAmount.value + platformTaxAmount.value;
    totalAmount.value =
        (subTotal.value - discount.value) +
        double.parse(Constant.platformFeeModel?.fee ?? '0.0') +
        taxAmount.value;

    update();
  }

  Future<void> initiatePaydunyaPayment(BuildContext context) async {
    ShowToastDialog.showLoader("Please wait...".tr);
    try {
      log(
        '[PayDunya] config: isEnabled=${paydunyaConfig.value.isEnabled}, mode=${paydunyaConfig.value.mode}',
      );

      final createBody = jsonEncode({
        'amount': totalAmount.value,
        'order_id': currentOrder.value.id,
        'customer_name': Constant.userModel?.fullName() ?? '',
        'customer_email': Constant.userModel?.email ?? '',
      });
      final createUrl =
          '${Uri.parse(Constant.globalUrl).origin}/process-paydunya';
      log('[PayDunya] → POST $createUrl');
      log('[PayDunya] body: $createBody');

      final response = await http.post(
        Uri.parse(createUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
        },
        body: createBody,
      );

      log('[PayDunya] ← ${response.statusCode}: ${response.body}');
      ShowToastDialog.closeLoader();

      if (response.statusCode != 200) {
        String errMsg = response.body;
        try {
          final j = jsonDecode(response.body);
          errMsg =
              j['message'] ??
              j['error'] ??
              j['msg'] ??
              j['detail'] ??
              response.body;
        } catch (_) {}
        log('[PayDunya] create error: $errMsg');
        ShowToastDialog.showToast('PayDunya [${response.statusCode}]: $errMsg');
        return;
      }

      final data = jsonDecode(response.body);
      final String paymentUrl =
          data['checkout_url'] ??
          data['payment_url'] ??
          data['redirect_url'] ??
          data['url'] ??
          '';
      final String paydunyaToken =
          data['token'] ?? data['invoice_token'] ?? data['reference'] ?? '';
      log('[PayDunya] checkout_url: $paymentUrl  token: $paydunyaToken');

      if (paymentUrl.isEmpty) {
        ShowToastDialog.showToast('PayDunya: URL de paiement manquante');
        return;
      }

      final result = await Get.to(
        () => PaydunyaScreen(
          paymentUrl: paymentUrl,
          token: paydunyaToken,
          orderId: currentOrder.value.id ?? '',
        ),
      );

      if (result == true) {
        await completeOrder();
      } else if (result == 'expired') {
        ShowToastDialog.showToast("Délai de paiement dépassé.".tr);
      } else {
        ShowToastDialog.showToast("Paiement annulé.".tr);
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(
        "Une erreur est survenue. Veuillez réessayer.".tr,
      );
      log('[PayDunya] intercity exception: $e');
    }
  }

  Future<void> completeOrder() async {
    if (selectedPaymentMethod.value == PaymentGateway.cod.name) {
      currentOrder.value.paymentMethod = selectedPaymentMethod.value;
      await FireStoreUtils.cabOrderPlace(currentOrder.value).then((value) {
        ShowToastDialog.showToast("Payment method changed".tr);
        Get.back();
        Get.back();
      });
    } else {
      currentOrder.value.paymentStatus = true;
      currentOrder.value.paymentMethod = selectedPaymentMethod.value;
      userModel.value.inProgressOrderID ??= [];
      userModel.value.inProgressOrderID!.clear();
      await FireStoreUtils.updateUser(userModel.value);

      if (selectedPaymentMethod.value == PaymentGateway.wallet.name) {
        WalletTransactionModel transactionModel = WalletTransactionModel(
          id: Constant.getUuid(),
          amount: double.parse(totalAmount.toString()),
          date: Timestamp.now(),
          paymentMethod: PaymentGateway.wallet.name,
          transactionUser: "customer",
          userId: FireStoreUtils.getCurrentUid(),
          isTopup: false,
          orderId: currentOrder.value.id,
          note: "Cab Amount debited".tr,
          paymentStatus: "success".tr,
          serviceType: Constant.parcelServiceType,
        );

        await FireStoreUtils.setWalletTransaction(transactionModel).then((
          value,
        ) async {
          if (value == true) {
            await FireStoreUtils.updateUserWallet(
              amount: "-${totalAmount.value.toString()}",
              userId: FireStoreUtils.getCurrentUid(),
            );
          }
        });
      }

      await FireStoreUtils.cabOrderPlace(currentOrder.value).then((value) {
        ShowToastDialog.showToast("Payment successfully".tr);
        Get.back();
      });
    }
  }

  Future<void> placeOrder() async {
    DestinationLocation sourceLocation = DestinationLocation(
      latitude:
          Constant.selectedMapType == 'osm'
              ? departureLatLongOsm.value.latitude
              : departureLatLong.value.latitude,
      longitude:
          Constant.selectedMapType == 'osm'
              ? departureLatLongOsm.value.longitude
              : departureLatLong.value.longitude,
    );

    DestinationLocation destinationLocation = DestinationLocation(
      latitude:
          Constant.selectedMapType == 'osm'
              ? destinationLatLongOsm.value.latitude
              : destinationLatLong.value.latitude,
      longitude:
          Constant.selectedMapType == 'osm'
              ? destinationLatLongOsm.value.longitude
              : destinationLatLong.value.longitude,
    );

    CabOrderModel orderModel = CabOrderModel();
    orderModel.id = const Uuid().v4();
    orderModel.distance = distance.value.toString();
    orderModel.duration = duration.value;
    orderModel.vehicleId = selectedVehicleType.value.id;
    orderModel.vehicleType = selectedVehicleType.value;
    orderModel.authorID = FireStoreUtils.getCurrentUid();
    orderModel.sourceLocationName = sourceTextEditController.value.text;
    orderModel.destinationLocationName =
        destinationTextEditController.value.text;

    orderModel.sourceLocation = sourceLocation;
    orderModel.destinationLocation = destinationLocation;
    orderModel.author = userModel.value;
    orderModel.subTotal = subTotal.value.toString();
    orderModel.discount = discount.value.toString();
    orderModel.couponCode = selectedCouponModel.value.code;
    orderModel.couponId = selectedCouponModel.value.id;

    orderModel.taxSetting = Constant.orderProductTaxList;
    orderModel.adminCommissionType =
        Constant.sectionConstantModel!.adminCommision != null &&
                Constant.sectionConstantModel!.adminCommision!.isEnabled == true
            ? Constant.sectionConstantModel!.adminCommision!.commissionType
                .toString()
            : null;
    orderModel.adminCommission =
        Constant.sectionConstantModel!.adminCommision != null &&
                Constant.sectionConstantModel!.adminCommision!.isEnabled == true
            ? Constant.sectionConstantModel!.adminCommision!.amount.toString()
            : null;
    orderModel.couponCode = couponCodeTextEditController.value.text;
    orderModel.paymentMethod = selectedPaymentMethod.value;
    orderModel.paymentStatus = false;
    orderModel.triggerDelevery = Timestamp.now();
    orderModel.tipAmount = "0.0";
    orderModel.scheduleReturnDateTime = Timestamp.now();
    orderModel.rideType = 'intercity';
    orderModel.roundTrip = false;
    orderModel.sectionId = Constant.sectionConstantModel!.id;
    orderModel.createdAt = Timestamp.now();
    orderModel.otpCode =
        (maths.Random().nextInt(9000) + 1000)
            .toString(); // Generate a 4-digit OTP
    orderModel.status = Constant.orderPlaced;
    orderModel.scheduleDateTime = Timestamp.now();
    log("Order Model : ${orderModel.toJson()}");
    ShowToastDialog.showLoader("Please wait".tr);
    await FireStoreUtils.cabOrderPlace(orderModel);
    await FireStoreUtils.sendCabBookEmail(orderModel: orderModel);
    userModel.value.inProgressOrderID!.add(orderModel.id);
    await FireStoreUtils.updateUser(userModel.value);
    ShowToastDialog.closeLoader();

    bottomSheetType.value = 'waitingForDriver';
  }

  double getAmount(VehicleType vehicleType) {
    final double currentDistance = distance.value;
    if (currentDistance <=
        (vehicleType.minimum_delivery_charges_within_km ?? 0)) {
      return double.tryParse(vehicleType.minimum_delivery_charges.toString()) ??
          0.0;
    } else {
      return (vehicleType.delivery_charges_per_km ?? 0.0) * currentDistance;
    }
  }

  void setDepartureMarker(double lat, double long) {
    if (Constant.selectedMapType == 'osm') {
      _setOsmMarker(lat, long, isDeparture: true);
    } else {
      _setGoogleMarker(lat, long, isDeparture: true);
    }
  }

  void setDestinationMarker(double lat, double lng) {
    if (Constant.selectedMapType == 'osm') {
      _setOsmMarker(lat, lng, isDeparture: false);
    } else {
      _setGoogleMarker(lat, lng, isDeparture: false);
    }
  }

  void setStopMarker(double lat, double lng, int index) {
    if (Constant.selectedMapType == 'osm') {
      // Add new stop marker without clearing
      osmMarker.add(
        flutterMap.Marker(
          point: latlong.LatLng(lat, lng),
          width: 40,
          height: 40,
          child: stopIconOsm!,
        ),
      );

      getDirections(isStopMarker: true);
    } else {
      final markerId = MarkerId('Stop $index');

      markers.removeWhere((marker) => marker.markerId == markerId);
      markers.add(
        Marker(
          markerId: markerId,
          infoWindow: InfoWindow(
            title: 'Stop ${String.fromCharCode(index + 65)}',
          ),
          position: LatLng(lat, lng),
          icon: stopIcon!,
        ),
      );

      getDirections();
    }
  }

  void _setOsmMarker(double lat, double lng, {required bool isDeparture}) {
    final marker = flutterMap.Marker(
      point: latlong.LatLng(lat, lng),
      width: 40,
      height: 40,
      child: isDeparture ? departureIconOsm! : destinationIconOsm!,
    );
    if (isDeparture) {
      departureLatLongOsm.value = latlong.LatLng(lat, lng);
    } else {
      destinationLatLongOsm.value = latlong.LatLng(lat, lng);
    }
    osmMarker.add(marker);
    if (departureLatLongOsm.value.latitude != 0 &&
        destinationLatLongOsm.value.latitude != 0) {
      getDirections();
      animateToSource(lat, lng);
    }
  }

  void _setGoogleMarker(double lat, double lng, {required bool isDeparture}) {
    final LatLng pos = LatLng(lat, lng);
    final markerId = MarkerId(isDeparture ? 'Departure' : 'Destination');
    final icon = isDeparture ? departureIcon! : destinationIcon!;
    final title = isDeparture ? 'Departure'.tr : 'Destination'.tr;

    if (isDeparture) {
      departureLatLong.value = pos;
    } else {
      destinationLatLong.value = pos;
    }

    // Remove only the matching departure/destination marker
    markers.removeWhere((marker) => marker.markerId == markerId);

    // Add new marker
    markers.add(
      Marker(
        markerId: markerId,
        position: pos,
        icon: icon,
        infoWindow: InfoWindow(title: title),
      ),
    );

    mapController.animateCamera(CameraUpdate.newLatLngZoom(pos, 14));

    if (departureLatLong.value.latitude != 0 &&
        destinationLatLong.value.latitude != 0) {
      getDirections();
    } else {
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(lat, lng), zoom: 14),
        ),
      );
    }
  }

  Future<void> getDirections({bool isStopMarker = false}) async {
    if (Constant.selectedMapType == 'osm') {
      final wayPoints = <latlong.LatLng>[];

      // Only add valid source
      if (departureLatLongOsm.value.latitude != 0.0 &&
          departureLatLongOsm.value.longitude != 0.0) {
        wayPoints.add(departureLatLongOsm.value);
      }

      // Only add valid destination
      if (destinationLatLongOsm.value.latitude != 0.0 &&
          destinationLatLongOsm.value.longitude != 0.0) {
        wayPoints.add(destinationLatLongOsm.value);
      }

      if (!isStopMarker) osmMarker.clear();

      // Add source marker
      if (departureLatLongOsm.value.latitude != 0.0 &&
          departureLatLongOsm.value.longitude != 0.0) {
        osmMarker.add(
          flutterMap.Marker(
            point: departureLatLongOsm.value,
            width: 40,
            height: 40,
            child: departureIconOsm!,
          ),
        );
      }

      // Add destination marker
      if (destinationLatLongOsm.value.latitude != 0.0 &&
          destinationLatLongOsm.value.longitude != 0.0) {
        osmMarker.add(
          flutterMap.Marker(
            point: destinationLatLongOsm.value,
            width: 40,
            height: 40,
            child: destinationIconOsm!,
          ),
        );
      }

      if (wayPoints.length >= 2) {
        await fetchRouteWithWaypoints(wayPoints);
      }
    } else {
      // Google Maps path
      fetchGoogleRouteWithWaypoints();
    }
  }

  Future<void> fetchGoogleRouteWithWaypoints() async {
    if (departureLatLong.value.latitude == 0.0 ||
        destinationLatLong.value.latitude == 0.0)
      return;

    final origin =
        '${departureLatLong.value.latitude},${departureLatLong.value.longitude}';
    final destination =
        '${destinationLatLong.value.latitude},${destinationLatLong.value.longitude}';

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=$origin&destination=$destination'
      '&mode=driving&key=${Constant.mapAPIKey}',
    );

    try {
      final response = await http.get(url);
      final data = json.decode(response.body);
      log("=======>$data");
      if (data['status'] == 'OK') {
        final route = data['routes'][0];
        final legs = route['legs'] as List;

        // Polyline
        final encodedPolyline = route['overview_polyline']['points'];
        final decodedPoints = PolylinePoints.decodePolyline(encodedPolyline);
        final coordinates =
            decodedPoints.map((e) => LatLng(e.latitude, e.longitude)).toList();

        addPolyLine(coordinates);

        // Distance & Duration
        num totalDistance = 0;
        num totalDuration = 0;
        for (var leg in legs) {
          totalDistance += leg['distance']['value']!; // meters
          totalDuration += leg['duration']['value']!; // seconds
        }

        // Convert distance to KM or Miles
        if (Constant.distanceType.toLowerCase() == "KM".toLowerCase()) {
          distance.value = totalDistance / 1000.0;
        } else {
          distance.value = totalDistance / 1609.34;
        }

        // Format duration
        final hours = totalDuration ~/ 3600;
        final minutes = ((totalDuration % 3600) / 60).round();
        duration.value = '${hours}h ${minutes}m';
      } else {
        print('Google Directions API Error: ${data['status']}');
      }
    } catch (e) {
      print("Google route fetch error: $e");
    }
  }

  Future<void> fetchRouteWithWaypoints(List<latlong.LatLng> points) async {
    final coordinates = points
        .map((p) => '${p.longitude},${p.latitude}')
        .join(';');
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/$coordinates?overview=full&geometries=geojson',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final geometry =
            decoded['routes'][0]['geometry']['coordinates'] as List;
        final dist = decoded['routes'][0]['distance'];
        final dur = decoded['routes'][0]['duration'];

        routePoints.clear();
        routePoints.addAll(
          geometry.map((coord) => latlong.LatLng(coord[1], coord[0])),
        );

        if (Constant.distanceType.toLowerCase() == "KM".toLowerCase()) {
          distance.value = dist / 1000.00;
        } else {
          distance.value = dist / 1609.34;
        }

        final hours = dur ~/ 3600;
        final minutes = ((dur % 3600) / 60).round();
        duration.value = '${hours}h ${minutes}m';

        // Zoom to fit polyline after drawing
        zoomToPolylineOSM();
      } else {
        print("Failed to get route: ${response.body}");
      }
    } catch (e) {
      print("Route fetch error: $e");
    }
  }

  void zoomToPolylineOSM() {
    if (routePoints.isEmpty) return;
    // LatLngBounds requires at least two points
    final bounds = flutterMap.LatLngBounds(
      routePoints.first,
      routePoints.first,
    );
    for (final point in routePoints) {
      bounds.extend(point);
    }
    final center = bounds.center;
    // Calculate zoom level to fit all points
    double zoom = getBoundsZoomLevel(bounds);
    mapOsmController.move(center, zoom);
  }

  double getBoundsZoomLevel(flutterMap.LatLngBounds bounds) {
    // Simple heuristic: zoom out for larger bounds
    final latDiff =
        (bounds.northEast.latitude - bounds.southWest.latitude).abs();
    final lngDiff =
        (bounds.northEast.longitude - bounds.southWest.longitude).abs();
    double maxDiff = math.max(latDiff, lngDiff);
    if (maxDiff < 0.005) return 18.0;
    if (maxDiff < 0.01) return 16.0;
    if (maxDiff < 0.05) return 14.0;
    if (maxDiff < 0.1) return 12.0;
    if (maxDiff < 0.5) return 10.0;
    return 8.0;
  }

  void addPolyLine(List<LatLng> points) {
    final id = const PolylineId("poly");
    final polyline = Polyline(
      polylineId: id,
      color: AppThemeData.primary300,
      points: points,
      width: 6,
      geodesic: true,
    );
    polyLines[id] = polyline;

    if (points.length >= 2) {
      // Zoom to fit all polyline points
      updateCameraLocationToFitPolyline(points, mapController);
    }
  }

  Future<void> updateCameraLocationToFitPolyline(
    List<LatLng> points,
    GoogleMapController? mapController,
  ) async {
    if (mapController == null || points.isEmpty) return;
    double minLat = points.first.latitude, maxLat = points.first.latitude;
    double minLng = points.first.longitude, maxLng = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    final cameraUpdate = CameraUpdate.newLatLngBounds(bounds, 50);
    await checkCameraLocation(cameraUpdate, mapController);
  }

  Future<void> animateToSource(double lat, double long) async {
    final hasBothCoords =
        departureLatLongOsm.value.latitude != 0.0 &&
        destinationLatLongOsm.value.latitude != 0.0;

    if (hasBothCoords) {
      await calculateZoomLevel(
        source: departureLatLongOsm.value,
        destination: destinationLatLongOsm.value,
      );
    } else {
      mapOsmController.move(latlong.LatLng(lat, long), 10);
    }
  }

  RxMap<PolylineId, Polyline> polyLines = <PolylineId, Polyline>{}.obs;

  Future<void> calculateZoomLevel({
    required latlong.LatLng source,
    required latlong.LatLng destination,
    double paddingFraction = 0.001,
  }) async {
    final bounds = flutterMap.LatLngBounds.fromPoints([source, destination]);
    final screenSize = Size(Get.width, Get.height * 0.5);
    const double worldDimension = 256.0;
    const double maxZoom = 10.0;

    double latToRad(double lat) =>
        math.log(
          (1 + math.sin(lat * math.pi / 180)) /
              (1 - math.sin(lat * math.pi / 180)),
        ) /
        2;

    double computeZoom(double screenPx, double worldPx, double fraction) =>
        math.log(screenPx / worldPx / fraction) / math.ln2;

    final north = bounds.northEast.latitude;
    final south = bounds.southWest.latitude;
    final east = bounds.northEast.longitude;
    final west = bounds.southWest.longitude;

    final latDelta = (north - south).abs();
    final lngDelta = (east - west).abs();

    final center = bounds.center;

    if (latDelta < 1e-6 || lngDelta < 1e-6) {
      mapOsmController.move(center, maxZoom);
    } else {
      final latFraction = (latToRad(north) - latToRad(south)) / math.pi;
      final lngFraction = ((east - west + 360) % 360) / 360;

      final latZoom = computeZoom(
        screenSize.height,
        worldDimension,
        latFraction + paddingFraction,
      );
      final lngZoom = computeZoom(
        screenSize.width,
        worldDimension,
        lngFraction + paddingFraction,
      );

      final zoomLevel = math.min(latZoom, lngZoom).clamp(0.0, maxZoom);
      mapOsmController.move(center, zoomLevel);
    }
  }

  Future<void> updateCameraLocation(
    LatLng source,
    LatLng destination,
    GoogleMapController? mapController,
  ) async {
    if (mapController == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        math.min(source.latitude, destination.latitude),
        math.min(source.longitude, destination.longitude),
      ),
      northeast: LatLng(
        math.max(source.latitude, destination.latitude),
        math.max(source.longitude, destination.longitude),
      ),
    );

    final cameraUpdate = CameraUpdate.newLatLngBounds(bounds, 90);
    await checkCameraLocation(cameraUpdate, mapController);
  }

  Future<void> checkCameraLocation(
    CameraUpdate cameraUpdate,
    GoogleMapController mapController,
  ) async {
    await mapController.animateCamera(cameraUpdate);
    final l1 = await mapController.getVisibleRegion();
    final l2 = await mapController.getVisibleRegion();

    if (l1.southwest.latitude == -90 || l2.southwest.latitude == -90) {
      await checkCameraLocation(cameraUpdate, mapController);
    }
  }

  Future<void> setIcons() async {
    try {
      if (Constant.selectedMapType == 'osm') {
        departureIconOsm = Image.asset(
          "assets/icons/pickup.png",
          width: 30,
          height: 30,
        );
        destinationIconOsm = Image.asset(
          "assets/icons/dropoff.png",
          width: 30,
          height: 30,
        );
        taxiIconOsm = Image.asset(
          "assets/icons/ic_taxi.png",
          width: 30,
          height: 30,
        );
        stopIconOsm = Image.asset(
          "assets/icons/location.png",
          width: 26,
          height: 26,
        );
      } else {
        const config = ImageConfiguration(size: Size(48, 48));
        departureIcon = await BitmapDescriptor.fromAssetImage(
          config,
          "assets/icons/pickup.png",
        );
        destinationIcon = await BitmapDescriptor.fromAssetImage(
          config,
          "assets/icons/dropoff.png",
        );
        taxiIcon = await BitmapDescriptor.fromAssetImage(
          config,
          "assets/icons/ic_taxi.png",
        );
        stopIcon = await BitmapDescriptor.fromAssetImage(
          config,
          "assets/icons/location.png",
        );
      }
    } catch (e) {
      print('Error loading icons: $e');
    }
  }

  void clearMapDataIfLocationsRemoved() {
    final isSourceEmpty =
        departureLatLongOsm.value.latitude == 0.0 &&
        departureLatLongOsm.value.longitude == 0.0;
    final isDestinationEmpty =
        destinationLatLongOsm.value.latitude == 0.0 &&
        destinationLatLongOsm.value.longitude == 0.0;

    if (isSourceEmpty || isDestinationEmpty) {
      // Clear polylines
      polyLines.clear();

      // Clear OSM markers (if using OSM)
      osmMarker.clear();

      // Clear Google markers (if using Google Maps)
      markers.clear();

      // Clear route points (optional)
      routePoints.clear();

      // Reset distance and duration values
      distance.value = 0.0;
      duration.value = '';
    }
  }

  void removeSource() {
    // Clear departure location and related data
    departureLatLongOsm.value = latlong.LatLng(0.0, 0.0);
    departureLatLong.value = const LatLng(0.0, 0.0);
    sourceTextEditController.value.clear();

    // Remove marker
    if (Constant.selectedMapType == 'osm') {
      osmMarker.removeWhere(
        (marker) => marker.point == departureLatLongOsm.value,
      );
    } else {
      markers.removeWhere((marker) => marker.markerId.value == 'Departure');
    }

    // Clear polylines and route info if needed
    clearMapDataIfLocationsRemoved();
    update();
  }

  void removeDestination() {
    destinationLatLongOsm.value = latlong.LatLng(0.0, 0.0);
    destinationLatLong.value = const LatLng(0.0, 0.0);
    destinationTextEditController.value.clear();

    if (Constant.selectedMapType == 'osm') {
      osmMarker.removeWhere(
        (marker) => marker.point == destinationLatLongOsm.value,
      );
    } else {
      markers.removeWhere((marker) => marker.markerId.value == 'Destination');
    }

    clearMapDataIfLocationsRemoved();
    update();
  }

  Future<void> searchPlaceNameOSM() async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?lat=${departureLatLongOsm.value.latitude}&lon=${departureLatLongOsm.value.longitude}&format=json&addressdetails=1',
    );

    final response = await http.get(
      url,
      headers: {
        'User-Agent': 'FlutterMapApp/1.0 (menil.siddhiinfosoft@gmail.com)',
      },
    );

    if (response.statusCode == 200) {
      log("response.body :: ${response.body}");
      Map<String, dynamic> data = json.decode(response.body);
      sourceTextEditController.value.text = AddressFormatter.shortAddress(
        data['display_name']?.toString(),
        addressDetails:
            data['address'] is Map<String, dynamic>
                ? data['address'] as Map<String, dynamic>
                : null,
      );
    }
  }

  Future<void> searchPlaceNameGoogle() async {
    final lat = departureLatLong.value.latitude;
    final lng = departureLatLong.value.longitude;

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=${Constant.mapAPIKey}',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        final results = data['results'] as List;
        if (results.isNotEmpty) {
          final formattedAddress = results[0]['formatted_address'];
          sourceTextEditController.value.text = formattedAddress;
        }
      } else {
        log("Google API Error: ${data['status']}");
      }
    } else {
      log("HTTP Error: ${response.statusCode}");
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  Rx<WalletSettingModel> walletSettingModel = WalletSettingModel().obs;
  Rx<CodSettingModel> cashOnDeliverySettingModel = CodSettingModel().obs;
  Rx<PaydunyaConfigModel> paydunyaConfig = PaydunyaConfigModel().obs;

  Future<void> getPaymentSettings() async {
    await FireStoreUtils.getPaymentSettingsData().then((value) {
      walletSettingModel.value = WalletSettingModel.fromJson(
        jsonDecode(Preferences.getString(Preferences.walletSettings)),
      );
      cashOnDeliverySettingModel.value = CodSettingModel.fromJson(
        jsonDecode(Preferences.getString(Preferences.codSettings)),
      );

      if (walletSettingModel.value.isEnabled == true) {
        selectedPaymentMethod.value = PaymentGateway.wallet.name;
      } else if (cashOnDeliverySettingModel.value.isEnabled == true) {
        selectedPaymentMethod.value = PaymentGateway.cod.name;
      }

      final paydunyaPrefs = Preferences.getString(
        Preferences.paydunyaSettings,
        defaultValue: '',
      );
      if (paydunyaPrefs.isNotEmpty) {
        paydunyaConfig.value = PaydunyaConfigModel.fromJson(
          jsonDecode(paydunyaPrefs),
        );
        if (paydunyaConfig.value.isEnabled &&
            selectedPaymentMethod.value.isEmpty) {
          selectedPaymentMethod.value = PaymentGateway.paydunya.name;
        }
      }
    });
  }

  bool isCurrentDateInRange(DateTime startDate, DateTime endDate) {
    final currentDate = DateTime.now();
    return currentDate.isAfter(startDate) && currentDate.isBefore(endDate);
  }
}
