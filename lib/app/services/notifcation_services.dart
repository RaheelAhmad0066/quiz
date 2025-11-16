//get token
// ignore_for_file: avoid_print, unused_local_variable

import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import '../controllers/match/match_controller.dart';
import '../routes/app_routes.dart';




class NotificationService {
  //initialising firebase message plugin
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  //initialising firebase message plugin
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  //send notificartion request
  void requestNotificationPermission() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: true,
      criticalAlert: true,
      provisional: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print('user granted permission');
      }
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      if (kDebugMode) {
        print('user granted provisional permission');
      }
    } else {
      //appsetting.AppSettings.openNotificationSettings();
      if (kDebugMode) {
        print('user denied permission');
      }
    }
  }

//Fetch FCM Token
  Future<String> getDeviceToken() async {
    try {
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Wait a bit for APNS token to be available (especially on iOS)
      await Future.delayed(const Duration(milliseconds: 500));
      
      String? token = await messaging.getToken();
      
      if (token == null || token.isEmpty) {
        // Retry once after a delay
        await Future.delayed(const Duration(seconds: 2));
        token = await messaging.getToken();
      }
      
      if (token == null || token.isEmpty) {
        throw Exception('FCM token is null or empty');
      }
      
      print("token=> $token");
      return token;
    } catch (e) {
      print("Error getting FCM token: $e");
      rethrow;
    }
  }

  // Initialize local notifications plugin (should be called once at app startup)
  Future<void> initializeLocalNotifications() async {
    // Create Android notification channel
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.high,
      );
      
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
    
    // Request iOS permissions
    if (Platform.isIOS) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
    
    var androidInitializationSettings =
        const AndroidInitializationSettings('@mipmap/ic_launcher');
    var iosInitializationSettings = const DarwinInitializationSettings();

    var initializationSetting = InitializationSettings(
        android: androidInitializationSettings, iOS: iosInitializationSettings);

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSetting,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap and action buttons
        _handleNotificationResponse(response);
      },
    );
  }
  
  /// Handle notification response (tap or action button)
  void _handleNotificationResponse(NotificationResponse response) {
    if (kDebugMode) {
      print('📬 Notification response: actionId=${response.actionId}, payload=${response.payload}');
    }
    
    final payload = response.payload ?? '';
    if (payload.isEmpty) {
      if (kDebugMode) {
        print('⚠️ Empty payload in notification response');
      }
      return;
    }
    
    // Handle action buttons first
    if (response.actionId != null && response.actionId!.isNotEmpty) {
      if (kDebugMode) {
        print('📬 Action button tapped: ${response.actionId}');
      }
      
      if (response.actionId == 'accept' || 
          response.actionId == 'accept_action' ||
          response.actionId == 'ACCEPT_ACTION') {
        // User tapped Accept button
        _handleAcceptFromNotification(payload);
        return;
      } else if (response.actionId == 'reject' || 
                 response.actionId == 'reject_action' ||
                 response.actionId == 'REJECT_ACTION') {
        // User tapped Reject button
        _handleRejectFromNotification(payload);
        return;
      }
    }
    
    // If no action button, user tapped notification - handle normally
    if (payload.isNotEmpty) {
      handleMessageFromPayload(payload);
    }
  }
  
  /// Handle accept action from notification
  void _handleAcceptFromNotification(String payload) {
    if (kDebugMode) {
      print('✅ Accept button tapped, payload: $payload');
    }
    final matchId = _extractMatchIdFromPayload(payload);
    if (matchId != null && matchId.isNotEmpty) {
      if (kDebugMode) {
        print('✅ Extracted matchId: $matchId');
      }
      handleNotificationAction('accept_action', payload);
    } else {
      if (kDebugMode) {
        print('❌ Could not extract matchId from payload: $payload');
      }
    }
  }
  
  /// Handle reject action from notification
  void _handleRejectFromNotification(String payload) {
    if (kDebugMode) {
      print('❌ Reject button tapped, payload: $payload');
    }
    final matchId = _extractMatchIdFromPayload(payload);
    if (matchId != null && matchId.isNotEmpty) {
      if (kDebugMode) {
        print('✅ Extracted matchId: $matchId');
      }
      handleNotificationAction('reject_action', payload);
    } else {
      if (kDebugMode) {
        print('❌ Could not extract matchId from payload: $payload');
      }
    }
  }
  
  /// Extract matchId from payload
  String? _extractMatchIdFromPayload(String payload) {
    try {
      // Payload format: matchId:xxx,inviterName:yyy,type:match_invitation
      // Or: {type: match_invitation, matchId: xxx, inviterName: yyy}
      
      // Method 1: Simple format (matchId:value)
      if (payload.contains('matchId:')) {
        final matchIdMatch = RegExp(r'matchId:([^,]+)').firstMatch(payload);
        if (matchIdMatch != null && matchIdMatch.group(1) != null) {
          return matchIdMatch.group(1)!.trim();
        }
      }
      
      // Method 2: JSON-like format
      if (payload.contains('matchId')) {
        final patterns = [
          RegExp(r"matchId\s*:\s*([^,]+)"),
          RegExp(r"matchId\s*=\s*([^\s,}]+)"),
          RegExp(r"'matchId':\s*'([^']+)'"),
          RegExp(r'"matchId":\s*"([^"]+)"'),
        ];
        
        for (var pattern in patterns) {
          final match = pattern.firstMatch(payload);
          if (match != null && match.group(1) != null) {
            return match.group(1)!.trim();
          }
        }
      }
      
      // Method 3: Extract from string representation
      final matchIdStart = payload.indexOf('matchId');
      if (matchIdStart != -1) {
        final afterMatchId = payload.substring(matchIdStart + 7);
        final colonIndex = afterMatchId.indexOf(':');
        if (colonIndex != -1) {
          final valueStart = afterMatchId.substring(colonIndex + 1).trim();
          final value = valueStart.split(',').first.split('}').first.trim();
          return value.replaceAll("'", '').replaceAll('"', '').trim();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error extracting matchId: $e');
      }
    }
    return null;
  }
  
  /// Handle message from payload string
  void handleMessageFromPayload(String payload) {
    // This will be called when notification is tapped (not action button)
    // The actual handling is done in handleMessage with RemoteMessage
  }

  //function to initialise flutter local notification plugin to show notifications for android when app is active
  void initLocalNotifications(RemoteMessage message) async {
    // Check if already initialized
    var androidInitializationSettings =
        const AndroidInitializationSettings('@mipmap/ic_launcher');
    var iosInitializationSettings = const DarwinInitializationSettings();

    var initializationSetting = InitializationSettings(
        android: androidInitializationSettings, iOS: iosInitializationSettings);

    await _flutterLocalNotificationsPlugin.initialize(initializationSetting,
        onDidReceiveNotificationResponse: (response) {
      // handle interaction when app is active for android
      handleMessage(message);
    });
  }

//
  void firebaseInit() {
    FirebaseMessaging.onMessage.listen((message) async {
      RemoteNotification? notification = message.notification;
      
      if (kDebugMode) {
        print("📬 Foreground notification received");
        print("   Title: ${notification?.title}");
        print("   Body: ${notification?.body}");
        print("   Data: ${message.data.toString()}");
      }

      // Show notification for both iOS and Android when app is in foreground
      if (Platform.isIOS) {
        await forgroundMessage();
        // Also show local notification for iOS
        if (notification != null) {
          await showNotification(message);
        }
      }

      if (Platform.isAndroid) {
        // Ensure channel is created before showing notification
        if (notification != null) {
          await showNotification(message);
        }
      }
      
      // Handle notification data
      handleMessage(message);
    });
  }

  //handle tap on notification when app is in background or terminated
  Future<void> setupInteractMessage() async {
    // // when app is terminated
    // RemoteMessage? initialMessage =
    //     await FirebaseMessaging.instance.getInitialMessage();

    // if (initialMessage != null) {
    //   handleMessage(context, initialMessage);
    // }

    //when app ins background
    FirebaseMessaging.onMessageOpenedApp.listen((event) {
      handleMessage(event);
    });

    // Handle terminated state
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null && message.data.isNotEmpty) {
        handleMessage(message);
      }
    });
  }

  // function to show visible notification when app is active
  Future<void> showNotification(RemoteMessage message) async {
    if (message.notification == null) return;
    
    final notification = message.notification!;
    final title = notification.title ?? 'Notification';
    final body = notification.body ?? '';
    final data = message.data;
    final notificationType = data['type'] ?? '';
    
    // Create/Get Android notification channel
    const String channelId = 'high_importance_channel';
    const String channelName = 'High Importance Notifications';
    
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: 'This channel is used for important notifications.',
        importance: Importance.high,
        playSound: true,
      );
      
      // Create channel if not exists
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    // Notification details without action buttons (user will use notification screen)
    final androidNotificationDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Match invitations and important updates',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      showWhen: true,
      enableVibration: true,
      ticker: 'ticker',
    );

    final darwinNotificationDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails, iOS: darwinNotificationDetails);

    // Generate unique notification ID based on matchId if available, otherwise timestamp
    final notificationId = data['matchId'] != null 
        ? data['matchId'].toString().hashCode.abs().remainder(100000)
        : DateTime.now().millisecondsSinceEpoch.remainder(100000);
    
    // Create payload with all notification data as JSON string for easier parsing
    // Format: matchId:xxx,inviterName:yyy,type:match_invitation
    final payload = 'matchId:${data['matchId'] ?? ''},inviterName:${data['inviterName'] ?? 'Someone'},type:${data['type'] ?? ''}';
    
    await _flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
    
    if (kDebugMode) {
      print('✅ Local notification shown: $title - $body');
      print('   Payload: $payload');
      print('   Actions: ${notificationType == 'match_invitation' ? 'Accept/Reject' : 'None'}');
    }
  }

  Future forgroundMessage() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Handle notification message based on user role and notification type
  Future<void> handleMessage(RemoteMessage message) async {
    try {
      final data = message.data;
      final notificationType = data['type'] ?? '';
      
      if (kDebugMode) {
        print('📬 Notification received - Type: $notificationType');
        print('📬 Notification data: $data');
      }

      // Handle match invitation - navigate to match list screen
      // User will see notification in bell icon and can accept/reject from there
      if (notificationType == 'match_invitation') {
        final matchId = data['matchId'] ?? '';
        final inviterName = data['inviterName'] ?? 'Someone';
        
        if (matchId.isNotEmpty) {
          if (kDebugMode) {
            print('📬 Match invitation received: $matchId from $inviterName');
            print('📬 Navigate to match list - user can accept/reject from notification screen');
          }
          
          // Navigate to match list screen where user can see notifications
          // The notification will appear in the bell icon badge
          if (Get.context != null) {
            // Just refresh the match list - notification will show in bell icon
            // User can tap bell icon to see and accept/reject invitations
          }
        }
      }
      
      // For now, just log the message
      if (kDebugMode) {
        print('📬 Handling notification: ${message.notification?.title}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling notification: $e');
      }
    }
  }
  
  /// Handle notification response from action buttons or tap
  void handleNotificationAction(String? actionId, String? payload) {
    if (actionId == null || payload == null || payload.isEmpty) {
      if (kDebugMode) {
        print('❌ Invalid actionId or payload: actionId=$actionId, payload=$payload');
      }
      return;
    }
    
    final matchId = _extractMatchIdFromPayload(payload);
    if (matchId == null || matchId.isEmpty) {
      if (kDebugMode) {
        print('❌ Could not extract matchId from payload: $payload');
      }
      return;
    }
    
    if (kDebugMode) {
      print('✅ Processing notification action: $actionId for matchId: $matchId');
    }
    
    if (!Get.isRegistered<MatchController>()) {
      Get.put(MatchController());
    }
    final controller = Get.find<MatchController>();
    
    if (actionId == 'accept_action' || actionId == 'accept' || actionId == 'ACCEPT_ACTION') {
      if (kDebugMode) {
        print('✅ Accepting match invitation: $matchId');
      }
      controller.handleMatchInvitationResponse(
        matchId: matchId,
        accepted: true,
      ).then((_) {
        // Navigate after handling
        Get.toNamed(AppRoutes.matchLobby, arguments: {'matchId': matchId});
      }).catchError((e) {
        if (kDebugMode) {
          print('❌ Error accepting invitation: $e');
        }
      });
    } else if (actionId == 'reject_action' || actionId == 'reject' || actionId == 'REJECT_ACTION') {
      if (kDebugMode) {
        print('❌ Rejecting match invitation: $matchId');
      }
      controller.handleMatchInvitationResponse(
        matchId: matchId,
        accepted: false,
      ).catchError((e) {
        if (kDebugMode) {
          print('❌ Error rejecting invitation: $e');
        }
      });
    }
  }

}
