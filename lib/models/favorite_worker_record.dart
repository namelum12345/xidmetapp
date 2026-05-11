import 'package:cloud_firestore/cloud_firestore.dart';

/// `users/{uid}/favorite_workers/{workerId}`.
class FavoriteWorkerRecord {
  const FavoriteWorkerRecord({
    required this.workerId,
    required this.displayName,
    required this.skills,
    this.photoUrl,
    this.savedAt,
  });

  final String workerId;
  final String displayName;
  final List<String> skills;
  final String? photoUrl;
  final DateTime? savedAt;

  factory FavoriteWorkerRecord.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    final ts = d['savedAt'];
    return FavoriteWorkerRecord(
      workerId: doc.id,
      displayName: d['displayName'] as String? ?? '',
      skills: List<String>.from(d['skills'] ?? const []),
      photoUrl: d['photoUrl'] as String?,
      savedAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}
