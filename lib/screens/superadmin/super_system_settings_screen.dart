import 'package:flutter/material.dart';

import '../../services/super_admin_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/gradient_primary_button.dart';
import '../../widgets/outlined_auth_button.dart';
import '../../widgets/setting_nav_tile.dart';
import 'super_admin_named_screens.dart';

class _SuperSettingPushTile extends StatelessWidget {
  const _SuperSettingPushTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.screen,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget screen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          onTap: () {
            Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => screen,
              ),
            );
          },
          child: SettingTileVisual(
            icon: icon,
            title: title,
            subtitle: subtitle,
          ),
        ),
      ),
    );
  }
}

class SuperSystemSettingsScreen extends StatelessWidget {
  const SuperSystemSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ColoredBox(
      color: AppColors.background,
      child: ListenableBuilder(
        listenable: SuperAdminService.instance,
        builder: (context, _) {
          final s = SuperAdminService.instance;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              Text(
                'Parametrlər',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sistem və əməliyyatlar',
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              const _SuperSettingPushTile(
                icon: Icons.flag_outlined,
                title: 'Şikayətlər',
                subtitle: 'İstifadəçi, icraçı, elan',
                screen: ReportsScreen(),
              ),
              const _SuperSettingPushTile(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Monetizasiya',
                subtitle: 'Komissiya və premium',
                screen: MonetizationScreen(),
              ),
              const _SuperSettingPushTile(
                icon: Icons.vpn_key_outlined,
                title: 'İcazə şablonu',
                subtitle: 'Defolt icazələr',
                screen: PermissionsScreen(),
              ),
              const _SuperSettingPushTile(
                icon: Icons.history_rounded,
                title: 'Audit log',
                subtitle: 'Kim nə etdi',
                screen: LogsScreen(),
              ),
              const _SuperSettingPushTile(
                icon: Icons.campaign_outlined,
                title: 'Push bildiriş',
                subtitle: 'Hamı və ya icraçılar',
                screen: NotificationScreen(),
              ),
              const _SuperSettingPushTile(
                icon: Icons.gavel_rounded,
                title: 'Qlobal blok',
                subtitle: 'İstifadəçi / icraçı ID',
                screen: BanManagementScreen(),
              ),
              const SizedBox(height: 24),
              Text(
                'Sistem parametrləri',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Maksimal radius (km)',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Slider(
                      value: s.maxRadiusKm,
                      min: 5,
                      max: 80,
                      divisions: 15,
                      activeColor: AppColors.primary,
                      label: '${s.maxRadiusKm.toStringAsFixed(0)} km',
                      onChanged: (v) =>
                          SuperAdminService.instance.setMaxRadius(v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kateqoriyalar',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: s.managedCategories
                          .map(
                            (c) => Chip(
                              label: Text(c),
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.08),
                              side: const BorderSide(color: AppColors.outline),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tezliklə redaktə UI əlavə olunacaq',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bacarıqlar',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...s.managedSkills.map(
                      (sk) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline_rounded,
                              size: 18,
                              color: AppColors.primary.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(sk)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Nüsxələmə',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GradientPrimaryButton(
                      label: 'Backup',
                      onPressed: () {
                        SuperAdminService.instance.backupDummy();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Backup yaradıldı')),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    OutlinedAuthButton(
                      label: 'Restore',
                      onPressed: () {
                        SuperAdminService.instance.restoreDummy();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Restore simulyasiyası')),
                        );
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
