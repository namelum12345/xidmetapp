import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/gradient_primary_button.dart';

class ProfileSupportScreen extends StatelessWidget {
  const ProfileSupportScreen({super.key});

  Future<void> _mail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'destek@qonsudan.local',
      queryParameters: {
        'subject': 'Qonşudan Xidmət — dəstək',
      },
    );
    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Poçt tətbiqi açılmadı')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dəstək / Yardım'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tez-tez verilən suallar',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '• Elan yaradın və yaxınlıqda uyğun icraçılar avtomatik bildirilir.\n'
                  '• Mesajlar bölməsindən təklif və danışıqları idarə edin.\n'
                  '• Profil menyusundan məkan və şifrəni yeniləyə bilərsiniz.',
                ),
                const SizedBox(height: 20),
                GradientPrimaryButton(
                  label: 'Dəstəkə yaz',
                  onPressed: () => _mail(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
