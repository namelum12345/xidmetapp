import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

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
                        child: Text(
                          user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'A',
                          style: TextStyle(color: kPrimary, fontSize: 32, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${user?.name ?? ''} ${user?.surname ?? ''}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('Admin', style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700)),
                      ),
                      Text(user?.email ?? '', style: TextStyle(color: kTextSecondary)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.lock_outline_rounded),
                    title: const Text('Şifrəni dəyiş', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: Icon(Icons.chevron_right_rounded, color: kTextSecondary),
                    onTap: () => context.push('/profile/change-password'),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: Icon(Icons.logout_rounded, color: kError),
                    title: Text('Çıxış', style: TextStyle(fontWeight: FontWeight.w600, color: kError)),
                    onTap: () async {
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
                      if (confirmed == true) await AuthService.instance.signOut();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
