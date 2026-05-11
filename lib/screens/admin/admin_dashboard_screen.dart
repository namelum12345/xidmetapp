import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../shells/admin_shell.dart';
import '../../theme/app_colors.dart';
import '../../widgets/dashboard/stream_query_stat_cards.dart';
import 'admin_reports_screen.dart';

/// Admin panel əsas səhifə — kartlar real-time say + birbaşa tab marshrutları.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  static final _db = FirebaseFirestore.instance;

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
                    'Admin Panel',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'İdarəetmə (canlı Firestore)',
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.05,
              ),
              delegate: SliverChildListDelegate([
                StreamAdminQueryStatCard(
                  query: _db.collection('users'),
                  icon: Icons.person_outline_rounded,
                  label: 'İstifadəçilər',
                  onTap: () =>
                      AdminShell.goToTab(context, AdminShell.tabUsers),
                ),
                StreamAdminQueryStatCard(
                  query: _db.collection('workers'),
                  icon: Icons.engineering_outlined,
                  label: 'İcraçılar',
                  onTap: () =>
                      AdminShell.goToTab(context, AdminShell.tabWorkers),
                ),
                StreamAdminQueryStatCard(
                  query: _db.collection('jobs'),
                  icon: Icons.campaign_outlined,
                  label: 'Elanlar',
                  onTap: () => AdminShell.goToTab(context, AdminShell.tabJobs),
                ),
                StreamAdminQueryStatCard(
                  query: _db.collection('chats'),
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Mesajlar',
                  onTap: () =>
                      AdminShell.goToTab(context, AdminShell.tabChats),
                ),
                StreamAdminQueryStatCard(
                  query: _db.collection('complaints'),
                  countFromDocs: (docs) => docs
                      .where((d) => d.data()['pending'] == true)
                      .length,
                  icon: Icons.flag_outlined,
                  label: 'Şikayətlər',
                  onTap: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => const AdminReportsScreen(),
                      ),
                    );
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
