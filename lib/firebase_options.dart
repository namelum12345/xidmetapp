// Lokal emulyator üçün `projectId: demo-qonsudan-xidmet` (Firebase tələbi: demo- prefiksi).
// REAL Firebase üçün bu faylı `flutterfire configure` çıxışı ilə əvəz edin:
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// Həmçinin Firebase Console-da aktiv edin: Authentication (Email, Anonymous və istəyə görə Phone),
// Cloud Firestore, Cloud Messaging. Android üçün `google-services.json`, iOS üçün
// `GoogleService-Info.plist` avtomatik əlavə olunur. Web üçün FCM üçün Web Push sertifikatı (VAPID).

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  /// `flutterfire configure` etməyənə qədər saxlanmış demo `projectId`.
  /// Prod Firebase bu açarlarla işləmir — vebdə giriş **400** verir; `main.dart`
  /// bu halda emulyatora avtomatik qoşulur.
  static bool get usesPlaceholderFirebaseConfig {
    try {
      return currentPlatform.projectId == 'demo-qonsudan-xidmet';
    } catch (_) {
      return false;
    }
  }

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
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // TODO: replace all values from Firebase Console → Project settings, or run `flutterfire configure`.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'emulator-web-key-not-for-production',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-qonsudan-xidmet',
    authDomain: 'demo-qonsudan-xidmet.firebaseapp.com',
    storageBucket: 'demo-qonsudan-xidmet.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'emulator-android-key-not-for-production',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-qonsudan-xidmet',
    storageBucket: 'demo-qonsudan-xidmet.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'emulator-ios-key-not-for-production',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-qonsudan-xidmet',
    storageBucket: 'demo-qonsudan-xidmet.appspot.com',
    iosBundleId: 'com.example.qonsudanXidmet',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'emulator-macos-key-not-for-production',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-qonsudan-xidmet',
    storageBucket: 'demo-qonsudan-xidmet.appspot.com',
    iosBundleId: 'com.example.qonsudanXidmet',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'emulator-web-key-not-for-production',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-qonsudan-xidmet',
    authDomain: 'demo-qonsudan-xidmet.firebaseapp.com',
    storageBucket: 'demo-qonsudan-xidmet.appspot.com',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'emulator-web-key-not-for-production',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-qonsudan-xidmet',
    authDomain: 'demo-qonsudan-xidmet.firebaseapp.com',
    storageBucket: 'demo-qonsudan-xidmet.appspot.com',
  );
}
