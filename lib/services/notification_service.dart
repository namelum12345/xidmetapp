import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../router/app_routes.dart';
import '../router/app_router.dart' show appRouter;
import 'auth_service.dart';
import 'role_router_service.dart';

/// FCM ilə bildirişə toxunulduqda marshrutlaşdırma (chat / elan).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  bool _attached = false;

  /// `runApp`-dan sonra çağırın (bir dəfə).
  void attachTapNavigation() {
    if (_attached) return;
    _attached = true;

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage msg) {
      _scheduleNav(msg.data);
    });

    unawaited(_handleInitialMessage());
  }

  Future<void> _handleInitialMessage() async {
    final msg = await FirebaseMessaging.instance.getInitialMessage();
    if (msg != null) _scheduleNav(msg.data);
  }

  void _scheduleNav(Map<String, dynamic> data) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigateFromPayload(data);
    });
  }

  /// Data payload ilə marshrut (testlər üçün də açıqdır).
  void navigateFromPayload(Map<String, dynamic> data) {
    if (AuthService.instance.firebaseUser == null) return;

    final kind = data['kind']?.toString();
    if (kind == 'new_message') {
      final threadId = data['threadId']?.toString();
      if (threadId == null || threadId.isEmpty) return;
      final role = RoleRouterService.marketplaceViewerRole(
        AuthService.instance.profile,
      );
      appRouter.push(AppRoutes.chat(threadId), extra: role);
      return;
    }

    if (kind == 'new_job') {
      final jobId = data['jobId']?.toString();
      if (jobId == null || jobId.isEmpty) return;
      final role = RoleRouterService.marketplaceViewerRole(
        AuthService.instance.profile,
      );
      appRouter.push(AppRoutes.jobDetail(jobId), extra: role);
    }
  }
}
