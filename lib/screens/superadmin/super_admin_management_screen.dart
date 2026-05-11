import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/superadmin_control_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/gradient_primary_button.dart';

class SuperAdminManagementScreen extends StatelessWidget {
  const SuperAdminManagementScreen({super.key});

  Future<void> _createAdmin(BuildContext context) async {
    final name = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController(text: '123456');

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Admin yarat'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Ad'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: email,
                decoration: const InputDecoration(labelText: 'E-poçt'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: password,
                decoration: const InputDecoration(labelText: 'Şifrə'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Ləğv'),
            ),
            TextButton(
              onPressed: () async {
                final n = name.text.trim();
                final e = email.text.trim();
                final p = password.text;
                if (n.isEmpty || e.isEmpty || p.length < 6) return;
                try {
                  await SuperadminControlService.instance.createAdmin(
                    name: n,
                    email: e,
                    password: p,
                  );
                } catch (err) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Xəta: $err')),
                  );
                  return;
                }
                if (!context.mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$e admin yaradıldı')),
                );
              },
              child: const Text('Yarat'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ColoredBox(
      color: AppColors.background,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: SuperadminControlService.instance.usersStream(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Firestore: ${snap.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final raw = snap.data?.docs ?? const [];
          final docs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(raw)
            ..sort((a, b) {
              final ta = a.data()['createdAt'];
              final tb = b.data()['createdAt'];
              if (ta is Timestamp && tb is Timestamp) {
                return tb.compareTo(ta);
              }
              if (ta is Timestamp) return -1;
              if (tb is Timestamp) return 1;
              return 0;
            });

          final admins = docs.where((d) => (d.data()['role'] ?? '') == 'admin').toList();
          final users = docs
              .where((d) =>
                  (d.data()['role'] ?? '') != 'superadmin' &&
                  (d.data()['role'] ?? '') != 'super_admin')
              .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Text(
                'Admin idarəetməsi',
                style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              GradientPrimaryButton(
                label: 'Admin yarat',
                onPressed: () => _createAdmin(context),
              ),
              const SizedBox(height: 18),
              Text(
                'Admin siyahısı',
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              if (admins.isEmpty)
                const Text('Admin yoxdur')
              else
                ...admins.map((d) {
                  final m = d.data();
                  return Card(
                    child: ListTile(
                      title: Text((m['name'] as String? ?? '').trim().isEmpty
                          ? (m['email'] as String? ?? d.id)
                          : (m['name'] as String)),
                      subtitle: Text(m['email'] as String? ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          try {
                            await SuperadminControlService.instance.deleteAdmin(d.id);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Admin silindi')),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Xəta: $e')),
                            );
                          }
                        },
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 18),
              Text(
                'İstifadəçilər',
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              ...users.map((d) {
                final m = d.data();
                final role = (m['role'] as String? ?? 'user');
                final blocked = m['isBlocked'] == true;
                return Card(
                  child: ListTile(
                    title: Text((m['name'] as String? ?? '').trim().isEmpty
                        ? (m['email'] as String? ?? d.id)
                        : (m['name'] as String)),
                    subtitle: Text('${m['email'] ?? ''} • $role'),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        try {
                          if (v == 'block') {
                            await SuperadminControlService.instance.toggleBlocked(
                              uid: d.id,
                              blocked: !blocked,
                            );
                          } else if (v == 'delete') {
                            await SuperadminControlService.instance.deleteUser(d.id);
                          } else {
                            await SuperadminControlService.instance.changeRole(
                              uid: d.id,
                              fromRole: role,
                              toRole: v,
                            );
                          }
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Əməliyyat tamamlandı')),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Xəta: $e')),
                          );
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'block',
                          child: Text(blocked ? 'Unblock' : 'Block'),
                        ),
                        const PopupMenuItem(value: 'user', child: Text('Role: user')),
                        const PopupMenuItem(value: 'worker', child: Text('Role: worker')),
                        const PopupMenuItem(value: 'admin', child: Text('Role: admin')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete user')),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
