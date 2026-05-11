import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/favorite_worker_record.dart';
import '../../services/favorite_workers_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/gradient_primary_button.dart';

class ProfileFavoriteWorkersScreen extends StatelessWidget {
  const ProfileFavoriteWorkersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Seçilmiş işçilər'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: StreamBuilder<List<FavoriteWorkerRecord>>(
        stream: FavoriteWorkersService.instance.favoritesStream(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data!;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: SizedBox(
                  width: double.infinity,
                  child: GradientPrimaryButton(
                    label: 'İcraçı əlavə et',
                    onPressed: () => _pickWorkerToAdd(context),
                  ),
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? Center(
                        child: Text(
                          'Hələ seçilmiş işçi yoxdur',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: list.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final w = list[i];
                          return AppCard(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor:
                                      AppColors.primary.withValues(alpha: 0.12),
                                  backgroundImage: w.photoUrl != null &&
                                          w.photoUrl!.isNotEmpty
                                      ? NetworkImage(w.photoUrl!)
                                      : null,
                                  child: w.photoUrl == null || w.photoUrl!.isEmpty
                                      ? const Icon(Icons.person_rounded,
                                          color: AppColors.primary)
                                      : null,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        w.displayName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(fontWeight: FontWeight.w800),
                                      ),
                                      if (w.skills.isNotEmpty)
                                        Text(
                                          w.skills.take(4).join(' • '),
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
                                IconButton(
                                  tooltip: 'Sil',
                                  onPressed: () async {
                                    final ok = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Silinsin?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text('Ləğv'),
                                          ),
                                          FilledButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: const Text('Sil'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (ok == true) {
                                      await FavoriteWorkersService.instance
                                          .removeFavorite(w.workerId);
                                    }
                                  },
                                  icon: const Icon(Icons.delete_outline_rounded),
                                  color: const Color(0xFFDC2626),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  static Future<void> _pickWorkerToAdd(BuildContext context) async {
    final snap = await FirebaseFirestore.instance
        .collection('workers')
        .limit(50)
        .get();
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          maxChildSize: 0.9,
          builder: (ctx, scroll) {
            return ListView.builder(
              controller: scroll,
              padding: const EdgeInsets.all(16),
              itemCount: snap.docs.length,
              itemBuilder: (ctx, i) {
                final d = snap.docs[i];
                final m = d.data();
                final name = m['displayName'] as String? ?? d.id;
                return ListTile(
                  leading: const Icon(Icons.engineering_outlined),
                  title: Text(name),
                  subtitle: Text(
                    List<String>.from(m['skills'] ?? const []).join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      await FavoriteWorkersService.instance.addFavorite(d.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Əlavə edildi')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$e')),
                        );
                      }
                    }
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
