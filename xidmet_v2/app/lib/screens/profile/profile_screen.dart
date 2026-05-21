import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService.instance,
      builder: (context, _) {
        final user = AuthService.instance.user;
        return Scaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: kPrimary.withOpacity(0.1),
                        backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
                        child: user?.photoUrl == null
                            ? Text(
                                user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                                style: TextStyle(color: kPrimary, fontSize: 32, fontWeight: FontWeight.w700),
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${user?.name ?? ''} ${user?.surname ?? ''}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(user?.email ?? '', style: TextStyle(color: kTextSecondary)),
                      if (user?.phone != null) ...[
                        const SizedBox(height: 2),
                        Text(user!.phone!, style: TextStyle(color: kTextSecondary)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                _SectionTitle('Hesab'),
                _Tile(Icons.edit_outlined, 'Profili düzənlə', () => context.push('/profile/edit')),
                _Tile(Icons.lock_outline_rounded, 'Şifrəni dəyiş', () => context.push('/profile/change-password')),
                _Tile(Icons.work_outline_rounded, 'Mənim işlərim', () => context.push('/profile/my-jobs')),
                const SizedBox(height: 8),
                _SectionTitle('Tərcihlər'),
                _Tile(Icons.notifications_outlined, 'Bildirişlər', () => context.push('/profile/notifications')),
                _Tile(Icons.settings_outlined, 'Parametrlər', () => context.push('/profile/settings')),
                _Tile(Icons.help_outline_rounded, 'Yardım', () => context.push('/profile/support')),
                const SizedBox(height: 8),
                _Tile(
                  Icons.logout_rounded,
                  'Çıxış',
                  () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Çıxış'),
                        content: const Text('Hesabdan çıxmaq istəyirsiniz?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İmtina')),
                          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Çıx')),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await AuthService.instance.signOut();
                    }
                  },
                  color: kError,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
      child: Text(text, style: TextStyle(color: kTextSecondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.icon, this.label, this.onTap, {this.color});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: c),
        title: Text(label, style: TextStyle(color: c, fontWeight: FontWeight.w600)),
        trailing: Icon(Icons.chevron_right_rounded, color: kTextSecondary),
        onTap: onTap,
      ),
    );
  }
}
