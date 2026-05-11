import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/favorite_worker_record.dart';

class FavoriteWorkersService {
  FavoriteWorkersService._();
  static final FavoriteWorkersService instance = FavoriteWorkersService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Stream<List<FavoriteWorkerRecord>> favoritesStream() {
    final uid = _uid;
    if (uid == null) {
      return const Stream.empty();
    }
    return _db
        .collection('users')
        .doc(uid)
        .collection('favorite_workers')
        .snapshots()
        .map(
          (s) => s.docs
              .map(FavoriteWorkerRecord.fromDoc)
              .toList()
            ..sort((a, b) {
              final ta = a.savedAt;
              final tb = b.savedAt;
              if (ta == null && tb == null) return 0;
              if (ta == null) return 1;
              if (tb == null) return -1;
              return tb.compareTo(ta);
            }),
        );
  }

  Future<void> addFavorite(String workerUid) async {
    final uid = _uid;
    if (uid == null) throw StateError('Giriş tapılmadı');
    if (workerUid == uid) {
      throw StateError('Özünüzü seçilmişə əlavə edə bilməzsiniz');
    }
    final w = await _db.collection('workers').doc(workerUid).get();
    if (!w.exists) throw StateError('İcraçı tapılmadı');
    final u = await _db.collection('users').doc(workerUid).get();
    final wd = w.data()!;
    final ud = u.data() ?? {};
    await _db
        .collection('users')
        .doc(uid)
        .collection('favorite_workers')
        .doc(workerUid)
        .set({
      'workerId': workerUid,
      'displayName': wd['displayName'] as String? ?? 'İcraçı',
      'skills': wd['skills'] ?? [],
      'photoUrl': ud['photoUrl'],
      'savedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeFavorite(String workerUid) async {
    final uid = _uid;
    if (uid == null) throw StateError('Giriş tapılmadı');
    await _db
        .collection('users')
        .doc(uid)
        .collection('favorite_workers')
        .doc(workerUid)
        .delete();
  }
}
