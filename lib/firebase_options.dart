// File generated using Firebase configuration
// This file contains Firebase options for different platforms

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAQeqg9Wbpnho9jF7j7kZoYYCr8s03Tjuw',
    appId: '1:39592817605:web:bdb598f6569295342f11ac',
    messagingSenderId: '39592817605',
    projectId: 'afn-test',
    authDomain: 'afn-test.firebaseapp.com',
    databaseURL: 'https://afn-test-default-rtdb.firebaseio.com',
    storageBucket: 'afn-test.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAQeqg9Wbpnho9jF7j7kZoYYCr8s03Tjuw',
    appId: '1:39592817605:android:bdb598f6569295342f11ac',
    messagingSenderId: '39592817605',
    projectId: 'afn-test',
    databaseURL: 'https://afn-test-default-rtdb.firebaseio.com',
    storageBucket: 'afn-test.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAQeqg9Wbpnho9jF7j7kZoYYCr8s03Tjuw',
    appId: '1:39592817605:ios:bdb598f6569295342f11ac',
    messagingSenderId: '39592817605',
    projectId: 'afn-test',
    databaseURL: 'https://afn-test-default-rtdb.firebaseio.com',
    storageBucket: 'afn-test.firebasestorage.app',
    iosBundleId: 'com.example.afnTest',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAQeqg9Wbpnho9jF7j7kZoYYCr8s03Tjuw',
    appId: '1:39592817605:ios:your-macos-app-id',
    messagingSenderId: '39592817605',
    projectId: 'afn-test',
    databaseURL: 'https://afn-test-default-rtdb.firebaseio.com',
    storageBucket: 'afn-test.firebasestorage.app',
    iosBundleId: 'com.example.afnTest',
  );
}

