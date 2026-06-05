import 'dart:async';

import 'package:customer/constant/assets.dart';
import 'package:customer/constant/collection_name.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/models/advertisement_model.dart';
import 'package:customer/models/cab_order_model.dart';
import 'package:customer/models/coupon_model.dart';
import 'package:customer/models/parcel_order_model.dart';
import 'package:customer/models/section_model.dart';
import 'package:customer/models/vendor_category_model.dart';
import 'package:customer/screen_ui/help_support_screen/help_support_screen.dart';
import 'package:customer/screen_ui/location_enable_screens/address_list_screen.dart';
import 'package:customer/screen_ui/location_enable_screens/location_permission_screen.dart';
import 'package:customer/screen_ui/multi_vendor_service/favourite_screens/favourite_screen.dart';
import 'package:customer/screen_ui/multi_vendor_service/order_list_screen/order_screen.dart';
import 'package:customer/screen_ui/multi_vendor_service/profile_screen/profile_screen.dart';
import 'package:customer/screen_ui/multi_vendor_service/refer_friend_screen/refer_friend_screen.dart';
import 'package:customer/service/fire_store_utils.dart';
import 'package:customer/utils/tracking_navigation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../controllers/service_list_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../themes/app_them_data.dart';
import '../../models/rental_order_model.dart';
import '../../models/vendor_model.dart';
import '../../utils/network_image_widget.dart';
import '../../utils/service_section_router.dart';
import '../../utils/utils.dart';
import '../multi_vendor_service/restaurant_details_screen/restaurant_details_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ROOT
// ─────────────────────────────────────────────────────────────────────────────

class ServiceListScreen extends StatefulWidget {
  const ServiceListScreen({super.key});

  static const Color _background = _ServiceListScreenColors.bg;
  static const Color _orange = _ServiceListScreenColors.orange;

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  int _selectedIndex = 0;

