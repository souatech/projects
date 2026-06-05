import 'package:customer/constant/constant.dart';
import 'package:customer/controllers/category_restaurant_controller.dart';
import 'package:customer/models/advertisement_model.dart';
import 'package:customer/models/coupon_model.dart';
import 'package:customer/models/vendor_model.dart';
import 'package:customer/themes/app_them_data.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/utils/network_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../controllers/theme_controller.dart';
import '../../../widget/restaurant_image_view.dart';
import '../restaurant_details_screen/restaurant_details_screen.dart';

class CategoryRestaurantScreen extends StatelessWidget {
  const CategoryRestaurantScreen({super.key});

  static const Color _orange = Color(0xFFFF4B12);
  static const Color _bg = Color(0xFFF8F9FB);
  static const Color _ink = Color(0xFF111827);

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDark.value;
    return GetX(
      init: CategoryRestaurantController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: isDark ? AppThemeData.surfaceDark : _bg,
          appBar: AppBar(
            backgroundColor: isDark ? AppThemeData.surfaceDark : _bg,
            centerTitle: false,
            titleSpacing: 0,
            title: Text(
              controller.vendorCategoryModel.value.title ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppThemeData.boldTextStyle(
                fontSize: 18,
                color: isDark ? AppThemeData.grey50 : _ink,
              ),
            ),
          ),
          body:
              controller.isLoading.value
                  ? Constant.loader()
                  : controller.allNearestRestaurant.isEmpty
                  ? Constant.showEmptyView(message: "No Restaurant found".tr)
                  : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                    children: [
                      if (controller.categoryAdvertisements.isNotEmpty) ...[
                        _CategoryAdsStrip(
                          advertisements: controller.categoryAdvertisements,
                          restaurants: controller.allNearestRestaurant,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 18),
                      ],
                      if (controller.categoryCoupons.isNotEmpty &&
                          controller.couponVendors.isNotEmpty) ...[
                        _CategoryCouponsStrip(
                          coupons: controller.categoryCoupons,
                          vendors: controller.couponVendors,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 18),
                      ],
                      ...controller.allNearestRestaurant.map((vendorModel) {
                        return InkWell(
                          onTap:
                              () => Get.to(
                                const RestaurantDetailsScreen(),
                                arguments: {"vendorModel": vendorModel},
                              ),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Container(
                              decoration: ShapeDecoration(
                                color:
                                    isDark
                                        ? AppThemeData.grey900
                                        : AppThemeData.grey50,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(16),
                                          topRight: Radius.circular(16),
                                        ),
                                        child: Stack(
                                          children: [
                                            RestaurantImageView(
                                              vendorModel: vendorModel,
                                            ),
                                            Container(
                                              height: Responsive.height(
                                                20,
                                                context,
                                              ),
                                              width: Responsive.width(
                                                100,
                                                context,
                                              ),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: const Alignment(
                                                    -0.00,
                                                    -1.00,
                                                  ),
                                                  end: const Alignment(0, 1),
                                                  colors: [
                                                    Colors.black.withValues(
                                                      alpha: 0,
                                                    ),
                                                    const Color(0xFF111827),
                                                  ],
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
                                                          horizontal: 10,
                                                          vertical: 7,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          AppThemeData
                                                              .success300,
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
                                                          "Free Delivery".tr,
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            color:
                                                                AppThemeData
                                                                    .success600,
                                                            fontFamily:
                                                                AppThemeData
                                                                    .semiBold,
                                                            fontWeight:
                                                                FontWeight.w600,
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
                                                      horizontal: 10,
                                                      vertical: 7,
                                                    ),
                                                child: Row(
                                                  children: [
                                                    SvgPicture.asset(
                                                      "assets/icons/ic_star.svg",
                                                      colorFilter:
                                                          ColorFilter.mode(
                                                            AppThemeData
                                                                .primary300,
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
                                                                ? AppThemeData
                                                                    .primary300
                                                                : AppThemeData
                                                                    .primary300,
                                                        fontFamily:
                                                            AppThemeData
                                                                .semiBold,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              decoration: ShapeDecoration(
                                                color:
                                                    isDark
                                                        ? AppThemeData.grey800
                                                        : const Color(
                                                          0xFFFFF0E8,
                                                        ),
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
                                                      horizontal: 10,
                                                      vertical: 7,
                                                    ),
                                                child: Row(
                                                  children: [
                                                    SvgPicture.asset(
                                                      "assets/icons/ic_map_distance.svg",
                                                      colorFilter:
                                                          const ColorFilter.mode(
                                                            _orange,
                                                            BlendMode.srcIn,
                                                          ),
                                                    ),
                                                    const SizedBox(width: 5),
                                                    Text(
                                                      "${Constant.getDistance(lat1: vendorModel.latitude.toString(), lng1: vendorModel.longitude.toString(), lat2: Constant.selectedLocation.location!.latitude.toString(), lng2: Constant.selectedLocation.location!.longitude.toString())} ${Constant.distanceType}",
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: _orange,
                                                        fontFamily:
                                                            AppThemeData
                                                                .semiBold,
                                                        fontWeight:
                                                            FontWeight.w600,
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
                                      horizontal: 16,
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
                      }),
                    ],
                  ),
        );
      },
    );
  }
}

class _CategoryAdsStrip extends StatelessWidget {
  final List<AdvertisementModel> advertisements;
  final List<VendorModel> restaurants;
  final bool isDark;

  const _CategoryAdsStrip({
    required this.advertisements,
    required this.restaurants,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return _CategoryBusinessStrip(
      title: 'Restaurants sponsorisés'.tr,
      isDark: isDark,
      children:
          advertisements.map((ad) {
            final vendor = restaurants.firstWhereOrNull(
              (item) => item.id == ad.vendorId,
            );
            return _CategoryPromoCard(
              title: ad.title ?? vendor?.title ?? '',
              subtitle: ad.description ?? vendor?.location ?? '',
              imageUrl: ad.coverImage ?? vendor?.photo ?? '',
              isDark: isDark,
              onTap:
                  vendor == null
                      ? null
                      : () => Get.to(
                        const RestaurantDetailsScreen(),
                        arguments: {'vendorModel': vendor},
                      ),
            );
          }).toList(),
    );
  }
}

class _CategoryCouponsStrip extends StatelessWidget {
  final List<CouponModel> coupons;
  final List<VendorModel> vendors;
  final bool isDark;

  const _CategoryCouponsStrip({
    required this.coupons,
    required this.vendors,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return _CategoryBusinessStrip(
      title: 'Offres spéciales'.tr,
      isDark: isDark,
      children: List.generate(coupons.length, (index) {
        final coupon = coupons[index];
        final vendor = vendors[index];
        return _CategoryPromoCard(
          title:
              coupon.description?.isNotEmpty == true
                  ? coupon.description!
                  : '${coupon.discount ?? ''} ${coupon.discountType ?? ''}',
          subtitle: 'Code promo : @code'.trParams({'code': coupon.code ?? ''}),
          imageUrl:
              coupon.image?.isNotEmpty == true
                  ? coupon.image!
                  : vendor.photo ?? '',
          isDark: isDark,
          onTap:
              () => Get.to(
                const RestaurantDetailsScreen(),
                arguments: {'vendorModel': vendor},
              ),
        );
      }),
    );
  }
}

class _CategoryBusinessStrip extends StatelessWidget {
  final String title;
  final bool isDark;
  final List<Widget> children;

  const _CategoryBusinessStrip({
    required this.title,
    required this.isDark,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppThemeData.boldTextStyle(
            fontSize: 18,
            color: isDark ? AppThemeData.grey50 : CategoryRestaurantScreen._ink,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 126,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: children.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) => children[index],
          ),
        ),
      ],
    );
  }
}

class _CategoryPromoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final bool isDark;
  final VoidCallback? onTap;

  const _CategoryPromoCard({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 245,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppThemeData.grey900 : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: NetworkImageWidget(
                imageUrl: imageUrl,
                width: 76,
                height: 96,
                fit: BoxFit.cover,
                showShimmer: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppThemeData.boldTextStyle(
                      fontSize: 14,
                      color:
                          isDark
                              ? AppThemeData.grey50
                              : CategoryRestaurantScreen._ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppThemeData.mediumTextStyle(
                      fontSize: 12,
                      color:
                          isDark ? AppThemeData.grey300 : AppThemeData.grey600,
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
