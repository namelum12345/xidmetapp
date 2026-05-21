import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geo;
import '../../router/app_router.dart' show appRouter;

import '../../models/user_role.dart';
import '../../router/app_routes.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/profile/profile_header.dart';
import '../../widgets/profile/profile_menu_tile.dart';

/// Marketplace profil menyusu (istifadəçi / icraçı).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.viewerRole});

  final UserRole viewerRole;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _locationLabel;

  bool get _worker => widget.viewerRole == UserRole.worker;

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
          p.administrativeArea,
        ].where((e) => (e ?? '').trim().isNotEmpty).map((e) => e!.trim()).toList();
        setState(() {
          _locationLabel = parts.isEmpty
              ? '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}'
              : parts.take(3).join(', ');
        });
      } else {
        setState(() {
          _locationLabel =
              '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationLabel =
              '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}';
        });
      }
    }
  }

  String _roleLabel() {
    final p = AuthService.instance.profile;
    if (p == null) return '';
    if (p.isSuperAdmin) return 'Superadmin';
    if (p.isAdmin) return 'Admin';
    if (p.role == 'worker') return 'İcraçı';
    return 'İstifadəçi';
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil'),
        automaticallyImplyLeading: false,
      ),
      body: ListenableBuilder(
        listenable: AuthService.instance,
        builder: (context, _) {
          final profile = AuthService.instance.profile;
          if (profile == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final locText = _locationLabel ??
              (profile.location != null
                  ? 'Məkan təyin olunub'
                  : 'Məkan əlavə edilməyib');

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: ProfileHeader(
                  displayName: profile.displayName,
                  roleLabel: _roleLabel(),
                  locationLabel: locText,
                  photoUrl: profile.photoUrl,
                  onAvatarTap: () => appRouter.push(
                    AppRoutes.profileEdit(_worker),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ProfileMenuTile(
                icon: Icons.edit_outlined,
                title: 'Hesabı redaktə et',
                subtitle: 'Ad, soyad, telefon, şəkil',
                onTap: () => appRouter.push(AppRoutes.profileEdit(_worker)),
              ),
              ProfileMenuTile(
                icon: Icons.lock_outline_rounded,
                title: 'Şifrəni dəyiş',
                onTap: () => appRouter.push(AppRoutes.profileChangePassword(_worker)),
              ),
              ProfileMenuTile(
                icon: Icons.map_outlined,
                title: 'Məkanımı dəyiş',
                subtitle: 'GPS və ya xəritədə seçim',
                onTap: () => appRouter.push(AppRoutes.profileEdit(_worker)),
              ),
              ProfileMenuTile(
                icon: Icons.work_outline_rounded,
                title: 'Elanlarım',
                subtitle: _worker ? 'Seçilmiş və təklifləriniz' : 'Yaratdığınız elanlar',
                onTap: () => appRouter.push(AppRoutes.profileMyJobs(_worker)),
              ),
              ProfileMenuTile(
                icon: Icons.task_alt_outlined,
                title: 'Tamamlanan işlər',
                subtitle: 'Bitmiş elanlar',
                onTap: () => appRouter.push(
                  '${AppRoutes.profileMyJobs(_worker)}?tab=completed',
                ),
              ),
              ProfileMenuTile(
                icon: Icons.people_outline_rounded,
                title: 'Seçilmiş işçilər',
                onTap: () => appRouter.push(AppRoutes.profileFavorites(_worker)),
              ),
              ProfileMenuTile(
                icon: Icons.notifications_outlined,
                title: 'Bildirişlər',
                onTap: () => appRouter.push(AppRoutes.profileNotifications(_worker)),
              ),
              ProfileMenuTile(
                icon: Icons.help_outline_rounded,
                title: 'Dəstək / Yardım',
                onTap: () => appRouter.push(AppRoutes.profileSupport(_worker)),
              ),
              ProfileMenuTile(
                icon: Icons.settings_outlined,
                title: 'Parametrlər',
                onTap: () => appRouter.push(AppRoutes.profileSettings(_worker)),
              ),
              const SizedBox(height: 8),
              ProfileMenuTile(
                icon: Icons.logout_rounded,
                title: 'Çıxış et',
                onTap: _logout,
                isDanger: true,
              ),
            ],
          );
        },
      ),
    );
  }
}
