// ignore_for_file: depend_on_referenced_packages, deprecated_member_use, unnecessary_underscores

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/controllers/map_view_controller.dart';
import 'package:customer/models/advertisement_model.dart';
import 'package:customer/models/coupon_model.dart';
import 'package:customer/models/favourite_model.dart';
import 'package:customer/models/order_model.dart';
import 'package:customer/models/product_model.dart';
import 'package:customer/models/user_model.dart';
import 'package:customer/models/vendor_category_model.dart';
import 'package:customer/models/vendor_model.dart';
import 'package:customer/screen_ui/location_enable_screens/address_list_screen.dart';
import 'package:customer/screen_ui/location_enable_screens/location_permission_screen.dart';
import 'package:customer/screen_ui/multi_vendor_service/home_screen/restaurant_list_screen.dart';
import 'package:customer/screen_ui/multi_vendor_service/home_screen/story_view.dart';
import 'package:customer/themes/app_them_data.dart';
import 'package:customer/themes/custom_dialog_box.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/themes/round_button_fill.dart';
import 'package:customer/utils/network_image_widget.dart';
import 'package:customer/utils/preferences.dart';
import 'package:customer/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as flutter_map;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as location;
import 'package:url_launcher/url_launcher.dart';

import '../../../controllers/food_home_controller.dart';
import '../../../controllers/dash_board_controller.dart';
import '../../../controllers/theme_controller.dart';
import '../../../models/banner_model.dart';
import '../../../models/story_model.dart';
import '../../../service/database_helper.dart';
import '../../../service/fire_store_utils.dart';
import '../../../themes/show_toast_dialog.dart';
import '../../../widget/restaurant_image_view.dart';
import '../../../widget/video_widget.dart';
import '../advertisement_screens/all_advertisement_screen.dart';
import '../order_list_screen/order_details_screen.dart';
import '../restaurant_details_screen/restaurant_details_screen.dart';
import '../search_screen/search_screen.dart';
import '../../help_support_screen/help_support_screen.dart';
import 'category_restaurant_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'discount_restaurant_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const Color _bg = Color(0xFFF8F9FB);
  static const Color _orange = Color(0xFFFF4B12);
  static const Color _ink = Color(0xFF111111);

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDark.value;
    return GetX(
      init: FoodHomeController(),
      builder: (controller) {
        if (controller.isLoading.value) {
          return Scaffold(
            backgroundColor: isDark ? AppThemeData.surfaceDark : _bg,
            body: _buildHomeShimmer(isDark),
          );
        }

        if (Constant.isZoneAvailable == false ||
            controller.allNearestRestaurant.isEmpty) {
          return Scaffold(
            backgroundColor: isDark ? AppThemeData.surfaceDark : _bg,
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset("assets/images/location.gif", height: 120),
                  const SizedBox(height: 12),
                  Text(
                    "No Store Found in Your Area".tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color:
                          isDark ? AppThemeData.grey100 : AppThemeData.grey800,
                      fontSize: 22,
                      fontFamily: AppThemeData.semiBold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Currently, there are no available store in your zone. Try changing your location to find nearby options."
                        .tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color:
                          isDark ? AppThemeData.grey50 : AppThemeData.grey500,
                      fontSize: 16,
                      fontFamily: AppThemeData.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  RoundedButtonFill(
                    title: "Change Zone".tr,
                    width: 55,
                    height: 5.5,
                    color: AppThemeData.primary300,
                    textColor: AppThemeData.grey50,
                    onPress:
                        () async =>
                            Get.offAll(const LocationPermissionScreen()),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: isDark ? AppThemeData.surfaceDark : _bg,
          body:
              controller.isListView.value == false
                  ? const MapView()
                  : SafeArea(
                    child: RefreshIndicator(
                      color: _orange,
                      onRefresh: controller.getData,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: _FoodHeader(
                              controller: controller,
                              isDark: isDark,
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: _FoodSearchRow(
                              controller: controller,
                              isDark: isDark,
                            ),
                          ),
                          if (controller.vendorCategoryModel.isNotEmpty)
                            SliverToBoxAdapter(
                              child: _FoodCategoryStrip(
                                controller: controller,
                                isDark: isDark,
                              ),
                            ),
                          SliverToBoxAdapter(
                            child: _FoodHeroBanner(
                              controller: controller,
                              isDark: isDark,
                            ),
                          ),
                          if (Constant.isEnableAdsFeature == true &&
                              controller.advertisementList.isNotEmpty)
                            SliverToBoxAdapter(
                              child: _SponsoredRestaurants(
                                controller: controller,
                                isDark: isDark,
                              ),
                            ),
                          if (controller.popularRestaurantList.isNotEmpty)
                            SliverToBoxAdapter(
                              child: _PopularRestaurantsSection(
                                controller: controller,
                                isDark: isDark,
                              ),
                            ),
                          if (controller.couponRestaurantList.isNotEmpty &&
                              controller.couponList.isNotEmpty)
                            SliverToBoxAdapter(
                              child: _SpecialOffersSection(
                                controller: controller,
                                isDark: isDark,
                              ),
                            ),
                          SliverToBoxAdapter(
                            child: _FoodRecentOrders(isDark: isDark),
                          ),
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height:
                                  24 + MediaQuery.of(context).padding.bottom,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
        );
      },
    );
  }
}

class _FoodHeader extends StatelessWidget {
  final FoodHomeController controller;
  final bool isDark;

  const _FoodHeader({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final String address =
        Constant.selectedLocation.getFullAddress().isEmpty
            ? 'Sélectionner une adresse'.tr
            : Utils.shortAddressFromText(
              Constant.selectedLocation.getFullAddress(),
              fallback: 'Sélectionner une adresse'.tr,
            );
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/icons/joxmako_icon.png',
                width: 112,
                height: 76,
                fit: BoxFit.contain,
              ),
              const Spacer(),
              _FoodCircleButton(
                icon: Icons.notifications_none_rounded,
                isDark: isDark,
                onTap:
                    () => Get.to(
                      HelpSupportScreen(isNavigateViaNotification: true),
                    ),
              ),
              const SizedBox(width: 12),
              _FoodAvatar(isDark: isDark),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _openAddressPicker(context, controller),
            borderRadius: BorderRadius.circular(18),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: HomeScreen._orange,
                  size: 36,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Livraison à'.tr,
                        style: AppThemeData.mediumTextStyle(
                          fontSize: 13,
                          color:
                              isDark
                                  ? AppThemeData.grey300
                                  : AppThemeData.grey500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppThemeData.boldTextStyle(
                          fontSize: 18,
                          color: isDark ? AppThemeData.grey50 : HomeScreen._ink,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: HomeScreen._orange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodCircleButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _FoodCircleButton({
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: isDark ? AppThemeData.grey800 : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [_foodShadow(isDark)],
          ),
          child: Icon(
            icon,
            color: isDark ? AppThemeData.grey50 : HomeScreen._ink,
            size: 26,
          ),
        ),
      ),
    );
  }
}

class _FoodAvatar extends StatelessWidget {
  final bool isDark;

  const _FoodAvatar({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final String imageUrl = Constant.userModel?.profilePictureURL ?? '';
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: () {
        final dashboardController =
            Get.isRegistered<DashBoardController>()
                ? Get.find<DashBoardController>()
                : Get.put(DashBoardController());
        dashboardController.selectedIndex.value = 3;
      },
      child: Container(
        width: 54,
        height: 54,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isDark ? AppThemeData.grey800 : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [_foodShadow(isDark)],
        ),
        child: ClipOval(
          child:
              imageUrl.isEmpty
                  ? Image.asset(Constant.userPlaceHolder, fit: BoxFit.cover)
                  : NetworkImageWidget(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    showShimmer: false,
                  ),
        ),
      ),
    );
  }
}

class _FoodSearchRow extends StatelessWidget {
  final FoodHomeController controller;
  final bool isDark;

  const _FoodSearchRow({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap:
                  () => Get.to(
                    const SearchScreen(),
                    arguments: {'vendorList': controller.allNearestRestaurant},
                  ),
              borderRadius: BorderRadius.circular(28),
              child: Container(
                height: 58,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: isDark ? AppThemeData.grey800 : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [_foodShadow(isDark)],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      color:
                          isDark ? AppThemeData.grey200 : AppThemeData.grey700,
                      size: 27,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Rechercher un plat, un restaurant...'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppThemeData.mediumTextStyle(
                          fontSize: 15,
                          color:
                              isDark
                                  ? AppThemeData.grey300
                                  : AppThemeData.grey500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          _FoodCircleButton(
            icon: Icons.tune_rounded,
            isDark: isDark,
            onTap: () => _showFoodModeSheet(context, controller, isDark),
          ),
        ],
      ),
    );
  }
}

class _FoodCategoryStrip extends StatelessWidget {
  final FoodHomeController controller;
  final bool isDark;

  const _FoodCategoryStrip({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final categories = controller.vendorCategoryModel;
    return SizedBox(
      height: 98,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _FoodCategoryTile(
              title: 'Tout'.tr,
              imageUrl: Constant.sectionConstantModel?.sectionImage ?? '',
              selected: true,
              isDark: isDark,
              onTap:
                  () => Get.to(
                    const RestaurantListScreen(),
                    arguments: {
                      'vendorList': controller.allNearestRestaurant,
                      'title': 'Restaurants'.tr,
                    },
                  ),
            );
          }
          final category = categories[index - 1];
          return _FoodCategoryTile(
            title: category.title ?? '',
            imageUrl: category.photo ?? '',
            isDark: isDark,
            onTap:
                () => Get.to(
                  const CategoryRestaurantScreen(),
                  arguments: {'vendorCategoryModel': category, 'dineIn': false},
                ),
          );
        },
      ),
    );
  }
}

