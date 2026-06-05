import 'dart:async';
import 'package:driver/constant/collection_name.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/send_notification.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/models/order_model.dart';
import 'package:driver/models/user_model.dart';
import 'package:driver/services/audio_player_service.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:get/get.dart';

class HomeScreenMultipleOrderController extends GetxController {
  StreamSubscription? _driverSubscription;
  Rx<UserModel> driverModel = Constant.userModel!.obs;
  RxBool isLoading = true.obs;
  RxInt selectedTabIndex = 0.obs;

  RxList<dynamic> newOrder = [].obs;
  RxList<dynamic> activeOrder = [].obs;

  @override
  void onInit() {
    // TODO: implement onInt
    getDriver();
    super.onInit();
  }

  Future<void> getDriver() async {
    _driverSubscription = FireStoreUtils.fireStore
        .collection(CollectionName.users)
        .doc(FireStoreUtils.getCurrentUid())
        .snapshots()
        .listen(
      (event) async {
        if (event.exists) {
          driverModel.value = UserModel.fromJson(event.data()!);
          Constant.userModel = driverModel.value;
          newOrder.clear();
          activeOrder.clear();
          if (driverModel.value.orderRequestData != null) {
            for (var element in driverModel.value.orderRequestData!) {
              final orderId = _orderIdFromRef(element);
              if (orderId.isNotEmpty) {
                print(
                    "[DRIVER_NEW_ORDER] serviceType=delivery-service sectionId=unknown orderId=$orderId status=requested");
                newOrder.add(orderId);
              }
            }
          }

          if (driverModel.value.inProgressOrderID != null) {
            for (var element in driverModel.value.inProgressOrderID!) {
              final orderId = _orderIdFromRef(element);
              if (orderId.isNotEmpty) {
                activeOrder.add(orderId);
              }
            }
          }

          if (newOrder.isEmpty == true) {
            await AudioPlayerService.playSound(false);
          }

          if (newOrder.isNotEmpty) {
            if (driverModel.value.vendorID?.isEmpty == true) {
              await AudioPlayerService.playSound(true);
            }
          }
        }
      },
      onError: (e) {},
    );
    isLoading.value = false;
    update();
  }

  @override
  void onClose() {
    _driverSubscription?.cancel();
    super.onClose();
  }

  String _orderIdFromRef(dynamic value) {
    if (value == null) {
      return '';
    }
    if (value is String) {
      return value.trim();
    }
    if (value is Map) {
      for (final key in ['id', 'orderId', 'orderID', 'order_id']) {
        final orderId = value[key]?.toString().trim() ?? '';
        if (orderId.isNotEmpty) {
          return orderId;
        }
      }
    }
    return value.toString().trim();
  }

  Future<void> acceptOrder(OrderModel currentOrder) async {
    await AudioPlayerService.playSound(false);
    ShowToastDialog.showLoader("Please wait".tr);
    final orderId = currentOrder.id?.trim() ?? '';
    if (orderId.isEmpty) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Order not found".tr);
      return;
    }
    driverModel.value.orderRequestData ??= [];
    driverModel.value.inProgressOrderID ??= [];
    driverModel.value.orderRequestData!
        .removeWhere((element) => _orderIdFromRef(element) == orderId);
    if (!driverModel.value.inProgressOrderID!
        .any((element) => _orderIdFromRef(element) == orderId)) {
      driverModel.value.inProgressOrderID!.add(orderId);
    }

    await FireStoreUtils.updateUser(driverModel.value);

    currentOrder.status = Constant.driverAccepted;
    currentOrder.driverID = driverModel.value.id;
    currentOrder.driver = driverModel.value;

    await FireStoreUtils.setOrder(currentOrder);
    ShowToastDialog.closeLoader();
    await SendNotification.sendFcmMessage(Constant.driverAcceptedNotification,
        currentOrder.author?.fcmToken.toString() ?? "", {});
    await SendNotification.sendFcmMessage(Constant.driverAcceptedNotification,
        currentOrder.vendor?.fcmToken.toString() ?? "", {});
  }

  Future<void> rejectOrder(OrderModel currentOrder) async {
    ShowToastDialog.showLoader("Please wait".tr);
    await AudioPlayerService.playSound(false);
    final orderId = currentOrder.id?.trim() ?? '';
    if (orderId.isEmpty) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Order not found".tr);
      return;
    }
    currentOrder.rejectedByDrivers ??= [];
    currentOrder.rejectedByDrivers!.add(driverModel.value.id);
    currentOrder.status = Constant.driverRejected;
    await FireStoreUtils.setOrder(currentOrder);
    driverModel.value.orderRequestData ??= [];
    driverModel.value.orderRequestData!
        .removeWhere((element) => _orderIdFromRef(element) == orderId);
    await FireStoreUtils.updateUser(driverModel.value);
    ShowToastDialog.closeLoader();
  }
}
