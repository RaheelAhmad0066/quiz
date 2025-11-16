// ignore_for_file: avoid_print

import 'dart:convert';

// ignore: depend_on_referenced_packages
import 'package:afn_test/app/services/get_services.dart';
import 'package:http/http.dart' as http;


class SendNotificationService {
  static Future<void> sendNotificationUsingApi({
    required String? token,
    required String? title,
    required String? body,
    required Map<String, dynamic>? data,
  }) async {
    String serverKey = await GetServicekey().getServiceKeyToken();
    print("notification server key => ${serverKey}");
    String url =
        "https://fcm.googleapis.com/v1/projects/afn-test/messages:send";

    var headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $serverKey',
    };

    // Build message with action buttons for match invitations
    Map<String, dynamic> message = {
      "message": {
        "token": token,
        "notification": {"body": body, "title": title},
        "data": data,
      }
    };
    
    // Add Android and APNS specific settings for match invitations
    if (data != null && data['type'] == 'match_invitation') {
      message["message"]["android"] = {
        "priority": "high",
        "notification": {
          "channel_id": "high_importance_channel",
          "sound": "default",
          "click_action": "FLUTTER_NOTIFICATION_CLICK",
        }
      };
      
      message["message"]["apns"] = {
        "headers": {
          "apns-priority": "10",
        },
        "payload": {
          "aps": {
            "sound": "default",
            "badge": 1,
            "category": "MATCH_INVITATION",
          }
        }
      };
    } else {
      // Default Android settings for other notifications
      message["message"]["android"] = {
        "priority": "normal",
      };
    }

    //hit api
    final http.Response response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(message),
    );

    if (response.statusCode == 200) {
      print("Notification Send Successfully!");
    } else {
      print("Notification not send!--- ${response.body}");
    }
  }

  static Future<void> sendNotificationGroup({
    required String? title,
    required String? body,
    required Map<String, dynamic>? data,
  }) async {
    String serverKey = await GetServicekey().getServiceKeyToken();
    print("notification server key => ${serverKey}");
    String url =
        "https://fcm.googleapis.com/v1/projects/afn-test/messages:send";

    var headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $serverKey',
    };

    //mesaage
    Map<String, dynamic> message = {
      "message": {
        "topic": "all",
        "notification": {"body": body, "title": title},
        "data": data,
      }
    };

    //hit api
    final http.Response response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(message),
    );

    if (response.statusCode == 200) {
      print("Notification Send Successfully!");
    } else {
      print("Notification not send!--- ${response.body}");
    }
  }
}