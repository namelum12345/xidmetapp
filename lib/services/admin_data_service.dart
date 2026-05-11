import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/admin_models.dart';
import '../models/job_listing.dart';
import 'admin_log_service.dart';
import 'job_service.dart';

/// Firestore-backed admin lists + job status.
class AdminDataService extends ChangeNotifier {
  AdminDataService._();
  static final AdminDataService instance = AdminDataService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _userSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _workerSub;

  List<AdminUserRecord> users = [];
  List<AdminWorkerRecord> workers = [];

  void startListening() {
    _userSub?.cancel();
    _userSub = _db.collection('users').snapshots().listen(
      (s) {
        users = s.docs.map((d) {
          final m = d.data();
          final role = m['role'] as String? ?? 'user';
          return AdminUserRecord(
            id: d.id,
            name: '${m['name'] ?? ''} ${m['surname'] ?? ''}'.trim().isEmpty
                ? (d.id)
                : '${m['name'] ?? ''} ${m['surname'] ?? ''}'.trim(),
            phone: m['phoneKey'] as String? ?? '',
            roleLabel: _roleLabel(role),
            banned: m['banned'] == true || m['isBlocked'] == true,
          );
        }).toList();
        notifyListeners();
      },
      onError: (_) {
        users = [];
        notifyListeners();
      },
    );

    _workerSub?.cancel();
    _workerSub = _db.collection('workers').snapshots().listen(
      (s) {
        workers = s.docs.map((d) {
          final m = d.data();
          return AdminWorkerRecord(
            id: d.id,
            name: m['displayName'] as String? ?? d.id,
            skills: List<String>.from(m['skills'] ?? []),
            rating: (m['rating'] as num?)?.toDouble() ?? 0,
            approved: m['approved'] != false,
            disabled: m['disabled'] == true,
          );
        }).toList();
        notifyListeners();
      },
      onError: (_) {
        workers = [];
        notifyListeners();
      },
    );
  }

  void stopListening() {
    _userSub?.cancel();
    _workerSub?.cancel();
    _userSub = null;
    _workerSub = null;
  }

  String _roleLabel(String r) {
    return switch (r) {
      'worker' => 'İcraçı',
      'admin' => 'Admin',
      'superadmin' => 'Superadmin',
      'super_admin' => 'Superadmin',
      _ => 'İstifadəçi',
    };
  }

  AdminJobLifecycle lifecycleForJob(String jobId) {
    final j = JobService.instance.getById(jobId);
    if (j == null) return AdminJobLifecycle.active;
    return j.status == 'completed'
        ? AdminJobLifecycle.completed
        : AdminJobLifecycle.active;
  }

  Future<void> setJobLifecycle(String jobId, AdminJobLifecycle v) async {
    await _db.collection('jobs').doc(jobId).update({
      'status': v == AdminJobLifecycle.completed ? 'completed' : 'active',
    });
    await AdminLogService.instance.log(
      action: 'set_job_lifecycle',
      targetId: jobId,
      extra: {'status': v.name},
    );
  }

  List<JobListing> jobsFromCatalog() => JobService.instance.allJobs();

  Future<void> banUser(String id) async {
    await _db.collection('users').doc(id).update({
      'banned': true,
      'isBlocked': true,
    });
    await AdminLogService.instance.log(action: 'ban_user', targetId: id);
  }

  Future<void> deleteUser(String id) async {
    final snap = await _db.collection('users').doc(id).get();
    final phoneKey = snap.data()?['phoneKey'] as String?;
    await _db.collection('users').doc(id).delete();
    await _db.collection('workers').doc(id).delete();
    if (phoneKey != null && phoneKey.isNotEmpty) {
      await _db.collection('login_aliases').doc(phoneKey).delete();
    }
    await AdminLogService.instance.log(action: 'delete_user', targetId: id);
  }

  Future<void> approveWorker(String id) async {
    await _db.collection('workers').doc(id).update({
      'approved': true,
      'disabled': false,
    });
    await AdminLogService.instance.log(action: 'approve_worker', targetId: id);
  }

  Future<void> disableWorker(String id) async {
    await _db.collection('workers').doc(id).update({'disabled': true});
    await AdminLogService.instance.log(action: 'disable_worker', targetId: id);
  }

  Future<void> deleteJob(String jobId) async {
    await JobService.instance.deleteJob(jobId);
    await AdminLogService.instance.log(action: 'delete_job', targetId: jobId);
  }
}
