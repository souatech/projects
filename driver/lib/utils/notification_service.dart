import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:driver/app/chat_screens/chat_screen.dart';
import 'package:driver/app/dash_board_screen/dash_board_screen.dart';
import 'package:driver/app/rental_service/rental_dashboard_screen.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/controllers/dash_board_controller.dart';
import 'package:driver/models/user_model.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

Future<void> firebaseMessageBackgroundHandle(RemoteMessage message) async {
  log("[BACKGROUND_HANDLER] messageId=${message.messageId} data=${message.data}");
}

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initInfo() async {
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    var request = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    log("[NOTIFICATION_RECEIVED] Permission status: ${request.authorizationStatus}");

    if (request.authorizationStatus == AuthorizationStatus.authorized || request.authorizationStatus == AuthorizationStatus.provisional) {
      const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosInitializationSettings = DarwinInitializationSettings();

      final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: iosInitializationSettings,
      );

      await flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (response.payload != null) {
            final data = jsonDecode(response.payload!);
            final String type = data['type'] ?? '';
            final String role = data['chatType'] ?? '';
            final String orderId = data['orderId'] ?? '';
            final String senderId = data['senderId'] ?? '';
            handleMessageClick(type: type, role: role, orderId: orderId, senderId: senderId);
          }
        },
      );

      setupInteractedMessage();

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        log("[FCM_TOKEN_FOUND] onTokenRefresh len=${newToken.length}");
        final uid = FireStoreUtils.getCurrentUid();
        if (uid.isNotEmpty) {
          await FireStoreUtils.fireStore.collection('users').doc(uid).update({'fcmToken': newToken});
        }
      });
    }
  }

  Future<void> setupInteractedMessage() async {
    // App opened from terminated state
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      final String type = initialMessage.data['type'] ?? '';
      final String role = initialMessage.data['chatType'] ?? '';
      final String orderId = initialMessage.data['orderId'] ?? '';
      final String senderId = initialMessage.data['senderId'] ?? '';
      handleMessageClick(type: type, role: role, orderId: orderId, senderId: senderId);
    }

    // App in background and notification tapped
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage? message) {
      if (message != null) {
        log("[BACKGROUND_HANDLER] onMessageOpenedApp: data=${message.data}");
        final String type = message.data['type'] ?? '';
        final String role = message.data['chatType'] ?? '';
        final String orderId = message.data['orderId'] ?? '';
        final String senderId = message.data['senderId'] ?? '';
        log("[NAVIGATION_TRIGGERED] type=$type orderId=$orderId");
        handleMessageClick(type: type, role: role, orderId: orderId, senderId: senderId);
      }
    });

    // App in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log("[FOREGROUND_HANDLER] notification=${message.notification?.title} data=${message.data}");
      // Toujours afficher la notif locale (y compris data-only messages)
      display(message);
    });

    await FirebaseMessaging.instance.subscribeToTopic("driver");
  }

  static Future<String> getToken() async {
    try {
      if (Platform.isIOS) {
        // APNS token must be set before FCM token can be retrieved on iOS.
        // If it's not ready yet, return empty and let the caller retry later.
        final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken == null) {
          log('[FCM_TOKEN_FOUND] APNS token not ready yet — returning empty, will retry on next login');
          return '';
        }
      }
      final String? token = await FirebaseMessaging.instance.getToken();
      log("[FCM_TOKEN_FOUND] token=${token != null ? '${token.substring(0, 20)}...(len=${token.length})' : 'NULL'}");
      return token ?? '';
    } catch (e) {
      log('[FCM_TOKEN_FOUND] ERROR — $e — returning empty, app continues normally');
      return '';
    }
  }

  void display(RemoteMessage message) async {
    try {
      const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
        'driver_notifications_channel',
        'Driver Notifications',
        channelDescription: 'App Notifications',
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'ticker',
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosDetails,
      );

      final String type = message.data['type'] ?? '';
      final String fallbackTitle = type == 'cab_ride_request'
          ? 'Nouvelle demande de trajet'
          : type == 'new_delivery_order'
              ? 'Nouvelle livraison'
              : type == 'parcel_order_request'
                  ? 'Nouvelle demande colis'
                  : 'Nouvelle demande';
      await flutterLocalNotificationsPlugin.show(
          id: 0,
          title: message.notification?.title ?? fallbackTitle,
          body: message.notification?.body ?? '',
          notificationDetails: notificationDetails,
          payload: jsonEncode(message.data));
    } catch (e) {
      log("Notification display error: $e");
    }
  }

  Future<void> handleMessageClick({required String type, String? senderId, String? orderId, required String role}) async {
    final String uid = FireStoreUtils.getCurrentUid();
    if (type == 'rental_accepted' || type == 'rental_order') {
      log("[NAVIGATION_TRIGGERED] type=$type orderId=$orderId — navigating to RentalDashboardScreen");
      Get.offAll(DashBoardScreen());
      Get.to(const RentalDashboardScreen(), arguments: {'orderId': orderId ?? ''});
    } else if (type == 'cab_ride_request' || type == 'new_delivery_order' || type == 'parcel_order_request') {
      log("[NAVIGATION_TRIGGERED] type=$type orderId=$orderId — navigating to DashBoard");
      Get.offAll(DashBoardScreen());
    } else if (type == 'admin_chat' && uid.isNotEmpty) {
      DashBoardController controller = Get.put(DashBoardController());
      controller.drawerIndex.value = 7;
      Get.offAll(DashBoardScreen());
    } else if (type == 'orderChat') {
      ShowToastDialog.showLoader("Please wait".tr);
      log("Customer Notification :: $senderId :: ${FireStoreUtils.getCurrentUid()}");
      UserModel? customer = await FireStoreUtils.getUserProfile(senderId.toString());
      UserModel? driver = await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid());
      ShowToastDialog.closeLoader();
      DashBoardController dashBoardScreen = Get.put(DashBoardController());
      dashBoardScreen.drawerIndex.value = 5;
      Get.offAll(DashBoardScreen());
      Get.to(const ChatScreen(), arguments: {
        "senderName": driver!.fullName(),
        "senderId": driver.id,
        "senderProfileUrl": driver.profilePictureURL ?? "",
        "receivedName": customer!.fullName(),
        "receivedId": customer.id,
        "receivedProfileUrl": customer.profilePictureURL ?? "",
        "orderId": orderId,
        "token": customer.fcmToken,
        "chatType": Constant.userRoleDriver,
      });
    }
  }
}
