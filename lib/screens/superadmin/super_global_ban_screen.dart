import 'package:flutter/material.dart';

import '../../services/super_admin_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/gradient_primary_button.dart';

class SuperGlobalBanScreen extends StatefulWidget {
  const SuperGlobalBanScreen({super.key});

  @override
  State<SuperGlobalBanScreen> createState() => _SuperGlobalBanScreenState();
}

class _SuperGlobalBanScreenState extends State<SuperGlobalBanScreen> {
  final _userId = TextEditingController();
  final _workerId = TextEditingController();

  @override
  void dispose() {
    _userId.dispose();
    _workerId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ColoredBox(
      color: AppColors.background,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Text(
            'İstifadəçi və ya icraçı UID ilə blok (Firestore `users.banned` / `workers.disabled`).',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _userId,
                  decoration: const InputDecoration(
                    labelText: 'İstifadəçi ID',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                GradientPrimaryButton(
                  label: 'İstifadəçini blokla',
                  onPressed: () async {
                    final id = _userId.text.trim();
                    if (id.isEmpty) return;
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await SuperAdminService.instance.globalBanUser(id);
                      if (!context.mounted) return;
                      messenger.showSnackBar(
                        SnackBar(content: Text('Bloklandı: $id')),
                      );
                      _userId.clear();
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Xəta: $e')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _workerId,
                  decoration: const InputDecoration(
                    labelText: 'İcraçı ID',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                GradientPrimaryButton(
                  label: 'İcraçını blokla',
                  onPressed: () async {
                    final id = _workerId.text.trim();
                    if (id.isEmpty) return;
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await SuperAdminService.instance.globalBanWorker(id);
                      if (!context.mounted) return;
                      messenger.showSnackBar(
                        SnackBar(content: Text('İcraçı deaktiv edildi: $id')),
                      );
                      _workerId.clear();
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Xəta: $e')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
