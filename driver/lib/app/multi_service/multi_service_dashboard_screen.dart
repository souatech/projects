import 'package:driver/app/cab_screen/cab_dashboard_screen.dart';
import 'package:driver/app/rental_service/rental_dashboard_screen.dart';
import 'package:driver/app/unified_delivery/unified_delivery_home_screen.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/controllers/cab_dashboard_controller.dart';
import 'package:driver/controllers/rental_dashboard_controller.dart';
import 'package:driver/themes/app_them_data.dart';
import 'package:driver/themes/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Controller that tracks which service tab is active.
class MultiServiceDashboardController extends GetxController {
  RxInt currentIndex = 0.obs;
}

enum _DriverWorkGroup { deliveries, courses, locations }

/// Unified dashboard for drivers registered to multiple services.
/// Shows business groups instead of one technical tab per service type.
class MultiServiceDashboardScreen extends StatelessWidget {
  const MultiServiceDashboardScreen({super.key});

  List<String> _serviceTypes() {
    final user = Constant.userModel;
    if (user == null) return ['delivery-service'];
    final role = user.driverRole?.trim();
    if (role == 'delivery') return ['delivery-service'];
    if (role == 'cab') return ['cab-service'];
    if (role == 'cab_rental') return ['cab-service', 'rental-service'];
    if (user.serviceTypes != null && user.serviceTypes!.isNotEmpty) {
      return user.serviceTypes!;
    }
    return ['delivery-service'];
  }

  List<_DriverWorkGroup> _workGroups(List<String> serviceTypes) {
    final groups = <_DriverWorkGroup>[];
    final hasDeliveries = serviceTypes.any(_isDeliveryLike);
    if (hasDeliveries) {
      groups.add(_DriverWorkGroup.deliveries);
    }
    if (serviceTypes.contains('cab-service')) {
      groups.add(_DriverWorkGroup.courses);
    }
    if (serviceTypes.contains('rental-service')) {
      groups.add(_DriverWorkGroup.locations);
    }
    return groups.isEmpty ? [_DriverWorkGroup.deliveries] : groups;
  }

  bool _isDeliveryLike(String serviceType) {
    return serviceType != 'cab-service' && serviceType != 'rental-service';
  }

  Widget _dashboardForGroup(_DriverWorkGroup group, List<String> serviceTypes) {
    switch (group) {
      case _DriverWorkGroup.courses:
        return const CabDashboardScreen();
      case _DriverWorkGroup.locations:
        return const RentalDashboardScreen();
      case _DriverWorkGroup.deliveries:
        return const UnifiedDeliveryHomeScreen();
    }
  }

  BottomNavigationBarItem _navItemForGroup(_DriverWorkGroup group) {
    switch (group) {
      case _DriverWorkGroup.courses:
        return const BottomNavigationBarItem(
          icon: Icon(Icons.local_taxi_outlined),
          activeIcon: Icon(Icons.local_taxi),
          label: 'Courses',
        );
      case _DriverWorkGroup.locations:
        return const BottomNavigationBarItem(
          icon: Icon(Icons.car_rental_outlined),
          activeIcon: Icon(Icons.car_rental),
          label: 'Locations',
        );
      case _DriverWorkGroup.deliveries:
        return const BottomNavigationBarItem(
          icon: Icon(Icons.delivery_dining_outlined),
          activeIcon: Icon(Icons.delivery_dining),
          label: 'Livraisons',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final serviceTypes = _serviceTypes();
    final workGroups = _workGroups(serviceTypes);
    debugPrint("[DRIVER_DASHBOARD] using unified dashboard");
    debugPrint("[DRIVER_TABS] ${workGroups.map(_groupLogName).join('/')}");

    final themeController = Get.find<ThemeController>();

    return GetBuilder<MultiServiceDashboardController>(
      init: MultiServiceDashboardController(),
      builder: (controller) {
        return Obx(() {
          final isDark = themeController.isDark.value;
          final selectedIndex =
              controller.currentIndex.value.clamp(0, workGroups.length - 1);
          return Scaffold(
            body: IndexedStack(
              index: selectedIndex,
              children: workGroups
                  .map((group) => _dashboardForGroup(group, serviceTypes))
                  .toList(),
            ),
            bottomNavigationBar: workGroups.length > 1
                ? BottomNavigationBar(
                    currentIndex: selectedIndex,
                    onTap: (index) {
                      controller.currentIndex.value = index;
                      _resetDashboardDrawers();
                    },
                    type: BottomNavigationBarType.fixed,
                    selectedItemColor: AppThemeData.primary300,
                    unselectedItemColor:
                        isDark ? AppThemeData.grey400 : AppThemeData.grey500,
                    backgroundColor:
                        isDark ? AppThemeData.grey900 : AppThemeData.grey50,
                    items: workGroups.map(_navItemForGroup).toList(),
                  )
                : _SingleWorkGroupBar(
                    item: _navItemForGroup(workGroups.first),
                    isDark: isDark,
                  ),
          );
        });
      },
    );
  }

  String _groupLogName(_DriverWorkGroup group) {
    switch (group) {
      case _DriverWorkGroup.deliveries:
        return 'delivery';
      case _DriverWorkGroup.courses:
        return 'cab';
      case _DriverWorkGroup.locations:
        return 'rental';
    }
  }

  void _resetDashboardDrawers() {
    if (Get.isRegistered<CabDashBoardController>()) {
      Get.find<CabDashBoardController>().drawerIndex.value = 0;
    }
    if (Get.isRegistered<RentalDashboardController>()) {
      Get.find<RentalDashboardController>().drawerIndex.value = 0;
    }
  }
}

class _SingleWorkGroupBar extends StatelessWidget {
  const _SingleWorkGroupBar({
    required this.item,
    required this.isDark,
  });

  final BottomNavigationBarItem item;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: isDark ? AppThemeData.grey900 : AppThemeData.grey50,
          border: Border(
            top: BorderSide(
              color: isDark ? AppThemeData.grey800 : AppThemeData.grey200,
            ),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconTheme(
                data: IconThemeData(color: AppThemeData.primary300),
                child: item.activeIcon,
              ),
              const SizedBox(height: 4),
              Text(
                item.label ?? '',
                style: TextStyle(
                  color: AppThemeData.primary300,
                  fontSize: 12,
                  fontFamily: AppThemeData.medium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
