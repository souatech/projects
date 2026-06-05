import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/controllers/dash_board_controller.dart';
import 'package:customer/models/advertisement_model.dart';
import 'package:customer/models/coupon_model.dart';
import 'package:customer/models/favourite_model.dart';
import 'package:customer/models/vendor_category_model.dart';
import 'package:customer/models/vendor_model.dart';
import 'package:customer/utils/preferences.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/banner_model.dart';
import '../models/story_model.dart';
import '../service/cart_provider.dart';
import '../service/fire_store_utils.dart';

class FoodHomeController extends GetxController {
  DashBoardController dashBoardController = Get.find<DashBoardController>();
  final CartProvider cartProvider = CartProvider();

  StreamSubscription? _cartSub;
  StreamSubscription? _restaurantSub;

  Future<void> getCartData() async {
    _cartSub?.cancel();
    _cartSub = cartProvider.cartStream.listen((event) async {
      cartItem.clear();
      cartItem.addAll(event);
    });
    update();
  }

  RxBool isLoading = true.obs;
  RxBool isListView = true.obs;
  RxBool isPopular = true.obs;
  RxString selectedOrderTypeValue = "Delivery".obs;

  Rx<PageController> pageController =
      PageController(viewportFraction: 0.877).obs;
  Rx<PageController> pageBottomController =
      PageController(viewportFraction: 0.877).obs;
  RxInt currentPage = 0.obs;
  RxInt currentBottomPage = 0.obs;

  late TabController tabController;

  @override
  void onInit() async {
    await getData();
    super.onInit();
  }

  RxList<VendorCategoryModel> vendorCategoryModel = <VendorCategoryModel>[].obs;

  RxList<VendorModel> allNearestRestaurant = <VendorModel>[].obs;
  RxList<VendorModel> newArrivalRestaurantList = <VendorModel>[].obs;
  RxList<AdvertisementModel> advertisementList = <AdvertisementModel>[].obs;
  RxList<VendorModel> popularRestaurantList = <VendorModel>[].obs;
  RxList<VendorModel> couponRestaurantList = <VendorModel>[].obs;
  RxList<CouponModel> couponList = <CouponModel>[].obs;

  RxList<StoryModel> storyList = <StoryModel>[].obs;
  RxList<BannerModel> bannerModel = <BannerModel>[].obs;
  RxList<BannerModel> bannerBottomModel = <BannerModel>[].obs;

  RxList<FavouriteModel> favouriteList = <FavouriteModel>[].obs;

  Future<void> getData() async {
    final section = Constant.sectionConstantModel;
    // ignore: avoid_print
    print(
      "[SECTION_RECEIVED] screen=Multivendor sectionId=${section?.id} sectionName=${section?.name} type=${section?.serviceType}",
    );
    // ignore: avoid_print
    print("[SECTION_LOAD] screen=Multivendor sectionId=${section?.id}");
    isLoading.value = true;
    vendorCategoryModel.clear();
    allNearestRestaurant.clear();
    newArrivalRestaurantList.clear();
    advertisementList.clear();
    popularRestaurantList.clear();
    couponRestaurantList.clear();
    couponList.clear();
    storyList.clear();
    bannerModel.clear();
    bannerBottomModel.clear();
    getCartData();
    selectedOrderTypeValue.value = _normalizeOrderType(
      Preferences.getString(
        Preferences.foodDeliveryType,
        defaultValue: "Delivery",
      ),
    );
    await getZone();
    _restaurantSub?.cancel();
    _restaurantSub = FireStoreUtils.getAllNearestRestaurant().listen((
      event,
    ) async {
      popularRestaurantList.clear();
      newArrivalRestaurantList.clear();
      allNearestRestaurant.clear();
      advertisementList.clear();

      allNearestRestaurant.addAll(event);
      newArrivalRestaurantList.addAll(event);
      popularRestaurantList.addAll(event);
      Constant.restaurantList = allNearestRestaurant;
      popularRestaurantList.sort(
        (a, b) => Constant.calculateReview(
          reviewCount: b.reviewsCount.toString(),
          reviewSum: b.reviewsSum.toString(),
        ).compareTo(
          Constant.calculateReview(
            reviewCount: a.reviewsCount.toString(),
            reviewSum: a.reviewsSum.toString(),
          ),
        ),
      );

      newArrivalRestaurantList.sort(
        (a, b) => (b.createdAt ?? Timestamp.now()).toDate().compareTo(
          (a.createdAt ?? Timestamp.now()).toDate(),
        ),
      );
      await getVendorCategory();
      await FireStoreUtils.getHomeCoupon().then((value) {
        couponRestaurantList.clear();
        couponList.clear();
        for (var element1 in value) {
          for (var element in allNearestRestaurant) {
            if (element1.vendorID == element.id &&
                element1.expiresAt!.toDate().isAfter(DateTime.now())) {
              couponList.add(element1);
              couponRestaurantList.add(element);
            }
          }
        }
      });

      await FireStoreUtils.getStory().then((stories) {
        storyList.clear();

        // ignore: avoid_print
        print("Total stories fetched: ${stories.length}");
        // Create a fast lookup Set of all nearest vendor IDs
        final nearestIds = allNearestRestaurant.map((e) => e.id).toSet();

        // ignore: avoid_print
        print("nearestIds: $nearestIds");
        // Filter stories whose vendorID exists in nearestIds
        storyList.addAll(
          stories.where((story) => nearestIds.contains(story.vendorID)),
        );
        // ignore: avoid_print
        print("Filtered storyList length: ${storyList.length}");
      });

      if (Constant.isEnableAdsFeature == true) {
        await FireStoreUtils.getAllAdvertisement().then((value) {
          advertisementList.clear();
          for (var element1 in value) {
            for (var element in allNearestRestaurant) {
              if (element1.vendorId == element.id) {
                advertisementList.add(element1);
              }
            }
          }
        });
      }
    });
    setLoading();
  }