  Future<void> _openAddressPicker() async {
    if (Constant.userModel == null) {
      await Get.to(const LocationPermissionScreen());
      if (mounted) setState(() {});
      return;
    }
    final value = await Get.to(const AddressListScreen());
    if (value != null) {
      Constant.selectedLocation = value;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return GetX(
      init: ServiceListController(),
      builder: (controller) {
        final bool isDark = themeController.isDark.value;
        final activeSections = _activeNavigableSections(controller.sectionList);
        return Scaffold(
          backgroundColor:
              isDark ? AppThemeData.grey900 : ServiceListScreen._background,
          body: controller.isLoading.value
              ? const SafeArea(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: ServiceListScreen._orange,
                    ),
                  ),
                )
              : _selectedIndex == 0
                  ? _ServiceHomeBody(
                      controller: controller,
                      sections: activeSections,
                      banners: controller.serviceListBanner,
                      isDark: isDark,
                      onAddressTap: _openAddressPicker,
                      onSelectTab: (index) {
                        _ensureSectionContext(controller.sectionList);
                        setState(() => _selectedIndex = index);
                      },
                    )
                  : _ShellPage(
                      sections: activeSections,
                      selectedIndex: _selectedIndex,
                    ),
          bottomNavigationBar: controller.isLoading.value
              ? null
              : _HomeBottomBar(
                  sections: activeSections,
                  isDark: isDark,
                  currentIndex: _selectedIndex,
                  onTap: (index) {
                    _ensureSectionContext(controller.sectionList);
                    setState(() => _selectedIndex = index);
                  },
                ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HOME BODY — layout complet
// ─────────────────────────────────────────────────────────────────────────────

class _ServiceHomeBody extends StatelessWidget {
  final ServiceListController controller;
  final List<SectionModel> sections;
  final List<dynamic> banners;
  final bool isDark;
  final VoidCallback onAddressTap;
  final ValueChanged<int> onSelectTab;

  const _ServiceHomeBody({
    required this.controller,
    required this.sections,
    required this.banners,
    required this.isDark,
    required this.onAddressTap,
    required this.onSelectTab,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        color: ServiceListScreen._orange,
        onRefresh: controller.loadData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. Header
            SliverToBoxAdapter(
              child: _HomeHeader(
                sections: sections,
                isDark: isDark,
                onAddressTap: onAddressTap,
                onSelectTab: onSelectTab,
              ),
            ),
            // 2. Services actifs (horizontal scroll)
            if (sections.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyServicesState(isDark: isDark),
              )
            else ...[
              // 3. Banner admin
              SliverToBoxAdapter(
                child: _AdminBanner(banners: banners, isDark: isDark),
              ),
              // 4. Services actifs
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
                  child: _SectionTitle(
                    title: 'Nos services'.tr,
                    isDark: isDark,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _ServicesRail(
                  sections: sections,
                  isDark: isDark,
                  onTap: (s) => controller.onServiceTap(context, s),
                ),
              ),
              // 5. Parrainage
              SliverToBoxAdapter(
                child: _ReferralSection(sections: sections, isDark: isDark),
              ),
              // 6. Catégories Food + Restaurants
              SliverToBoxAdapter(
                child: _ServiceSection(
                  sections: sections,
                  serviceTypeFlag: 'delivery-service',
                  categoriesLabel: 'Catégories Food'.tr,
                  vendorsLabel: 'Restaurants près de vous'.tr,
                  isDark: isDark,
                  onViewAll: () {
                    final s = _findSection(sections, 'delivery-service');
                    if (s != null) controller.onServiceTap(context, s);
                  },
                ),
              ),
              // 7. Catégories Grocery + Épiceries
              SliverToBoxAdapter(
                child: _ServiceSection(
                  sections: sections,
                  serviceTypeFlag: 'ecommerce-service',
                  categoriesLabel: 'Catégories Épicerie'.tr,
                  vendorsLabel: 'Magasins & épiceries proches de chez vous'.tr,
                  isDark: isDark,
                  onViewAll: () {
                    final s = _findSection(sections, 'ecommerce-service');
                    if (s != null) controller.onServiceTap(context, s);
                  },
                ),
              ),
              // 8. Derniers colis
              SliverToBoxAdapter(
                child: _RecentParcelsSection(
                  isDark: isDark,
                  onViewAll: () => onSelectTab(2),
                ),
              ),
              // 9. Derniers trajets cab
              SliverToBoxAdapter(
                child: _RecentRidesSection(
                  isDark: isDark,
                  onViewAll: () => onSelectTab(2),
                ),
              ),
              // 10. Rental si actif
              SliverToBoxAdapter(
                child: _RecentRentalSection(
                  sections: sections,
                  isDark: isDark,
                  onViewAll: () => onSelectTab(2),
                ),
              ),
              // 11. Promotions actives
              SliverToBoxAdapter(
                child: _ActivePromosSection(
                  sections: sections,
                  isDark: isDark,
                ),
              ),
              // 12. Sponsors actifs
              SliverToBoxAdapter(
                child: _SponsorsSection(sections: sections, isDark: isDark),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 20 + MediaQuery.of(context).padding.bottom,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHELL (tabs 1-4)
// ─────────────────────────────────────────────────────────────────────────────

class _ShellPage extends StatelessWidget {
  final List<SectionModel> sections;
  final int selectedIndex;

  const _ShellPage({required this.sections, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    _ensureSectionContext(sections);
    if (selectedIndex == 1) return const FavouriteScreen();
    if (selectedIndex == 2) return const OrderScreen();
    if (selectedIndex == 3) {
      return HelpSupportScreen(isNavigateViaNotification: false);
    }
    return const ProfileScreen();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  final List<SectionModel> sections;
  final bool isDark;
  final VoidCallback onAddressTap;
  final ValueChanged<int> onSelectTab;

  const _HomeHeader({
    required this.sections,
    required this.isDark,
    required this.onAddressTap,
    required this.onSelectTab,
  });

  @override
  Widget build(BuildContext context) {
    final String address =
        Constant.selectedLocation.getFullAddress().isNotEmpty
            ? _shortLocation(Constant.selectedLocation.getFullAddress())
            : 'Choisir une adresse'.tr;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            AppAssets.icAppLogo,
            width: 100,
            height: 72,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: onAddressTap,
                child: Ink(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isDark ? AppThemeData.grey800 : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [_softShadow(isDark)],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: _ServiceListScreenColors.orange,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppThemeData.boldTextStyle(
                            fontSize: 14,
                            color: isDark
                                ? AppThemeData.grey50
                                : _ServiceListScreenColors.ink,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _ServiceListScreenColors.orange,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _NotificationButton(isDark: isDark),
          const SizedBox(width: 8),
          _ProfileAvatar(
            sections: sections,
            isDark: isDark,
            onTap: () => onSelectTab(4),
          ),
        ],
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final bool isDark;
  const _NotificationButton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Get.to(HelpSupportScreen(isNavigateViaNotification: true)),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isDark ? AppThemeData.grey800 : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [_smallShadow(isDark)],
          ),
          child: Icon(
            Icons.notifications_none_rounded,
            color: isDark ? AppThemeData.grey50 : _ServiceListScreenColors.ink,
            size: 26,
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final List<SectionModel> sections;
  final bool isDark;
  final VoidCallback onTap;

  const _ProfileAvatar({
    required this.sections,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String imageUrl = Constant.userModel?.profilePictureURL ?? '';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          _ensureSectionContext(sections);
          onTap();
        },
        child: Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isDark ? AppThemeData.grey800 : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [_smallShadow(isDark)],
          ),
          child: ClipOval(
            child: imageUrl.isEmpty
                ? Image.asset(Constant.userPlaceHolder, fit: BoxFit.cover)
                : NetworkImageWidget(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    showShimmer: false,
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. SERVICES RAIL
// ─────────────────────────────────────────────────────────────────────────────

class _ServicesRail extends StatelessWidget {
  final List<SectionModel> sections;
  final bool isDark;
  final ValueChanged<SectionModel> onTap;

  const _ServicesRail({
    required this.sections,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 20),
      child: SizedBox(
        height: 108,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          scrollDirection: Axis.horizontal,
          itemCount: sections.length,
          separatorBuilder: (_, si) => const SizedBox(width: 14),
          itemBuilder: (context, index) {
            final section = sections[index];
            return _ServiceRailItem(
              title: _serviceTitle(section),
              imageUrl: section.sectionImage ?? '',
              isDark: isDark,
              onTap: () => onTap(section),
            );
          },
        ),
      ),
    );
  }
}

class _ServiceRailItem extends StatelessWidget {
  final String title;
  final String imageUrl;
  final bool isDark;
  final VoidCallback onTap;

  const _ServiceRailItem({
    required this.title,
    required this.imageUrl,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 82,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppThemeData.grey800
                      : const Color(0xFFFFF4EF),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? AppThemeData.grey700
                        : const Color(0xFFECEEF3),
                  ),
                  boxShadow: [_microShadow(isDark)],
                ),
                clipBehavior: Clip.antiAlias,
                child: imageUrl.trim().isEmpty
                    ? _ServiceInitialsBadge(title: title, isDark: isDark)
                    : Padding(
                        padding: const EdgeInsets.all(8),
                        child: NetworkImageWidget(
                          imageUrl: imageUrl,
                          fit: BoxFit.contain,
                          showShimmer: false,
                        ),
                      ),
              ),
              const SizedBox(height: 7),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppThemeData.boldTextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppThemeData.grey50
                      : _ServiceListScreenColors.ink,
                ).copyWith(height: 1.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceInitialsBadge extends StatelessWidget {
  final String title;
  final bool isDark;

  const _ServiceInitialsBadge({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        _initials(title),
        style: AppThemeData.boldTextStyle(
          fontSize: 14,
          color:
              isDark ? AppThemeData.grey50 : _ServiceListScreenColors.orange,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. ADMIN BANNER
// ─────────────────────────────────────────────────────────────────────────────

class _AdminBanner extends StatefulWidget {
  final List<dynamic> banners;
  final bool isDark;

  const _AdminBanner({required this.banners, required this.isDark});

  @override
  State<_AdminBanner> createState() => _AdminBannerState();
}

class _AdminBannerState extends State<_AdminBanner> {
  late final PageController _ctrl;
  Timer? _timer;
  int _page = 0;

  List<String> get _images => widget.banners
      .map(_serviceBannerImage)
      .where((u) => u.trim().isNotEmpty)
      .toList();

  @override
  void initState() {
    super.initState();
    _ctrl = PageController();
    _startTimer();
  }

  void _startTimer() {
    if (_images.length <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_ctrl.hasClients) return;
      final count = _images.length;
      if (count <= 1) return;
      _ctrl.animateToPage(
        (_page + 1) % count,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void didUpdateWidget(covariant _AdminBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banners.length != widget.banners.length) {
      _page = 0;
      _timer?.cancel();
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = _images;
    if (images.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: AspectRatio(
          aspectRatio: 2.1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: _ctrl,
                itemCount: images.length,
                onPageChanged: (v) => setState(() => _page = v),
                itemBuilder: (_, i) => NetworkImageWidget(
                  imageUrl: images[i],
                  fit: BoxFit.cover,
                  showShimmer: false,
                ),
              ),
              if (images.length > 1)
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      images.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _page == i ? 18 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: _page == i
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. PARRAINAGE
// ─────────────────────────────────────────────────────────────────────────────

class _ReferralSection extends StatelessWidget {
  final List<SectionModel> sections;
  final bool isDark;

  const _ReferralSection({required this.sections, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final SectionModel? referralSection = _firstReferralSection(sections);
    if (Constant.userModel == null || referralSection == null) {
      return const SizedBox.shrink();
    }
    final String amount = Constant.amountShow(
      amount: referralSection.referralAmount ?? '0',
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 26),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [AppThemeData.grey800, AppThemeData.grey800]
                : [const Color(0xFFFFF1E9), const Color(0xFFFFE5D8)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [_softShadow(isDark)],
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [_microShadow(isDark)],
              ),
              child: const Icon(
                Icons.card_giftcard_rounded,
                color: _ServiceListScreenColors.orange,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Parrainez et gagnez @amount'.trParams({'amount': amount}),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppThemeData.boldTextStyle(
                      fontSize: 16,
                      color: isDark
                          ? AppThemeData.grey50
                          : _ServiceListScreenColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Plus vous parrainez, plus vous gagnez !'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppThemeData.regularTextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppThemeData.grey200
                          : AppThemeData.grey700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () {
                  Constant.sectionConstantModel = referralSection;
                  Get.to(const ReferFriendScreen());
                },
                child: Ink(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _ServiceListScreenColors.orange,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(
                    'Inviter'.tr,
                    style: AppThemeData.boldTextStyle(
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5+6 / 7+8. SERVICE SECTION (catégories + vendeurs)
// ─────────────────────────────────────────────────────────────────────────────

class _ServiceSectionData {
  final List<VendorCategoryModel> categories;
  final List<VendorModel> vendors;

  _ServiceSectionData({required this.categories, required this.vendors});
}

class _ServiceSection extends StatefulWidget {
  final List<SectionModel> sections;
  final String serviceTypeFlag;
  final String categoriesLabel;
  final String vendorsLabel;
  final bool isDark;
  final VoidCallback onViewAll;

  const _ServiceSection({
    required this.sections,
    required this.serviceTypeFlag,
    required this.categoriesLabel,
    required this.vendorsLabel,
    required this.isDark,
    required this.onViewAll,
  });

  @override
  State<_ServiceSection> createState() => _ServiceSectionState();
}

class _ServiceSectionState extends State<_ServiceSection> {
  late Future<_ServiceSectionData> _future;
  SectionModel? _section;

  @override
  void initState() {
    super.initState();
    _section = _findSection(widget.sections, widget.serviceTypeFlag);
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant _ServiceSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sections != widget.sections) {
      final found = _findSection(widget.sections, widget.serviceTypeFlag);
      if (found?.id != _section?.id) {
        setState(() {
          _section = found;
          _future = _load();
        });
      }
    }
  }

  Future<_ServiceSectionData> _load() async {
    final id = (_section?.id ?? '').trim();
    if (id.isEmpty) {
      return _ServiceSectionData(categories: [], vendors: []);
    }
    final results = await Future.wait([
      _loadCategories(id),
      _loadVendors(id),
    ]);
    return _ServiceSectionData(
      categories: results[0] as List<VendorCategoryModel>,
      vendors: results[1] as List<VendorModel>,
    );
  }

  Future<List<VendorCategoryModel>> _loadCategories(String sectionId) async {
    try {
      final snap = await FireStoreUtils.fireStore
          .collection(CollectionName.vendorCategories)
          .where('section_id', isEqualTo: sectionId)
          .where('publish', isEqualTo: true)
          .limit(8)
          .get();
      return snap.docs
          .map((d) => VendorCategoryModel.fromJson(d.data()))
          .where((c) => (c.title ?? '').trim().isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<VendorModel>> _loadVendors(String sectionId) async {
    try {
      final snap = await FireStoreUtils.fireStore
          .collection(CollectionName.vendors)
          .where('section_id', isEqualTo: sectionId)
          .limit(7)
          .get();
      return snap.docs
          .map((d) {
            try {
              return VendorModel.fromJson(d.data());
            } catch (_) {
              return null;
            }
          })
          .whereType<VendorModel>()
          .where((v) => (v.title ?? '').trim().isNotEmpty)
          .take(5)
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_section == null) return const SizedBox.shrink();

    return FutureBuilder<_ServiceSectionData>(
      future: _future,
      builder: (context, snap) {
        final data = snap.data;
        if (data == null ||
            (data.categories.isEmpty && data.vendors.isEmpty)) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Catégories
              if (data.categories.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _TitleWithAction(
                    title: widget.categoriesLabel,
                    isDark: widget.isDark,
                    onTap: widget.onViewAll,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    scrollDirection: Axis.horizontal,
                    itemCount: data.categories.length,
                    separatorBuilder: (_, si) => const SizedBox(width: 14),
                    itemBuilder: (_, i) => _CategoryChip(
                      category: data.categories[i],
                      isDark: widget.isDark,
                      onTap: widget.onViewAll,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
              ],
              // Vendeurs
              if (data.vendors.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _TitleWithAction(
                    title: widget.vendorsLabel,
                    isDark: widget.isDark,
                    onTap: widget.onViewAll,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 190,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    scrollDirection: Axis.horizontal,
                    itemCount: data.vendors.length,
                    separatorBuilder: (_, si) => const SizedBox(width: 14),
                    itemBuilder: (_, i) => _VendorCard(
                      vendor: data.vendors[i],
                      section: _section,
                      isDark: widget.isDark,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final VendorCategoryModel category;
  final bool isDark;
  final VoidCallback? onTap;

  const _CategoryChip({
    required this.category,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String photo = category.photo ?? '';
    final String title = category.title ?? '';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 72,
        child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color:
                  isDark ? AppThemeData.grey800 : const Color(0xFFFFF4EF),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? AppThemeData.grey700
                    : const Color(0xFFECEEF3),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: photo.isEmpty
                ? Center(
                    child: Text(
                      _initials(title),
                      style: AppThemeData.boldTextStyle(
                        fontSize: 13,
                        color: _ServiceListScreenColors.orange,
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(6),
                    child: NetworkImageWidget(
                      imageUrl: photo,
                      fit: BoxFit.contain,
                      showShimmer: false,
                    ),
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: AppThemeData.mediumTextStyle(
              fontSize: 11,
              color: isDark
                  ? AppThemeData.grey100
                  : _ServiceListScreenColors.ink,
            ).copyWith(height: 1.2),
          ),
        ],
        ),
      ),
    );
  }
}

class _VendorCard extends StatelessWidget {
  final VendorModel vendor;
  final SectionModel? section;
  final bool isDark;

  const _VendorCard({
    required this.vendor,
    required this.isDark,
    this.section,
  });

  @override
  Widget build(BuildContext context) {
    final String photo = vendor.photo ?? '';
    final String title = vendor.title ?? '';
    final num reviewsCount = vendor.reviewsCount ?? 0;
    final num reviewsSum = vendor.reviewsSum ?? 0;
    final double rating =
        reviewsCount > 0 ? reviewsSum / reviewsCount : 0.0;
    final String? distText = _vendorDistanceText(vendor);

    return InkWell(
      onTap: () {
        if (section != null) Constant.sectionConstantModel = section;
        Get.to(
          const RestaurantDetailsScreen(),
          arguments: {'vendorModel': vendor},
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 178,
        decoration: BoxDecoration(
          color: isDark ? AppThemeData.grey800 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [_smallShadow(isDark)],
        ),
        clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 118,
            width: double.infinity,
            child: photo.isEmpty
                ? Container(
                    color: _ServiceListScreenColors.orange
                        .withValues(alpha: 0.08),
                    child: Center(
                      child: Text(
                        _initials(title),
                        style: AppThemeData.boldTextStyle(
                          fontSize: 22,
                          color: _ServiceListScreenColors.orange,
                        ),
                      ),
                    ),
                  )
                : NetworkImageWidget(
                    imageUrl: photo,
                    fit: BoxFit.cover,
                    showShimmer: false,
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppThemeData.boldTextStyle(
                fontSize: 13,
                color: isDark
                    ? AppThemeData.grey50
                    : _ServiceListScreenColors.ink,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: (rating <= 0 && distText == null)
                ? const SizedBox.shrink()
                : Row(
                    children: [
                      if (rating > 0) ...[
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFA726),
                          size: 14,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          rating.toStringAsFixed(1),
                          style: AppThemeData.mediumTextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppThemeData.grey200
                                : AppThemeData.grey600,
                          ),
                        ),
                        if (distText != null) const SizedBox(width: 8),
                      ],
                      if (distText != null) ...[
                        Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: isDark
                              ? AppThemeData.grey200
                              : AppThemeData.grey600,
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            distText,
                            overflow: TextOverflow.ellipsis,
                            style: AppThemeData.mediumTextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppThemeData.grey200
                                  : AppThemeData.grey600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 9. DERNIERS COLIS
// ─────────────────────────────────────────────────────────────────────────────

class _RecentParcelsSection extends StatefulWidget {
  final bool isDark;
  final VoidCallback onViewAll;

  const _RecentParcelsSection({
    required this.isDark,
    required this.onViewAll,
  });

  @override
  State<_RecentParcelsSection> createState() => _RecentParcelsSectionState();
}

class _RecentParcelsSectionState extends State<_RecentParcelsSection> {
  late final Future<List<ParcelOrderModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<ParcelOrderModel>> _load() async {
    final uid = FireStoreUtils.getCurrentUid();
    if (uid.isEmpty) return [];
    try {
      final snap = await FireStoreUtils.fireStore
          .collection(CollectionName.parcelOrders)
          .where('authorID', isEqualTo: uid)
          .limit(5)
          .get();
      final orders = snap.docs
          .map((d) {
            try {
              return ParcelOrderModel.fromJson(d.data());
            } catch (_) {
              return null;
            }
          })
          .whereType<ParcelOrderModel>()
          .toList();
      orders.sort((a, b) {
        final at = a.createdAt ?? Timestamp.fromMillisecondsSinceEpoch(0);
        final bt = b.createdAt ?? Timestamp.fromMillisecondsSinceEpoch(0);
        return bt.compareTo(at);
      });
      return orders.take(3).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ParcelOrderModel>>(
      future: _future,
      builder: (context, snap) {
        final orders = snap.data ?? [];
        if (orders.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TitleWithAction(
                title: 'Derniers colis'.tr,
                isDark: widget.isDark,
                onTap: widget.onViewAll,
              ),
              const SizedBox(height: 12),
              ...orders.map(
                (o) => _OrderRow(
                  icon: Icons.inventory_2_outlined,
                  title: (o.parcelType ?? '').trim().isNotEmpty
                      ? o.parcelType!
                      : 'Colis'.tr,
                  subtitle: _joinRoute(
                    o.sender?.address,
                    o.receiver?.address,
                    fallback: 'Livraison de colis'.tr,
                  ),
                  status: o.status ?? '',
                  createdAt: o.createdAt,
                  isDark: widget.isDark,
                  onTap: () => TrackingNavigation.openParcel(order: o),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 10. DERNIERS TRAJETS
// ─────────────────────────────────────────────────────────────────────────────

class _RecentRidesSection extends StatefulWidget {
  final bool isDark;
  final VoidCallback onViewAll;

  const _RecentRidesSection({
    required this.isDark,
    required this.onViewAll,
  });

  @override
  State<_RecentRidesSection> createState() => _RecentRidesSectionState();
}

class _RecentRidesSectionState extends State<_RecentRidesSection> {
  late final Future<List<CabOrderModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<CabOrderModel>> _load() async {
    final uid = FireStoreUtils.getCurrentUid();
    if (uid.isEmpty) return [];
    try {
      final snap = await FireStoreUtils.fireStore
          .collection(CollectionName.rides)
          .where('authorID', isEqualTo: uid)
          .limit(5)
          .get();
      final orders = snap.docs
          .map((d) {
            try {
              return CabOrderModel.fromJson(d.data());
            } catch (_) {
              return null;
            }
          })
          .whereType<CabOrderModel>()
          .toList();
      orders.sort((a, b) {
        final at = a.createdAt ?? Timestamp.fromMillisecondsSinceEpoch(0);
        final bt = b.createdAt ?? Timestamp.fromMillisecondsSinceEpoch(0);
        return bt.compareTo(at);
      });
      return orders.take(3).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CabOrderModel>>(
      future: _future,
      builder: (context, snap) {
        final orders = snap.data ?? [];
        if (orders.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TitleWithAction(
                title: 'Derniers trajets'.tr,
                isDark: widget.isDark,
                onTap: widget.onViewAll,
              ),
              const SizedBox(height: 12),
              ...orders.map(
                (o) => _OrderRow(
                  icon: Icons.directions_car_outlined,
                  title: 'Trajet'.tr,
                  subtitle: _joinRoute(
                    o.sourceLocationName,
                    o.destinationLocationName,
                    fallback: 'Course cab'.tr,
                  ),
                  status: o.status ?? '',
                  createdAt: o.createdAt,
                  isDark: widget.isDark,
                  onTap: () =>
                      TrackingNavigation.openCab(order: o, preferLiveTracking: false),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Shared order row widget
class _OrderRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String status;
  final Timestamp? createdAt;
  final bool isDark;
  final VoidCallback onTap;

  const _OrderRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.createdAt,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: isDark ? AppThemeData.grey800 : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? AppThemeData.grey700
                    : const Color(0xFFECEEF3),
              ),
              boxShadow: [_microShadow(isDark)],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _ServiceListScreenColors.orange
                        .withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: _ServiceListScreenColors.orange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppThemeData.boldTextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppThemeData.grey50
                              : _ServiceListScreenColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppThemeData.regularTextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppThemeData.grey300
                              : AppThemeData.grey600,
                        ),
                      ),
                      if (createdAt != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          _formatActivityDate(createdAt),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppThemeData.regularTextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppThemeData.grey400
                                : AppThemeData.grey500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(status: status, isDark: isDark),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark
                      ? AppThemeData.grey300
                      : _ServiceListScreenColors.ink,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final bool isDark;

  const _StatusBadge({required this.status, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bool done = _isCompletedStatus(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: done
            ? const Color(0xFFDCF7E5)
            : (isDark ? AppThemeData.grey700 : const Color(0xFFF1F2F4)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        _shortStatus(status),
        style: AppThemeData.mediumTextStyle(
          fontSize: 11,
          color: done
              ? const Color(0xFF159447)
              : (isDark ? AppThemeData.grey100 : AppThemeData.grey700),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 10. DERNIÈRES LOCATIONS (RENTAL)
// ─────────────────────────────────────────────────────────────────────────────

class _RecentRentalSection extends StatefulWidget {
  final List<SectionModel> sections;
  final bool isDark;
  final VoidCallback onViewAll;

  const _RecentRentalSection({
    required this.sections,
    required this.isDark,
    required this.onViewAll,
  });

  @override
  State<_RecentRentalSection> createState() => _RecentRentalSectionState();
}

class _RecentRentalSectionState extends State<_RecentRentalSection> {
  late final Future<List<RentalOrderModel>> _future;

  @override
  void initState() {
    super.initState();
    final hasRental =
        widget.sections.any((s) => s.serviceTypeFlag == 'rental-service' && s.isActive == true);
    _future = hasRental ? _load() : Future.value([]);
  }

  Future<List<RentalOrderModel>> _load() async {
    final uid = FireStoreUtils.getCurrentUid();
    if (uid.isEmpty) return [];
    try {
      final snap = await FireStoreUtils.fireStore
          .collection(CollectionName.rentalOrders)
          .where('authorID', isEqualTo: uid)
          .limit(5)
          .get();
      final orders = snap.docs
          .map((d) {
            try {
              return RentalOrderModel.fromJson(d.data());
            } catch (_) {
              return null;
            }
          })
          .whereType<RentalOrderModel>()
          .toList();
      orders.sort((a, b) {
        final at = a.createdAt ?? Timestamp.fromMillisecondsSinceEpoch(0);
        final bt = b.createdAt ?? Timestamp.fromMillisecondsSinceEpoch(0);
        return bt.compareTo(at);
      });
      return orders.take(3).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RentalOrderModel>>(
      future: _future,
      builder: (context, snap) {
        final orders = snap.data ?? [];
        if (orders.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TitleWithAction(
                title: 'Dernières locations'.tr,
                isDark: widget.isDark,
                onTap: widget.onViewAll,
              ),
              const SizedBox(height: 12),
              ...orders.map(
                (o) => _OrderRow(
                  icon: Icons.directions_car_rounded,
                  title: (o.vehicleTypeName ?? '').trim().isNotEmpty
                      ? o.vehicleTypeName!
                      : 'Location'.tr,
                  subtitle: _joinRoute(
                    o.sourceLocationName,
                    o.dropoffLocationName,
                    fallback: 'Réservation véhicule'.tr,
                  ),
                  status: o.status ?? '',
                  createdAt: o.createdAt,
                  isDark: widget.isDark,
                  onTap: () => TrackingNavigation.openRental(order: o),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 11. PROMOTIONS ACTIVES
// ─────────────────────────────────────────────────────────────────────────────

class _ActivePromosSection extends StatefulWidget {
  final List<SectionModel> sections;
  final bool isDark;

  const _ActivePromosSection({
    required this.sections,
    required this.isDark,
  });

  @override
  State<_ActivePromosSection> createState() => _ActivePromosSectionState();
}

class _ActivePromosSectionState extends State<_ActivePromosSection> {
  late final Future<List<CouponModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<CouponModel>> _load() async {
    final ids = [
      _findSection(widget.sections, 'delivery-service')?.id,
      _findSection(widget.sections, 'ecommerce-service')?.id,
    ].whereType<String>().where((id) => id.trim().isNotEmpty).toList();

    if (ids.isEmpty) return [];

    final List<CouponModel> all = [];
    await Future.wait(ids.map((sectionId) async {
      try {
        final snap = await FireStoreUtils.fireStore
            .collection(CollectionName.promos)
            .where('sectionId', isEqualTo: sectionId)
            .where('expiresAt', isGreaterThanOrEqualTo: Timestamp.now())
            .where('isEnabled', isEqualTo: true)
            .limit(5)
            .get();
        all.addAll(
          snap.docs.map((d) => CouponModel.fromJson(d.data())),
        );
      } catch (_) {}
    }));
    return all.take(8).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CouponModel>>(
      future: _future,
      builder: (context, snap) {
        final promos = snap.data ?? [];
        if (promos.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _SectionTitle(
                  title: 'Promotions actives'.tr,
                  isDark: widget.isDark,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 116,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  scrollDirection: Axis.horizontal,
                  itemCount: promos.length,
                  separatorBuilder: (_, si) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => _PromoCard(
                    promo: promos[i],
                    sections: widget.sections,
                    isDark: widget.isDark,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PromoCard extends StatelessWidget {
  final CouponModel promo;
  final List<SectionModel> sections;
  final bool isDark;

  const _PromoCard({
    required this.promo,
    required this.sections,
    required this.isDark,
  });

  Future<void> _open() async {
    final vid = (promo.vendorID ?? '').trim();
    if (vid.isNotEmpty) {
      final vendor = await FireStoreUtils.getVendorById(vid);
      if (vendor == null) return;
      final section = _findSectionById(sections, vendor.sectionId);
      if (section != null) Constant.sectionConstantModel = section;
      Get.to(
        const RestaurantDetailsScreen(),
        arguments: {'vendorModel': vendor},
      );
      return;
    }
    final sid = (promo.sectionId ?? '').trim();
    if (sid.isNotEmpty) {
      final section = _findSectionById(sections, sid);
      if (section != null) {
        Constant.sectionConstantModel = section;
        await ServiceSectionRouter.open(section);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String image = promo.image ?? '';
    final String code = promo.code ?? '';
    final String discount = promo.discount ?? '';
    final bool isPercent =
        (promo.discountType ?? '').toLowerCase().contains('percent');
    final String discountLabel = isPercent ? '$discount%' : discount;
    final String description = promo.description ?? '';
    final bool hasDestination =
        (promo.vendorID ?? '').trim().isNotEmpty ||
        (promo.sectionId ?? '').trim().isNotEmpty;

    final card = Container(
      width: 220,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.grey800 : const Color(0xFFFFF4EF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppThemeData.grey700 : const Color(0xFFFFD4C2),
        ),
        boxShadow: [_microShadow(isDark)],
      ),
      child: Row(
        children: [
          if (image.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: NetworkImageWidget(
                imageUrl: image,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                showShimmer: false,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (discountLabel.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _ServiceListScreenColors.orange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      discountLabel,
                      style: AppThemeData.boldTextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                if (discountLabel.isNotEmpty) const SizedBox(height: 5),
                if (code.isNotEmpty)
                  Text(
                    'Code : $code',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppThemeData.boldTextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppThemeData.grey50
                          : _ServiceListScreenColors.ink,
                    ),
                  ),
                if (description.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppThemeData.regularTextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppThemeData.grey300
                          : AppThemeData.grey600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (!hasDestination) return card;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: _open,
      child: card,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 12. SPONSORS ACTIFS
// ─────────────────────────────────────────────────────────────────────────────

class _SponsorEntry {
  final AdvertisementModel ad;
  final VendorModel? vendor;
  _SponsorEntry({required this.ad, this.vendor});
}

class _SponsorsSection extends StatefulWidget {
  final List<SectionModel> sections;
  final bool isDark;

  const _SponsorsSection({required this.sections, required this.isDark});

  @override
  State<_SponsorsSection> createState() => _SponsorsSectionState();
}

class _SponsorsSectionState extends State<_SponsorsSection> {
  late final Future<List<_SponsorEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_SponsorEntry>> _load() async {
    try {
      final ads = await FireStoreUtils.getAllAdvertisement();
      if (ads.isEmpty) return [];
      final entries = await Future.wait(ads.map((ad) async {
        final vid = (ad.vendorId ?? '').trim();
        if (vid.isEmpty) return _SponsorEntry(ad: ad);
        final vendor = await FireStoreUtils.getVendorById(vid);
        if (vendor == null) return null;
        final vendorSection =
            _findSectionById(widget.sections, vendor.sectionId);
        if (vendorSection == null || vendorSection.isActive != true) {
          return null;
        }
        return _SponsorEntry(ad: ad, vendor: vendor);
      }));
      return entries.whereType<_SponsorEntry>().toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_SponsorEntry>>(
      future: _future,
      builder: (context, snap) {
        final entries = snap.data ?? [];
        if (entries.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _SectionTitle(
                  title: 'Sponsorisés'.tr,
                  isDark: widget.isDark,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 152,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  scrollDirection: Axis.horizontal,
                  itemCount: entries.length,
                  separatorBuilder: (_, si) => const SizedBox(width: 14),
                  itemBuilder: (_, i) => _SponsorCard(
                    entry: entries[i],
                    sections: widget.sections,
                    isDark: widget.isDark,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SponsorCard extends StatelessWidget {
  final _SponsorEntry entry;
  final List<SectionModel> sections;
  final bool isDark;

  const _SponsorCard({
    required this.entry,
    required this.sections,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final String cover = entry.ad.coverImage ?? '';
    final String profile = entry.ad.profileImage ?? '';
    final String adTitle = entry.ad.title ?? '';
    final VendorModel? vendor = entry.vendor;

    final card = Container(
      width: 200,
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.grey800 : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [_smallShadow(isDark)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 94,
            width: double.infinity,
            child: cover.isEmpty
                ? Container(
                    color: _ServiceListScreenColors.orange
                        .withValues(alpha: 0.08),
                    child: Center(
                      child: Text(
                        _initials(vendor?.title ?? adTitle),
                        style: AppThemeData.boldTextStyle(
                          fontSize: 20,
                          color: _ServiceListScreenColors.orange,
                        ),
                      ),
                    ),
                  )
                : NetworkImageWidget(
                    imageUrl: cover,
                    fit: BoxFit.cover,
                    showShimmer: false,
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Row(
              children: [
                if (profile.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: NetworkImageWidget(
                      imageUrl: profile,
                      width: 30,
                      height: 30,
                      fit: BoxFit.cover,
                      showShimmer: false,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    vendor?.title ?? adTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppThemeData.boldTextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppThemeData.grey50
                          : _ServiceListScreenColors.ink,
                    ).copyWith(height: 1.2),
                  ),
                ),
                if (vendor != null)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: _ServiceListScreenColors.orange,
                    size: 16,
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    if (vendor == null) return card;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        final section = _findSectionById(sections, vendor.sectionId);
        if (section != null) Constant.sectionConstantModel = section;
        Get.to(
          const RestaurantDetailsScreen(),
          arguments: {'vendorModel': vendor},
        );
      },
      child: card,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM NAV
// ─────────────────────────────────────────────────────────────────────────────

class _HomeBottomBar extends StatelessWidget {
  final List<SectionModel> sections;
  final bool isDark;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _HomeBottomBar({
    required this.sections,
    required this.isDark,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).padding.bottom;
    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        margin: EdgeInsets.fromLTRB(24, 0, 24, bottomInset > 0 ? 0 : 10),
        height: 88,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? AppThemeData.grey900 : Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [_softShadow(isDark)],
        ),
        child: Row(
          children: [
            _BottomNavButton(
              isDark: isDark,
              selected: currentIndex == 0,
              assetIcon: 'assets/icons/ic_home_cab.svg',
              label: 'Home'.tr,
              onTap: () => onTap(0),
            ),
            _BottomNavButton(
              isDark: isDark,
              selected: currentIndex == 1,
              assetIcon: 'assets/icons/ic_fav.svg',
              label: 'Favourites'.tr,
              onTap: () => onTap(1),
            ),
            _BottomNavButton(
              isDark: isDark,
              selected: currentIndex == 2,
              assetIcon: 'assets/icons/ic_orders.svg',
              label: 'Orders'.tr,
              featured: true,
              onTap: () => onTap(2),
            ),
            _BottomNavButton(
              isDark: isDark,
              selected: currentIndex == 3,
              assetIcon: 'assets/icons/ic_help_support.svg',
              label: 'Messages'.tr,
              onTap: () => onTap(3),
            ),
            _BottomNavButton(
              isDark: isDark,
              selected: currentIndex == 4,
              assetIcon: 'assets/icons/ic_profile.svg',
              label: 'Profile'.tr,
              onTap: () => onTap(4),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavButton extends StatelessWidget {
  final bool isDark;
  final bool selected;
  final bool featured;
  final String assetIcon;
  final String label;
  final VoidCallback onTap;

  const _BottomNavButton({
    required this.isDark,
    required this.selected,
    required this.assetIcon,
    required this.label,
    required this.onTap,
    this.featured = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? _ServiceListScreenColors.orange
        : isDark
            ? AppThemeData.grey300
            : AppThemeData.grey600;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: SizedBox(
          height: 78,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: featured ? 60 : 36,
                height: featured ? 60 : 36,
                decoration: BoxDecoration(
                  color: featured
                      ? _ServiceListScreenColors.orange
                      : selected
                          ? _ServiceListScreenColors.orange
                              .withValues(alpha: 0.10)
                          : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SvgPicture.asset(
                    assetIcon,
                    height: featured ? 26 : 22,
                    width: featured ? 26 : 22,
                    colorFilter: ColorFilter.mode(
                      featured ? Colors.white : color,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              if (!featured) ...[
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppThemeData.mediumTextStyle(
                    fontSize: 11,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyServicesState extends StatelessWidget {
  final bool isDark;
  const _EmptyServicesState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
      child: Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark ? AppThemeData.grey800 : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [_microShadow(isDark)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: _ServiceListScreenColors.orange
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.apps_rounded,
                  color: _ServiceListScreenColors.orange,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Aucun service actif'.tr,
                style: AppThemeData.semiBoldTextStyle(
                  fontSize: 17,
                  color: isDark
                      ? AppThemeData.grey50
                      : _ServiceListScreenColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Les services activés apparaîtront automatiquement ici.'.tr,
                textAlign: TextAlign.center,
                style: AppThemeData.regularTextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppThemeData.grey200
                      : AppThemeData.grey700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UI PRIMITIVES
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionTitle({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppThemeData.boldTextStyle(
        fontSize: 20,
        color: isDark ? AppThemeData.grey50 : _ServiceListScreenColors.ink,
      ).copyWith(height: 1.15),
    );
  }
}

class _TitleWithAction extends StatelessWidget {
  final String title;
  final bool isDark;
  final VoidCallback onTap;

  const _TitleWithAction({
    required this.title,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _SectionTitle(title: title, isDark: isDark)),
        const SizedBox(width: 10),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
            child: Row(
              children: [
                Text(
                  'Voir tout'.tr,
                  style: AppThemeData.boldTextStyle(
                    fontSize: 13,
                    color: _ServiceListScreenColors.orange,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: _ServiceListScreenColors.orange,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COLORS
// ─────────────────────────────────────────────────────────────────────────────

class _ServiceListScreenColors {
  static const Color bg = Color(0xFFF8F9FB);
  static const Color ink = Color(0xFF111827);
  static const Color orange = Color(0xFFFF4B12);
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

String _serviceTitle(SectionModel section) {
  final adminName = (section.name ?? '').trim();
  if (adminName.isNotEmpty) return adminName;
  return Constant.translateServiceName(section.serviceTypeFlag ?? '');
}

String _shortLocation(String address) {
  return Utils.shortAddressFromText(
    address,
    fallback: 'Choisir une adresse'.tr,
  );
}

String _serviceBannerImage(dynamic banner) {
  if (banner is String) return banner;
  if (banner is Map) {
    final value = banner['photo'] ??
        banner['image'] ??
        banner['url'] ??
        banner['banner'] ??
        banner['bannerImage'];
    return value?.toString() ?? '';
  }
  return '';
}

List<SectionModel> _activeNavigableSections(List<SectionModel> sections) {
  return sections
      .where((s) => s.isActive == true && _isNavigableSection(s))
      .toList();
}

bool _isNavigableSection(SectionModel section) {
  const flags = {
    'ecommerce-service',
    'delivery-service',
    'cab-service',
    'rental-service',
    'parcel_delivery',
    'ondemand-service',
  };
  return flags.contains(section.serviceTypeFlag);
}

String _initials(String value) {
  final words = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.trim().isNotEmpty)
      .toList();
  if (words.isEmpty) return 'JX';
  if (words.length == 1) {
    return String.fromCharCodes(words.first.runes.take(2)).toUpperCase();
  }
  return words
      .take(2)
      .map((w) => String.fromCharCode(w.runes.first))
      .join()
      .toUpperCase();
}

SectionModel? _firstReferralSection(List<SectionModel> sections) {
  for (final s in sections) {
    if ((s.referralAmount ?? '').trim().isNotEmpty) return s;
  }
  return null;
}

void _ensureSectionContext(List<SectionModel> sections) {
  if (Constant.sectionConstantModel == null && sections.isNotEmpty) {
    Constant.sectionConstantModel = sections.first;
  }
}

SectionModel? _findSection(List<SectionModel> sections, String flag) {
  for (final s in sections) {
    if (s.serviceTypeFlag == flag) return s;
  }
  return null;
}

SectionModel? _findSectionById(List<SectionModel> sections, String? id) {
  if (id == null || id.trim().isEmpty) return null;
  for (final s in sections) {
    if (s.id == id) return s;
  }
  return null;
}

String _joinRoute(String? from, String? to, {required String fallback}) {
  final String f = (from ?? '').trim();
  final String t = (to ?? '').trim();
  if (f.isNotEmpty && t.isNotEmpty) return '$f → $t';
  if (f.isNotEmpty) return f;
  if (t.isNotEmpty) return t;
  return fallback;
}

String _formatActivityDate(Timestamp? timestamp) {
  if (timestamp == null) return '';
  final DateTime date = timestamp.toDate();
  final DateTime now = DateTime.now();
  final bool isToday =
      date.year == now.year && date.month == now.month && date.day == now.day;
  final DateTime yesterday = now.subtract(const Duration(days: 1));
  final bool isYesterday =
      date.year == yesterday.year &&
      date.month == yesterday.month &&
      date.day == yesterday.day;
  final String hh = date.hour.toString().padLeft(2, '0');
  final String mm = date.minute.toString().padLeft(2, '0');
  if (isToday) return '${'Aujourd\'hui'.tr}, $hh:$mm';
  if (isYesterday) return '${'Hier'.tr}, $hh:$mm';
  final String dd = date.day.toString().padLeft(2, '0');
  final String mo = date.month.toString().padLeft(2, '0');
  return '$dd/$mo/${date.year}, $hh:$mm';
}

bool _isCompletedStatus(String status) {
  final n = status.toLowerCase();
  return n.contains('completed') ||
      n.contains('delivered') ||
      n.contains('livr') ||
      n.contains('termin');
}

String _shortStatus(String status) {
  if (status.trim().isEmpty) return 'En cours'.tr;
  if (_isCompletedStatus(status)) return 'Terminé'.tr;
  final n = status.toLowerCase();
  if (n.contains('cancel')) return 'Annulé'.tr;
  if (n.contains('reject')) return 'Refusé'.tr;
  return 'En cours'.tr;
}

BoxShadow _smallShadow(bool isDark) => BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.075),
      blurRadius: 22,
      offset: const Offset(0, 11),
    );

BoxShadow _softShadow(bool isDark) => BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.26 : 0.10),
      blurRadius: 30,
      offset: const Offset(0, 16),
    );

BoxShadow _microShadow(bool isDark) => BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.045),
      blurRadius: 15,
      offset: const Offset(0, 7),
    );

String? _vendorDistanceText(VendorModel vendor) {
  final loc = Constant.currentLocation;
  if (loc == null) return null;
  final lat = vendor.latitude;
  final lng = vendor.longitude;
  if (lat == null || lng == null) return null;
  return '${Constant.getDistance(
    lat1: loc.latitude.toString(),
    lng1: loc.longitude.toString(),
    lat2: lat.toString(),
    lng2: lng.toString(),
  )} ${Constant.distanceType}';
}
