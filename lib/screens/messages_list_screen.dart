import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/user_role.dart';
import '../router/app_routes.dart';
import '../services/chat_service.dart';
import '../theme/app_colors.dart';
import '../widgets/chat_list_item.dart';

class MessagesListScreen extends StatelessWidget {
  const MessagesListScreen({
    super.key,
    required this.viewerRole,
  });

  final UserRole viewerRole;

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes.clamp(1, 59)} dəq';
    }
    if (now.day == t.day && now.month == t.month && now.year == t.year) {
      final h = t.hour.toString().padLeft(2, '0');
      final m = t.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    return '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')}';
  }

  String _preview(String text) {
    if (text.length <= 80) return text;
    return '${text.substring(0, 77)}…';
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: ListenableBuilder(
        listenable: ChatService.instance,
        builder: (context, _) {
          final service = ChatService.instance;
          final threads = service.threads;
          debugPrint(
            '[MessagesListScreen] viewer=$viewerRole threads=${threads.length}',
          );

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ChatService.instance.startThreadsListener();
              await Future<void>.delayed(const Duration(milliseconds: 300));
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Mesajlar',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
              if (threads.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.forum_outlined,
                            size: 56,
                            color: AppColors.textSecondary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Hələ söhbət yoxdur',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                            const SizedBox(height: 8),
                          Text(
                            'Elana təklif göndərdikdə və ya icraçı ilə əlaqə saxladıqda söhbətlər burada görünəcək.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final thread = threads[index];
                        final msgs = service.messagesFor(thread.id);
                        final last = msgs.isNotEmpty ? msgs.last : null;
                        final preview = thread.lastMessageText ??
                            last?.text ??
                            'Yeni söhbət';
                        final unread = viewerRole == UserRole.user
                            ? thread.unreadForOwner
                            : thread.unreadForWorker;

                        return ChatListItem(
                          thread: thread,
                          lastMessagePreview: _preview(preview),
                          timeLabel: _formatTime(thread.updatedAt),
                          unreadCount: unread,
                          viewerRole: viewerRole,
                          onTap: () {
                            context.push(
                              AppRoutes.chat(thread.id),
                              extra: viewerRole,
                            );
                          },
                        );
                      },
                      childCount: threads.length,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
