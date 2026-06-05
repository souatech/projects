import 'package:customer/constant/constant.dart';
import 'package:customer/screen_ui/service_home_screen/service_list_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import '../../controllers/home_parcel_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../models/banner_model.dart';
import '../../models/parcel_category.dart';
import '../../models/parcel_order_model.dart';
import '../../models/user_model.dart';
import '../../themes/app_them_data.dart';
import '../../themes/show_toast_dialog.dart';
import '../../utils/network_image_widget.dart';
import '../../utils/utils.dart';
import '../../widget/osm_map/map_picker_page.dart';
import '../../widget/place_picker/location_picker_screen.dart';
import '../../widget/place_picker/selected_location_model.dart';
import '../auth_screens/login_screen.dart';
import '../location_enable_screens/address_list_screen.dart';
import 'book_parcel_screen.dart';
import 'parcel_order_details.dart';

class HomeParcelScreen extends StatelessWidget {
  const HomeParcelScreen({super.key});

  static const Color _bg = Color(0xFFF8F9FB);
  static const Color _orange = Color(0xFFFF4B12);
  static const Color _ink = Color(0xFF111111);

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDark.value;

    return GetX<HomeParcelController>(
      init: HomeParcelController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: isDark ? AppThemeData.grey900 : _bg,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            elevation: 0,
            backgroundColor: isDark ? AppThemeData.grey900 : _bg,
            title: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(50),
                    onTap: () {
                      Get.offAll(const ServiceListScreen());
                    },
                    child: Container(
                      height: 42,
                      width: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? AppThemeData.grey800 : Colors.white,
                        boxShadow: [_parcelShadow(isDark)],
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 5),
                          child: Icon(
                            Icons.arrow_back_ios,
                            color: isDark ? Colors.white : _ink,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Constant.userModel == null
                            ? InkWell(
                              onTap: () {
                                Get.offAll(const LoginScreen());
                              },
                              child: Text(
                                "Login".tr,
                                style: AppThemeData.boldTextStyle(
                                  fontSize: 14,
                                  color: isDark ? Colors.white : _ink,
                                ),
                              ),
                            )
                            : Text(
                              Constant.userModel!.fullName(),
                              style: AppThemeData.boldTextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white : _ink,
                              ),
                            ),
                        InkWell(
                          onTap: () async {
                            if (Constant.userModel != null) {
                              Get.to(AddressListScreen())!.then((value) {
                                if (value != null) {
                                  ShippingAddress shippingAddress = value;
                                  Constant.selectedLocation = shippingAddress;
                                }
                              });
                            } else {
                              Constant.checkPermission(
                                onTap: () async {
                                  ShowToastDialog.showLoader(
                                    "Please wait...".tr,
                                  );

                                  ShippingAddress shippingAddress =
                                      ShippingAddress();

                                  try {
                                    await Geolocator.requestPermission();
                                    await Geolocator.getCurrentPosition();
                                    ShowToastDialog.closeLoader();

                                    if (Constant.selectedMapType == 'osm') {
                                      final result = await Get.to(
                                        () => MapPickerPage(),
                                      );
                                      if (result != null) {
                                        final firstPlace = result;
                                        final lat =
                                            firstPlace.coordinates.latitude;
                                        final lng =
                                            firstPlace.coordinates.longitude;
                                        final address = firstPlace.address;

                                        shippingAddress.addressAs = "Home";
                                        shippingAddress.locality =
                                            address.toString();
                                        shippingAddress.location = UserLocation(
                                          latitude: lat,
                                          longitude: lng,
                                        );

                                        Constant.selectedLocation =
                                            shippingAddress;
                                        Get.back();
                                      }
                                    } else {
                                      Get.to(LocationPickerScreen())!.then((
                                        value,
                                      ) async {
                                        if (value != null) {
                                          SelectedLocationModel
                                          selectedLocationModel = value;

                                          shippingAddress.addressAs = "Home";
                                          shippingAddress
                                              .location = UserLocation(
                                            latitude:
                                                selectedLocationModel
                                                    .latLng!
                                                    .latitude,
                                            longitude:
                                                selectedLocationModel
                                                    .latLng!
                                                    .longitude,
                                          );
                                          shippingAddress
                                              .locality = Utils.formatAddress(
                                            selectedLocation:
                                                selectedLocationModel,
                                          );

                                          Constant.selectedLocation =
                                              shippingAddress;
                                        }
                                      });
                                    }
                                  } catch (e) {
                                    await placemarkFromCoordinates(
                                      19.228825,
                                      72.854118,
                                    ).then((valuePlaceMaker) {
                                      Placemark placeMark = valuePlaceMaker[0];
                                      shippingAddress.location = UserLocation(
                                        latitude: 19.228825,
                                        longitude: 72.854118,
                                      );
                                      String currentLocation =
                                          "${placeMark.name}, ${placeMark.subLocality}, ${placeMark.locality}, ${placeMark.administrativeArea}, ${placeMark.postalCode}, ${placeMark.country}";
                                      shippingAddress.locality =
                                          currentLocation;
                                    });

                                    Constant.selectedLocation = shippingAddress;
                                    ShowToastDialog.closeLoader();
                                  }
                                },
                                context: context,
                              );
                            }
                          },
                          child: Text(
                            Constant.selectedLocation.getFullAddress().isEmpty
                                ? "Choisir une adresse".tr
                                : Utils.shortAddressFromText(
                                  Constant.selectedLocation.getFullAddress(),
                                  fallback: "Choisir une adresse".tr,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppThemeData.boldTextStyle(
                              fontSize: 18,
                              color: isDark ? Colors.white : _ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          body:
              controller.isLoading.value
                  ? Center(child: Constant.loader())
                  : SafeArea(
                    top: false,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        12,
                        20,
                        24 + MediaQuery.of(context).padding.bottom,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ParcelHero(
                            isDark: isDark,
                            banners: controller.bannerTopHome,
                          ),
                          const SizedBox(height: 22),
                          Text(
                            "What are you sending?".tr,
                            style: AppThemeData.boldTextStyle(
                              fontSize: 22,
                              color: isDark ? Colors.white : _ink,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ..._prioritizedParcelCategories(
                            controller.parcelCategory,
                          ).map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: buildItems(item: item, isDark: isDark),
                            ),
                          ),
                          if (controller.recentParcelOrders.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _RecentParcelOrders(
                              orders: controller.recentParcelOrders,
                              isDark: isDark,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
        );
      },
    );
  }

  Widget buildItems({required ParcelCategory item, required bool isDark}) {
    final title = item.title ?? '';
    final isGP = title.toLowerCase().contains('gp');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () {
          if (Constant.userModel == null) {
            Get.to(const LoginScreen());
          } else {
            Get.to(
              const BookParcelScreen(),
              arguments: {'parcelCategory': item},
            );
          }
        },
        child: Ink(
          height: 176,
          decoration: BoxDecoration(
            color: isDark ? AppThemeData.grey800 : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark ? AppThemeData.grey700 : const Color(0xFFEDEFF3),
            ),
            boxShadow: [_parcelShadow(isDark)],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -8,
                bottom: -2,
                child: Opacity(
                  opacity: 0.14,
                  child: Icon(
                    isGP ? Icons.public_rounded : Icons.local_shipping_rounded,
                    size: 138,
                    color: _orange,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0E8),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(13),
                        child: NetworkImageWidget(
                          imageUrl: item.image ?? '',
                          fit: BoxFit.contain,
                          showShimmer: false,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppThemeData.boldTextStyle(
                              color: isDark ? Colors.white : _ink,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isGP
                                ? "Envoyez vos colis avec un GP".tr
                                : "Livraison rapide partout".tr,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppThemeData.mediumTextStyle(
                              color:
                                  isDark
                                      ? AppThemeData.grey300
                                      : AppThemeData.grey600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: _orange,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Text(
                              "Continuer".tr,
                              style: AppThemeData.boldTextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: _orange,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentParcelOrders extends StatelessWidget {
  final List<ParcelOrderModel> orders;
  final bool isDark;

  const _RecentParcelOrders({required this.orders, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final visibleOrders = orders.take(3).toList();
    if (visibleOrders.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Derniers envois".tr,
          style: AppThemeData.boldTextStyle(
            fontSize: 20,
            color: isDark ? Colors.white : HomeParcelScreen._ink,
          ),
        ),
        const SizedBox(height: 12),
        ...visibleOrders.map(
          (order) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _RecentParcelOrderCard(order: order, isDark: isDark),
          ),
        ),
      ],
    );
  }
}

class _RecentParcelOrderCard extends StatelessWidget {
  final ParcelOrderModel order;
  final bool isDark;

  const _RecentParcelOrderCard({required this.order, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final route = _parcelRoute(order);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => Get.to(() => const ParcelOrderDetails(), arguments: order),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppThemeData.grey800 : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? AppThemeData.grey700 : const Color(0xFFEDEFF3),
            ),
            boxShadow: [_parcelShadow(isDark)],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0E8),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: NetworkImageWidget(
                    imageUrl:
                        order.parcelImages?.isNotEmpty == true
                            ? order.parcelImages!.first.toString()
                            : '',
                    fit: BoxFit.contain,
                    showShimmer: false,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.parcelType?.isNotEmpty == true
                          ? order.parcelType!
                          : "Colis".tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppThemeData.boldTextStyle(
                        fontSize: 15,
                        color: isDark ? Colors.white : HomeParcelScreen._ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      route,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppThemeData.mediumTextStyle(
                        fontSize: 13,
                        color:
                            isDark
                                ? AppThemeData.grey300
                                : AppThemeData.grey600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _parcelDate(order.createdAt),
                      style: AppThemeData.regularTextStyle(
                        fontSize: 12,
                        color:
                            isDark
                                ? AppThemeData.grey400
                                : AppThemeData.grey500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: HomeParcelScreen._orange.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  Constant.translateStatus(order.status),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppThemeData.semiBoldTextStyle(
                    fontSize: 11,
                    color: HomeParcelScreen._orange,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: HomeParcelScreen._ink,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParcelHero extends StatelessWidget {
  final bool isDark;
  final List<BannerModel> banners;

  const _ParcelHero({required this.isDark, required this.banners});

  @override
  Widget build(BuildContext context) {
    if (banners.isNotEmpty) {
      return BannerView(bannerList: banners);
    }
    return const SizedBox.shrink();
  }
}

List<ParcelCategory> _prioritizedParcelCategories(
  List<ParcelCategory> categories,
) {
  final list = List<ParcelCategory>.from(categories);
  list.sort((a, b) {
    int score(ParcelCategory category) {
      final title = (category.title ?? '').toLowerCase();
      if (title.contains('express')) return 0;
      if (title.contains('gp')) return 1;
      return 2;
    }

    return score(a).compareTo(score(b));
  });
  return list;
}

String _parcelRoute(ParcelOrderModel order) {
  final from = Utils.shortAddressFromText(
    order.sender?.address ?? '',
    fallback: '',
  );
  final to = Utils.shortAddressFromText(
    order.receiver?.address ?? '',
    fallback: '',
  );
  if (from.isNotEmpty && to.isNotEmpty) {
    return '$from → $to';
  }
  if (from.isNotEmpty) {
    return from;
  }
  if (to.isNotEmpty) {
    return to;
  }
  return 'Adresse non renseignée'.tr;
}

String _parcelDate(Timestamp? timestamp) {
  if (timestamp == null) {
    return '';
  }
  final date = timestamp.toDate();
  final now = DateTime.now();
  final label =
      date.year == now.year && date.month == now.month && date.day == now.day
          ? "Aujourd’hui".tr
          : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  return '$label, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

BoxShadow _parcelShadow(bool isDark) {
  return BoxShadow(
    color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.07),
    blurRadius: 24,
    offset: const Offset(0, 12),
  );
}

class BannerView extends StatefulWidget {
  final List<BannerModel> bannerList;

  const BannerView({super.key, required this.bannerList});

  @override
  State<BannerView> createState() => _BannerViewState();
}

class _BannerViewState extends State<BannerView> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _scheduleNext();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _scheduleNext() {
    if (widget.bannerList.length <= 1) return;
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted ||
          !_controller.hasClients ||
          widget.bannerList.length <= 1) {
        return;
      }
      final next = (_page + 1) % widget.bannerList.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
      _scheduleNext();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.bannerList.length,
            onPageChanged: (value) => setState(() => _page = value),
            itemBuilder: (context, index) {
              final banner = widget.bannerList[index];
              return ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: NetworkImageWidget(
                  imageUrl: banner.photo ?? '',
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
        ),
        if (widget.bannerList.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.bannerList.length, (index) {
              final selected = index == _page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 5,
                width: selected ? 22 : 6,
                decoration: BoxDecoration(
                  color:
                      selected
                          ? HomeParcelScreen._orange
                          : AppThemeData.grey300,
                  borderRadius: BorderRadius.circular(99),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
