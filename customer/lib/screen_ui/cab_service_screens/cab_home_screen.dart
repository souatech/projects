import 'package:customer/constant/constant.dart';
import 'package:customer/controllers/cab_dashboard_controller.dart';
import 'package:customer/controllers/cab_home_controller.dart';
import 'package:customer/controllers/theme_controller.dart';
import 'package:customer/models/banner_model.dart';
import 'package:customer/models/cab_order_model.dart';
import 'package:customer/screen_ui/help_support_screen/help_support_screen.dart';
import 'package:customer/screen_ui/multi_vendor_service/favourite_screens/favourite_screen.dart';
import 'package:customer/screen_ui/multi_vendor_service/profile_screen/profile_screen.dart';
import 'package:customer/screen_ui/service_home_screen/service_list_screen.dart';
import 'package:customer/service/fire_store_utils.dart';
import 'package:customer/themes/app_them_data.dart';
import 'package:customer/utils/network_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'Intercity_home_screen.dart';
import 'cab_booking_screen.dart';
import 'cab_order_details.dart';

const Color _cabOrange = Color(0xFFFF4B12);
const Color _cabBg = Color(0xFFF8F9FB);
const Color _cabInk = Color(0xFF10131A);

class CabHomeScreen extends StatelessWidget {
  const CabHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final section = Constant.sectionConstantModel;
    final serviceName =
        (section?.name ?? '').trim().isNotEmpty
            ? section!.name!.trim()
            : Constant.translateServiceName(section?.serviceTypeFlag ?? '');
    final rideOptions = _activeCabRideOptions(section);

    return GetX(
      init: CabHomeController(),
      builder: (controller) {
        final isDark = themeController.isDark.value;
        return Scaffold(
          backgroundColor: isDark ? AppThemeData.greyDark50 : _cabBg,
          body:
              controller.isLoading.value
                  ? Constant.loader()
                  : SafeArea(
                    bottom: false,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        18,
                        20,
                        24 + MediaQuery.of(context).padding.bottom,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _CabHeader(isDark: isDark),
                          const SizedBox(height: 34),
                          _GreetingBlock(serviceName: serviceName),
                          const SizedBox(height: 24),
                          _DestinationSearchBar(
                            onTap: () => Get.to(() => const CabBookingScreen()),
                          ),
                          const SizedBox(height: 24),
                          if (rideOptions.isNotEmpty)
                            _RideOptionsGrid(options: rideOptions),
                          const SizedBox(height: 24),
                          _CabActionStrip(isDark: isDark),
                          const SizedBox(height: 24),
                          if (controller.bannerTopHome.isNotEmpty) ...[
                            _CabAdminBannerCarousel(
                              banners: controller.bannerTopHome,
                            ),
                            const SizedBox(height: 24),
                          ],
                          _RecentRideSection(isDark: isDark),
                        ],
                      ),
                    ),
                  ),
        );
      },
    );
  }
}

class _CabAdminBannerCarousel extends StatefulWidget {
  final List<BannerModel> banners;

  const _CabAdminBannerCarousel({required this.banners});

  @override
  State<_CabAdminBannerCarousel> createState() =>
      _CabAdminBannerCarouselState();
}

