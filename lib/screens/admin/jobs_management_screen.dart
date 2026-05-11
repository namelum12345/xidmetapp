import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/admin_models.dart';
import '../../models/user_role.dart';
import '../../router/app_routes.dart';
import '../../services/admin_data_service.dart';
import '../../services/job_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin_job_row.dart';

class JobsManagementScreen extends StatefulWidget {
  const JobsManagementScreen({super.key});

  @override
  State<JobsManagementScreen> createState() => _JobsManagementScreenState();
}

class _JobsManagementScreenState extends State<JobsManagementScreen> {
  AdminJobLifecycle? _filter;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ColoredBox(
      color: AppColors.background,
      child: ListenableBuilder(
        listenable: Listenable.merge([
          AdminDataService.instance,
          JobService.instance,
        ]),
        builder: (context, _) {
          final admin = AdminDataService.instance;
          var jobs = admin.jobsFromCatalog();
          if (_filter != null) {
            jobs = jobs
                .where(
                  (j) => admin.lifecycleForJob(j.id) == _filter,
                )
                .toList();
          }

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Elanlar',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Hamısı',
                        selected: _filter == null,
                        onTap: () => setState(() => _filter = null),
                      ),
                      const SizedBox(width: 10),
                      _FilterChip(
                        label: 'Aktiv',
                        selected: _filter == AdminJobLifecycle.active,
                        onTap: () => setState(
                          () => _filter = AdminJobLifecycle.active,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _FilterChip(
                        label: 'Tamamlanıb',
                        selected: _filter == AdminJobLifecycle.completed,
                        onTap: () => setState(
                          () => _filter = AdminJobLifecycle.completed,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                sliver: jobs.isEmpty
                    ? SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Elan yoxdur',
                              style: textTheme.bodyLarge?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final job = jobs[index];
                            final life = admin.lifecycleForJob(job.id);
                            return AdminJobRow(
                              job: job,
                              lifecycle: life,
                              onToggleCompleted: () async {
                                final next = life == AdminJobLifecycle.active
                                    ? AdminJobLifecycle.completed
                                    : AdminJobLifecycle.active;
                                try {
                                  await admin.setJobLifecycle(job.id, next);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Status yeniləndi'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Xəta: $e'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              onDelete: () async {
                                try {
                                  await admin.deleteJob(job.id);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Elan silindi'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Xəta: $e'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              onEdit: () {
                                context.push(
                                  AppRoutes.jobDetail(job.id),
                                  extra: UserRole.user,
                                );
                              },
                            );
                          },
                          childCount: jobs.length,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.outline,
              width: selected ? 1.8 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}
