import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter/foundation.dart';

import '../models/chat_message.dart';
import '../models/chat_thread.dart';
import '../models/user_role.dart';
import 'auth_service.dart';
import 'job_service.dart';

/// Real-time Firestore chats + messages.
class ChatService extends ChangeNotifier {
  ChatService._();
  static final ChatService instance = ChatService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static void _logFirestore(String action, String detail) {
    final uid = AuthService.instance.firebaseUser?.uid ?? '(null)';
    final role = AuthService.instance.profile?.role ?? '(no-profile)';
    debugPrint('[FirestoreAccess] $action | uid=$uid role=$role | $detail');
  }

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _threadSub;
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
      _msgSubs = {};

  List<ChatThread> _threads = [];
  final Map<String, List<ChatMessage>> _messages = {};

  List<ChatThread> get threads => List.unmodifiable(_threads);

  List<ChatMessage> messagesFor(String threadId) {
    return List.unmodifiable(_messages[threadId] ?? const []);
  }

  ChatThread? threadById(String id) {
    try {
      return _threads.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<ChatThread?> fetchThread(String id) async {
    final cached = threadById(id);
    if (cached != null) return cached;
    final uid = AuthService.instance.firebaseUser?.uid;
    debugPrint('[ChatService] fetchThread chatId=$id uid=$uid');
    final d = await _db.collection('chats').doc(id).get();
    if (!d.exists) {
      debugPrint('[ChatService] fetchThread: doc missing');
      return null;
    }
    final parts = List<String>.from(d.data()?['participantIds'] ?? const []);
    if (uid == null || !parts.contains(uid)) {
      debugPrint('[ChatService] fetchThread: uid not in participantIds');
      return null;
    }
    return ChatThread.fromFirestore(d);
  }

  void startThreadsListener() {
    final uid = AuthService.instance.firebaseUser?.uid;
    _threadSub?.cancel();
    _threads = [];
    if (uid == null) {
      debugPrint('[ChatService] startThreadsListener: no uid, skip');
      notifyListeners();
      return;
    }

    debugPrint('[ChatService] startThreadsListener uid=$uid');

    /// `orderBy` + `array-contains` tələb etdiyi indeks olmadan boş siyahı verə bilər —
    /// sorğunu sadələşdirib sıralamanı müştəridə edirik.
    _threadSub = _db
        .collection('chats')
        .where('participantIds', arrayContains: uid)
        .snapshots()
        .listen(
      (snap) {
        final list = snap.docs.map(ChatThread.fromFirestore).toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        _threads = list;
        _logFirestore('threadsSnapshot', 'count=${_threads.length} chatIds=${list.map((e) => e.id).join(",")}');
        notifyListeners();
      },
      onError: (Object e, StackTrace st) {
        debugPrint('[ChatService] threads stream ERROR uid=$uid err=$e');
        debugPrint('$st');
        _threads = [];
        notifyListeners();
      },
    );
  }

  void stopThreadsListener() {
    _threadSub?.cancel();
    _threadSub = null;
    for (final s in _msgSubs.values) {
      s.cancel();
    }
    _msgSubs.clear();
    _messages.clear();
    _threads = [];
    notifyListeners();
  }

  void ensureMessagesSubscription(String threadId) {
    if (_msgSubs.containsKey(threadId)) return;
    debugPrint('[ChatService] ensureMessagesSubscription threadId=$threadId');
    _msgSubs[threadId] = messagesQuery(threadId).snapshots().listen(
      (snap) {
        _messages[threadId] =
            snap.docs.map((d) => ChatMessage.fromDoc(d, threadId)).toList();
        notifyListeners();
      },
      onError: (Object e, StackTrace st) {
        debugPrint('[ChatService] messages stream ERROR threadId=$threadId err=$e');
        debugPrint('$st');
      },
    );
  }

  /// Real-vaxt mesaj axını ([StreamBuilder] üçün).
  Stream<QuerySnapshot<Map<String, dynamic>>> messagesSnapshots(
    String threadId,
  ) {
    return messagesQuery(threadId).snapshots();
  }

  Query<Map<String, dynamic>> messagesQuery(String threadId) {
    return _db
        .collection('chats')
        .doc(threadId)
        .collection('messages')
        .orderBy('timestamp');
  }

  /// Qarşı tərəfdən gələn son mesajları «oxundu» kimi işarələyir (`readBy`).
  Future<void> markPeerMessagesRead(String threadId, String viewerUid) async {
    final snap = await _db
        .collection('chats')
        .doc(threadId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .get();

    WriteBatch batch = _db.batch();
    var pending = 0;

    for (final doc in snap.docs) {
      final data = doc.data();
      if (data['senderId'] == viewerUid) continue;
      final rb = List<String>.from(data['readBy'] ?? []);
      if (rb.contains(viewerUid)) continue;

      batch.update(doc.reference, {
        'readBy': FieldValue.arrayUnion([viewerUid]),
      });
      pending++;

      if (pending >= 450) {
        await batch.commit();
        batch = _db.batch();
        pending = 0;
      }
    }
    if (pending > 0) await batch.commit();
  }

  void cancelMessagesSubscription(String threadId) {
    _msgSubs[threadId]?.cancel();
    _msgSubs.remove(threadId);
    _messages.remove(threadId);
  }

  Future<String> createThreadFromWorkerOffer({
    required String jobId,
    required double offerAmount,
  }) async {
    final job = JobService.instance.getById(jobId);
    if (job == null) {
      throw StateError('Elan tapılmadı');
    }
    final ownerId = job.createdBy;
    if (ownerId == null) throw StateError('Yaradıcı tapılmadı');

    final workerId = AuthService.instance.firebaseUser!.uid;
    if (workerId == ownerId) {
      throw StateError('Öz elanına təklif göndərə bilməzsiniz');
    }

    final workerProfile = AuthService.instance.profile!;
    final chatId = '${jobId}_$workerId';

    final priceStr = offerAmount == offerAmount.roundToDouble()
        ? offerAmount.toStringAsFixed(0)
        : offerAmount.toStringAsFixed(2);

    final msgText =
        'Salam! «${job.title}» elanı üçün təklifim: $priceStr ₼. Ətraflı danışa bilərik?';

    final chatRef = _db.collection('chats').doc(chatId);
    final ownerSnap = await _db.collection('users').doc(ownerId).get();
    final ownerPhoto = ownerSnap.data()?['photoUrl'] as String?;
    final workerPhoto = workerProfile.photoUrl;

    final msgRef = chatRef.collection('messages').doc();
    final notifRef = _db
        .collection('users')
        .doc(ownerId)
        .collection('in_app_notifications')
        .doc();

    _logFirestore(
      'createThreadFromWorkerOffer',
      'tx: chats/$chatId + messages/* + jobs/$jobId/applications/$workerId + '
          'users/$ownerId/in_app_notifications/*',
    );

    try {
      // `chats` və `messages` eyni tranzaksiyada olanda qaydalar `messages` üçün
      // `exists(chats/...)` / `get(chats/...)` hələ yeni sənədi görmür → permission-denied.
      // Əvvəl söhbət sənədi commit olunur, sonra ilk mesaj yazılır.
      var isNewChat = false;
      await _db.runTransaction((tx) async {
        final existing = await tx.get(chatRef);
        isNewChat = !existing.exists;

        if (isNewChat) {
          tx.set(chatRef, {
            'jobId': jobId,
            'userId': ownerId,
            'workerId': workerId,
            'participantIds': <String>[ownerId, workerId],
            'jobTitle': job.title,
            'jobShortDescription': job.shortDescription,
            'jobPriceAzn': job.priceAzn,
            'ownerName': job.posterName,
            'workerName': workerProfile.displayName.isEmpty
                ? 'İcraçı'
                : workerProfile.displayName,
            if (ownerPhoto != null && ownerPhoto.isNotEmpty)
              'ownerPhotoUrl': ownerPhoto,
            if (workerPhoto != null && workerPhoto.isNotEmpty)
              'workerPhotoUrl': workerPhoto,
            'lastMessageAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'lastMessageText': msgText,
            'lastMessage': msgText,
            'unreadOwner': 1,
            'unreadWorker': 0,
          });

          tx.set(notifRef, {
            'type': 'job_offer',
            'fromUid': workerId,
            'jobId': jobId,
            'title': job.title,
            'body': 'Yeni təklif: $priceStr ₼',
            'createdAt': FieldValue.serverTimestamp(),
            'read': false,
          });
        }

        tx.set(
          _db
              .collection('jobs')
              .doc(jobId)
              .collection('applications')
              .doc(workerId),
          {
            'workerId': workerId,
            'offerAmount': offerAmount,
            'createdAt': FieldValue.serverTimestamp(),
            'status': 'pending',
          },
          SetOptions(merge: true),
        );
      });

      if (isNewChat) {
        await msgRef.set({
          'senderId': workerId,
          'text': msgText,
          'timestamp': FieldValue.serverTimestamp(),
          'readBy': <String>[workerId],
        });
      }
    } catch (e, st) {
      final detail = e is FirebaseException
          ? '${e.code} ${e.message}'
          : '$e';
      _logFirestore('createThreadFromWorkerOffer FAILED', detail);
      debugPrint('$st');
      rethrow;
    }

    _logFirestore('createThreadFromWorkerOffer OK', 'chatId=$chatId');
    return chatId;
  }

  Future<void> sendText({
    required String threadId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final uid = AuthService.instance.firebaseUser!.uid;
    final chatRef = _db.collection('chats').doc(threadId);
    final snap = await chatRef.get();
    if (!snap.exists) return;
    final data = snap.data()!;
    final ownerId = data['userId'] as String? ?? '';
    final isOwner = uid == ownerId;

    final msgRef = chatRef.collection('messages').doc();
    final preview =
        trimmed.length > 120 ? '${trimmed.substring(0, 117)}…' : trimmed;

    final recipientId = isOwner ? data['workerId'] as String? ?? '' : ownerId;
    final notifRef = recipientId.isNotEmpty && recipientId != uid
        ? _db
            .collection('users')
            .doc(recipientId)
            .collection('in_app_notifications')
            .doc()
        : null;

    _logFirestore(
      'sendText',
      'tx: chats/$threadId/messages/* update chats/$threadId',
    );

    try {
      await _db.runTransaction((tx) async {
      tx.set(msgRef, {
        'senderId': uid,
        'text': trimmed,
        'timestamp': FieldValue.serverTimestamp(),
        'readBy': [uid],
      });

      tx.update(chatRef, {
        'lastMessageAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessageText': preview,
        'lastMessage': preview,
        if (isOwner) 'unreadWorker': FieldValue.increment(1),
        if (!isOwner) 'unreadOwner': FieldValue.increment(1),
      });

      if (notifRef != null) {
        tx.set(notifRef, {
          'type': 'chat_message',
          'fromUid': uid,
          'jobId': data['jobId'] as String? ?? '',
          'title': data['jobTitle'] as String? ?? 'Mesaj',
          'body': preview,
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
        });
        debugPrint(
          '[ChatService] sendText in-app notif → $recipientId chat=$threadId',
        );
      }
    });
    } catch (e, st) {
      _logFirestore('sendText FAILED', '$e');
      debugPrint('$st');
      rethrow;
    }
  }

  Future<void> markRead(String threadId, UserRole viewerRole) async {
    final uid = AuthService.instance.firebaseUser?.uid;
    if (uid == null) return;

    final chatRef = _db.collection('chats').doc(threadId);
    final isOwner = viewerRole == UserRole.user;
    await chatRef.update({
      if (isOwner) 'unreadOwner': 0,
      if (!isOwner) 'unreadWorker': 0,
    });

    final local = threadById(threadId);
    if (local != null) {
      if (isOwner) {
        local.unreadForOwner = 0;
      } else {
        local.unreadForWorker = 0;
      }
      notifyListeners();
    }
  }

  int unreadCount(UserRole viewerRole) {
    return _threads.fold<int>(0, (total, t) {
      final n = viewerRole == UserRole.user
          ? t.unreadForOwner
          : t.unreadForWorker;
      return total + n;
    });
  }
}
