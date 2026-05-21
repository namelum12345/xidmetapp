import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geo;
import '../../router/app_router.dart' show appRouter;

import '../../router/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/job_service.dart';
import '../../services/worker_profile_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/worker/worker_menu_tile.dart';

/// İcraçı hesab menyusu — Firestore `workers` + statistikalar.
class WorkerProfileScreen extends StatefulWidget {
  const WorkerProfileScreen({super.key});

  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen> {
  String? _locationLabel;

  @override
  void initState() {
    super.initState();
    _resolveLocation(AuthService.instance.profile?.location);
  }

  Future<void> _resolveLocation(GeoPoint? point) async {
    if (point == null || !mounted) return;
    try {
      final marks = await geo.placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      if (!mounted) return;
      if (marks.isNotEmpty) {
        final p = marks.first;
        final parts = [
          p.street,
          p.subLocality,
          p.locality,
        ].where((e) => (e ?? '').trim().isNotEmpty).map((e) => e!.trim()).toList();
        setState(() {
          _locationLabel = parts.isEmpty
              ? '${point.latitude.toStringAsFixed(3)}, ${point.longitude.toStringAsFixed(3)}'
              : parts.take(3).join(', ');
        });
      } else {
        setState(() {
          _locationLabel =
              '${point.latitude.toStringAsFixed(3)}, ${point.longitude.toStringAsFixed(3)}';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationLabel =
              '${point.latitude.toStringAsFixed(3)}, ${point.longitude.toStringAsFixed(3)}';
        });
      }
    }
  }

  String _availabilityLabel(String? raw) {
    return switch (raw) {
      'busy' => 'Məşğul',
      'offline' => 'Offline',
      _ => 'Aktiv',
    };
  }

  Color _availabilityColor(String? raw) {
    return switch (raw) {
      'busy' => const Color(0xFFF59E0B),
      'offline' => const Color(0xFF9CA3AF),
      _ => const Color(0xFF22C55E),
    };
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Çıxış'),
        content: const Text('Hesabdan çıxmaq istəyirsiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Ləğv')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Çıxış et'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await AuthService.instance.signOut();
    if (!mounted) return;
    appRouter.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = AuthService.instance.firebaseUser?.uid;
    final user = AuthService.instance.profile;

    if (uid == null || user == null) {
      return const Scaffold(
        body: Center(child: Text('Giriş tapılmadı')),
      );
    }

    final workerStream = WorkerProfileService.instance.workerDocStream(uid);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: ListenableBuilder(
        listenable: JobService.instance,
        builder: (context, _) {
          final stats = JobService.instance.workerCompletedStats(uid);
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: workerStream,
            builder: (context, wSnap) {
              final wd = wSnap.data?.data() ?? {};
              final rating = (wd['rating'] as num?)?.toDouble() ?? 0.0;
              final rc = (wd['ratingCount'] as num?)?.toInt() ?? 0;
              final availability = wd['availability'] as String? ?? 'active';
              final badgeText = _availabilityLabel(availability);

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.96, end: 1),
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    builder: (context, scale, child) {
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.14),
                            AppColors.surface,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.07),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 46,
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.15),
                              backgroundImage: user.photoUrl != null &&
                                      user.photoUrl!.isNotEmpty
                                  ? NetworkImage(user.photoUrl!)
                                  : null,
                              child: user.photoUrl == null || user.photoUrl!.isEmpty
                                  ? Text(
                                      _initials(user.displayName),
                                      style: theme.textTheme.headlineSmall?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              user.displayName.isEmpty ? 'İcraçı' : user.displayName,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ...List.generate(5, (i) {
                                  final v = rating.clamp(0, 5);
                                  final filled = i < v.round().clamp(0, 5);
                                  return Icon(
                                    filled
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    color: AppColors.primary,
                                    size: 22,
                                  );
                                }),
                                const SizedBox(width: 8),
                                Text(
                                  rc > 0
                                      ? '${rating.toStringAsFixed(1)} ($rc rəy)'
                                      : 'Hələ rəy yoxdur',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _InfoPill(
                                  icon: Icons.work_outline_rounded,
                                  label: '${stats.completedCount} tamamlanan iş',
                                ),
                                const SizedBox(width: 10),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _availabilityColor(availability)
                                        .withValues(alpha: 0.15),
                                    borderRadius:
                                        BorderRadius.circular(AppTheme.radiusMd),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.circle,
                                        size: 10,
                                        color: _availabilityColor(availability),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        badgeText,
                                        style: theme.textTheme.labelLarge?.copyWith(
                                          color: _availabilityColor(availability),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (_locationLabel != null &&
                                _locationLabel!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 18,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.55),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      _locationLabel!,
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Menyu',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  WorkerMenuTile(
                    icon: Icons.edit_outlined,
                    title: 'Profili redaktə et',
                    onTap: () => appRouter.push(AppRoutes.profileEdit(true)),
                  ),
                  WorkerMenuTile(
                    icon: Icons.construction_outlined,
                    title: 'Bacarıqlarım',
                    onTap: () => appRouter.push(AppRoutes.workerSkills),
                  ),
                  WorkerMenuTile(
                    icon: Icons.toggle_on_outlined,
                    title: 'Aktivlik statusu',
                    subtitle: _availabilityLabel(availability),
                    onTap: () => appRouter.push(AppRoutes.workerAvailability),
                  ),
                  WorkerMenuTile(
                    icon: Icons.payments_outlined,
                    title: 'Qazancım',
                    onTap: () => appRouter.push(AppRoutes.workerEarnings),
                  ),
                  WorkerMenuTile(
                    icon: Icons.task_alt_outlined,
                    title: 'Tamamlanan işlər',
                    onTap: () => appRouter.push(AppRoutes.profileMyJobs(true)),
                  ),
                  WorkerMenuTile(
                    icon: Icons.reviews_outlined,
                    title: 'Rəylər',
                    onTap: () => appRouter.push(AppRoutes.workerReviews),
                  ),
                  WorkerMenuTile(
                    icon: Icons.notifications_active_outlined,
                    title: 'Bildirişlər',
                    subtitle: 'Yeni elanlar, mesajlar, təkliflər',
                    onTap: () => appRouter.push(AppRoutes.profileNotifications(true)),
                  ),
                  WorkerMenuTile(
                    icon: Icons.map_outlined,
                    title: 'Məkanımı dəyiş',
                    onTap: () => appRouter.push(AppRoutes.workerChangeLocation),
                  ),
                  WorkerMenuTile(
                    icon: Icons.settings_outlined,
                    title: 'Parametrlər',
                    onTap: () => appRouter.push(AppRoutes.profileSettings(true)),
                  ),
                  WorkerMenuTile(
                    icon: Icons.logout_rounded,
                    title: 'Çıxış et',
                    isDanger: true,
                    onTap: _logout,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  static String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    final w = parts[0];
    return w.length >= 2 ? w.substring(0, 2).toUpperCase() : w[0].toUpperCase();
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
