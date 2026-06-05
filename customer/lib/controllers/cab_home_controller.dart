import 'package:customer/models/banner_model.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/service/fire_store_utils.dart';
import 'package:get/get.dart';

class CabHomeController extends GetxController {
  RxBool isLoading = true.obs;
  RxList<BannerModel> bannerTopHome = <BannerModel>[].obs;

  @override
  void onInit() {
    // TODO: implement onInit
    getData();
    super.onInit();
  }

  Future<void> getData() async {
    final section = Constant.sectionConstantModel;
    // ignore: avoid_print
    print(
      "[SECTION_RECEIVED] screen=Cab sectionId=${section?.id} sectionName=${section?.name} type=${section?.serviceType}",
    );
    // ignore: avoid_print
    print("[SECTION_LOAD] screen=Cab sectionId=${section?.id}");
    isLoading.value = true;
    bannerTopHome.clear();
    await FireStoreUtils.getHomeTopBanner().then((value) {
      bannerTopHome.value = value;
    });
    isLoading.value = false;
  }
}
