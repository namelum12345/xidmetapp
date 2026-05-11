import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/super_admin_models.dart';
import 'admin_data_service.dart';
import 'admin_log_service.dart';
import 'auth_service.dart';
import 'chat_service.dart';
import 'job_service.dart';

/// Global control plane for superadmin (mock — replace with API).
class SuperAdminService extends ChangeNotifier {
  SuperAdminService._();
  static final SuperAdminService instance = SuperAdminService._();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final List<SubAdminRecord> subAdmins = [
    SubAdminRecord(
      id: 'sa1',
      name: 'Polad',
      email: 'polad@system.local',
      role: SubAdminRole.fullAdmin,
      permissions: PermissionSet(),
    ),
    SubAdminRecord(
      id: 'sa2',
      name: 'Dəstək 1',
      email: 'support@system.local',
      role: SubAdminRole.support,
      permissions: PermissionSet(
        manageUsers: true,
        manageWorkers: false,
        manageJobs: false,
        accessChats: true,
        banUsers: false,
      ),
    ),
  ];

  /// Default template for yeni adminlər ([PermissionsScreen] redaktə edir).
  PermissionSet permissionTemplate = PermissionSet();

  double maxRadiusKm = 25;
  final List<String> managedCategories = [
    'Təmizlik',
    'Təmir',
    'Elektrik',
    'Santexnika',
    'Çatdırılma',
  ];
  final List<String> managedSkills = [
    'Ev təmiri',
    'Mebel',
    'Kran',
    'Kondisioner',
  ];

  double commissionPercent = 12;
  bool premiumJobEnabled = true;
  bool workerBoostEnabled = false;

  final List<ComplaintRecord> complaints = [
    ComplaintRecord(
      id: 'c1',
      type: ComplaintTargetType.job,
      title: 'Elan təsviri uyğun deyil',
      reporter: 'user_u1',
      targetId: 'j2',
    ),
    ComplaintRecord(
      id: 'c2',
      type: ComplaintTargetType.worker,
      title: 'Gecikmə',
      reporter: 'user_u2',
      targetId: 'w1',
    ),
    ComplaintRecord(
      id: 'c3',
      type: ComplaintTargetType.user,
      title: 'Sözləşmə pozuntusu',
      reporter: 'worker_w3',
      targetId: 'u1',
    ),
  ];

