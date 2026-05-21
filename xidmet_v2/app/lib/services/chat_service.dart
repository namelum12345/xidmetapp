import '../models/models.dart';
import 'api_service.dart';

class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  Future<List<ChatThreadModel>> getThreads() async {
    final resp = await ApiService.instance.get('/chats');
    return (resp as List).map((t) => ChatThreadModel.fromJson(t)).toList();
  }

  Future<List<ChatMessageModel>> getMessages(String threadId) async {
    final resp = await ApiService.instance.get('/chats/$threadId/messages');
    return (resp as List).map((m) => ChatMessageModel.fromJson(m)).toList();
  }

  Future<Map<String, dynamic>> sendMessage({
    required String text,
    String? threadId,
    String? otherUserId,
    String? listingId,
  }) async {
    final resp = await ApiService.instance.post('/chats/send', {
      'text': text,
      if (threadId != null) 'thread_id': threadId,
      if (otherUserId != null) 'other_user_id': otherUserId,
      if (listingId != null) 'listing_id': listingId,
    });
    return resp as Map<String, dynamic>;
  }
}
