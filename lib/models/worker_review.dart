import 'package:cloud_firestore/cloud_firestore.dart';

class WorkerReview {
  const WorkerReview({
    required this.id,
    required this.jobId,
    required this.reviewerName,
    required this.rating,
    required this.comment,
    required this.jobTitle,
    this.createdAt,
  });

  final String id;
  final String jobId;
  final String reviewerName;
  final int rating;
  final String comment;
  final String jobTitle;
  final DateTime? createdAt;

  factory WorkerReview.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    return WorkerReview(
      id: doc.id,
      jobId: d['jobId'] as String? ?? doc.id,
      reviewerName: d['reviewerName'] as String? ?? '',
      rating: (d['rating'] as num?)?.toInt() ?? 0,
      comment: d['comment'] as String? ?? '',
      jobTitle: d['jobTitle'] as String? ?? '',
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}
