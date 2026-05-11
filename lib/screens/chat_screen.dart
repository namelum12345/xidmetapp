import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/chat_message.dart';
import '../models/chat_thread.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../theme/app_colors.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/job_mini_card.dart';
import '../widgets/message_input.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.threadId,
    required this.viewerRole,
    this.readOnly = false,
  });

  final String threadId;
  final UserRole viewerRole;

  /// Admin monitorinq — mesaj göndərmə əlçatmaz.
  final bool readOnly;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  ChatThread? _resolvedThread;
  var _threadLoadDone = false;
  Timer? _seenDebounce;

  /// Mesaj siyahısı dəyişəndə scroll (hər snapshot-da təkrarlamamaq üçün).
  String _lastScrollDigest = '';

  void _scrollToBottom({bool animated = true}) {
    if (!_scroll.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients || !mounted) return;
      final target = _scroll.position.maxScrollExtent;
      if (!animated) {
        _scroll.jumpTo(target);
        return;
      }
      _scroll.animateTo(
        target,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _debouncedMarkPeerRead(String myUid) {
    if (widget.readOnly || myUid.isEmpty) return;
    _seenDebounce?.cancel();
    _seenDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      ChatService.instance.markPeerMessagesRead(widget.threadId, myUid);
    });
  }

  @override
  void initState() {
    super.initState();
    final me = AuthService.instance.firebaseUser?.uid;
    debugPrint('[ChatScreen] init threadId=${widget.threadId} uid=$me role=${widget.viewerRole}');
    ChatService.instance.ensureMessagesSubscription(widget.threadId);
    _resolveThread();
  }

  Future<void> _resolveThread() async {
    var t = ChatService.instance.threadById(widget.threadId);
    t ??= await ChatService.instance.fetchThread(widget.threadId);
    debugPrint(
      '[ChatScreen] _resolveThread threadId=${widget.threadId} found=${t != null}',
    );
    if (!mounted) return;
    setState(() {
      _resolvedThread = t;
      _threadLoadDone = true;
    });
    if (!widget.readOnly && t != null) {
      await ChatService.instance.markRead(widget.threadId, widget.viewerRole);
    }
    _scrollToBottom(animated: false);
  }

  @override
  void dispose() {
    ChatService.instance.cancelMessagesSubscription(widget.threadId);
    _seenDebounce?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (widget.readOnly) return;
    try {
      await ChatService.instance.sendText(
        threadId: widget.threadId,
        text: _input.text,
      );
      _input.clear();
      _scrollToBottom();
    } catch (e, st) {
      debugPrint('[ChatScreen] send FAILED $e');
      debugPrint('$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Göndərilmədi: $e')),
        );
      }
    }
  }

  String _timeLabel(DateTime t) {
    return DateFormat('HH:mm').format(t);
  }

  String _priceLine(double? p) {
    if (p == null) return 'Razılaşma ilə';
    return '${p.toStringAsFixed(0)} ₼';
  }

  String _peerUid(ChatThread thread) {
    return widget.viewerRole == UserRole.user
        ? thread.workerUserId
        : thread.ownerUserId;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: ChatService.instance,
      builder: (context, _) {
        final thread = ChatService.instance.threadById(widget.threadId) ??
            _resolvedThread;
        if (thread == null) {
          if (!_threadLoadDone) {
            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => context.pop(),
                ),
                title: const Text('Söhbət'),
              ),
              body: const Center(child: CircularProgressIndicator()),
            );
          }
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.pop(),
              ),
              title: const Text('Söhbət'),
            ),
            body: Center(
              child: Text(
                'Söhbət tapılmadı',
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          );
        }

        final uid = AuthService.instance.firebaseUser?.uid;
        final peer = thread.peerNameForViewer(widget.viewerRole);
        final peerUid = _peerUid(thread);
        final online = thread.peerOnline;

        final headerTitle =
            widget.readOnly ? thread.jobTitle : peer;
        final headerSubtitle = widget.readOnly
            ? '${thread.ownerName} • ${thread.workerName}'
            : (online ? 'İndi aktiv' : 'Oflayn');

        return Scaffold(
          backgroundColor: AppColors.background,
          resizeToAvoidBottomInset: !widget.readOnly,
          body: Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: AppColors.textPrimary,
                      ),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.15),
                        child: widget.readOnly
                            ? Icon(
                                Icons.admin_panel_settings_outlined,
                                color: AppColors.primary,
                                size: 22,
                              )
                            : Text(
                                peer.isNotEmpty
                                    ? peer[0].toUpperCase()
                                    : '?',
                                style: textTheme.titleMedium?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              headerTitle,
                              maxLines: widget.readOnly ? 2 : 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (widget.readOnly)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Monitorinq (yalnız oxu)',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            else
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: online
                                          ? AppColors.matchBadge
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      headerSubtitle,
                                      style: textTheme.labelMedium?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            if (widget.readOnly)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  headerSubtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.labelSmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: ChatService.instance.messagesSnapshots(
                    widget.threadId,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];
                    final messages = docs
                        .map(
                          (d) =>
                              ChatMessage.fromDoc(d, widget.threadId),
                        )
                        .toList();

                    if (!widget.readOnly && uid != null) {
                      final hasUnreadPeer = messages.any(
                        (m) =>
                            m.senderId != uid && !m.readBy.contains(uid),
                      );
                      if (hasUnreadPeer) {
                        _debouncedMarkPeerRead(uid);
                      }
                    }

                    final digest =
                        '${messages.length}:${messages.isEmpty ? '' : messages.last.id}';
                    if (digest != _lastScrollDigest) {
                      _lastScrollDigest = digest;
                      _scrollToBottom();
                    }

                    return ListView(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      children: [
                        JobMiniCard(
                          title: thread.jobTitle,
                          shortDescription: thread.jobShortDescription,
                          priceLine: _priceLine(thread.jobPriceAzn),
                        ),
                        const SizedBox(height: 20),
                        ...messages.map(
                          (m) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: ChatBubble(
                                key: ValueKey(m.id),
                                text: m.text,
                                isSent: widget.readOnly
                                    ? m.senderId == thread.workerUserId
                                    : m.isMine(uid),
                                timeLabel: _timeLabel(m.sentAt),
                                seenByPeer: widget.readOnly
                                    ? false
                                    : m.isMine(uid) &&
                                        m.readBy.contains(peerUid),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              if (widget.readOnly)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 12,
                    bottom: MediaQuery.paddingOf(context).bottom + 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        color: AppColors.primary.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Bu söhbət yalnız izlənilir — mesaj göndərilmir.',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                MessageInput(
                  controller: _input,
                  onSend: () {
                    _send();
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
