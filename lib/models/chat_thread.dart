import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_role.dart';

/// Job-linked chat (`chats/{id}`).
class ChatThread {
  ChatThread({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.jobShortDescription,
    required this.jobPriceAzn,
    required this.ownerName,
    required this.workerName,
    required this.ownerUserId,
    required this.workerUserId,
    this.ownerPhotoUrl,
    this.workerPhotoUrl,
    this.peerOnline = false,
    this.unreadForOwner = 0,
    this.unreadForWorker = 0,
    required this.updatedAt,
    this.lastMessageText,
  });

  final String id;
  final String jobId;
  final String jobTitle;
  final String jobShortDescription;
  final double? jobPriceAzn;
  final String ownerName;
  final String workerName;
  final String ownerUserId;
  final String workerUserId;
  final String? ownerPhotoUrl;
  final String? workerPhotoUrl;
  final bool peerOnline;
  int unreadForOwner;
  int unreadForWorker;
  DateTime updatedAt;

  /// Siyahı önbaxışı üçün (`messages` yüklənməyəndə də işləsin).
  final String? lastMessageText;

  String peerNameForViewer(UserRole appRole) {
    return appRole == UserRole.user ? workerName : ownerName;
  }

  String? peerPhotoUrlForViewer(UserRole appRole) {
    return appRole == UserRole.user ? workerPhotoUrl : ownerPhotoUrl;
  }

  factory ChatThread.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    final lm = d['lastMessageAt'];
    final up = d['updatedAt'];
    DateTime updatedAt;
    if (lm is Timestamp) {
      updatedAt = lm.toDate();
    } else if (up is Timestamp) {
      updatedAt = up.toDate();
    } else {
      updatedAt = DateTime.fromMillisecondsSinceEpoch(0);
    }
    final lastText = (d['lastMessageText'] as String?) ?? (d['lastMessage'] as String?);
    return ChatThread(
      id: doc.id,
      jobId: d['jobId'] as String? ?? '',
      jobTitle: d['jobTitle'] as String? ?? '',
      jobShortDescription: d['jobShortDescription'] as String? ?? '',
      jobPriceAzn: (d['jobPriceAzn'] as num?)?.toDouble(),
      ownerName: d['ownerName'] as String? ?? '',
      workerName: d['workerName'] as String? ?? '',
      ownerUserId: d['userId'] as String? ?? '',
      workerUserId: d['workerId'] as String? ?? '',
      ownerPhotoUrl: d['ownerPhotoUrl'] as String?,
      workerPhotoUrl: d['workerPhotoUrl'] as String?,
      peerOnline: false,
      unreadForOwner: (d['unreadOwner'] as num?)?.toInt() ?? 0,
      unreadForWorker: (d['unreadWorker'] as num?)?.toInt() ?? 0,
      updatedAt: updatedAt,
      lastMessageText: lastText,
    );
  }
}
