import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_routes.dart';
import '../../services/auth_service.dart';
import '../../shells/super_admin_shell.dart';
import '../../theme/app_colors.dart';
import '../../widgets/dashboard/stream_query_stat_cards.dart';
import '../../widgets/gradient_primary_button.dart';
import '../../widgets/setting_nav_tile.dart';

/// Superadmin panel — kartlar real-time Firestore axınları ilə.
class SuperAdminDashboardScreen extends StatelessWidget {
  const SuperAdminDashboardScreen({super.key});

  static final _db = FirebaseFirestore.instance;

  static int _adminRoleCount(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return docs.where((d) {
      final r = (d.data()['role'] as String? ?? '').trim().toLowerCase();
      return r == 'admin';
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ColoredBox(
      color: AppColors.background,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Super Admin',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sistem idarəetməsi (canlı Firestore)',
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.18,
              ),
              delegate: SliverChildListDelegate([
                StreamSuperQueryStatCard(
                  query: _db.collection('users'),
                  icon: Icons.people_outline_rounded,
                  label: 'İstifadəçilər',
                  onTap: () => context.go(AppRoutes.superManageUsers),
                ),
                StreamSuperQueryStatCard(
                  query: _db.collection('workers'),
                  icon: Icons.engineering_outlined,
                  label: 'İcraçılar',
                  onTap: () => context.go(AppRoutes.superManageWorkers),
                ),
                StreamSuperQueryStatCard(
                  query: _db.collection('users'),
                  icon: Icons.shield_outlined,
                  label: 'Adminlər',
                  countFromDocs: _adminRoleCount,
                  onTap: () =>
                      SuperAdminShell.goToTab(context, SuperAdminShell.tabAdmins),
                ),
                StreamSuperQueryStatCard(
                  query: _db.collection('jobs'),
                  icon: Icons.work_outline_rounded,
                  label: 'Elanlar',
                  onTap: () => context.go(AppRoutes.superManageJobs),
                ),
                StreamSuperQueryStatCard(
                  query: _db.collection('chats'),
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Söhbətlər',
                  onTap: () => context.go(AppRoutes.superManageChats),
                ),
                StreamSuperQueryStatCard(
                  query: _db.collection('complaints'),
                  countFromDocs: (docs) => docs
                      .where((d) => d.data()['pending'] == true)
                      .length,
                  icon: Icons.flag_outlined,
                  label: 'Şikayətlər',
                  onTap: () => context.go(AppRoutes.superReports),
                ),
                StreamSuperQueryStatCard(
                  query: _db.collection('logs'),
                  icon: Icons.history_rounded,
                  label: 'Loglar',
                  onTap: () => context.go(AppRoutes.superAudit),
                ),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Əməliyyatlar',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  SettingTile(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Monetizasiya',
                    subtitle: 'Komissiya və premium',
                    onTap: () => context.go(AppRoutes.superMonetization),
                  ),
                  SettingTile(
                    icon: Icons.vpn_key_outlined,
                    title: 'İcazə şablonu',
                    subtitle: 'Defolt icazələr',
                    onTap: () => context.go(AppRoutes.superPermissions),
                  ),
                  SettingTile(
                    icon: Icons.campaign_outlined,
                    title: 'Push bildiriş',
                    subtitle: 'Hamısı və ya icraçılar',
                    onTap: () => context.go(AppRoutes.superNotifications),
                  ),
                  SettingTile(
                    icon: Icons.gavel_rounded,
                    title: 'Qlobal blok',
                    subtitle: 'İstifadəçi / icraçı ID',
                    onTap: () => context.go(AppRoutes.superGlobalBan),
                  ),
                  const SizedBox(height: 28),
                  GradientPrimaryButton(
                    label: 'Çıxış',
                    onPressed: () async {
                      await AuthService.instance.signOut();
                      if (!context.mounted) return;
                      context.go(AppRoutes.login);
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