  final List<AuditLogEntry> auditLogs = [
    AuditLogEntry(
      id: 'l1',
      actor: 'superadmin',
      action: AuditAction.createAdmin,
      detail: 'Admin yaradıldı: Dəstək 1',
      at: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    AuditLogEntry(
      id: 'l2',
      actor: 'Polad',
      action: AuditAction.banUser,
      detail: 'İstifadəçi bloklandı: u_test',
      at: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  /// Dummy chart: son 7 gün aktiv istifadəçi indeksi (0–100).
  final List<double> dailyActiveIndex = [42, 55, 48, 61, 58, 72, 65];

  /// Dummy: ən çox seçilən xidmət adları + faiz.
  final List<(String, double)> topServices = [
    ('Təmizlik', 0.28),
    ('Təmir', 0.22),
    ('Elektrik', 0.18),
    ('Santexnika', 0.15),
  ];

  int get usersCount => AdminDataService.instance.users.length;
  int get workersCount => AdminDataService.instance.workers.length;
  int get jobsCount => JobService.instance.allJobs().length;
  int get chatsCount => ChatService.instance.threads.length;
  int get adminsCount =>
      AdminDataService.instance.users.where((u) => u.roleLabel == 'Admin').length;
  int get bannedTotalCount {
    final bannedUsers =
        AdminDataService.instance.users.where((u) => u.banned).length;
    final blockedWorkers =
        AdminDataService.instance.workers.where((w) => w.disabled).length;
    return bannedUsers + blockedWorkers;
  }

  void addSubAdmin({
    required String name,
    required String email,
    required SubAdminRole role,
  }) {
    final id = 'sa_${DateTime.now().millisecondsSinceEpoch}';
    subAdmins.add(
      SubAdminRecord(
        id: id,
        name: name,
        email: email,
        role: role,
        permissions: permissionTemplate.copy(),
      ),
    );
    _log('superadmin', AuditAction.createAdmin, 'Admin yaradıldı: $name');
    AdminLogService.instance.log(
      action: 'create_admin',
      targetId: id,
      extra: {'name': name, 'email': email},
    );
    notifyListeners();
  }

  /// Mövcud istifadəçini e-poçta görə adminə yüksəldir.
  Future<void> createAdminFromExistingUser({
    required String email,
  }) async {
    final q = await _db
        .collection('users')
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();
    if (q.docs.isEmpty) {
      throw StateError('Bu email ilə istifadəçi tapılmadı');
    }
    final d = q.docs.first;
    await d.reference.update({'role': 'admin'});
    await AdminLogService.instance.log(
      action: 'promote_admin',
      targetId: d.id,
      extra: {'email': email.trim().toLowerCase()},
    );
  }

  /// Sistemdə bir dənə superadmin saxlayır; qalanları admin edir.
  Future<void> enforceSingleSuperadmin({required String keepEmail}) async {
    final all = await _db.collection('users').get();
    final normalizedKeep = keepEmail.trim().toLowerCase();

    DocumentReference<Map<String, dynamic>>? keepRef;
    for (final d in all.docs) {
      final m = d.data();
      final email = (m['email'] as String? ?? '').trim().toLowerCase();
      if (email == normalizedKeep) {
        keepRef = d.reference;
        break;
      }
    }
    if (keepRef == null) {
      throw StateError(
        'Seçilən superadmin email users kolleksiyasında yoxdur: $normalizedKeep',
      );
    }

    final batch = _db.batch();
    batch.update(keepRef, {'role': 'superadmin'});
    for (final d in all.docs) {
      if (d.id == keepRef.id) continue;
      final r = (d.data()['role'] as String? ?? '').trim();
      if (r == 'superadmin' || r == 'super_admin') {
        batch.update(d.reference, {'role': 'admin'});
      }
    }
    await batch.commit();
    await AdminLogService.instance.log(
      action: 'enforce_single_superadmin',
      targetId: keepRef.id,
      extra: {'email': normalizedKeep},
    );
  }

  /// Köhnə/yanlış test dataları təmizləyir.
  Future<void> cleanupLegacyTestData() async {
    final batch = _db.batch();
    final users = await _db.collection('users').get();
    for (final d in users.docs) {
      final m = d.data();
      final email = (m['email'] as String? ?? '').trim().toLowerCase();
      final role = (m['role'] as String? ?? '').trim();
      final invalidRole = !['user', 'worker', 'admin', 'superadmin', 'super_admin']
          .contains(role);
      if (email.endsWith('@test.com') || invalidRole) {
        batch.delete(d.reference);
      }
    }

    final workers = await _db.collection('workers').get();
    for (final w in workers.docs) {
      final u = await _db.collection('users').doc(w.id).get();
      if (!u.exists) batch.delete(w.reference);
    }

    final jobs = await _db.collection('jobs').get();
    for (final j in jobs.docs) {
      final createdBy = (j.data()['createdBy'] as String?) ?? '';
      if (createdBy.isEmpty) {
        batch.delete(j.reference);
        continue;
      }
      final owner = await _db.collection('users').doc(createdBy).get();
      if (!owner.exists) batch.delete(j.reference);
    }

    final chats = await _db.collection('chats').get();
    for (final c in chats.docs) {
      final parts = List<String>.from(c.data()['participantIds'] ?? const []);
      if (parts.length != 2) {
        batch.delete(c.reference);
      }
    }

    final logs = await _db.collection('logs').get();
    for (final l in logs.docs) {
      final action = (l.data()['action'] as String?)?.trim() ?? '';
      if (action.isEmpty) batch.delete(l.reference);
    }
    await batch.commit();
    await AdminLogService.instance.log(action: 'cleanup_legacy_data');
  }

  void deleteSubAdmin(String id) {
    subAdmins.removeWhere((a) => a.id == id);
    _log('superadmin', AuditAction.deleteAdmin, 'Admin silindi: $id');
    AdminLogService.instance.log(action: 'delete_admin', targetId: id);
    notifyListeners();
  }

  void setSubAdminRole(String id, SubAdminRole role) {
    final a = _admin(id);
    if (a != null) {
      a.role = role;
      notifyListeners();
    }
  }

  SubAdminRecord? _admin(String id) {
    for (final a in subAdmins) {
      if (a.id == id) return a;
    }
    return null;
  }

  void updatePermissionTemplate(PermissionSet p) {
    permissionTemplate = p;
    notifyListeners();
  }

  Future<void> globalBanUser(String userId) async {
    await AdminDataService.instance.banUser(userId);
    _log('superadmin', AuditAction.banUser, 'Qlobal blok: user $userId');
    notifyListeners();
  }

  Future<void> globalBanWorker(String workerId) async {
    await AdminDataService.instance.disableWorker(workerId);
    _log('superadmin', AuditAction.banUser, 'Qlobal blok: worker $workerId');
    notifyListeners();
  }

  Future<void> ignoreComplaint(String id) async {
    final c = complaints.where((e) => e.id == id).firstOrNull;
    if (c != null) {
      c.pending = false;
      _log('superadmin', AuditAction.editJob, 'Şikayət rədd: $id');
      await _db
          .collection('complaints')
          .doc(id)
          .set({'pending': false}, SetOptions(merge: true));
      await AdminLogService.instance.log(action: 'ignore_complaint', targetId: id);
      notifyListeners();
    }
  }

  Future<void> takeComplaintAction(String id) async {
    final c = complaints.where((e) => e.id == id).firstOrNull;
    if (c != null) {
      c.pending = false;
      _log('superadmin', AuditAction.editJob, 'Şikayət üzrə tədbir: $id');
      await _db.collection('complaints').doc(id).set({
        'pending': false,
        'resolvedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await AdminLogService.instance.log(action: 'resolve_complaint', targetId: id);
      notifyListeners();
    }
  }

  void setMaxRadius(double km) {
    maxRadiusKm = km;
    AdminLogService.instance.log(
      action: 'set_max_radius',
      extra: {'value': maxRadiusKm},
    );
    notifyListeners();
  }

  void setCommission(double v) {
    commissionPercent = v.clamp(0, 50);
    AdminLogService.instance.log(
      action: 'set_commission',
      extra: {'value': commissionPercent},
    );
    notifyListeners();
  }

  void setPremiumJob(bool v) {
    premiumJobEnabled = v;
    AdminLogService.instance.log(
      action: 'set_premium_job',
      extra: {'value': premiumJobEnabled},
    );
    notifyListeners();
  }

  void setWorkerBoost(bool v) {
    workerBoostEnabled = v;
    AdminLogService.instance.log(
      action: 'set_worker_boost',
      extra: {'value': workerBoostEnabled},
    );
    notifyListeners();
  }

  void backupDummy() {
    _log('superadmin', AuditAction.editJob, 'Backup yaradıldı (dummy)');
    AdminLogService.instance.log(action: 'backup');
    notifyListeners();
  }

  void restoreDummy() {
    _log('superadmin', AuditAction.editJob, 'Restore başladı (dummy)');
    AdminLogService.instance.log(action: 'restore');
    notifyListeners();
  }

  Future<void> sendPushAll(String message) async {
    _log('superadmin', AuditAction.editJob, 'Push (hamısı): $message');
    await _db.collection('notification_queue').add({
      'message': message,
      'workersOnly': false,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': AuthService.instance.firebaseUser?.uid ?? 'unknown',
    });
    await AdminLogService.instance.log(
      action: 'send_push_all',
      extra: {'message': message},
    );
    notifyListeners();
  }

  Future<void> sendPushWorkersOnly(String message) async {
    _log('superadmin', AuditAction.editJob, 'Push (icraçılar): $message');
    await _db.collection('notification_queue').add({
      'message': message,
      'workersOnly': true,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': AuthService.instance.firebaseUser?.uid ?? 'unknown',
    });
    await AdminLogService.instance.log(
      action: 'send_push_workers',
      extra: {'message': message},
    );
    notifyListeners();
  }

  void _log(String actor, AuditAction action, String detail) {
    auditLogs.insert(
      0,
      AuditLogEntry(
        id: 'log_${DateTime.now().microsecondsSinceEpoch}',
        actor: actor,
        action: action,
        detail: detail,
        at: DateTime.now(),
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final i = iterator;
    return i.moveNext() ? i.current : null;
  }
}
