import 'package:customer/constant/constant.dart';
import 'package:customer/controllers/cab_home_controller.dart';
import 'package:customer/controllers/food_home_controller.dart';
import 'package:customer/controllers/home_e_commerce_controller.dart';
import 'package:customer/controllers/home_parcel_controller.dart';
import 'package:customer/controllers/rental_home_controller.dart';
import 'package:customer/models/section_model.dart';
import 'package:customer/models/tax_model.dart';
import 'package:customer/screen_ui/cab_service_screens/cab_dashboard_screen.dart';
import 'package:customer/screen_ui/ecommarce/dash_board_e_commerce_screen.dart';
import 'package:customer/screen_ui/multi_vendor_service/dash_board_screens/dash_board_screen.dart';
import 'package:customer/screen_ui/on_demand_service/on_demand_dashboard_screen.dart';
import 'package:customer/screen_ui/parcel_service/parcel_dashboard_screen.dart';
import 'package:customer/screen_ui/rental_service/rental_dashboard_screen.dart';
import 'package:customer/service/fire_store_utils.dart';
import 'package:customer/themes/app_them_data.dart';
import 'package:customer/utils/preferences.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ServiceSectionRouter {
  const ServiceSectionRouter._();

  static Future<void> open(SectionModel section, {bool replace = false}) async {
    final fromSectionId = Constant.sectionConstantModel?.id ?? '';
    // ignore: avoid_print
    print(
      "[OPEN_SECTION_CLICK] fromSection=$fromSectionId toSection=${section.id} type=${section.serviceType} name=${section.name}",
    );
    await prepare(section);

    final target = _targetFor(section);
    final route = _targetNameFor(section);
    // ignore: avoid_print
    print("[OPEN_SECTION_NAV] route=$route argsSection=${section.id}");
    final arguments = {
      'sectionModel': section,
      'sectionId': section.id,
      'sectionName': section.name,
      'serviceType': section.serviceType,
    };
    if (replace) {
      Get.offAll(target, arguments: arguments);
    } else {
      Get.to(target, arguments: arguments);
    }
  }

  static Future<void> prepare(SectionModel section) async {
    final oldSectionId = Constant.sectionConstantModel?.id ?? '';
    Constant.sectionConstantModel = section;
    AppThemeData.primary300 = Color(
      int.tryParse(section.color?.replaceFirst('#', '0xff') ?? '') ??
          0xFFFF6839,
    );

    if (section.serviceType == 'Ecommerce Service') {
      await Preferences.setString(Preferences.foodDeliveryType, 'Delivery');
    }

    await FireStoreUtils.getTaxList(section.id).then((value) {
      if (value == null) {
        return;
      }
      Constant.taxProductList =
          value
              .where((TaxModel taxModel) => taxModel.scope == 'product')
              .toList();
      Constant.orderProductTaxList =
          value
              .where((TaxModel taxModel) => taxModel.scope == 'order')
              .toList();
      Constant.driverDeliveryTaxList =
          value
              .where((TaxModel taxModel) => taxModel.scope == 'delivery')
              .toList();

      if (section.packagingChargeEnable == true) {
        Constant.packagingTaxList =
            value
                .where((TaxModel taxModel) => taxModel.scope == 'packaging')
                .toList();
      }
      if (section.platformFee?.enable == true) {
        Constant.platformFeeModel = section.platformFee;
        Constant.platformTaxList =
            value
                .where((TaxModel taxModel) => taxModel.scope == 'platform')
                .toList();
      }
    });
    _reloadRegisteredControllers(oldSectionId, section);
  }

  static Widget Function() _targetFor(SectionModel section) {
    switch (section.serviceTypeFlag) {
      case 'ecommerce-service':
        return () => const DashBoardEcommerceScreen();
      case 'cab-service':
        return () => const CabDashboardScreen();
      case 'rental-service':
        return () => const RentalDashboardScreen();
      case 'parcel_delivery':
        return () => const ParcelDashboardScreen();
      case 'ondemand-service':
        return () => const OnDemandDashboardScreen();
      default:
        return () => const DashBoardScreen();
    }
  }

  static String _targetNameFor(SectionModel section) {
    switch (section.serviceTypeFlag) {
      case 'ecommerce-service':
        return 'DashBoardEcommerceScreen';
      case 'cab-service':
        return 'CabDashboardScreen';
      case 'rental-service':
        return 'RentalDashboardScreen';
      case 'parcel_delivery':
        return 'ParcelDashboardScreen';
      case 'ondemand-service':
        return 'OnDemandDashboardScreen';
      default:
        return 'DashBoardScreen';
    }
  }

  static void _reloadRegisteredControllers(
    String oldSectionId,
    SectionModel section,
  ) {
    final newSectionId = section.id ?? '';
    if (oldSectionId == newSectionId) {
      return;
    }
    // ignore: avoid_print
    print("[SECTION_RELOAD] old=$oldSectionId new=$newSectionId");
    if (Get.isRegistered<FoodHomeController>()) {
      Get.find<FoodHomeController>().getData();
    }
    if (Get.isRegistered<HomeECommerceController>()) {
      Get.find<HomeECommerceController>().getData();
    }
    if (Get.isRegistered<HomeParcelController>()) {
      Get.find<HomeParcelController>().loadData();
    }
    if (Get.isRegistered<CabHomeController>()) {
      Get.find<CabHomeController>().getData();
    }
    if (Get.isRegistered<RentalHomeController>()) {
      Get.find<RentalHomeController>().reloadForSection();
    }
  }
}
