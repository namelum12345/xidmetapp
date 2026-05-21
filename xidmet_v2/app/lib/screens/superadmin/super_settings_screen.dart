import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class SuperSettingsScreen extends StatelessWidget {
  const SuperSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService.instance,
      builder: (context, _) {
        final user = AuthService.instance.user;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Parametrlər', style: TextStyle(fontWeight: FontWeight.w800)),
            centerTitle: false,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SuperAdmin Hesabı', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 8),
                      Text('Ad: ${user?.name ?? ''} ${user?.surname ?? ''}', style: TextStyle(color: kTextSecondary)),
                      Text('E-poçt: ${user?.email ?? ''}', style: TextStyle(color: kTextSecondary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.lock_outline_rounded),
                      title: const Text('Şifrəni dəyiş', style: TextStyle(fontWeight: FontWeight.w600)),
                      trailing: Icon(Icons.chevron_right_rounded, color: kTextSecondary),
                      onTap: () => context.push('/profile/change-password'),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SwitchListTile(
                      secondary: const Icon(Icons.dark_mode_outlined),
                      title: const Text('Tünd rejim', style: TextStyle(fontWeight: FontWeight.w600)),
                      value: Theme.of(context).brightness == Brightness.dark,
                      onChanged: (_) {},
                      activeColor: kPrimary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 24),
              Center(
                child: Text('Qonşudan Xidmət v1.0.0', style: TextStyle(color: kTextSecondary, fontSize: 12)),
              ),
            ],
          ),
        );
      },
    );
  }
}
