import 'package:afn_test/app/app_widgets/theme/app_themes.dart';
import 'package:afn_test/app/routes/app_pages.dart';
import 'package:afn_test/app/routes/app_routes.dart';
import 'package:afn_test/app/services/services.dart';
import 'package:afn_test/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Background message handler - must be top-level function
// Note: This runs in a separate isolate, so keep it minimal
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase in background isolate
  // This is required for background message handling
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Minimal logging - actual handling happens in foreground via NotificationService
  print('📬 Background message: ${message.messageId ?? 'unknown'}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
    
    // Setup background message handler - must be called before runApp
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    
    // Initialize Preferences and FCM Token Service
    await Services().initServices();
    print('Services initialized successfully');
  } catch (e) {
    print('Error initializing services: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // Design size (width, height)
      minTextAdapt: true,
      splitScreenMode: true,
      useInheritedMediaQuery: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: 'AFN Test App',
          theme: AppTheme.lightTheme,
          initialRoute: AppRoutes.splash, // Start with splash screen
          getPages: AppPages.routes,
          debugShowCheckedModeBanner: false,
        );    
      },
    );
  }
}
