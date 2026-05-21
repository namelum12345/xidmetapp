import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'services/app_settings_controller.dart';
import 'firebase_options.dart';
import 'services/admin_data_service.dart';
import 'services/auth_service.dart';
import 'services/chat_service.dart';
import 'services/fcm_service.dart';
import 'services/job_service.dart';
import 'services/notification_service.dart';

/// `true` — əl ilə emulyator. Demo `firebase_options` üçün əlavə olaraq
/// [DefaultFirebaseOptions.usesPlaceholderFirebaseConfig] avtomatik qoşulur.
const bool _useFirebaseEmulatorEnv =
    bool.fromEnvironment('USE_FIREBASE_EMULATOR', defaultValue: false);
/// Fiziki telefonda emulyator PC-dədirsə, build zamanı `--dart-define`'lə
/// kompüterin Wi‑Fi IP-si verilməlidir (məs. `scripts/build-apk-phone.sh`).
/// `127.0.0.1` yalnız eyni qurğuda işləyir.
/// **`10.0.2.2` yalnız Android Studio AVD emulyatorunda** (host = PC); real
/// telefonda həmişə PC-nin LAN IP-si (məs. 192.168.x.x).
const String _emulatorHost =
    String.fromEnvironment('FIREBASE_EMULATOR_HOST', defaultValue: '127.0.0.1');
const int _firestorePort =
    int.fromEnvironment('FIRESTORE_EMULATOR_PORT', defaultValue: 8080);
const int _authPort =
    int.fromEnvironment('AUTH_EMULATOR_PORT', defaultValue: 9099);
const int _functionsPort =
    int.fromEnvironment('FUNCTIONS_EMULATOR_PORT', defaultValue: 5001);
const int _storagePort =
    int.fromEnvironment('STORAGE_EMULATOR_PORT', defaultValue: 9199);

bool _emulatorsConfigured = false;

Future<void> _configureFirebaseEmulatorsIfNeeded() async {
  final autoDemo = DefaultFirebaseOptions.usesPlaceholderFirebaseConfig;
  final useEmu = _useFirebaseEmulatorEnv || autoDemo;
  if (!useEmu || _emulatorsConfigured) return;

  if (autoDemo && !_useFirebaseEmulatorEnv && kDebugMode) {
    debugPrint(
      '[Firebase] Demo layihə konfiqurasiyası: Auth/Firestore emulyatoruna '
      'qoşulur ($_emulatorHost). Emulyator işləmirsə: firebase emulators:start',
    );
  }

  FirebaseFirestore.instance.useFirestoreEmulator(_emulatorHost, _firestorePort);
  if (kIsWeb) {
    // Veb + emulyator: indeksli keş bəzən JS SDK-da "Unexpected state (ve:-1)" ilə uyğunsuzdur.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
  }
  await FirebaseAuth.instance.useAuthEmulator(_emulatorHost, _authPort);
  FirebaseFunctions.instance.useFunctionsEmulator(_emulatorHost, _functionsPort);
  await FirebaseStorage.instance.useStorageEmulator(_emulatorHost, _storagePort);
  _emulatorsConfigured = true;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _configureFirebaseEmulatorsIfNeeded();

  FirebaseMessaging.onBackgroundMessage(
    FcmService.firebaseMessagingBackgroundHandler,
  );

  await AuthService.instance.init();

  void attachFirestoreForUser(User? user) {
    if (user == null) {
      JobService.instance.stopListening();
      AdminDataService.instance.stopListening();
      ChatService.instance.stopThreadsListener();
      return;
    }
    JobService.instance.startListening();
    AdminDataService.instance.startListening();
    ChatService.instance.startThreadsListener();
    FcmService.instance.syncTokenForCurrentUser();
  }

  FirebaseAuth.instance.authStateChanges().listen(attachFirestoreForUser);

  attachFirestoreForUser(FirebaseAuth.instance.currentUser);

  await AppSettingsController.instance.load();

  runApp(const QonsudanXidmetApp());

  WidgetsBinding.instance.addPostFrameCallback((_) {
    FcmService.instance.attachForegroundNotifications(rootScaffoldMessengerKey);
    NotificationService.instance.attachTapNavigation();
  });
}
