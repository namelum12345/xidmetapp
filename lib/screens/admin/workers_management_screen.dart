import 'package:flutter/material.dart';

import '../../services/admin_data_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_worker_row.dart';

/// İcraçılar — shell tabı; **Scaffold/AppBar/pop yoxdur** (alt nav itməsin).
class WorkersManagementScreen extends StatelessWidget {
  const WorkersManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: ListenableBuilder(
        listenable: AdminDataService.instance,
        builder: (context, _) {
          final admin = AdminDataService.instance;
          final workers = admin.workers;

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'İcraçılar',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final w = workers[index];
                      return AdminWorkerRow(
                        worker: w,
                        onApprove: () async {
                          try {
                            await admin.approveWorker(w.id);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${w.name} təsdiqləndi'),
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
                        onDisable: () async {
                          try {
                            await admin.disableWorker(w.id);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${w.name} deaktiv edildi'),
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
                      );
                    },
                    childCount: workers.length,
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
