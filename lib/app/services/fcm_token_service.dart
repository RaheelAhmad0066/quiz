import 'package:afn_test/app/app_widgets/constant/keys.dart';
import 'package:afn_test/app/services/notifcation_services.dart';
import 'package:afn_test/app/services/prefferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';

import '../app_widgets/constant/debug_point.dart';


/// Centralized FCM Token Management Service
/// Handles token retrieval, storage, and updates for all roles
class FcmTokenService extends GetxService {
  static FcmTokenService get instance => Get.find<FcmTokenService>();
  
  final NotificationService _notificationService = NotificationService();
  final Preferences _preferences = Get.find<Preferences>();
  
  String? _currentToken;
  bool _isInitialized = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  /// Initialize FCM token service
  /// Should be called once at app startup
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Request notification permissions
      _notificationService.requestNotificationPermission();
      
      // Get and store FCM token
      await refreshToken();
      
      // Setup token refresh listener
      _setupTokenRefreshListener();
      
      // Initialize local notifications
      await _notificationService.initializeLocalNotifications();
      
      // Initialize Firebase messaging
      _notificationService.firebaseInit();
      
      // Setup message handlers
      await _notificationService.setupInteractMessage();
      
      _isInitialized = true;
      DebugPoint.log('✅ FCM Token Service initialized');
    } catch (e) {
      DebugPoint.log('❌ Error initializing FCM Token Service: $e');
    }
  }

  /// Get current FCM token
  String? get currentToken => _currentToken;

  /// Refresh and update FCM token
  Future<String?> refreshToken() async {
    try {
      final token = await _notificationService.getDeviceToken();
      
      // Check if token is valid (not empty)
      if (token.isEmpty) {
        DebugPoint.log('⚠️ FCM Token is empty, will retry later');
        return null;
      }
      
      _currentToken = token;
      
      // Store token locally
      await _preferences.setString(Keys.fcmToken, token);
      
      // Update token on server if user is logged in
      await updateTokenOnServer(token);
      
      _retryCount = 0; // Reset retry count on success
      DebugPoint.log('✅ FCM Token refreshed: ${token.substring(0, 20)}...');
      return token;
    } catch (e) {
      // Handle APNS token not set error (common on iOS simulator)
      final errorString = e.toString();
      if (errorString.contains('apns-token-not-set') || 
          errorString.contains('APNS token has not been received')) {
        if (_retryCount < _maxRetries) {
          _retryCount++;
          DebugPoint.log('⚠️ APNS token not available yet (iOS simulator or device not ready). Retrying... ($_retryCount/$_maxRetries)');
          // Retry after a delay (increasing delay with each retry)
          await Future.delayed(Duration(seconds: 2 + _retryCount), () {
            refreshToken();
          });
        } else {
          DebugPoint.log('⚠️ APNS token not available after $_maxRetries retries. This is normal on iOS simulator. Will work on real device.');
        }
        return null;
      }
      
      DebugPoint.log('❌ Error refreshing FCM token: $e');
      return null;
    }
  }

  /// Update FCM token on server (Firebase Realtime DB)
  /// This should be called whenever token changes or user profile is updated
  Future<void> updateTokenOnServer(String? token) async {
    try {
      // Get current user from Firebase Auth
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null || token == null || token.isEmpty) {
        DebugPoint.log('⚠️ Cannot update token: user not logged in or token is empty');
        return;
      }

      final userId = currentUser.uid;

      // Update token in Firebase Realtime DB
      try {
        final databaseRef = FirebaseDatabase.instance.ref();
        await databaseRef.child('users').child(userId).update({
          'fcmToken': token,
          'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        });
        DebugPoint.log('✅ FCM Token updated in Firebase Realtime DB');
      } catch (e) {
        DebugPoint.log('❌ Error updating FCM token in Firebase: $e');
      }
    } catch (e) {
      DebugPoint.log('❌ Error updating FCM token on server: $e');
    }
  }

  /// Setup listener for token refresh
  void _setupTokenRefreshListener() {
    _notificationService.messaging.onTokenRefresh.listen((newToken) {
      DebugPoint.log('🔄 FCM Token refreshed automatically');
      _currentToken = newToken;
      _preferences.setString(Keys.fcmToken, newToken);
      updateTokenOnServer(newToken);
    });
  }

  /// Get stored token from preferences
  String? getStoredToken() {
    return _preferences.getString(Keys.fcmToken);
  }

  /// Clear token (e.g., on logout)
  Future<void> clearToken() async {
    _currentToken = null;
    await _preferences.remove(Keys.fcmToken);
    DebugPoint.log('🗑️ FCM Token cleared');
  }
}

