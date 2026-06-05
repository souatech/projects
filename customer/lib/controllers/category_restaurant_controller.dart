import 'dart:async';

import 'package:customer/constant/constant.dart';
import 'package:customer/models/advertisement_model.dart';
import 'package:customer/models/coupon_model.dart';
import 'package:customer/models/vendor_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/vendor_category_model.dart';
import '../service/fire_store_utils.dart';
import 'package:get/get.dart';

class CategoryRestaurantController extends GetxController {
  RxBool isLoading = true.obs;
  RxBool dineIn = true.obs;
  RxBool ecommarce = true.obs;

  @override
  void onInit() {
    // TODO: implement onInit
    getArgument();
    super.onInit();
  }

  Rx<VendorCategoryModel> vendorCategoryModel = VendorCategoryModel().obs;
  RxList<VendorModel> allNearestRestaurant = <VendorModel>[].obs;
  RxList<AdvertisementModel> categoryAdvertisements =
      <AdvertisementModel>[].obs;
  RxList<CouponModel> categoryCoupons = <CouponModel>[].obs;
  RxList<VendorModel> couponVendors = <VendorModel>[].obs;
  StreamSubscription? _restaurantSub;

  Future<void> getArgument() async {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      vendorCategoryModel.value = argumentData['vendorCategoryModel'];
      dineIn.value = argumentData['dineIn'];
      ecommarce.value = argumentData['ecommerce'] ?? false;
      await getZone();
      await getRestaurant();
    }
    Future.delayed(Duration(seconds: 1), () {
      isLoading.value = false;
    });
  }

  Future getRestaurant() async {
    _restaurantSub?.cancel();
    _restaurantSub = FireStoreUtils.getAllNearestRestaurantByCategoryId(
      categoryId: vendorCategoryModel.value.id.toString(),
      isDining: dineIn.value,
    ).listen((event) async {
      allNearestRestaurant.value = event;
      await loadCategoryBusinessSections();
    });
  }

  Future<void> loadCategoryBusinessSections() async {
    final vendorIds =
        allNearestRestaurant
            .map((vendor) => vendor.id)
            .whereType<String>()
            .toSet();
    if (vendorIds.isEmpty) {
      categoryAdvertisements.clear();
      categoryCoupons.clear();
      couponVendors.clear();
      return;
    }

    await FireStoreUtils.getAllAdvertisement().then((value) {
      categoryAdvertisements.value =
          value.where((ad) => vendorIds.contains(ad.vendorId)).toList();
    });

    await FireStoreUtils.getHomeCoupon().then((value) {
      categoryCoupons.clear();
      couponVendors.clear();
      for (final coupon in value) {
        if (!vendorIds.contains(coupon.vendorID)) {
          continue;
        }
        final vendor = allNearestRestaurant.firstWhereOrNull(
          (item) => item.id == coupon.vendorID,
        );
        if (vendor != null) {
          categoryCoupons.add(coupon);
          couponVendors.add(vendor);
        }
      }
    });
  }

  Future<void> getZone() async {
    await FireStoreUtils.getZone().then((value) {
      if (value != null) {
        for (int i = 0; i < value.length; i++) {
          if (Constant.isPointInPolygon(
            LatLng(
              Constant.selectedLocation.location!.latitude ?? 0.0,
              Constant.selectedLocation.location!.longitude ?? 0.0,
            ),
            value[i].area!,
          )) {
            Constant.selectedZone = value[i];
            Constant.isZoneAvailable = true;
            break;
          } else {
            Constant.isZoneAvailable = false;
          }
        }
      }
    });
  }

  @override
  void onClose() {
    _restaurantSub?.cancel();
    super.onClose();
  }
}
