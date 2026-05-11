import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'admin_log_service.dart';
import 'auth_service.dart';

class SuperadminControlService {
  SuperadminControlService._();
  static final SuperadminControlService instance = SuperadminControlService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _fn = FirebaseFunctions.instance;

  /// `orderBy` + çatışmayan `createdAt` bəzi sənədləri çıxara bilər; sıralama UI-da.
  Stream<QuerySnapshot<Map<String, dynamic>>> usersStream() {
    return _db.collection('users').limit(2000).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> adminsStream() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'admin')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> createAdmin({
    required String name,
    required String email,
    required String password,
  }) async {
    final callable = _fn.httpsCallable('createAdminUserBySuperadmin');
    await callable.call({
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
    });
    await AdminLogService.instance.log(
      action: 'create_admin',
      targetId: email.trim().toLowerCase(),
    );
  }

  Future<void> deleteAdmin(String uid) async {
    final callable = _fn.httpsCallable('deleteUserBySuperadmin');
    await callable.call({'uid': uid});
    await AdminLogService.instance.log(action: 'delete_admin', targetId: uid);
  }

  Future<void> deleteUser(String uid) async {
    final callable = _fn.httpsCallable('deleteUserBySuperadmin');
    await callable.call({'uid': uid});
    await AdminLogService.instance.log(action: 'delete_user', targetId: uid);
  }

  Future<void> toggleBlocked({
    required String uid,
    required bool blocked,
  }) async {
    await _db.collection('users').doc(uid).update({
      'isBlocked': blocked,
      'banned': blocked,
    });
    await AdminLogService.instance.log(
      action: blocked ? 'block_user' : 'unblock_user',
      targetId: uid,
    );
  }

  Future<void> changeRole({
    required String uid,
    required String fromRole,
    required String toRole,
  }) async {
    if (toRole == 'superadmin') {
      throw StateError('superadmin rolu təyin etmək qadağandır');
    }
    if (fromRole == 'superadmin' || fromRole == 'super_admin') {
      throw StateError('superadmin rolu dəyişdirilə bilməz');
    }
    await _db.collection('users').doc(uid).update({'role': toRole});
    await AdminLogService.instance.log(
      action: 'change_role',
      targetId: uid,
      extra: {'fromRole': fromRole, 'toRole': toRole},
    );
  }

  String currentActorUid() => AuthService.instance.firebaseUser?.uid ?? 'unknown';
}
