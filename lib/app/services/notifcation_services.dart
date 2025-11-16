//get token
// ignore_for_file: avoid_print, unused_local_variable

import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import '../controllers/match/match_controller.dart';
import '../routes/app_routes.dart';
import '../app_widgets/app_toast.dart';




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
    
    var androidInitializationSettings =
        const AndroidInitializationSettings('@mipmap/ic_launcher');
    var iosInitializationSettings = const DarwinInitializationSettings();

    var initializationSetting = InitializationSettings(
        android: androidInitializationSettings, iOS: iosInitializationSettings);

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSetting,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap when app is in foreground
        if (kDebugMode) {
          print('📬 Notification tapped: ${response.payload}');
        }
        // You can navigate here based on payload
      },
    );
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

    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
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

    const DarwinNotificationDetails darwinNotificationDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails, iOS: darwinNotificationDetails);

    // Generate unique notification ID based on timestamp
    final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    
    await _flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      notificationDetails,
      payload: message.data.toString(),
    );
    
    if (kDebugMode) {
      print('✅ Local notification shown: $title - $body');
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

      // Handle match invitation
      if (notificationType == 'match_invitation') {
        final matchId = data['matchId'] ?? '';
        final inviterName = data['inviterName'] ?? 'Someone';
        
        if (matchId.isNotEmpty) {
          if (kDebugMode) {
            print('📬 Match invitation received: $matchId from $inviterName');
          }
          
          // Show dialog to accept/reject
          _showMatchInvitationDialog(matchId, inviterName);
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

  /// Show match invitation dialog with accept/reject options
  void _showMatchInvitationDialog(String matchId, String inviterName) {
    // Ensure MatchController is registered
    if (!Get.isRegistered<MatchController>()) {
      Get.put(MatchController());
    }
    
    Get.dialog(
      AlertDialog(
        title: Text('Match Invitation'),
        content: Text('$inviterName wants to play a match with you!'),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              // Reject invitation
              if (Get.isRegistered<MatchController>()) {
                final controller = Get.find<MatchController>();
                controller.handleMatchInvitationResponse(
                  matchId: matchId,
                  accepted: false,
                );
              } else {
                print('MatchController not registered, cannot handle rejection');
              }
            },
            child: Text('Reject'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // Accept invitation
              if (Get.isRegistered<MatchController>()) {
                final controller = Get.find<MatchController>();
                controller.handleMatchInvitationResponse(
                  matchId: matchId,
                  accepted: true,
                );
                // Navigate to lobby
                Get.toNamed(AppRoutes.matchLobby, arguments: {'matchId': matchId});
              } else {
                print('MatchController not registered, cannot handle acceptance');
                AppToast.showError('Unable to accept invitation. Please try again.');
              }
            },
            child: Text('Accept'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}
