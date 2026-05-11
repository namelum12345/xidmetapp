import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/app_settings_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/profile/settings_tile.dart';

class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Parametrlər'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListenableBuilder(
        listenable: AppSettingsController.instance,
        builder: (context, _) {
          final s = AppSettingsController.instance;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Görünüş',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 12),
                    SettingsTile(
                      title: 'Tünd rejim',
                      subtitle: 'Yalnız bu cihazda (UI)',
                      trailing: Switch(
                        value: s.themeMode == ThemeMode.dark,
                        activeThumbColor: AppColors.onPrimary,
                        activeTrackColor: AppColors.primary,
                        onChanged: (v) => s.setDarkMode(v),
                      ),
                    ),
                    SettingsTile(
                      title: 'Bildirişlər',
                      subtitle: 'Tətbiq daxili bildirişlər',
                      trailing: Switch(
                        value: s.notificationsEnabled,
                        activeThumbColor: AppColors.onPrimary,
                        activeTrackColor: AppColors.primary,
                        onChanged: (v) => s.setNotificationsEnabled(v),
                      ),
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
                      'Dil',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: s.languageCode,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'az', child: Text('Azərbaycan')),
                        DropdownMenuItem(value: 'en', child: Text('English')),
                        DropdownMenuItem(value: 'ru', child: Text('Русский')),
                      ],
                      onChanged: (v) {
                        if (v != null) s.setLanguageCode(v);
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
