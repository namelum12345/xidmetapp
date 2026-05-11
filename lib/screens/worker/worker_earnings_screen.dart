import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/auth_service.dart';
import '../../services/job_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/worker/worker_stat_card.dart';

class WorkerEarningsScreen extends StatelessWidget {
  const WorkerEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.firebaseUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Giriş tapılmadı')));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Qazancım'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListenableBuilder(
        listenable: JobService.instance,
        builder: (context, _) {
          final s = JobService.instance.workerCompletedStats(uid);
          final monthLabel =
              '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              Text(
                'Məbləğlər tamamlanmış elanlardakı «Qiymət (₼)» sahəsinə əsasən hesablanır.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 18),
              WorkerStatCard(
                title: 'Ümumi qazanc',
                value: '${s.totalEarningsAzn.toStringAsFixed(0)} ₼',
                subtitle: 'Bütün tamamlanan işlər',
                icon: Icons.account_balance_wallet_outlined,
              ),
              const SizedBox(height: 14),
              WorkerStatCard(
                title: 'Bu ay ($monthLabel)',
                value: '${s.thisMonthEarningsAzn.toStringAsFixed(0)} ₼',
                subtitle: '${s.thisMonthCompleted} iş bu ayda tamamlanıb',
                icon: Icons.calendar_month_outlined,
              ),
              const SizedBox(height: 14),
              WorkerStatCard(
                title: 'Tamamlanan işlər',
                value: '${s.completedCount}',
                subtitle: 'Seçildiyiniz və bitirdiyiniz elanlar',
                icon: Icons.task_alt_outlined,
              ),
            ],
          );
        },
      ),
    );
  }
}