class _FoodCategoryTile extends StatelessWidget {
  final String title;
  final String imageUrl;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _FoodCategoryTile({
    required this.title,
    this.imageUrl = '',
    this.selected = false,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 88,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color:
              selected
                  ? HomeScreen._orange
                  : isDark
                  ? AppThemeData.grey800
                  : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [_foodTinyShadow(isDark)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imageUrl.isNotEmpty)
              NetworkImageWidget(
                imageUrl: imageUrl,
                width: 32,
                height: 32,
                fit: BoxFit.contain,
                showShimmer: false,
              )
            else
              Text(
                _foodInitials(title),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppThemeData.boldTextStyle(
                  fontSize: 14,
                  color: selected ? Colors.white : HomeScreen._orange,
                ),
              ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppThemeData.semiBoldTextStyle(
                fontSize: 12,
                color:
                    selected
                        ? Colors.white
                        : isDark
                        ? AppThemeData.grey50
                        : HomeScreen._ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoodHeroBanner extends StatelessWidget {
  final FoodHomeController controller;
  final bool isDark;

  const _FoodHeroBanner({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (controller.bannerModel.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BannerView(controller: controller),
      ),
    );
  }
}

class _SponsoredRestaurants extends StatelessWidget {
  final FoodHomeController controller;
  final bool isDark;

  const _SponsoredRestaurants({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return _FoodSection(
      title: 'Restaurants sponsorisés',
      isDark: isDark,
      onViewAll:
          () => Get.to(
            AllAdvertisementScreen(),
          )?.then((value) => controller.getFavouriteRestaurant()),
      child: SizedBox(
        height: 225,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          scrollDirection: Axis.horizontal,
          itemCount: controller.advertisementList.length,
          itemBuilder:
              (context, index) => AdvertisementHomeCard(
                controller: controller,
                model: controller.advertisementList[index],
              ),
        ),
      ),
    );
  }
}

class _PopularRestaurantsSection extends StatelessWidget {
  final FoodHomeController controller;
  final bool isDark;

  const _PopularRestaurantsSection({
    required this.controller,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final restaurants = controller.popularRestaurantList.take(8).toList();
    return _FoodSection(
      title: 'Restaurants populaires',
      isDark: isDark,
      onViewAll:
          () => Get.to(
            const RestaurantListScreen(),
            arguments: {
              'vendorList': controller.popularRestaurantList,
              'title': 'Restaurants populaires'.tr,
            },
          )?.then((v) => controller.getFavouriteRestaurant()),
      child: SizedBox(
        height: 245,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          scrollDirection: Axis.horizontal,
          itemCount: restaurants.length,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder:
              (context, index) => _FoodRestaurantCard(
                vendor: restaurants[index],
                controller: controller,
                isDark: isDark,
              ),
        ),
      ),
    );
  }
}

class _FoodRestaurantCard extends StatelessWidget {
  final VendorModel vendor;
  final FoodHomeController controller;
  final bool isDark;

  const _FoodRestaurantCard({
    required this.vendor,
    required this.controller,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap:
          () => Get.to(
            const RestaurantDetailsScreen(),
            arguments: {'vendorModel': vendor},
          )?.then((v) => controller.getFavouriteRestaurant()),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 205,
        decoration: BoxDecoration(
          color: isDark ? AppThemeData.grey800 : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [_foodTinyShadow(isDark)],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 118,
              width: double.infinity,
              child: RestaurantImageView(vendorModel: vendor),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          vendor.title ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppThemeData.boldTextStyle(
                            fontSize: 15,
                            color:
                                isDark ? AppThemeData.grey50 : HomeScreen._ink,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFC107),
                        size: 18,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        Constant.calculateReview(
                          reviewCount: vendor.reviewsCount.toString(),
                          reviewSum: vendor.reviewsSum.toString(),
                        ),
                        style: AppThemeData.mediumTextStyle(
                          fontSize: 12,
                          color:
                              isDark
                                  ? AppThemeData.grey200
                                  : AppThemeData.grey700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    vendor.location ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppThemeData.regularTextStyle(
                      fontSize: 12,
                      color:
                          isDark ? AppThemeData.grey300 : AppThemeData.grey600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Frais de livraison'.tr,
                    style: AppThemeData.regularTextStyle(
                      fontSize: 12,
                      color:
                          isDark ? AppThemeData.grey300 : AppThemeData.grey600,
                    ),
                  ),
                  Text(
                    vendor.isSelfDelivery == true
                        ? 'GRATUIT'.tr
                        : Constant.amountShow(
                          amount: vendor.deliveryCharge?.toString() ?? '0',
                        ),
                    style: AppThemeData.semiBoldTextStyle(
                      fontSize: 12,
                      color:
                          vendor.isSelfDelivery == true
                              ? AppThemeData.success400
                              : HomeScreen._orange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecialOffersSection extends StatelessWidget {
  final FoodHomeController controller;
  final bool isDark;

  const _SpecialOffersSection({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final count =
        controller.couponList.length > 2 ? 2 : controller.couponList.length;
    return _FoodSection(
      title: 'Offres spéciales',
      isDark: isDark,
      onViewAll:
          () => Get.to(
            const DiscountRestaurantListScreen(),
            arguments: {
              'vendorList': controller.couponRestaurantList,
              'couponList': controller.couponList,
              'title': 'Offres spéciales'.tr,
            },
          ),
      child: SizedBox(
        height: 135,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          scrollDirection: Axis.horizontal,
          itemCount: count,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder:
              (context, index) => _OfferCard(
                coupon: controller.couponList[index],
                vendor: controller.couponRestaurantList[index],
                isDark: isDark,
              ),
        ),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final CouponModel coupon;
  final VendorModel vendor;
  final bool isDark;

  const _OfferCard({
    required this.coupon,
    required this.vendor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap:
          () => Get.to(
            const RestaurantDetailsScreen(),
            arguments: {'vendorModel': vendor},
          ),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppThemeData.grey800 : const Color(0xFFFFF0E8),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.percent_rounded, color: HomeScreen._orange),
                  const SizedBox(height: 10),
                  Text(
                    coupon.description?.isNotEmpty == true
                        ? coupon.description!
                        : '${coupon.discount ?? ''} ${coupon.discountType ?? ''}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppThemeData.boldTextStyle(
                      fontSize: 15,
                      color: isDark ? AppThemeData.grey50 : HomeScreen._ink,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Code promo : @code'.trParams({'code': coupon.code ?? ''}),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppThemeData.mediumTextStyle(
                      fontSize: 12,
                      color:
                          isDark ? AppThemeData.grey200 : AppThemeData.grey700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: NetworkImageWidget(
                imageUrl:
                    coupon.image?.isNotEmpty == true
                        ? coupon.image!
                        : vendor.photo ?? '',
                width: 85,
                height: 95,
                fit: BoxFit.cover,
                showShimmer: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoodRecentOrders extends StatelessWidget {
  final bool isDark;

  const _FoodRecentOrders({required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (Constant.userModel == null) {
      return const SizedBox.shrink();
    }
    return FutureBuilder<List<OrderModel>>(
      future: FireStoreUtils.getAllOrder(),
      builder: (context, snapshot) {
        final orders = (snapshot.data ?? []).take(2).toList();
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 80,
            child: Center(
              child: CircularProgressIndicator(
                color: HomeScreen._orange,
                strokeWidth: 2,
              ),
            ),
          );
        }
        return _FoodSection(
          title: 'Vos dernières commandes',
          isDark: isDark,
          onViewAll:
              () => Get.find<DashBoardController>().selectedIndex.value = 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child:
                orders.isEmpty
                    ? _FoodEmptyOrders(isDark: isDark)
                    : Column(
                      children:
                          orders
                              .map(
                                (order) =>
                                    _FoodOrderRow(order: order, isDark: isDark),
                              )
                              .toList(),
                    ),
          ),
        );
      },
    );
  }
}

class _FoodOrderRow extends StatelessWidget {
  final OrderModel order;
  final bool isDark;

  const _FoodOrderRow({required this.order, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap:
          () => Get.to(
            const OrderDetailsScreen(),
            arguments: {'orderModel': order},
          ),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppThemeData.grey800 : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [_foodTinyShadow(isDark)],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: NetworkImageWidget(
                imageUrl: order.vendor?.photo ?? '',
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                showShimmer: false,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.vendor?.title ?? 'Commande'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppThemeData.boldTextStyle(
                      fontSize: 15,
                      color: isDark ? AppThemeData.grey50 : HomeScreen._ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.products
                            ?.map((e) => e.name)
                            .whereType<String>()
                            .take(2)
                            .join(' + ') ??
                        '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppThemeData.regularTextStyle(
                      fontSize: 13,
                      color:
                          isDark ? AppThemeData.grey300 : AppThemeData.grey600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _foodDate(order.createdAt),
                    style: AppThemeData.regularTextStyle(
                      fontSize: 12,
                      color:
                          isDark ? AppThemeData.grey400 : AppThemeData.grey500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _foodStatus(order.status),
              style: AppThemeData.semiBoldTextStyle(
                fontSize: 12,
                color:
                    _foodDone(order.status)
                        ? AppThemeData.success400
                        : HomeScreen._orange,
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _FoodEmptyOrders extends StatelessWidget {
  final bool isDark;

  const _FoodEmptyOrders({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.grey800 : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [_foodTinyShadow(isDark)],
      ),
      child: Text(
        'Aucune commande récente'.tr,
        style: AppThemeData.mediumTextStyle(
          fontSize: 14,
          color: isDark ? AppThemeData.grey200 : AppThemeData.grey600,
        ),
      ),
    );
  }
}

class _FoodSection extends StatelessWidget {
  final String title;
  final bool isDark;
  final VoidCallback onViewAll;
  final Widget child;

  const _FoodSection({
    required this.title,
    required this.isDark,
    required this.onViewAll,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title.tr,
                    style: AppThemeData.boldTextStyle(
                      fontSize: 21,
                      color: isDark ? AppThemeData.grey50 : HomeScreen._ink,
                    ),
                  ),
                ),
                InkWell(
                  onTap: onViewAll,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Voir tout'.tr,
                          style: AppThemeData.boldTextStyle(
                            fontSize: 14,
                            color: HomeScreen._orange,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: HomeScreen._orange,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

Future<void> _openAddressPicker(
  BuildContext context,
  FoodHomeController controller,
) async {
  if (Constant.userModel != null) {
    Get.to(AddressListScreen())?.then((value) {
      if (value != null && value is ShippingAddress) {
        Constant.selectedLocation = value;
        controller.getData();
      }
    });
  } else {
    Get.offAll(const LocationPermissionScreen());
  }
}

void _showFoodModeSheet(
  BuildContext context,
  FoodHomeController controller,
  bool isDark,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: isDark ? AppThemeData.grey900 : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder:
        (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mode de commande'.tr,
                  style: AppThemeData.boldTextStyle(
                    fontSize: 18,
                    color: isDark ? AppThemeData.grey50 : HomeScreen._ink,
                  ),
                ),
                const SizedBox(height: 14),
                ...['Delivery', 'TakeAway'].map(
                  (value) => ListTile(
                    title: Text(value.tr),
                    trailing:
                        controller.selectedOrderTypeValue.value == value
                            ? const Icon(Icons.check, color: HomeScreen._orange)
                            : null,
                    onTap: () async {
                      if (cartItem.isEmpty) {
                        await Preferences.setString(
                          Preferences.foodDeliveryType,
                          value,
                        );
                        controller.selectedOrderTypeValue.value = value;
                        controller.getData();
                        Get.back();
                      } else {
                        Get.back();
                        showDialog(
                          context: context,
                          builder:
                              (_) => CustomDialogBox(
                                title: 'Alert'.tr,
                                descriptions:
                                    'Do you really want to change the delivery option? Your cart will be empty.'
                                        .tr,
                                positiveString: 'Ok'.tr,
                                negativeString: 'Cancel'.tr,
                                positiveClick: () async {
                                  await Preferences.setString(
                                    Preferences.foodDeliveryType,
                                    value,
                                  );
                                  controller.selectedOrderTypeValue.value =
                                      value;
                                  controller.getData();
                                  DatabaseHelper.instance
                                      .deleteAllCartProducts();
                                  controller.cartProvider.clearDatabase();
                                  controller.getCartData();
                                  Get.back();
                                },
                                negativeClick: Get.back,
                                img: null,
                              ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
  );
}

String _foodDate(Timestamp? timestamp) {
  if (timestamp == null) return '';
  final date = timestamp.toDate();
  final now = DateTime.now();
  final label =
      date.year == now.year && date.month == now.month && date.day == now.day
          ? 'Aujourd’hui'.tr
          : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  return '$label, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

bool _foodDone(String? status) =>
    (status ?? '').toLowerCase().contains('completed') ||
    (status ?? '').toLowerCase().contains('delivered');
String _foodStatus(String? status) =>
    _foodDone(status) ? 'Livré'.tr : 'En cours'.tr;

String _foodInitials(String value) {
  final words =
      value
          .trim()
          .split(RegExp(r'\s+'))
          .where((word) => word.trim().isNotEmpty)
          .toList();
  if (words.isEmpty) {
    return 'JX';
  }
  if (words.length == 1) {
    return String.fromCharCodes(words.first.runes.take(2)).toUpperCase();
  }
  return words
      .take(2)
      .map((word) => String.fromCharCode(word.runes.first))
      .join()
      .toUpperCase();
}

BoxShadow _foodShadow(bool isDark) => BoxShadow(
  color: Colors.black.withOpacity(isDark ? 0.24 : 0.07),
  blurRadius: 22,
  offset: const Offset(0, 11),
);
BoxShadow _foodTinyShadow(bool isDark) => BoxShadow(
  color: Colors.black.withOpacity(isDark ? 0.18 : 0.045),
  blurRadius: 14,
  offset: const Offset(0, 7),
);

class PopularRestaurant extends StatelessWidget {
  final FoodHomeController controller;

  const PopularRestaurant({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDark.value;
    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      scrollDirection: Axis.vertical,
      itemCount: controller.popularRestaurantList.length,
      itemBuilder: (BuildContext context, int index) {
        VendorModel vendorModel = controller.popularRestaurantList[index];
        return InkWell(
          onTap: () {
            Get.to(
              const RestaurantDetailsScreen(),
              arguments: {"vendorModel": vendorModel},
            )?.then((v) {
              controller.getFavouriteRestaurant();
            });
          },
          child: Padding(
            padding: EdgeInsets.only(
              bottom:
                  controller.popularRestaurantList.length - 1 == index
                      ? 60
                      : 20,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppThemeData.grey800 : AppThemeData.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        child: Stack(
                          children: [
                            RestaurantImageView(vendorModel: vendorModel),
                            Container(
                              height: Responsive.height(20, context),
                              width: Responsive.width(100, context),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: const Alignment(-0.00, -1.00),
                                  end: const Alignment(0, 1),
                                  colors: [
                                    Colors.black.withOpacity(0),
                                    const Color(0xFF111827),
                                  ],
                                ),
                              ),
                            ),

                            Positioned(
                              right: 10,
                              top: 10,
                              child: InkWell(
                                onTap: () async {
                                  if (controller.favouriteList
                                      .where(
                                        (p0) =>
                                            p0.restaurantId == vendorModel.id,
                                      )
                                      .isNotEmpty) {
                                    FavouriteModel favouriteModel =
                                        FavouriteModel(
                                          restaurantId: vendorModel.id,
                                          userId:
                                              FireStoreUtils.getCurrentUid(),
                                        );
                                    controller.favouriteList.removeWhere(
                                      (item) =>
                                          item.restaurantId == vendorModel.id,
                                    );
                                    await FireStoreUtils.removeFavouriteRestaurant(
                                      favouriteModel,
                                    );
                                  } else {
                                    FavouriteModel favouriteModel =
                                        FavouriteModel(
                                          restaurantId: vendorModel.id,
                                          userId:
                                              FireStoreUtils.getCurrentUid(),
                                        );
                                    controller.favouriteList.add(
                                      favouriteModel,
                                    );
                                    await FireStoreUtils.setFavouriteRestaurant(
                                      favouriteModel,
                                    );
                                  }
                                },
                                child: Obx(
                                  () =>
                                      controller.favouriteList
                                              .where(
                                                (p0) =>
                                                    p0.restaurantId ==
                                                    vendorModel.id,
                                              )
                                              .isNotEmpty
                                          ? SvgPicture.asset(
                                            "assets/icons/ic_like_fill.svg",
                                          )
                                          : SvgPicture.asset(
                                            "assets/icons/ic_like.svg",
                                          ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(
                          Responsive.width(-3, context),
                          Responsive.height(17.5, context),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Visibility(
                              visible:
                                  (vendorModel.isSelfDelivery == true &&
                                      Constant.isSelfDeliveryFeature == true),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppThemeData.success300,
                                      borderRadius: BorderRadius.circular(
                                        120,
                                      ), // Optional
                                    ),
                                    child: Row(
                                      children: [
                                        SvgPicture.asset(
                                          "assets/icons/ic_free_delivery.svg",
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          "Free Delivery".tr,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: AppThemeData.carRent600,
                                            fontFamily: AppThemeData.semiBold,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: ShapeDecoration(
                                color:
                                    isDark
                                        ? AppThemeData.primary600
                                        : AppThemeData.primary50,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(120),
                                ),
                              ),
                              child: Row(
                                children: [
                                  SvgPicture.asset(
                                    "assets/icons/ic_star.svg",
                                    colorFilter: ColorFilter.mode(
                                      AppThemeData.primary300,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    "${Constant.calculateReview(reviewCount: vendorModel.reviewsCount!.toStringAsFixed(0), reviewSum: vendorModel.reviewsSum.toString())} (${vendorModel.reviewsCount!.toStringAsFixed(0)})",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          isDark
                                              ? AppThemeData.primary300
                                              : AppThemeData.primary300,
                                      fontFamily: AppThemeData.semiBold,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: ShapeDecoration(
                                color:
                                    isDark
                                        ? AppThemeData.ecommerce600
                                        : AppThemeData.ecommerce50,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(120),
                                ),
                              ),
                              child: Row(
                                children: [
                                  SvgPicture.asset(
                                    "assets/icons/ic_map_distance.svg",
                                    colorFilter: ColorFilter.mode(
                                      AppThemeData.ecommerce300,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    "${Constant.getDistance(lat1: vendorModel.latitude.toString(), lng1: vendorModel.longitude.toString(), lat2: Constant.selectedLocation.location!.latitude.toString(), lng2: Constant.selectedLocation.location!.longitude.toString())} ${Constant.distanceType}",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          isDark
                                              ? AppThemeData.ecommerce300
                                              : AppThemeData.ecommerce300,
                                      fontFamily: AppThemeData.semiBold,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vendorModel.title.toString(),
                          textAlign: TextAlign.start,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 18,
                            overflow: TextOverflow.ellipsis,
                            fontFamily: AppThemeData.semiBold,
                            color:
                                isDark
                                    ? AppThemeData.grey50
                                    : AppThemeData.grey900,
                          ),
                        ),
                        Text(
                          vendorModel.location.toString(),
                          textAlign: TextAlign.start,
                          maxLines: 1,
                          style: TextStyle(
                            overflow: TextOverflow.ellipsis,
                            fontFamily: AppThemeData.medium,
                            fontWeight: FontWeight.w500,
                            color:
                                isDark
                                    ? AppThemeData.grey400
                                    : AppThemeData.grey400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class AllRestaurant extends StatelessWidget {
  final FoodHomeController controller;

  const AllRestaurant({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDark.value;
    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      scrollDirection: Axis.vertical,
      itemCount: controller.allNearestRestaurant.length,
      itemBuilder: (BuildContext context, int index) {
        VendorModel vendorModel = controller.allNearestRestaurant[index];
        return InkWell(
          onTap: () {
            Get.to(
              const RestaurantDetailsScreen(),
              arguments: {"vendorModel": vendorModel},
            )?.then((v) {
              controller.getFavouriteRestaurant();
            });
          },
          child: Padding(
            padding: EdgeInsets.only(
              bottom:
                  controller.allNearestRestaurant.length - 1 == index ? 60 : 20,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppThemeData.grey800 : AppThemeData.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        child: Stack(
                          children: [
                            RestaurantImageView(vendorModel: vendorModel),
                            Container(
                              height: Responsive.height(20, context),
                              width: Responsive.width(100, context),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: const Alignment(-0.00, -1.00),
                                  end: const Alignment(0, 1),
                                  colors: [
                                    Colors.black.withOpacity(0),
                                    const Color(0xFF111827),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              right: 10,
                              top: 10,
                              child: InkWell(
                                onTap: () async {
                                  if (controller.favouriteList
                                      .where(
                                        (p0) =>
                                            p0.restaurantId == vendorModel.id,
                                      )
                                      .isNotEmpty) {
                                    FavouriteModel favouriteModel =
                                        FavouriteModel(
                                          restaurantId: vendorModel.id,
                                          userId:
                                              FireStoreUtils.getCurrentUid(),
                                        );
                                    controller.favouriteList.removeWhere(
                                      (item) =>
                                          item.restaurantId == vendorModel.id,
                                    );
                                    await FireStoreUtils.removeFavouriteRestaurant(
                                      favouriteModel,
                                    );
                                  } else {
                                    FavouriteModel favouriteModel =
                                        FavouriteModel(
                                          restaurantId: vendorModel.id,
                                          userId:
                                              FireStoreUtils.getCurrentUid(),
                                        );
                                    controller.favouriteList.add(
                                      favouriteModel,
                                    );
                                    await FireStoreUtils.setFavouriteRestaurant(
                                      favouriteModel,
                                    );
                                  }
                                },
                                child: Obx(
                                  () =>
                                      controller.favouriteList
                                              .where(
                                                (p0) =>
                                                    p0.restaurantId ==
                                                    vendorModel.id,
                                              )
                                              .isNotEmpty
                                          ? SvgPicture.asset(
                                            "assets/icons/ic_like_fill.svg",
                                          )
                                          : SvgPicture.asset(
                                            "assets/icons/ic_like.svg",
                                          ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(
                          Responsive.width(-3, context),
                          Responsive.height(17.5, context),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Visibility(
                              visible:
                                  (vendorModel.isSelfDelivery == true &&
                                      Constant.isSelfDeliveryFeature == true),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppThemeData.carRent300,
                                      borderRadius: BorderRadius.circular(
                                        120,
                                      ), // Optional
                                    ),
                                    child: Row(
                                      children: [
                                        SvgPicture.asset(
                                          "assets/icons/ic_free_delivery.svg",
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          "Free Delivery".tr,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: AppThemeData.carRent600,
                                            fontFamily: AppThemeData.semiBold,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: ShapeDecoration(
                                color:
                                    isDark
                                        ? AppThemeData.primary600
                                        : AppThemeData.primary50,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(120),
                                ),
                              ),
                              child: Row(
                                children: [
                                  SvgPicture.asset(
                                    "assets/icons/ic_star.svg",
                                    colorFilter: ColorFilter.mode(
                                      AppThemeData.primary300,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    "${Constant.calculateReview(reviewCount: vendorModel.reviewsCount.toString(), reviewSum: vendorModel.reviewsSum.toString())} (${vendorModel.reviewsCount!.toStringAsFixed(0)})",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          isDark
                                              ? AppThemeData.primary300
                                              : AppThemeData.primary300,
                                      fontFamily: AppThemeData.semiBold,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: ShapeDecoration(
                                color:
                                    isDark
                                        ? AppThemeData.ecommerce600
                                        : AppThemeData.ecommerce50,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(120),
                                ),
                              ),
                              child: Row(
                                children: [
                                  SvgPicture.asset(
                                    "assets/icons/ic_map_distance.svg",
                                    colorFilter: ColorFilter.mode(
                                      AppThemeData.ecommerce300,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    "${Constant.getDistance(lat1: vendorModel.latitude.toString(), lng1: vendorModel.longitude.toString(), lat2: Constant.selectedLocation.location!.latitude.toString(), lng2: Constant.selectedLocation.location!.longitude.toString())} ${Constant.distanceType}",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          isDark
                                              ? AppThemeData.ecommerce300
                                              : AppThemeData.ecommerce300,
                                      fontFamily: AppThemeData.semiBold,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vendorModel.title.toString(),
                          textAlign: TextAlign.start,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 18,
                            overflow: TextOverflow.ellipsis,
                            fontFamily: AppThemeData.semiBold,
                            color:
                                isDark
                                    ? AppThemeData.grey50
                                    : AppThemeData.grey900,
                          ),
                        ),
                        Text(
                          vendorModel.location.toString(),
                          textAlign: TextAlign.start,
                          maxLines: 1,
                          style: TextStyle(
                            overflow: TextOverflow.ellipsis,
                            fontFamily: AppThemeData.medium,
                            fontWeight: FontWeight.w500,
                            color:
                                isDark
                                    ? AppThemeData.grey400
                                    : AppThemeData.grey400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class NewArrival extends StatelessWidget {
  final FoodHomeController controller;

  const NewArrival({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDark.value;
    return SizedBox(
      height: Responsive.height(24, context),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount:
            controller.newArrivalRestaurantList.length >= 10
                ? 10
                : controller.newArrivalRestaurantList.length,
        itemBuilder: (BuildContext context, int index) {
          VendorModel vendorModel = controller.newArrivalRestaurantList[index];
          return InkWell(
            onTap: () {
              Get.to(
                const RestaurantDetailsScreen(),
                arguments: {"vendorModel": vendorModel},
              )?.then((v) {
                controller.getFavouriteRestaurant();
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: SizedBox(
                width: Responsive.width(55, context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(10),
                        ),
                        child: Stack(
                          children: [
                            NetworkImageWidget(
                              imageUrl: vendorModel.photo.toString(),
                              fit: BoxFit.cover,
                              height: Responsive.height(100, context),
                              width: Responsive.width(100, context),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: const Alignment(0.00, 1.00),
                                  end: const Alignment(0, -1),
                                  colors: [
                                    Colors.black.withOpacity(0),
                                    AppThemeData.grey900,
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              right: 10,
                              top: 10,
                              child: InkWell(
                                onTap: () async {
                                  if (controller.favouriteList
                                      .where(
                                        (p0) =>
                                            p0.restaurantId == vendorModel.id,
                                      )
                                      .isNotEmpty) {
                                    FavouriteModel favouriteModel =
                                        FavouriteModel(
                                          restaurantId: vendorModel.id,
                                          userId:
                                              FireStoreUtils.getCurrentUid(),
                                        );
                                    controller.favouriteList.removeWhere(
                                      (item) =>
                                          item.restaurantId == vendorModel.id,
                                    );
                                    await FireStoreUtils.removeFavouriteRestaurant(
                                      favouriteModel,
                                    );
                                  } else {
                                    FavouriteModel favouriteModel =
                                        FavouriteModel(
                                          restaurantId: vendorModel.id,
                                          userId:
                                              FireStoreUtils.getCurrentUid(),
                                        );
                                    controller.favouriteList.add(
                                      favouriteModel,
                                    );
                                    await FireStoreUtils.setFavouriteRestaurant(
                                      favouriteModel,
                                    );
                                  }
                                },
                                child: Obx(
                                  () =>
                                      controller.favouriteList
                                              .where(
                                                (p0) =>
                                                    p0.restaurantId ==
                                                    vendorModel.id,
                                              )
                                              .isNotEmpty
                                          ? SvgPicture.asset(
                                            "assets/icons/ic_like_fill.svg",
                                          )
                                          : SvgPicture.asset(
                                            "assets/icons/ic_like.svg",
                                          ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      vendorModel.title.toString(),
                      textAlign: TextAlign.start,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 16,
                        overflow: TextOverflow.ellipsis,
                        fontFamily: AppThemeData.semiBold,
                        color:
                            isDark ? AppThemeData.grey50 : AppThemeData.grey50,
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Visibility(
                            visible:
                                (vendorModel.isSelfDelivery == true &&
                                    Constant.isSelfDeliveryFeature == true),
                            child: Row(
                              children: [
                                SvgPicture.asset(
                                  "assets/icons/ic_free_delivery.svg",
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "Free Delivery".tr,
                                  textAlign: TextAlign.start,
                                  maxLines: 1,
                                  style: TextStyle(
                                    overflow: TextOverflow.ellipsis,
                                    fontFamily: AppThemeData.medium,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        isDark
                                            ? AppThemeData.grey400
                                            : AppThemeData.grey400,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              SvgPicture.asset(
                                "assets/icons/ic_star.svg",
                                colorFilter: ColorFilter.mode(
                                  AppThemeData.primary300,
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "${Constant.calculateReview(reviewCount: vendorModel.reviewsCount.toString(), reviewSum: vendorModel.reviewsSum.toString())} (${vendorModel.reviewsCount!.toStringAsFixed(0)})",
                                textAlign: TextAlign.start,
                                maxLines: 1,
                                style: TextStyle(
                                  overflow: TextOverflow.ellipsis,
                                  fontFamily: AppThemeData.medium,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      isDark
                                          ? AppThemeData.grey400
                                          : AppThemeData.grey400,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              SvgPicture.asset(
                                "assets/icons/ic_map_distance.svg",
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "${Constant.getDistance(lat1: vendorModel.latitude.toString(), lng1: vendorModel.longitude.toString(), lat2: Constant.selectedLocation.location!.latitude.toString(), lng2: Constant.selectedLocation.location!.longitude.toString())} ${Constant.distanceType}",
                                textAlign: TextAlign.start,
                                maxLines: 1,
                                style: TextStyle(
                                  overflow: TextOverflow.ellipsis,
                                  fontFamily: AppThemeData.medium,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      isDark
                                          ? AppThemeData.grey400
                                          : AppThemeData.grey400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      vendorModel.location.toString(),
                      textAlign: TextAlign.start,
                      maxLines: 1,
                      style: TextStyle(
                        overflow: TextOverflow.ellipsis,
                        fontFamily: AppThemeData.medium,
                        fontWeight: FontWeight.w500,
                        color:
                            isDark
                                ? AppThemeData.grey400
                                : AppThemeData.grey400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AdvertisementHomeCard extends StatelessWidget {
  final AdvertisementModel model;
  final FoodHomeController controller;

  const AdvertisementHomeCard({
    super.key,
    required this.controller,
    required this.model,
  });

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDark.value;
    return InkWell(
      onTap: () async {
        ShowToastDialog.showLoader("Please wait...".tr);
        VendorModel? vendorModel = await FireStoreUtils.getVendorById(
          model.vendorId!,
        );
        ShowToastDialog.closeLoader();
        Get.to(
          const RestaurantDetailsScreen(),
          arguments: {"vendorModel": vendorModel},
        );
      },
      child: Container(
        margin: EdgeInsets.only(right: 16),
        width: Responsive.width(70, context),
        decoration: BoxDecoration(
          color: isDark ? AppThemeData.info600 : AppThemeData.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: isDark ? 6 : 2,
              spreadRadius: 0,
              offset: Offset(0, isDark ? 3 : 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                model.type == 'restaurant_promotion'
                    ? ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: NetworkImageWidget(
                        imageUrl: model.coverImage ?? '',
                        height: 135,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                    : VideoAdvWidget(
                      url: model.video ?? '',
                      height: 135,
                      width: double.infinity,
                    ),
                if (model.type != 'video_promotion' &&
                    model.vendorId != null &&
                    (model.showRating == true || model.showReview == true))
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: FutureBuilder(
                      future: FireStoreUtils.getVendorById(model.vendorId!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox();
                        } else {
                          if (snapshot.hasError) {
                            return const SizedBox();
                          } else if (snapshot.data == null) {
                            return const SizedBox();
                          } else {
                            VendorModel vendorModel = snapshot.data!;
                            return Container(
                              decoration: ShapeDecoration(
                                color:
                                    isDark
                                        ? AppThemeData.primary600
                                        : AppThemeData.primary50,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(120),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    if (model.showRating == true)
                                      SvgPicture.asset(
                                        "assets/icons/ic_star.svg",
                                        colorFilter: ColorFilter.mode(
                                          AppThemeData.primary300,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                    if (model.showRating == true)
                                      const SizedBox(width: 5),
                                    Text(
                                      "${model.showRating == true ? Constant.calculateReview(reviewCount: vendorModel.reviewsCount!.toStringAsFixed(0), reviewSum: vendorModel.reviewsSum.toString()) : ''} ${model.showReview == true ? '(${vendorModel.reviewsCount!.toStringAsFixed(0)})' : ''}",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color:
                                            isDark
                                                ? AppThemeData.primary300
                                                : AppThemeData.primary300,
                                        fontFamily: AppThemeData.semiBold,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (model.type == 'restaurant_promotion')
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: NetworkImageWidget(
                        imageUrl: model.profileImage ?? '',
                        height: 50,
                        width: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          model.title ?? '',
                          style: TextStyle(
                            color:
                                isDark
                                    ? AppThemeData.grey50
                                    : AppThemeData.grey900,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          model.description ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: AppThemeData.medium,
                            color:
                                isDark
                                    ? AppThemeData.grey400
                                    : AppThemeData.grey600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  model.type == 'restaurant_promotion'
                      ? IconButton(
                        icon: Obx(
                          () =>
                              controller.favouriteList
                                      .where(
                                        (p0) =>
                                            p0.restaurantId == model.vendorId,
                                      )
                                      .isNotEmpty
                                  ? SvgPicture.asset(
                                    "assets/icons/ic_like_fill.svg",
                                  )
                                  : SvgPicture.asset(
                                    "assets/icons/ic_like.svg",
                                    colorFilter: ColorFilter.mode(
                                      isDark
                                          ? AppThemeData.grey400
                                          : AppThemeData.grey600,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                        ),
                        onPressed: () async {
                          if (controller.favouriteList
                              .where((p0) => p0.restaurantId == model.vendorId)
                              .isNotEmpty) {
                            FavouriteModel favouriteModel = FavouriteModel(
                              restaurantId: model.vendorId,
                              userId: FireStoreUtils.getCurrentUid(),
                            );
                            controller.favouriteList.removeWhere(
                              (item) => item.restaurantId == model.vendorId,
                            );
                            await FireStoreUtils.removeFavouriteRestaurant(
                              favouriteModel,
                            );
                          } else {
                            FavouriteModel favouriteModel = FavouriteModel(
                              restaurantId: model.vendorId,
                              userId: FireStoreUtils.getCurrentUid(),
                            );
                            controller.favouriteList.add(favouriteModel);
                            await FireStoreUtils.setFavouriteRestaurant(
                              favouriteModel,
                            );
                          }
                          controller.update();
                        },
                      )
                      : Container(
                        decoration: ShapeDecoration(
                          color:
                              isDark
                                  ? AppThemeData.primary600
                                  : AppThemeData.primary50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          child: Icon(
                            Icons.arrow_forward,
                            size: 20,
                            color: AppThemeData.primary300,
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OfferView extends StatelessWidget {
  final FoodHomeController controller;

  const OfferView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDark.value;
    return SizedBox(
      height: Responsive.height(17, context),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount:
            controller.couponRestaurantList.length >= 15
                ? 15
                : controller.couponRestaurantList.length,
        itemBuilder: (BuildContext context, int index) {
          VendorModel vendorModel = controller.couponRestaurantList[index];
          CouponModel offerModel = controller.couponList[index];
          return InkWell(
            onTap: () {
              Get.to(
                const RestaurantDetailsScreen(),
                arguments: {"vendorModel": vendorModel},
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: SizedBox(
                width: Responsive.width(38, context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(10),
                        ),
                        child: Stack(
                          children: [
                            NetworkImageWidget(
                              imageUrl: vendorModel.photo.toString(),
                              fit: BoxFit.cover,
                              height: Responsive.height(100, context),
                              width: Responsive.width(100, context),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: const Alignment(-0.00, -1.00),
                                  end: const Alignment(0, 1),
                                  colors: [
                                    Colors.black.withOpacity(0),
                                    AppThemeData.grey900,
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 5,
                              left: 10,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Upto".tr,
                                    textAlign: TextAlign.start,
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontSize: 18,
                                      overflow: TextOverflow.ellipsis,
                                      fontFamily: AppThemeData.regular,
                                      fontWeight: FontWeight.w900,
                                      color:
                                          isDark
                                              ? AppThemeData.grey50
                                              : AppThemeData.grey50,
                                    ),
                                  ),
                                  Text(
                                    "${offerModel.discountType == "Fix Price" ? Constant.currencyModel!.symbol : ""}${offerModel.discount}${offerModel.discountType == "Percentage" ? "% off".tr : "off".tr}",
                                    textAlign: TextAlign.start,
                                    maxLines: 1,
                                    style: TextStyle(
                                      overflow: TextOverflow.ellipsis,
                                      fontFamily: AppThemeData.semiBold,
                                      color:
                                          isDark
                                              ? AppThemeData.grey50
                                              : AppThemeData.grey50,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      vendorModel.title.toString(),
                      textAlign: TextAlign.start,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 16,
                        overflow: TextOverflow.ellipsis,
                        fontFamily: AppThemeData.semiBold,
                        color:
                            isDark ? AppThemeData.grey50 : AppThemeData.grey900,
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Visibility(
                            visible:
                                (vendorModel.isSelfDelivery == true &&
                                    Constant.isSelfDeliveryFeature == true),
                            child: Row(
                              children: [
                                Row(
                                  children: [
                                    SvgPicture.asset(
                                      "assets/icons/ic_free_delivery.svg",
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      "Free Delivery".tr,
                                      style: TextStyle(
                                        fontSize: 12,
                                        overflow: TextOverflow.ellipsis,
                                        fontFamily: AppThemeData.medium,
                                        fontWeight: FontWeight.w500,
                                        color:
                                            isDark
                                                ? AppThemeData.grey300
                                                : AppThemeData.grey600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 6),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              SvgPicture.asset(
                                "assets/icons/ic_star.svg",
                                colorFilter: ColorFilter.mode(
                                  AppThemeData.primary300,
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "${Constant.calculateReview(reviewCount: vendorModel.reviewsCount.toString(), reviewSum: vendorModel.reviewsSum.toString())} (${vendorModel.reviewsCount!.toStringAsFixed(0)})",
                                textAlign: TextAlign.start,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 12,
                                  overflow: TextOverflow.ellipsis,
                                  fontFamily: AppThemeData.medium,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      isDark
                                          ? AppThemeData.grey300
                                          : AppThemeData.grey600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class BannerView extends StatelessWidget {
  final FoodHomeController controller;

  const BannerView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 168,
          child: PageView.builder(
            physics: const BouncingScrollPhysics(),
            controller: controller.pageController.value,
            scrollDirection: Axis.horizontal,
            itemCount: controller.bannerModel.length,
            padEnds: false,
            pageSnapping: true,
            allowImplicitScrolling: true,
            onPageChanged: (value) {
              controller.currentPage.value = value;
            },
            itemBuilder: (BuildContext context, int index) {
              BannerModel bannerModel = controller.bannerModel[index];
              return InkWell(
                onTap: () async {
                  if (bannerModel.redirect_type == "store") {
                    ShowToastDialog.showLoader("Please wait...".tr);
                    try {
                      VendorModel? vendorModel =
                          await FireStoreUtils.getVendorById(
                            bannerModel.redirect_id.toString(),
                          );
                      if (vendorModel == null) {
                        ShowToastDialog.showToast(
                          "Restaurant not available.".tr,
                        );
                        return;
                      }
                      if (vendorModel.zoneId == Constant.selectedZone?.id) {
                        Get.to(
                          const RestaurantDetailsScreen(),
                          arguments: {"vendorModel": vendorModel},
                        );
                      } else {
                        ShowToastDialog.showToast(
                          "The store is not available in your area. Change other location first."
                              .tr,
                        );
                      }
                    } catch (e) {
                      ShowToastDialog.showToast("Restaurant not available.".tr);
                    } finally {
                      ShowToastDialog.closeLoader();
                    }
                  } else if (bannerModel.redirect_type == "product") {
                    ShowToastDialog.showLoader("Please wait...".tr);
                    try {
                      ProductModel? productModel =
                          await FireStoreUtils.getProductById(
                            bannerModel.redirect_id.toString(),
                          );
                      if (productModel == null) {
                        ShowToastDialog.showToast(
                          "Restaurant not available.".tr,
                        );
                        return;
                      }
                      VendorModel? vendorModel =
                          await FireStoreUtils.getVendorById(
                            productModel.vendorID.toString(),
                          );
                      if (vendorModel == null) {
                        ShowToastDialog.showToast(
                          "Restaurant not available.".tr,
                        );
                        return;
                      }
                      if (vendorModel.zoneId == Constant.selectedZone?.id) {
                        Get.to(
                          const RestaurantDetailsScreen(),
                          arguments: {"vendorModel": vendorModel},
                        );
                      } else {
                        ShowToastDialog.showToast(
                          "The store is not available in your area. Change other location first."
                              .tr,
                        );
                      }
                    } catch (e) {
                      ShowToastDialog.showToast("Restaurant not available.".tr);
                    } finally {
                      ShowToastDialog.closeLoader();
                    }
                  } else if (bannerModel.redirect_type == "external_link") {
                    final uri = Uri.parse(bannerModel.redirect_id.toString());
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    } else {
                      ShowToastDialog.showToast("Could not launch".tr);
                    }
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(28)),
                    child: NetworkImageWidget(
                      imageUrl: bannerModel.photo.toString(),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(controller.bannerModel.length, (index) {
              return Obx(() {
                final selected = controller.currentPage.value == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: 5),
                  alignment: Alignment.centerLeft,
                  height: 6,
                  width: selected ? 22 : 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    color: selected ? HomeScreen._orange : Colors.black12,
                  ),
                );
              });
            }),
          ),
        ),
      ],
    );
  }
}

class BannerBottomView extends StatelessWidget {
  final FoodHomeController controller;

  const BannerBottomView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 150,
          child: PageView.builder(
            physics: const BouncingScrollPhysics(),
            controller: controller.pageBottomController.value,
            scrollDirection: Axis.horizontal,
            itemCount: controller.bannerBottomModel.length,
            padEnds: false,
            pageSnapping: true,
            allowImplicitScrolling: true,
            onPageChanged: (value) {
              controller.currentBottomPage.value = value;
            },
            itemBuilder: (BuildContext context, int index) {
              BannerModel bannerModel = controller.bannerBottomModel[index];
              return InkWell(
                onTap: () async {
                  if (bannerModel.redirect_type == "store") {
                    ShowToastDialog.showLoader("Please wait...".tr);
                    try {
                      VendorModel? vendorModel =
                          await FireStoreUtils.getVendorById(
                            bannerModel.redirect_id.toString(),
                          );
                      if (vendorModel == null) {
                        ShowToastDialog.showToast(
                          "Restaurant not available.".tr,
                        );
                        return;
                      }
                      if (vendorModel.zoneId == Constant.selectedZone?.id) {
                        Get.to(
                          const RestaurantDetailsScreen(),
                          arguments: {"vendorModel": vendorModel},
                        );
                      } else {
                        ShowToastDialog.showToast(
                          "The store is not available in your area. Change other location first."
                              .tr,
                        );
                      }
                    } catch (e) {
                      ShowToastDialog.showToast("Restaurant not available.".tr);
                    } finally {
                      ShowToastDialog.closeLoader();
                    }
                  } else if (bannerModel.redirect_type == "product") {
                    ShowToastDialog.showLoader("Please wait...".tr);
                    try {
                      ProductModel? productModel =
                          await FireStoreUtils.getProductById(
                            bannerModel.redirect_id.toString(),
                          );
                      if (productModel == null) {
                        ShowToastDialog.showToast(
                          "Restaurant not available.".tr,
                        );
                        return;
                      }
                      VendorModel? vendorModel =
                          await FireStoreUtils.getVendorById(
                            productModel.vendorID.toString(),
                          );
                      if (vendorModel == null) {
                        ShowToastDialog.showToast(
                          "Restaurant not available.".tr,
                        );
                        return;
                      }
                      if (vendorModel.zoneId == Constant.selectedZone?.id) {
                        Get.to(
                          const RestaurantDetailsScreen(),
                          arguments: {"vendorModel": vendorModel},
                        );
                      } else {
                        ShowToastDialog.showToast(
                          "The store is not available in your area. Change other location first."
                              .tr,
                        );
                      }
                    } catch (e) {
                      ShowToastDialog.showToast("Restaurant not available.".tr);
                    } finally {
                      ShowToastDialog.closeLoader();
                    }
                  } else if (bannerModel.redirect_type == "external_link") {
                    final uri = Uri.parse(bannerModel.redirect_id.toString());
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    } else {
                      ShowToastDialog.showToast("Could not launch".tr);
                    }
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    child: NetworkImageWidget(
                      imageUrl: bannerModel.photo.toString(),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(controller.bannerBottomModel.length, (
              index,
            ) {
              return Obx(
                () => Container(
                  margin: const EdgeInsets.only(right: 5),
                  alignment: Alignment.centerLeft,
                  height: 9,
                  width: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        controller.currentBottomPage.value == index
                            ? AppThemeData.primary300
                            : Colors.black12,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class CategoryView extends StatelessWidget {
  final FoodHomeController controller;

  const CategoryView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDark.value;
    return SizedBox(
      height: 108,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: controller.vendorCategoryModel.length,
        itemBuilder: (context, index) {
          VendorCategoryModel vendorCategoryModel =
              controller.vendorCategoryModel[index];
          return InkWell(
            onTap: () {
              Get.to(
                const CategoryRestaurantScreen(),
                arguments: {
                  "vendorCategoryModel": vendorCategoryModel,
                  "dineIn": false,
                },
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 82,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: isDark ? AppThemeData.grey800 : AppThemeData.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: NetworkImageWidget(
                      imageUrl: vendorCategoryModel.photo.toString(),
                      fit: BoxFit.cover,
                      height: 52,
                      width: 52,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      '${vendorCategoryModel.title}',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                            isDark ? AppThemeData.grey50 : AppThemeData.grey800,
                        fontFamily: AppThemeData.semiBold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class StoryView extends StatelessWidget {
  final FoodHomeController controller;

  const StoryView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: controller.storyList.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          StoryModel storyModel = controller.storyList[index];
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (context) => MoreStories(
                          storyList: controller.storyList,
                          index: index,
                        ),
                  ),
                );
              },
              child: SizedBox(
                width: 134,
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  child: Stack(
                    children: [
                      NetworkImageWidget(
                        imageUrl: storyModel.videoThumbnail.toString(),
                        fit: BoxFit.cover,
                        height: Responsive.height(100, context),
                        width: Responsive.width(100, context),
                      ),
                      Container(color: Colors.black.withOpacity(0.30)),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 8,
                        ),
                        child: FutureBuilder(
                          future: FireStoreUtils.getVendorById(
                            storyModel.vendorID.toString(),
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Constant.loader();
                            } else {
                              if (snapshot.hasError) {
                                return Center(
                                  child: Text(
                                    '${"Error".tr}: ${snapshot.error}',
                                  ),
                                );
                              } else if (snapshot.data == null) {
                                return const SizedBox();
                              } else {
                                VendorModel vendorModel = snapshot.data!;
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipOval(
                                      child: NetworkImageWidget(
                                        imageUrl: vendorModel.photo.toString(),
                                        width: 30,
                                        height: 30,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            vendorModel.title.toString(),
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              overflow: TextOverflow.ellipsis,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              SvgPicture.asset(
                                                "assets/icons/ic_star.svg",
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                "${Constant.calculateReview(reviewCount: vendorModel.reviewsCount.toString(), reviewSum: vendorModel.reviewsSum!.toStringAsFixed(0))} reviews",
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                                style: const TextStyle(
                                                  color:
                                                      AppThemeData.warning300,
                                                  fontSize: 10,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class MapView extends StatelessWidget {
  const MapView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDark.value;
    return GetX(
      init: MapViewController(),
      builder: (controller) {
        return Stack(
          children: [
            Constant.selectedMapType == "osm"
                ? flutter_map.FlutterMap(
                  mapController: controller.osmMapController,
                  options: flutter_map.MapOptions(
                    initialCenter: location.LatLng(
                      Constant.selectedLocation.location!.latitude ?? 0.0,
                      Constant.selectedLocation.location!.longitude ?? 0.0,
                    ),
                    initialZoom: 10,
                  ),
                  children: [
                    flutter_map.TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.joxmako.customer',
                    ),
                    flutter_map.MarkerLayer(markers: controller.osmMarker),
                  ],
                )
                : GoogleMap(
                  mapType: MapType.terrain,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                  markers: Set<Marker>.of(controller.markers.values),
                  onMapCreated: (GoogleMapController mapController) {
                    controller.mapController = mapController;
                  },
                  mapToolbarEnabled: true,
                  initialCameraPosition: CameraPosition(
                    zoom: 18,
                    target:
                        controller.homeController.allNearestRestaurant.isEmpty
                            ? LatLng(
                              Constant.selectedLocation.location!.latitude ??
                                  45.521563,
                              Constant.selectedLocation.location!.longitude ??
                                  -122.677433,
                            )
                            : LatLng(
                              controller
                                      .homeController
                                      .allNearestRestaurant
                                      .first
                                      .latitude ??
                                  45.521563,
                              controller
                                      .homeController
                                      .allNearestRestaurant
                                      .first
                                      .longitude ??
                                  -122.677433,
                            ),
                  ),
                ),
            controller.homeController.allNearestRestaurant.isEmpty
                ? Container()
                : Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 80),
                    child: SizedBox(
                      height: Responsive.height(25, context),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: PageView.builder(
                              pageSnapping: true,
                              controller: PageController(
                                viewportFraction: 0.88,
                              ),
                              onPageChanged: (value) async {
                                if (Constant.selectedMapType == "osm") {
                                  controller.osmMapController.move(
                                    location.LatLng(
                                      controller
                                          .homeController
                                          .allNearestRestaurant[value]
                                          .latitude!,
                                      controller
                                          .homeController
                                          .allNearestRestaurant[value]
                                          .longitude!,
                                    ),
                                    16,
                                  );
                                } else {
                                  CameraUpdate cameraUpdate =
                                      CameraUpdate.newCameraPosition(
                                        CameraPosition(
                                          zoom: 18,
                                          target: LatLng(
                                            controller
                                                .homeController
                                                .allNearestRestaurant[value]
                                                .latitude!,
                                            controller
                                                .homeController
                                                .allNearestRestaurant[value]
                                                .longitude!,
                                          ),
                                        ),
                                      );
                                  controller.mapController!.animateCamera(
                                    cameraUpdate,
                                  );
                                }
                              },
                              itemCount:
                                  controller
                                      .homeController
                                      .allNearestRestaurant
                                      .length,
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (context, index) {
                                VendorModel vendorModel =
                                    controller
                                        .homeController
                                        .allNearestRestaurant[index];
                                return InkWell(
                                  onTap: () {
                                    Get.to(
                                      const RestaurantDetailsScreen(),
                                      arguments: {"vendorModel": vendorModel},
                                    )?.then((v) {
                                      controller.homeController
                                          .getFavouriteRestaurant();
                                    });
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: index == 0 ? 0 : 10,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color:
                                            isDark
                                                ? AppThemeData.grey900
                                                : AppThemeData.grey50,
                                        borderRadius: const BorderRadius.all(
                                          Radius.circular(16),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    const BorderRadius.only(
                                                      topLeft: Radius.circular(
                                                        16,
                                                      ),
                                                      topRight: Radius.circular(
                                                        16,
                                                      ),
                                                    ),
                                                child: Stack(
                                                  children: [
                                                    NetworkImageWidget(
                                                      imageUrl:
                                                          vendorModel.photo
                                                              .toString(),
                                                      fit: BoxFit.cover,
                                                      height: Responsive.height(
                                                        14,
                                                        context,
                                                      ),
                                                      width: Responsive.width(
                                                        100,
                                                        context,
                                                      ),
                                                    ),
                                                    Container(
                                                      height: Responsive.height(
                                                        14,
                                                        context,
                                                      ),
                                                      width: Responsive.width(
                                                        100,
                                                        context,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          begin:
                                                              const Alignment(
                                                                -0.00,
                                                                -1.00,
                                                              ),
                                                          end: const Alignment(
                                                            0,
                                                            1,
                                                          ),
                                                          colors: [
                                                            Colors.black
                                                                .withOpacity(0),
                                                            const Color(
                                                              0xFF111827,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    Positioned(
                                                      right: 10,
                                                      top: 10,
                                                      child: InkWell(
                                                        onTap: () async {
                                                          if (controller
                                                              .homeController
                                                              .favouriteList
                                                              .where(
                                                                (p0) =>
                                                                    p0.restaurantId ==
                                                                    vendorModel
                                                                        .id,
                                                              )
                                                              .isNotEmpty) {
                                                            FavouriteModel
                                                            favouriteModel =
                                                                FavouriteModel(
                                                                  restaurantId:
                                                                      vendorModel
                                                                          .id,
                                                                  userId:
                                                                      FireStoreUtils.getCurrentUid(),
                                                                );
                                                            controller
                                                                .homeController
                                                                .favouriteList
                                                                .removeWhere(
                                                                  (item) =>
                                                                      item.restaurantId ==
                                                                      vendorModel
                                                                          .id,
                                                                );
                                                            await FireStoreUtils.removeFavouriteRestaurant(
                                                              favouriteModel,
                                                            );
                                                          } else {
                                                            FavouriteModel
                                                            favouriteModel =
                                                                FavouriteModel(
                                                                  restaurantId:
                                                                      vendorModel
                                                                          .id,
                                                                  userId:
                                                                      FireStoreUtils.getCurrentUid(),
                                                                );
                                                            controller
                                                                .homeController
                                                                .favouriteList
                                                                .add(
                                                                  favouriteModel,
                                                                );
                                                            await FireStoreUtils.setFavouriteRestaurant(
                                                              favouriteModel,
                                                            );
                                                          }
                                                        },
                                                        child: Obx(
                                                          () =>
                                                              controller
                                                                      .homeController
                                                                      .favouriteList
                                                                      .where(
                                                                        (p0) =>
                                                                            p0.restaurantId ==
                                                                            vendorModel.id,
                                                                      )
                                                                      .isNotEmpty
                                                                  ? SvgPicture.asset(
                                                                    "assets/icons/ic_like_fill.svg",
                                                                  )
                                                                  : SvgPicture.asset(
                                                                    "assets/icons/ic_like.svg",
                                                                  ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Transform.translate(
                                                offset: Offset(
                                                  Responsive.width(-3, context),
                                                  Responsive.height(
                                                    11,
                                                    context,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                    Visibility(
                                                      visible:
                                                          (vendorModel.isSelfDelivery ==
                                                                  true &&
                                                              Constant.isSelfDeliveryFeature ==
                                                                  true),
                                                      child: Row(
                                                        children: [
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      10,
                                                                  vertical: 7,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  AppThemeData
                                                                      .carRent300,
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    120,
                                                                  ), // Optional
                                                            ),
                                                            child: Row(
                                                              children: [
                                                                SvgPicture.asset(
                                                                  "assets/icons/ic_free_delivery.svg",
                                                                ),
                                                                const SizedBox(
                                                                  width: 5,
                                                                ),
                                                                Text(
                                                                  "Free Delivery"
                                                                      .tr,
                                                                  style: TextStyle(
                                                                    fontSize:
                                                                        14,
                                                                    color:
                                                                        AppThemeData
                                                                            .success600,
                                                                    fontFamily:
                                                                        AppThemeData
                                                                            .semiBold,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 6,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Container(
                                                      decoration: ShapeDecoration(
                                                        color:
                                                            isDark
                                                                ? AppThemeData
                                                                    .primary600
                                                                : AppThemeData
                                                                    .primary50,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                120,
                                                              ),
                                                        ),
                                                      ),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 12,
                                                              vertical: 8,
                                                            ),
                                                        child: Row(
                                                          children: [
                                                            SvgPicture.asset(
                                                              "assets/icons/ic_star.svg",
                                                              colorFilter:
                                                                  ColorFilter.mode(
                                                                    AppThemeData
                                                                        .primary300,
                                                                    BlendMode
                                                                        .srcIn,
                                                                  ),
                                                            ),
                                                            const SizedBox(
                                                              width: 5,
                                                            ),
                                                            Text(
                                                              "${Constant.calculateReview(reviewCount: vendorModel.reviewsCount.toString(), reviewSum: vendorModel.reviewsSum.toString())} (${vendorModel.reviewsCount!.toStringAsFixed(0)})",
                                                              style: TextStyle(
                                                                color:
                                                                    isDark
                                                                        ? AppThemeData
                                                                            .primary300
                                                                        : AppThemeData
                                                                            .primary300,
                                                                fontFamily:
                                                                    AppThemeData
                                                                        .semiBold,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Container(
                                                      decoration: ShapeDecoration(
                                                        color:
                                                            isDark
                                                                ? AppThemeData
                                                                    .ecommerce600
                                                                : AppThemeData
                                                                    .ecommerce50,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                120,
                                                              ),
                                                        ),
                                                      ),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 12,
                                                              vertical: 8,
                                                            ),
                                                        child: Row(
                                                          children: [
                                                            SvgPicture.asset(
                                                              "assets/icons/ic_map_distance.svg",
                                                              colorFilter:
                                                                  ColorFilter.mode(
                                                                    AppThemeData
                                                                        .ecommerce300,
                                                                    BlendMode
                                                                        .srcIn,
                                                                  ),
                                                            ),
                                                            const SizedBox(
                                                              width: 5,
                                                            ),
                                                            Text(
                                                              "${Constant.getDistance(lat1: vendorModel.latitude.toString(), lng1: vendorModel.longitude.toString(), lat2: Constant.selectedLocation.location!.latitude.toString(), lng2: Constant.selectedLocation.location!.longitude.toString())} ${Constant.distanceType}",
                                                              style: TextStyle(
                                                                color:
                                                                    isDark
                                                                        ? AppThemeData
                                                                            .ecommerce300
                                                                        : AppThemeData
                                                                            .ecommerce300,
                                                                fontFamily:
                                                                    AppThemeData
                                                                        .semiBold,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 15),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  vendorModel.title.toString(),
                                                  textAlign: TextAlign.start,
                                                  maxLines: 1,
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    fontFamily:
                                                        AppThemeData.semiBold,
                                                    color:
                                                        isDark
                                                            ? AppThemeData
                                                                .grey50
                                                            : AppThemeData
                                                                .grey900,
                                                  ),
                                                ),
                                                Text(
                                                  vendorModel.location
                                                      .toString(),
                                                  textAlign: TextAlign.start,
                                                  maxLines: 1,
                                                  style: TextStyle(
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    fontFamily:
                                                        AppThemeData.medium,
                                                    fontWeight: FontWeight.w500,
                                                    color:
                                                        isDark
                                                            ? AppThemeData
                                                                .grey400
                                                            : AppThemeData
                                                                .grey400,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}

Widget _buildHomeShimmer(bool isDark) {
  final baseColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
  final highlightColor =
      isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5);

  Widget box({double w = double.infinity, double h = 14, double radius = 8}) =>
      Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(radius),
        ),
      );

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 30),
    child: Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            // Header row: back icon + location block + cart icon
            Row(
              children: [
                box(w: 24, h: 24, radius: 4),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      box(w: 100, h: 12),
                      const SizedBox(height: 6),
                      box(w: 180, h: 14),
                    ],
                  ),
                ),
                box(w: 42, h: 42, radius: 21),
              ],
            ),
            const SizedBox(height: 14),
            // Search bar
            box(h: 48, radius: 12),
            const SizedBox(height: 20),
            // Stories row
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 5,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder:
                    (_, __) => Column(
                      children: [
                        box(w: 64, h: 64, radius: 32),
                        const SizedBox(height: 6),
                        box(w: 50, h: 10),
                      ],
                    ),
              ),
            ),
            const SizedBox(height: 20),
            // "Explore the Categories" title
            box(w: 140, h: 16),
            const SizedBox(height: 12),
            // Categories row
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 5,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder:
                    (_, __) => Column(
                      children: [
                        box(w: 56, h: 56, radius: 28),
                        const SizedBox(height: 6),
                        box(w: 44, h: 10),
                      ],
                    ),
              ),
            ),
            const SizedBox(height: 20),
            // Banner
            box(h: 160, radius: 16),
            const SizedBox(height: 20),
            // "Largest Discounts" title
            box(w: 120, h: 16),
            const SizedBox(height: 12),
            // Offer cards row
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, __) => box(w: 140, h: 160, radius: 12),
              ),
            ),
            const SizedBox(height: 20),
            // "Popular Stores" title
            box(w: 120, h: 16),
            const SizedBox(height: 12),
            // Restaurant cards
            ...List.generate(
              4,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    box(w: 80, h: 80, radius: 12),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          box(h: 14),
                          const SizedBox(height: 8),
                          box(w: 120, h: 12),
                          const SizedBox(height: 8),
                          box(w: 80, h: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
  );
}
