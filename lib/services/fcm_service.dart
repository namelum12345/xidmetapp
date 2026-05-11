import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../firebase_options.dart';
import 'auth_service.dart';

/// FCM icazəsi, token sinxronu və ön plan bildirişləri.
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static bool _foregroundAttached = false;
  static bool _tokenRefreshAttached = false;

  /// Arxa planda mesaj üçün Firebase init (Android/iOS).
  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }

  /// Ön planda gələn bildirişlər üçün SnackBar (web-də məhdud dəstək).
  void attachForegroundNotifications(
    GlobalKey<ScaffoldMessengerState> messengerKey,
  ) {
    if (_foregroundAttached) return;
    _foregroundAttached = true;

    FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
      final n = msg.notification;
      final text = switch ((n?.title, n?.body)) {
        (final t?, final b?) => '$t: $b',
        (final t?, null) => t,
        (null, final b?) => b,
        _ => msg.data['title']?.toString() ??
            msg.data['body']?.toString() ??
            'Bildiriş',
      };

      final ctx = messengerKey.currentContext;
      if (ctx != null && ctx.mounted) {
        ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(
          SnackBar(
            content: Text(text),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  Future<void> syncTokenForCurrentUser() async {
    final uid = AuthService.instance.firebaseUser?.uid;
    if (uid == null) return;

    try {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final token = await _messaging.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set(
              {'fcmToken': token},
              SetOptions(merge: true),
            );
      }
    } catch (_) {
      // Web üçün VAPID və ya icazə olmadıqda sus.
    }

    if (!_tokenRefreshAttached) {
      _tokenRefreshAttached = true;
      FirebaseMessaging.instance.onTokenRefresh.listen((t) async {
        final u = AuthService.instance.firebaseUser?.uid;
        if (u == null) return;
        try {
          await FirebaseFirestore.instance.collection('users').doc(u).set(
                {'fcmToken': t},
                SetOptions(merge: true),
              );
        } catch (_) {}
      });
    }
  }
}
