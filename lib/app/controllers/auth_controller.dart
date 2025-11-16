import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../app_widgets/app_toast.dart';
import '../app_widgets/constant/keys.dart';
import '../routes/app_routes.dart';
import '../services/fcm_token_service.dart';
import '../services/notifcation_services.dart';
import '../services/prefferences.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Observable user state
  final Rx<User?> user = Rx<User?>(null);
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      this.user.value = user;
    });
  }

  // Sign in with Email and Password
  Future<void> signInWithEmailPassword(String email, String password) async {
    try {
      isLoading.value = true;
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      // Store/Update user data in Firebase Realtime DB with FCM token
      if (userCredential.user != null) {
        await _storeUserDataInRealtimeDB(userCredential.user!);
      }
      
      // Mark onboarding as completed
      await _markOnboardingCompleted();
      
      AppToast.showCustomToast(
        'Success',
        'Logged in successfully!',
        type: ToastType.success,
      );
      Get.offAllNamed(AppRoutes.dashboard);
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';
      if (e.code == 'user-not-found') {
        message = 'No user found with this email';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      }
      AppToast.showCustomToast(
        'Error',
        message,
        type: ToastType.error,
      );
    } catch (e) {
      AppToast.showCustomToast(
        'Error',
        'Login failed: ${e.toString()}',
        type: ToastType.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Sign up with Email, Name and Password
  Future<void> signUpWithEmailPassword(
    String email,
    String name,
    String password,
  ) async {
    try {
      isLoading.value = true;
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      // Update display name
      await userCredential.user?.updateDisplayName(name.trim());
      await userCredential.user?.reload();
      
      // Store user data in Firebase Realtime DB with FCM token
      await _storeUserDataInRealtimeDB(userCredential.user!);
      
      // Mark onboarding as completed
      await _markOnboardingCompleted();
      
      AppToast.showCustomToast(
        'Success',
        'Account created successfully!',
        type: ToastType.success,
      );
      Get.offAllNamed(AppRoutes.dashboard);
    } on FirebaseAuthException catch (e) {
      String message = 'Sign up failed';
      if (e.code == 'weak-password') {
        message = 'Password is too weak';
      } else if (e.code == 'email-already-in-use') {
        message = 'Email is already registered';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      }
      AppToast.showCustomToast(
        'Error',
        message,
        type: ToastType.error,
      );
    } catch (e) {
      AppToast.showCustomToast(
        'Error',
        'Sign up failed: ${e.toString()}',
        type: ToastType.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Sign in with Google
  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User canceled the sign-in
        isLoading.value = false;
        return;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(credential);
      
      // Store/Update user data in Firebase Realtime DB with FCM token
      await _storeUserDataInRealtimeDB(userCredential.user!);
      
      // Mark onboarding as completed
      await _markOnboardingCompleted();
      
      AppToast.showCustomToast(
        'Success',
        'Signed in with Google!',
        type: ToastType.success,
      );
      Get.offAllNamed(AppRoutes.dashboard);
    } catch (e) {
      AppToast.showCustomToast(
        'Error',
        'Google sign in failed: ${e.toString()}',
        type: ToastType.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Sign in with Apple
  Future<void> signInWithApple() async {
    try {
      isLoading.value = true;
      
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);
      
      // Store/Update user data in Firebase Realtime DB with FCM token
      await _storeUserDataInRealtimeDB(userCredential.user!);
      
      // Mark onboarding as completed
      await _markOnboardingCompleted();
      
      AppToast.showCustomToast(
        'Success',
        'Signed in with Apple!',
        type: ToastType.success,
      );
      Get.offAllNamed(AppRoutes.dashboard);
    } catch (e) {
      AppToast.showCustomToast(
        'Error',
        'Apple sign in failed: ${e.toString()}',
        type: ToastType.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      Get.offAllNamed(AppRoutes.auth);
    } catch (e) {
      AppToast.showCustomToast(
        'Error',
        'Sign out failed: ${e.toString()}',
        type: ToastType.error,
      );
    }
  }

  // Continue as Guest
  void continueAsGuest() {
    // Mark onboarding as completed
    _markOnboardingCompleted();
    Get.offAllNamed(AppRoutes.dashboard);
  }
  
  // Mark onboarding as completed
  Future<void> _markOnboardingCompleted() async {
    try {
      if (Get.isRegistered<Preferences>()) {
        final prefs = Get.find<Preferences>();
        await prefs.setBool(Keys.onboardingCompleted, true);
      }
    } catch (e) {
      print('Error marking onboarding as completed: $e');
    }
  }
  
  // Check if onboarding is completed
  bool get isOnboardingCompleted {
    try {
      if (Get.isRegistered<Preferences>()) {
        final prefs = Get.find<Preferences>();
        return prefs.getBool(Keys.onboardingCompleted) ?? false;
      }
    } catch (e) {
      print('Error checking onboarding status: $e');
    }
    return false;
  }

  // Check if user is logged in
  bool get isLoggedIn => user.value != null;
  
  // Get user display name
  String get displayName => user.value?.displayName ?? 'Guest';
  
  // Get user email
  String get userEmail => user.value?.email ?? '';

  /// Store user data in Firebase Realtime DB with FCM token
  Future<void> _storeUserDataInRealtimeDB(User firebaseUser) async {
    try {
      if (Firebase.apps.isEmpty) return;

      final databaseRef = FirebaseDatabase.instance.ref();
      final userId = firebaseUser.uid;

      // Get FCM token - try multiple methods
      String? fcmToken;
      try {
        // Method 1: Try FcmTokenService
        if (Get.isRegistered<FcmTokenService>()) {
          final fcmService = Get.find<FcmTokenService>();
          fcmToken = fcmService.currentToken ?? await fcmService.refreshToken();
        }
        
        // Method 2: If still null, try getting directly from NotificationService
        if (fcmToken == null || fcmToken.isEmpty) {
          try {
            final notificationService = NotificationService();
            fcmToken = await notificationService.getDeviceToken();
            print('✅ Got FCM token directly from NotificationService');
          } catch (e) {
            print('⚠️ Could not get FCM token from NotificationService: $e');
          }
        }
        
        if (fcmToken != null && fcmToken.isNotEmpty) {
          print('✅ FCM Token retrieved: ${fcmToken.substring(0, 20)}...');
        } else {
          print('⚠️ FCM Token is null or empty');
        }
      } catch (e) {
        print('❌ Error getting FCM token: $e');
      }

      // Store/Update user data in users node (use update to preserve existing data)
      final userData = {
        'userId': userId,
        'userName': firebaseUser.displayName ?? 'User',
        'userEmail': firebaseUser.email ?? '',
        'userAvatar': firebaseUser.photoURL,
        'fcmToken': fcmToken,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      };
      
      // Check if user already exists
      final existingUser = await databaseRef.child('users').child(userId).get();
      if (!existingUser.exists) {
        // New user - set all data including createdAt
        userData['createdAt'] = DateTime.now().millisecondsSinceEpoch;
        await databaseRef.child('users').child(userId).set(userData);
      } else {
        // Existing user - update only (preserve createdAt)
        await databaseRef.child('users').child(userId).update(userData);
      }

      // Also store in leaderboard with initial values
      await databaseRef.child('leaderboard').child('allTime').child(userId).set({
        'userName': firebaseUser.displayName ?? 'User',
        'userEmail': firebaseUser.email ?? '',
        'userAvatar': firebaseUser.photoURL,
        'totalPoints': 0,
        'testsCompleted': 0,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      });

      print('✅ User data stored in Firebase Realtime DB');
    } catch (e) {
      print('❌ Error storing user data: $e');
    }
  }
}

