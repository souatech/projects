import 'dart:async';

import 'package:customer/constant/collection_name.dart';
import 'package:get/get.dart';
import '../constant/constant.dart';
import '../models/banner_model.dart';
import '../models/parcel_category.dart';
import '../models/parcel_order_model.dart';
import '../service/fire_store_utils.dart';

class HomeParcelController extends GetxController {
  RxBool isLoading = true.obs;

  RxList<BannerModel> bannerTopHome = <BannerModel>[].obs;
  RxList<ParcelCategory> parcelCategory = <ParcelCategory>[].obs;
  RxList<ParcelOrderModel> recentParcelOrders = <ParcelOrderModel>[].obs;
  StreamSubscription? _recentParcelSub;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  void loadData() async {
    try {
      final section = Constant.sectionConstantModel;
      // ignore: avoid_print
      print(
        "[SECTION_RECEIVED] screen=Parcel sectionId=${section?.id} sectionName=${section?.name} type=${section?.serviceType}",
      );
      // ignore: avoid_print
      print("[SECTION_LOAD] screen=Parcel sectionId=${section?.id}");
      isLoading.value = true;
      bannerTopHome.clear();
      parcelCategory.clear();

      // Load banners
      await FireStoreUtils.getHomeTopBanner().then((value) {
        bannerTopHome.value = value;
      });

      // Load parcel categories
      await FireStoreUtils.getParcelServiceCategory().then((value) {
        parcelCategory.value = value;
      });

      listenRecentParcelOrders();
    } catch (e) {
      bannerTopHome.clear();
      parcelCategory.clear();
      recentParcelOrders.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void listenRecentParcelOrders() {
    if (Constant.userModel == null) {
      recentParcelOrders.clear();
      return;
    }
    _recentParcelSub?.cancel();
    _recentParcelSub = FireStoreUtils.fireStore
        .collection(CollectionName.parcelOrders)
        .where('authorID', isEqualTo: FireStoreUtils.getCurrentUid())
        .orderBy('createdAt', descending: true)
        .limit(5)
        .snapshots()
        .listen((snapshot) {
          recentParcelOrders.value =
              snapshot.docs
                  .map((doc) => ParcelOrderModel.fromJson(doc.data()))
                  .toList();
        });
  }

  @override
  void onClose() {
    _recentParcelSub?.cancel();
    super.onClose();
  }
}
