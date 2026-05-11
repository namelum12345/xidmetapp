import 'package:flutter/material.dart';

import '../models/user_role.dart';
import '../services/job_service.dart';
import '../theme/app_colors.dart';
import '../widgets/marketplace_dashboard_page.dart';

/// Ana səhifə tab — marketplace (user).
///
/// Daxili [Scaffold] yoxdur — [RoleMainShell] xarici scaffold verir (worker ilə eyni səbəb).
class UserHomeScreen extends StatelessWidget {
  const UserHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ColoredBox(
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: AppColors.surface,
            elevation: 0.5,
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: kToolbarHeight,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Qonşudan Xidmət',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: JobService.instance,
              builder: (context, _) {
                return MarketplaceDashboardPage(
                  viewerRole: UserRole.user,
                  jobsProvider: () => JobService.instance.allJobs(),
                  showCreateFab: true,
                  showWorkerMatchBadges: false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
