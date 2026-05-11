import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth_service.dart';

/// Centralized admin/superadmin action logger.
class AdminLogService {
  AdminLogService._();
  static final AdminLogService instance = AdminLogService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> log({
    required String action,
    String? targetId,
    Map<String, dynamic>? extra,
  }) async {
    final auth = AuthService.instance;
    final performedBy = auth.firebaseUser?.uid ?? 'unknown';
    await _db.collection('logs').add({
      'action': action,
      'performedBy': performedBy,
      'targetId': targetId ?? '',
      'timestamp': FieldValue.serverTimestamp(),
      if (extra != null) ...extra,
    });
  }
}
