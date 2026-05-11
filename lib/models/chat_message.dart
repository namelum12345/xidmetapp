import 'package:cloud_firestore/cloud_firestore.dart';

/// Chat line item (Firestore `messages` subcollection).
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.threadId,
    required this.text,
    required this.sentAt,
    required this.senderId,
    this.readBy = const [],
  });

  final String id;
  final String threadId;
  final String text;
  final DateTime sentAt;
  final String senderId;
  final List<String> readBy;

  factory ChatMessage.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String threadId,
  ) {
    final m = doc.data() ?? {};
    final ts = m['timestamp'];
    final rb = m['readBy'];
    return ChatMessage(
      id: doc.id,
      threadId: threadId,
      text: m['text'] as String? ?? '',
      sentAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      senderId: m['senderId'] as String? ?? '',
      readBy: rb is List ? rb.map((e) => '$e').toList() : const [],
    );
  }

  bool isMine(String? uid) => uid != null && senderId == uid;
}
