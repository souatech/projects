import 'package:customer/screen_ui/cab_service_screens/cab_home_screen.dart';
import 'package:customer/screen_ui/multi_vendor_service/profile_screen/profile_screen.dart';
import 'package:get/get.dart';
import '../screen_ui/cab_service_screens/my_cab_booking_screen.dart';

class CabDashboardController extends GetxController {
  RxInt selectedIndex = 0.obs;

  RxList pageList = [].obs;

  @override
  void onInit() {
    pageList.value = [
      CabHomeScreen(),
      const MyCabBookingScreen(),
      const ProfileScreen(),
    ];
    super.onInit();
  }
}
