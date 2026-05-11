import 'package:flutter/material.dart';

import '../models/user_role.dart';
import '../services/auth_service.dart';
import '../services/job_service.dart';
import '../theme/app_colors.dart';
import '../widgets/marketplace_dashboard_page.dart';

/// Ana səhifə tab — marketplace (worker).
///
/// Daxili [Scaffold] yoxdur: [RoleMainShell] artıq [Scaffold] + alt nav verir;
/// iç-içə scaffold bəzən alt menyuda toxunuşu "ölü" edir.
class WorkerHomeScreen extends StatelessWidget {
  const WorkerHomeScreen({super.key});

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
                      'İcraçı paneli',
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
              listenable: Listenable.merge([
                JobService.instance,
                AuthService.instance,
              ]),
              builder: (context, _) {
                return MarketplaceDashboardPage(
                  viewerRole: UserRole.worker,
                  jobsProvider: () =>
                      JobService.instance.jobsSortedForWorker(),
                  showCreateFab: false,
                  showWorkerMatchBadges: true,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
