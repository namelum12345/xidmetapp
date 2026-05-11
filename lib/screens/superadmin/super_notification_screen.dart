import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/super_admin_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/gradient_primary_button.dart';

/// Push bildiriş mərkəzi (Firestore queue -> Cloud Functions -> FCM).
class SuperNotificationScreen extends StatefulWidget {
  const SuperNotificationScreen({super.key});

  @override
  State<SuperNotificationScreen> createState() =>
      _SuperNotificationScreenState();
}

class _SuperNotificationScreenState extends State<SuperNotificationScreen> {
  final _message = TextEditingController();
  var _workersOnly = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Push bildirişi'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mesaj',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _message,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Mətn daxil edin…',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Checkbox(
                      value: _workersOnly,
                      activeColor: AppColors.primary,
                      onChanged: (v) =>
                          setState(() => _workersOnly = v ?? false),
                    ),
                    Expanded(
                      child: Text(
                        'Yalnız icraçılar',
                        style: textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GradientPrimaryButton(
                  label: 'Göndər',
                  onPressed: () async {
                    final t = _message.text.trim();
                    if (t.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Mesaj yazın')),
                      );
                      return;
                    }
                    if (_workersOnly) {
                      await SuperAdminService.instance.sendPushWorkersOnly(t);
                    } else {
                      await SuperAdminService.instance.sendPushAll(t);
                    }
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Push növbəyə yazıldı')),
                    );
                    _message.clear();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vəsait',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bu ekran `notification_queue` kolleksiyasına yazır; Cloud Functions həmin yazıları FCM-ə göndərir.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
