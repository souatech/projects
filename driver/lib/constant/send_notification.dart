// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:developer';
import 'package:driver/constant/constant.dart';
import 'package:driver/models/notification_model.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class SendNotification {
  static final _scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

  static Future getCharacters() {
    return http.get(Uri.parse(Constant.jsonNotificationFileURL.toString()));
  }

  static Future<String> getAccessToken() async {
    if (Constant.jsonNotificationFileURL.isEmpty) {
      log('[FCM_TOKEN] ERROR: jsonNotificationFileURL is empty — check Firestore settings/notification_setting.serviceJson');
      throw Exception('jsonNotificationFileURL not configured');
    }
    final response = await getCharacters();
    final Map<String, dynamic> jsonData = json.decode(response.body);
    final serviceAccountCredentials = ServiceAccountCredentials.fromJson(jsonData);
    final client = await clientViaServiceAccount(serviceAccountCredentials, _scopes);
    return client.credentials.accessToken.data;
  }

  static Future<bool> sendFcmMessage(String type, String token, Map<String, dynamic>? payload) async {
    if (token.isEmpty || token.length <= 20) {
      log('[FCM_SENT] SKIP: token empty or too short for type=$type');
      return false;
    }
    try {
      log('[FCM_PAYLOAD_BUILT] type=$type token=${token.substring(0, 20)}...');
      final String accessToken = await getAccessToken();
      final NotificationModel? notificationModel = await FireStoreUtils.getNotificationContent(type);
      if (notificationModel == null) {
        log('[FCM_SENT] ERROR: notification template null for type=$type — add it in Firestore notifications collection');
        return false;
      }

      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/v1/projects/${Constant.senderId}/messages:send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(<String, dynamic>{
          'message': {
            'token': token,
            'notification': {'body': notificationModel.message ?? '', 'title': notificationModel.subject ?? ''},
            'data': payload,
          },
        }),
      );
      log('[FCM_RESPONSE] type=$type status=${response.statusCode} body=${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      log('[FCM_SENT] ERROR type=$type: $e');
      return false;
    }
  }

  static Future<bool> sendOneNotification({required String token, required String title, required String body, required Map<String, dynamic> payload}) async {
    if (token.isEmpty || token.length <= 20) {
      log('[FCM_SENT] SKIP sendOneNotification: token empty');
      return false;
    }
    try {
      log('[FCM_PAYLOAD_BUILT] sendOneNotification title=$title token=${token.substring(0, 20)}...');
      final String accessToken = await getAccessToken();

      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/v1/projects/${Constant.senderId}/messages:send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(<String, dynamic>{
          'message': {
            'token': token,
            'notification': {'body': body, 'title': title},
            'data': payload,
          },
        }),
      );
      log('[FCM_RESPONSE] sendOneNotification status=${response.statusCode} body=${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      log('[FCM_SENT] ERROR sendOneNotification: $e');
      return false;
    }
  }

  static Future<bool> sendChatFcmMessage(String title, String message, String token, Map<String, dynamic>? payload) async {
    if (token.isEmpty || token.length <= 20) return false;
    try {
      final String accessToken = await getAccessToken();
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/v1/projects/${Constant.senderId}/messages:send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(<String, dynamic>{
          'message': {
            'token': token,
            'notification': {'body': message, 'title': title},
            'data': payload,
          },
        }),
      );
      log('[FCM_RESPONSE] sendChatFcmMessage status=${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      log('[FCM_SENT] ERROR sendChatFcmMessage: $e');
      return false;
    }
  }
}