class _CabAdminBannerCarouselState extends State<_CabAdminBannerCarousel> {
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
    if (widget.banners.length <= 1) return;
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted || !_controller.hasClients || widget.banners.length <= 1) {
        return;
      }
      final next = (_page + 1) % widget.banners.length;
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
    final images =
        widget.banners
            .map((banner) => (banner.photo ?? '').trim())
            .where((photo) => photo.isNotEmpty)
            .toList();
    if (images.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 132,
          child: PageView.builder(
            controller: _controller,
            itemCount: images.length,
            onPageChanged: (value) => setState(() => _page = value),
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: NetworkImageWidget(
                  imageUrl: images[index],
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(images.length, (index) {
              final selected = index == _page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 5,
                width: selected ? 22 : 6,
                decoration: BoxDecoration(
                  color: selected ? _cabOrange : AppThemeData.grey300,
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

class _CabHeader extends StatelessWidget {
  final bool isDark;

  const _CabHeader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconCircle(
          icon: Icons.menu_rounded,
          isDark: isDark,
          onTap: () => Get.offAll(const ServiceListScreen()),
        ),
        Expanded(
          child: Center(
            child: Image.asset(
              'assets/icons/joxmako_icon.png',
              height: 66,
              fit: BoxFit.contain,
            ),
          ),
        ),
        _IconCircle(
          icon: Icons.notifications_none_rounded,
          isDark: isDark,
          showDot: false,
          onTap:
              () => Get.to(HelpSupportScreen(isNavigateViaNotification: true)),
        ),
        const SizedBox(width: 12),
        _ProfileAvatar(),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final image = Constant.userModel?.profilePictureURL ?? '';
    return GestureDetector(
      onTap: () {
        if (Get.isRegistered<CabDashboardController>()) {
          Get.find<CabDashboardController>().selectedIndex.value = 2;
        } else {
          Get.to(const ProfileScreen());
        }
      },
      child: Container(
        height: 48,
        width: 48,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppThemeData.grey200,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child:
            image.isEmpty
                ? Icon(Icons.person_rounded, color: AppThemeData.grey600)
                : NetworkImageWidget(imageUrl: image, fit: BoxFit.cover),
      ),
    );
  }
}

class _GreetingBlock extends StatelessWidget {
  final String serviceName;

  const _GreetingBlock({required this.serviceName});

  @override
  Widget build(BuildContext context) {
    final firstName = (Constant.userModel?.firstName ?? '').trim();
    final name =
        firstName.isEmpty ? Constant.userModel?.fullName().trim() : firstName;
    return Stack(
      children: [
        Positioned(
          right: 0,
          bottom: -4,
          child: Icon(
            Icons.location_city_rounded,
            color: Colors.black.withValues(alpha: 0.035),
            size: 118,
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${'Bonjour'.tr}, ${(name ?? '').isEmpty ? 'Guest'.tr : name} 👋",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppThemeData.boldTextStyle(color: _cabInk, fontSize: 30),
            ),
            const SizedBox(height: 8),
            Text(
              "Où allons-nous aujourd’hui ?".tr,
              style: AppThemeData.mediumTextStyle(
                color: AppThemeData.grey600,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DestinationSearchBar extends StatelessWidget {
  final VoidCallback onTap;

  const _DestinationSearchBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 70),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFEDEFF3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              color: AppThemeData.grey600,
              size: 30,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                "Où voulez-vous aller ?".tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppThemeData.mediumTextStyle(
                  color: AppThemeData.grey600,
                  fontSize: 17,
                ),
              ),
            ),
            Container(width: 1, height: 34, color: const Color(0xFFEDEFF3)),
            const SizedBox(width: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFEDEFF3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule_rounded, color: _cabInk, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Maintenant".tr,
                    style: AppThemeData.semiBoldTextStyle(
                      color: _cabInk,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppThemeData.grey600,
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

class _RideOptionsGrid extends StatelessWidget {
  final List<_CabRideOption> options;

  const _RideOptionsGrid({required this.options});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children:
              options
                  .map(
                    (option) => SizedBox(
                      width: cardWidth,
                      child: _CabRideOptionCard(option: option),
                    ),
                  )
                  .toList(),
        );
      },
    );
  }
}

class _CabRideOption {
  final String title;
  final String subtitle;
  final String assetIcon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _CabRideOption({
    required this.title,
    required this.subtitle,
    required this.assetIcon,
    required this.gradient,
    required this.onTap,
  });
}

List<_CabRideOption> _activeCabRideOptions(dynamic section) {
  final rideType = (section?.rideType ?? '').toString().toLowerCase();
  final serviceName = (section?.name ?? '').toString().trim();
  final options = <_CabRideOption>[];

  if (rideType == 'both' || rideType == 'ride') {
    options.add(
      _CabRideOption(
        title:
            serviceName.isNotEmpty
                ? serviceName
                : Constant.translateServiceName(section?.serviceTypeFlag ?? ''),
        subtitle: "Déplacements rapides en ville".tr,
        assetIcon: 'assets/icons/ic_mini_car.png',
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF1E8), Color(0xFFFFD7C4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: () => Get.to(() => const CabBookingScreen()),
      ),
    );
  }

  if (rideType == 'both' || rideType == 'intercity') {
    options.add(
      _CabRideOption(
        title: 'intercity'.tr,
        subtitle: "Voyagez vers toutes les régions".tr,
        assetIcon: 'assets/images/ic_cab.png',
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE7C9), Color(0xFFD29A64)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: () => Get.to(() => const IntercityHomeScreen()),
      ),
    );
  }

  return options;
}

class _CabRideOptionCard extends StatelessWidget {
  final _CabRideOption option;

  const _CabRideOptionCard({required this.option});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: option.onTap,
      child: Container(
        height: 194,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: option.gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: 0,
              child: Image.asset(
                option.assetIcon,
                height: 112,
                width: 170,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              right: 22,
              top: 68,
              child: Icon(
                Icons.location_city_rounded,
                size: 72,
                color: Colors.white.withValues(alpha: 0.22),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppThemeData.boldTextStyle(
                      color: _cabInk,
                      fontSize: 27,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 148,
                    child: Text(
                      option.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppThemeData.mediumTextStyle(
                        color: AppThemeData.grey700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    height: 46,
                    width: 46,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: _cabOrange,
                      size: 28,
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

class _CabActionStrip extends StatelessWidget {
  final bool isDark;

  const _CabActionStrip({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _CabQuickAction(
        icon: Icons.history_rounded,
        label: "Mes courses".tr,
        onTap: () => Get.find<CabDashboardController>().selectedIndex.value = 1,
      ),
      _CabQuickAction(
        icon: Icons.star_border_rounded,
        label: "Favoris".tr,
        onTap: () => Get.to(const FavouriteScreen()),
      ),
      _CabQuickAction(
        icon: Icons.headset_mic_outlined,
        label: "Support".tr,
        onTap:
            () => Get.to(HelpSupportScreen(isNavigateViaNotification: false)),
      ),
      _CabQuickAction(
        icon: Icons.more_horiz_rounded,
        label: "Plus".tr,
        onTap: () => Get.find<CabDashboardController>().selectedIndex.value = 2,
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.greyDark100 : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children:
            actions
                .map(
                  (action) => Expanded(
                    child: GestureDetector(
                      onTap: action.onTap,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(action.icon, size: 32, color: _cabInk),
                          const SizedBox(height: 8),
                          Text(
                            action.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppThemeData.mediumTextStyle(
                              color: _cabInk,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }
}

class _CabQuickAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CabQuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class _RecentRideSection extends StatelessWidget {
  final bool isDark;

  const _RecentRideSection({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CabOrderModel>>(
      stream: FireStoreUtils.getCabDriverOrders(),
      builder: (context, snapshot) {
        final rides = (snapshot.data ?? []).take(3).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Dernières courses réalisées".tr,
                    style: AppThemeData.boldTextStyle(
                      color: _cabInk,
                      fontSize: 22,
                    ),
                  ),
                ),
                TextButton(
                  onPressed:
                      () =>
                          Get.find<CabDashboardController>()
                              .selectedIndex
                              .value = 1,
                  child: Row(
                    children: [
                      Text(
                        "Voir tout".tr,
                        style: AppThemeData.semiBoldTextStyle(
                          color: _cabOrange,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: _cabOrange,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (snapshot.connectionState == ConnectionState.waiting)
              Container(
                height: 92,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Constant.loader(),
              )
            else if (rides.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFEDEFF3)),
                ),
                child: Text(
                  "Aucune course trouvée".tr,
                  style: AppThemeData.mediumTextStyle(
                    color: AppThemeData.grey600,
                    fontSize: 15,
                  ),
                ),
              )
            else
              Column(
                children:
                    rides
                        .map(
                          (ride) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _RecentRideCard(ride: ride),
                          ),
                        )
                        .toList(),
              ),
          ],
        );
      },
    );
  }
}

class _RecentRideCard extends StatelessWidget {
  final CabOrderModel ride;

  const _RecentRideCard({required this.ride});

  @override
  Widget build(BuildContext context) {
    final source = _shortPlace(ride.sourceLocationName);
    final destination = _shortPlace(ride.destinationLocationName);
    final date =
        ride.createdAt == null
            ? ''
            : Constant.timestampToDateTime(ride.createdAt!);
    final amount = Constant.amountShow(amount: ride.subTotal ?? '0');
    final status = Constant.translateStatus(ride.status);
    final isCompleted = (ride.status ?? '').toLowerCase().contains('complete');

    return GestureDetector(
      onTap:
          () => Get.to(
            () => const CabOrderDetails(),
            arguments: {"cabOrderModel": ride},
          ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEDEFF3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              child: CustomPaint(
                painter: _RouteMiniPainter(),
                child: const SizedBox(height: 48),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    source,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppThemeData.semiBoldTextStyle(
                      color: _cabInk,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    destination,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppThemeData.mediumTextStyle(
                      color: AppThemeData.grey600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    date,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppThemeData.mediumTextStyle(
                      color: AppThemeData.grey600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    amount,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppThemeData.boldTextStyle(
                      color: _cabInk,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color:
                    isCompleted
                        ? const Color(0xFFE8F7EE)
                        : AppThemeData.warning50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                status,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppThemeData.semiBoldTextStyle(
                  color:
                      isCompleted
                          ? const Color(0xFF078C35)
                          : AppThemeData.warning500,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, color: AppThemeData.grey600),
          ],
        ),
      ),
    );
  }
}

class _IconCircle extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final bool showDot;
  final VoidCallback onTap;

  const _IconCircle({
    required this.icon,
    required this.isDark,
    required this.onTap,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: isDark ? AppThemeData.greyDark100 : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: _cabInk, size: 30),
          ),
          if (showDot)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                height: 9,
                width: 9,
                decoration: const BoxDecoration(
                  color: _cabOrange,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RouteMiniPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint =
        Paint()
          ..color = AppThemeData.grey600
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;
    final path =
        Path()
          ..moveTo(10, size.height - 10)
          ..quadraticBezierTo(size.width * 0.34, 4, size.width * 0.62, 20)
          ..quadraticBezierTo(size.width * 0.82, 34, size.width - 10, 8);
    _drawDashedPath(canvas, path, linePaint);

    final startPaint = Paint()..color = _cabOrange;
    final endPaint = Paint()..color = Colors.black;
    canvas.drawCircle(Offset(10, size.height - 10), 6, startPaint);
    canvas.drawCircle(Offset(size.width - 10, 8), 6, endPaint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + 10;
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + 8;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

String _shortPlace(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return "Adresse non disponible".tr;
  final parts =
      text
          .split(',')
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .toList();
  if (parts.length <= 2) return text;
  return parts.take(2).join(', ');
}
