import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/super_admin_service.dart';
import '../../shells/super_admin_shell.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/gradient_primary_button.dart';
import '../../widgets/outlined_auth_button.dart';
import '../../widgets/setting_nav_tile.dart';
import 'super_admin_named_screens.dart';

/// Push naviqasiyalı parametr sətri.
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
              MaterialPageRoute<void>(builder: (_) => screen),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Superadmin → "Parametrlər" tabı.
/// Bölmələr:
///   1) Adminlər — icazə şablonu, audit, push, qlobal blok, admin siyahısına keçid.
///   2) Şikayət və moderasiya.
///   3) Maliyyə (komissiya).
///   4) Sistem — radius, kateqoriyalar, bacarıqlar.
///   5) Nüsxələmə — backup/restore.
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
              const SizedBox(height: 4),
              Text(
                'Sistem və admin idarəetmə vasitələri',
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const _SectionHeader(
                title: 'Adminlər',
                subtitle: 'Admin hesablarına aid əməliyyatlar',
              ),
              _AdminQuickStatsCard(
                onOpenAdmins: () => SuperAdminShell.goToTab(
                  context,
                  SuperAdminShell.tabAdmins,
                ),
              ),
              const SizedBox(height: 10),
              const _SuperSettingPushTile(
                icon: Icons.vpn_key_outlined,
                title: 'Defolt icazə şablonu',
                subtitle: 'Yeni adminlər üçün icazələr',
                screen: PermissionsScreen(),
              ),
              const _SuperSettingPushTile(
                icon: Icons.history_rounded,
                title: 'Audit log',
                subtitle: 'Kim hansı əməliyyatı icra etdi',
                screen: LogsScreen(),
              ),
              const _SuperSettingPushTile(
                icon: Icons.campaign_outlined,
                title: 'Push bildiriş',
                subtitle: 'Hamı və ya yalnız icraçılar üçün',
                screen: NotificationScreen(),
              ),
              const _SuperSettingPushTile(
                icon: Icons.gavel_rounded,
                title: 'Qlobal blok',
                subtitle: 'İstifadəçi / icraçı ID üzrə',
                screen: BanManagementScreen(),
              ),
              const _SectionHeader(
                title: 'Şikayət və moderasiya',
              ),
              const _SuperSettingPushTile(
                icon: Icons.flag_outlined,
                title: 'Şikayətlər',
                subtitle: 'İstifadəçi, icraçı, elan',
                screen: ReportsScreen(),
              ),
              const _SectionHeader(
                title: 'Maliyyə',
                subtitle: 'Komissiya analitikaya təsir edir',
              ),
              const _SuperSettingPushTile(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Monetizasiya',
                subtitle: 'Komissiya faizi və premium',
                screen: MonetizationScreen(),
              ),
              const _SectionHeader(
                title: 'Sistem',
                subtitle: 'Marketplace tənzimləmələri',
              ),
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
              const _SectionHeader(title: 'Nüsxələmə'),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                          const SnackBar(
                            content: Text('Restore simulyasiyası'),
                          ),
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

/// Adminlər bölməsi üçün xülasə kartı: cəmi/aktiv/bloklu admin sayı +
/// "Adminlər" tabına keçid düyməsi.
class _AdminQuickStatsCard extends StatelessWidget {
  const _AdminQuickStatsCard({required this.onOpenAdmins});

  final VoidCallback onOpenAdmins;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? const [];
        var blocked = 0;
        for (final d in docs) {
          final m = d.data();
          if (m['isBlocked'] == true || m['banned'] == true) blocked++;
        }
        final total = docs.length;
        final active = total - blocked;

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin hesabları',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Yarat, blokla, sil və ya rol dəyiş',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(label: 'Cəmi', value: '$total'),
                  ),
                  Container(width: 1, height: 30, color: AppColors.outline),
                  Expanded(
                    child: _MiniStat(
                      label: 'Aktiv',
                      value: '$active',
                      color: const Color(0xFF22C55E),
                    ),
                  ),
                  Container(width: 1, height: 30, color: AppColors.outline),
                  Expanded(
                    child: _MiniStat(
                      label: 'Bloklu',
                      value: '$blocked',
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onOpenAdmins,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Adminləri idarə et'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(
          value,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: color ?? AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
