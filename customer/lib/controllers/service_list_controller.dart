import 'package:customer/models/section_model.dart';
import 'package:customer/service/cart_provider.dart';
import 'package:customer/service/database_helper.dart';
import 'package:customer/service/fire_store_utils.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/models/user_model.dart';
import 'package:customer/models/currency_model.dart';
import 'package:customer/themes/app_them_data.dart';
import 'package:customer/themes/round_button_fill.dart';
import 'package:customer/themes/show_toast_dialog.dart';
import 'package:customer/utils/notification_service.dart';
import 'package:customer/utils/service_section_router.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../screen_ui/auth_screens/login_screen.dart';

class ServiceListController extends GetxController {
  var isLoading = false.obs;
  var serviceListBanner = <dynamic>[].obs;
  var sectionList = <SectionModel>[].obs;
  var currencyData = CurrencyModel().obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    isLoading.value = true;

    // fetch currency
    CurrencyModel? currency = await FireStoreUtils.getCurrency();

    currencyData.value =
        currency ??
        CurrencyModel(
          id: "",
          code: "USD",
          decimal: 2,
          isactive: true,
          name: "US Dollar",
          symbol: "\$",
          symbolatright: false,
        );

    // Load sections
    List<SectionModel> sections = await FireStoreUtils.getSections();

    sectionList.assignAll(sections);
    Constant.sectionList = sections;

    await FireStoreUtils.getSectionBannerList().then((value) {
      serviceListBanner.assignAll(value);
    });

    await getZone();
    isLoading.value = false;
  }

  Future<void> getZone() async {
    await FireStoreUtils.getZone().then((value) {
      if (value != null) {
        Constant.zoneList = value;
      }
    });
  }

  Future<void> onServiceTap(
    BuildContext context,
    SectionModel sectionModel,
  ) async {
    try {
      ShowToastDialog.showLoader("Please wait...".tr);
      if (auth.FirebaseAuth.instance.currentUser != null) {
        String uid = auth.FirebaseAuth.instance.currentUser!.uid;
        UserModel? user = await FireStoreUtils.getUserProfile(uid);
        if (user != null && user.role == Constant.userRoleCustomer) {
          user.fcmToken = await NotificationService.getToken();
          await FireStoreUtils.updateUser(user);
          ShowToastDialog.closeLoader();
          await _navigate(sectionModel);
        } else {
          ShowToastDialog.closeLoader();
          Get.offAll(() => const LoginScreen());
        }
      } else {
        ShowToastDialog.closeLoader();
        await _navigate(sectionModel);
      }
    } catch (e) {
      // ignore: avoid_print
      print("Error during service tap: $e");
      ShowToastDialog.closeLoader();
    }
  }

  Future<void> _navigate(SectionModel sectionModel) async {
    if (sectionModel.serviceTypeFlag == "ecommerce-service" ||
        sectionModel.serviceTypeFlag == "delivery-service") {
      if (cartItem.isNotEmpty) {
        showAlertDialog(Get.context!, UserModel(), sectionModel);
      } else {
        await ServiceSectionRouter.open(sectionModel);
      }
    } else {
      await ServiceSectionRouter.open(sectionModel);
    }
  }

  final CartProvider cartProvider = CartProvider();

  void showAlertDialog(
    BuildContext context,
    UserModel user,
    SectionModel sectionModel,
  ) {
    Get.defaultDialog(
      title: "Alert!".tr,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "If you select this Section/Service, your previously added items will be removed from the cart."
                .tr,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: RoundedButtonFill(
                  height: 5.5,
                  title: "Cancel".tr,
                  onPress: () {
                    Get.back();
                  },
                  color: AppThemeData.grey900,
                  textColor: AppThemeData.surface,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RoundedButtonFill(
                  title: "OK".tr,
                  height: 5.5,
                  onPress: () async {
                    DatabaseHelper.instance.deleteAllCartProducts();
                    cartProvider.clearDatabase();
                    Get.back();
                    await ServiceSectionRouter.open(
                      sectionModel,
                      replace: true,
                    );
                  },
                  color: AppThemeData.primary300,
                  textColor: AppThemeData.surface,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [], // 👈 keep this empty since we put buttons in content
    );
  }
}
