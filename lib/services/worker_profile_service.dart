import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// İcraçı `workers/{uid}` sənədi + sinxron yeniləmələr.
class WorkerProfileService {
  WorkerProfileService._();
  static final WorkerProfileService instance = WorkerProfileService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Stream<DocumentSnapshot<Map<String, dynamic>>> workerDocStream(String uid) {
    return _db.collection('workers').doc(uid).snapshots();
  }

  Future<void> updateMyWorker(Map<String, dynamic> patch) async {
    final uid = _uid;
    if (uid == null) throw StateError('Giriş tapılmadı');
    if (patch.isEmpty) return;
    await _db.collection('workers').doc(uid).update(patch);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> reviewsStreamFor(String workerId) {
    return _db
        .collection('workers')
        .doc(workerId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .limit(80)
        .snapshots();
  }
}
