import 'package:flutter/material.dart';

import '../superadmin/super_reports_screen.dart';

/// Admin üçün şikayətlər (Firestore real-time — eyni UI [SuperReportsScreen]).
class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) => const SuperReportsScreen();
}
