import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/user_role.dart';
import '../../router/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';

/// Bildirişlər: in-app + oxunmamış söhbətlər.
class ProfileNotificationsScreen extends StatelessWidget {
  const ProfileNotificationsScreen({super.key, required this.viewerRole});

  final UserRole viewerRole;

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.firebaseUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Giriş tapılmadı')));
    }

    final notifStream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('in_app_notifications')
        .orderBy('createdAt', descending: true)
        .limit(60)
        .snapshots();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bildirişlər'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListenableBuilder(
        listenable: ChatService.instance,
        builder: (context, _) {
          final unreadThreads = ChatService.instance.threads.where((t) {
            final n = viewerRole == UserRole.user
                ? t.unreadForOwner
                : t.unreadForWorker;
            return n > 0;
          }).toList();

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: notifStream,
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(child: Text('${snap.error}'));
              }
              final docs = snap.data?.docs ?? [];

              if (docs.isEmpty && unreadThreads.isEmpty) {
                return Center(
                  child: Text(
                    'Bildiriş yoxdur',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (unreadThreads.isNotEmpty) ...[
                    Text(
                      'Oxunmamış mesajlar',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 10),
                    ...unreadThreads.map((t) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              context.push(
                                AppRoutes.chat(t.id),
                                extra: viewerRole,
                              );
                            },
                            child: AppCard(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t.peerNameForViewer(viewerRole),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        if (t.lastMessageText != null)
                                          Text(
                                            t.lastMessageText!,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                  ],
                  if (docs.isNotEmpty) ...[
                    Text(
                      'Elan və yeniləmələr',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 10),
                    ...docs.map((d) {
                      final m = d.data();
                      final type = m['type'] as String? ?? '';
                      final title = m['title'] as String? ?? '';
                      final body = m['body'] as String? ?? '';
                      final jobId = m['jobId'] as String? ?? '';
                      final read = m['read'] == true;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Dismissible(
                          key: Key(d.id),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) =>
                              d.reference.delete(),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: const Color(0xFFDC2626),
                            child: const Icon(Icons.delete_outline, color: Colors.white),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () async {
                                if (!read) {
                                  await d.reference.update({'read': true});
                                }
                                if (jobId.isNotEmpty && context.mounted) {
                                  context.push(
                                    AppRoutes.jobDetail(jobId),
                                    extra: viewerRole,
                                  );
                                }
                              },
                              child: AppCard(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      type == 'job_offer'
                                          ? Icons.local_offer_outlined
                                          : Icons.notifications_outlined,
                                      color: read
                                          ? AppColors.textSecondary
                                          : AppColors.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                                  fontWeight: read
                                                      ? FontWeight.w600
                                                      : FontWeight.w800,
                                                ),
                                          ),
                                          if (body.isNotEmpty)
                                            Text(
                                              body,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: AppColors.textSecondary,
                                                  ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (!read)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(top: 4),
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}