  String _normalizeOrderType(String v) {
    const translated = {
      'Livraison': 'Delivery',
      'À emporter': 'TakeAway',
      'توصيل': 'Delivery',
      'استلام': 'TakeAway',
    };
    return translated[v] ?? v;
  }

  Future<void> setLoading() async {
    await Future.delayed(Duration(seconds: 1), () async {
      if (allNearestRestaurant.isEmpty) {
        await Future.delayed(Duration(seconds: 2), () {
          isLoading.value = false;
        });
      } else {
        isLoading.value = false;
      }
      update();
    });
  }

  Future<void> getVendorCategory() async {
    await FireStoreUtils.getHomeVendorCategory().then((value) {
      vendorCategoryModel.value = value;
      if (Constant.restaurantList != null) {
        List<String> usedCategoryIds =
            Constant.restaurantList!
                .expand((vendor) => vendor.categoryID ?? [])
                .whereType<String>()
                .toSet()
                .toList();
        vendorCategoryModel.value =
            vendorCategoryModel
                .where((category) => usedCategoryIds.contains(category.id))
                .toList();
      }
    });

    await FireStoreUtils.getHomeTopBanner().then((value) {
      bannerModel.value = value;
    });

    await FireStoreUtils.getHomeBottomBanner().then((value) {
      bannerBottomModel.value = value;
    });

    await getFavouriteRestaurant();
  }

  Future<void> getFavouriteRestaurant() async {
    if (Constant.userModel?.id != null) {
      await FireStoreUtils.getFavouriteRestaurant().then((value) {
        favouriteList.value = value;
      });
    }
    log("Constant.userModel?.id :: ${favouriteList.length}");
  }

  @override
  void onClose() {
    _cartSub?.cancel();
    _restaurantSub?.cancel();
    pageController.value.dispose();
    pageBottomController.value.dispose();
    super.onClose();
  }

  Future<void> getZone() async {
    await FireStoreUtils.getZone().then((value) {
      if (value != null) {
        for (int i = 0; i < value.length; i++) {
          if (Constant.isPointInPolygon(
            LatLng(
              Constant.selectedLocation.location?.latitude ?? 0.0,
              Constant.selectedLocation.location?.longitude ?? 0.0,
            ),
            value[i].area!,
          )) {
            Constant.selectedZone = value[i];
            Constant.isZoneAvailable = true;
            break;
          } else {
            Constant.selectedZone = value[i];
            Constant.isZoneAvailable = false;
          }
        }
      }
    });
  }
}
