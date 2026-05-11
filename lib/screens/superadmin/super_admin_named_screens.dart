import 'package:flutter/material.dart';

import 'super_audit_log_screen.dart';
import 'super_monetization_screen.dart';
import 'super_notification_screen.dart';
import 'super_permissions_screen.dart';
import 'super_reports_screen.dart';

export 'ban_management_screen.dart' show BanManagementScreen;

/// Şikayətlər — tam ekran ([Navigator.push] üçün sinif adı).
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SuperReportsScreen();
  }
}

/// Monetizasiya.
class MonetizationScreen extends StatelessWidget {
  const MonetizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SuperMonetizationScreen();
  }
}

/// İcazə şablonu.
class PermissionsScreen extends StatelessWidget {
  const PermissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SuperPermissionsScreen();
  }
}

/// Audit log / sistem jurnalı.
class LogsScreen extends StatelessWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SuperAuditLogScreen();
  }
}

/// Push bildirişlər.
class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SuperNotificationScreen();
  }
}
