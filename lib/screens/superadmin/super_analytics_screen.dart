import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/job_category.dart';
import '../../services/super_admin_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

/// Superadmin → "Analitika" tabı.
/// Real Firestore məlumatları:
/// - Qazanc (komissiya): tamamlanmış işlərin cəmindən faiz.
/// - Sayğaclar: istifadəçilər / icraçılar / adminlər / elanlar.
/// - Elan statuslarının bölgüsü, ən populyar kateqoriyalar, son 7 gün qeydiyyatlar.
class SuperAnalyticsScreen extends StatefulWidget {
  const SuperAnalyticsScreen({super.key});

  @override
  State<SuperAnalyticsScreen> createState() => _SuperAnalyticsScreenState();
}

class _SuperAnalyticsScreenState extends State<SuperAnalyticsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _usersSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _workersSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _jobsSub;

  QuerySnapshot<Map<String, dynamic>>? _usersSnap;
  QuerySnapshot<Map<String, dynamic>>? _workersSnap;
  QuerySnapshot<Map<String, dynamic>>? _jobsSnap;

  Object? _error;

  @override
  void initState() {
    super.initState();
    _usersSub = _db.collection('users').snapshots().listen(
      (s) => setState(() => _usersSnap = s),
      onError: (e) => setState(() => _error = e),
    );
    _workersSub = _db.collection('workers').snapshots().listen(
      (s) => setState(() => _workersSnap = s),
      onError: (e) => setState(() => _error = e),
    );
    _jobsSub = _db.collection('jobs').snapshots().listen(
      (s) => setState(() => _jobsSnap = s),
      onError: (e) => setState(() => _error = e),
    );
  }

  @override
  void dispose() {
    _usersSub?.cancel();
    _workersSub?.cancel();
    _jobsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (_error != null) {
      return ColoredBox(
        color: AppColors.background,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Firestore xətası: $_error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final loaded =
        _usersSnap != null && _workersSnap != null && _jobsSnap != null;
    if (!loaded) {
      return const ColoredBox(
        color: AppColors.background,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final users = _usersSnap!.docs;
    final workers = _workersSnap!.docs;
    final jobs = _jobsSnap!.docs;

    final commissionPercent = SuperAdminService.instance.commissionPercent;
    final earnings = _computeEarnings(jobs, commissionPercent);
    final counts = _computeCounts(users: users, workers: workers, jobs: jobs);
    final categoryBreakdown = _computeCategoryBreakdown(jobs);
    final registrations = _computeRegistrationsLast7Days(users);
    final statusBreakdown = _computeStatusBreakdown(jobs);

    return ColoredBox(
      color: AppColors.background,
      child: ListenableBuilder(
        listenable: SuperAdminService.instance,
        builder: (context, _) {
          final live = SuperAdminService.instance.commissionPercent;
          final liveEarnings = _computeEarnings(jobs, live);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Text(
                'Analitika',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Real vaxt göstəricilər (Firestore)',
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              _EarningsCard(
                earnings: liveEarnings,
                commissionPercent: live,
              ),
              const SizedBox(height: 14),
              _CountsGrid(counts: counts),
              const SizedBox(height: 14),
              _StatusBreakdownCard(breakdown: statusBreakdown),
              const SizedBox(height: 14),
              _RegistrationsChartCard(daily: registrations),
              const SizedBox(height: 14),
              _CategoryBreakdownCard(items: categoryBreakdown),
              const SizedBox(height: 14),
              _RecentCompletedJobsCard(
                jobs: earnings.completedJobsForList,
              ),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================
// Hesablamalar
// ============================================================

class _EarningsResult {
  _EarningsResult({
    required this.totalRevenueAzn,
    required this.commissionAzn,
    required this.completedCount,
    required this.activeCount,
    required this.cancelledCount,
    required this.thisMonthRevenueAzn,
    required this.thisMonthCommissionAzn,
    required this.completedJobsForList,
  });

  final double totalRevenueAzn;
  final double commissionAzn;
  final int completedCount;
  final int activeCount;
  final int cancelledCount;
  final double thisMonthRevenueAzn;
  final double thisMonthCommissionAzn;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> completedJobsForList;
}

_EarningsResult _computeEarnings(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> jobs,
  double commissionPercent,
) {
  double total = 0;
  double month = 0;
  int completed = 0;
  int active = 0;
  int cancelled = 0;
  final completedList =
      <QueryDocumentSnapshot<Map<String, dynamic>>>[];
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month);

  for (final d in jobs) {
    final m = d.data();
    final status = (m['status'] as String? ?? 'active').toLowerCase();
    final price = (m['priceAzn'] as num?)?.toDouble() ?? 0;
    switch (status) {
      case 'completed':
        completed++;
        total += price;
        completedList.add(d);
        final completedAt = m['completedAt'];
        if (completedAt is Timestamp) {
          final dt = completedAt.toDate();
          if (!dt.isBefore(monthStart)) month += price;
        }
        break;
      case 'cancelled':
        cancelled++;
        break;
      default:
        active++;
    }
  }

  final rate = (commissionPercent / 100).clamp(0.0, 1.0);
  return _EarningsResult(
    totalRevenueAzn: total,
    commissionAzn: total * rate,
    completedCount: completed,
    activeCount: active,
    cancelledCount: cancelled,
    thisMonthRevenueAzn: month,
    thisMonthCommissionAzn: month * rate,
    completedJobsForList: completedList,
  );
}

class _CountsResult {
  _CountsResult({
    required this.users,
    required this.workers,
    required this.admins,
    required this.jobs,
  });

  final int users;
  final int workers;
  final int admins;
  final int jobs;
}

_CountsResult _computeCounts({
  required List<QueryDocumentSnapshot<Map<String, dynamic>>> users,
  required List<QueryDocumentSnapshot<Map<String, dynamic>>> workers,
  required List<QueryDocumentSnapshot<Map<String, dynamic>>> jobs,
}) {
  int admins = 0;
  int regularUsers = 0;
  for (final d in users) {
    final r = (d.data()['role'] as String? ?? '').trim().toLowerCase();
    if (r == 'admin') admins++;
    if (r == 'user') regularUsers++;
  }
  return _CountsResult(
    users: regularUsers,
    workers: workers.length,
    admins: admins,
    jobs: jobs.length,
  );
}

class _StatusBreakdown {
  _StatusBreakdown({
    required this.active,
    required this.completed,
    required this.cancelled,
  });

  final int active;
  final int completed;
  final int cancelled;

  int get total => active + completed + cancelled;
}

_StatusBreakdown _computeStatusBreakdown(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> jobs,
) {
  int a = 0, c = 0, x = 0;
  for (final d in jobs) {
    final s = (d.data()['status'] as String? ?? 'active').toLowerCase();
    switch (s) {
      case 'completed':
        c++;
        break;
      case 'cancelled':
        x++;
        break;
      default:
        a++;
    }
  }
  return _StatusBreakdown(active: a, completed: c, cancelled: x);
}

List<(JobCategoryId, int)> _computeCategoryBreakdown(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> jobs,
) {
  final counts = <JobCategoryId, int>{};
  for (final d in jobs) {
    final cid = (d.data()['categoryId'] as String? ?? '').trim();
    JobCategoryId? cat;
    for (final c in JobCategoryId.values) {
      if (c.id == cid) {
        cat = c;
        break;
      }
    }
    if (cat == null) continue;
    counts[cat] = (counts[cat] ?? 0) + 1;
  }
  final entries = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return entries.map((e) => (e.key, e.value)).toList();
}

List<int> _computeRegistrationsLast7Days(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> users,
) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final buckets = List<int>.filled(7, 0);
  for (final d in users) {
    final ts = d.data()['createdAt'];
    if (ts is! Timestamp) continue;
    final dt = ts.toDate();
    final day = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(day).inDays;
    if (diff >= 0 && diff < 7) {
      buckets[6 - diff]++;
    }
  }
  return buckets;
}

// ============================================================
// UI parçaları
// ============================================================

String _fmtAzn(double v) {
  if (v >= 1000) {
    final k = v / 1000;
    return '${k.toStringAsFixed(k >= 100 ? 0 : 1)}k ₼';
  }
  return '${v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2)} ₼';
}

class _EarningsCard extends StatelessWidget {
  const _EarningsCard({
    required this.earnings,
    required this.commissionPercent,
  });

  final _EarningsResult earnings;
  final double commissionPercent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        gradient: const LinearGradient(
          colors: [Color(0xFF5B54E5), Color(0xFF7D76FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payments_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Komissiya qazancı',
                style: textTheme.titleMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${commissionPercent.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _fmtAzn(earnings.commissionAzn),
            style: textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ümumi dövriyyə: ${_fmtAzn(earnings.totalRevenueAzn)}',
            style: textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _EarningSubMetric(
                  label: 'Bu ay komissiya',
                  value: _fmtAzn(earnings.thisMonthCommissionAzn),
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _EarningSubMetric(
                  label: 'Tamamlanmış iş',
                  value: '${earnings.completedCount}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EarningSubMetric extends StatelessWidget {
  const _EarningSubMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountsGrid extends StatelessWidget {
  const _CountsGrid({required this.counts});

  final _CountsResult counts;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.7,
      children: [
        _CountTile(
          icon: Icons.people_outline_rounded,
          label: 'İstifadəçilər',
          value: '${counts.users}',
          accent: const Color(0xFF6C63FF),
        ),
        _CountTile(
          icon: Icons.engineering_outlined,
          label: 'İcraçılar',
          value: '${counts.workers}',
          accent: const Color(0xFF22C55E),
        ),
        _CountTile(
          icon: Icons.shield_outlined,
          label: 'Adminlər',
          value: '${counts.admins}',
          accent: const Color(0xFFF59E0B),
        ),
        _CountTile(
          icon: Icons.work_outline_rounded,
          label: 'Elanlar',
          value: '${counts.jobs}',
          accent: const Color(0xFF0EA5E9),
        ),
      ],
    );
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBreakdownCard extends StatelessWidget {
  const _StatusBreakdownCard({required this.breakdown});

  final _StatusBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final total = math.max(breakdown.total, 1);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Elanların statusu',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  Expanded(
                    flex: breakdown.active,
                    child: Container(color: const Color(0xFF6C63FF)),
                  ),
                  Expanded(
                    flex: breakdown.completed,
                    child: Container(color: const Color(0xFF22C55E)),
                  ),
                  Expanded(
                    flex: breakdown.cancelled,
                    child: Container(color: const Color(0xFFEF4444)),
                  ),
                  if (total == 1)
                    Expanded(
                      flex: 1,
                      child: Container(color: AppColors.outline),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _LegendRow(
            color: const Color(0xFF6C63FF),
            label: 'Aktiv',
            value: breakdown.active,
            total: breakdown.total,
          ),
          _LegendRow(
            color: const Color(0xFF22C55E),
            label: 'Tamamlanmış',
            value: breakdown.completed,
            total: breakdown.total,
          ),
          _LegendRow(
            color: const Color(0xFFEF4444),
            label: 'Ləğv',
            value: breakdown.cancelled,
            total: breakdown.total,
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
    required this.total,
  });

  final Color color;
  final String label;
  final int value;
  final int total;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final pct = total == 0 ? 0 : (value * 100 / total);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '$value (${pct.toStringAsFixed(0)}%)',
            style: textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RegistrationsChartCard extends StatelessWidget {
  const _RegistrationsChartCard({required this.daily});

  final List<int> daily;

  static const _labels = ['B.e', 'Ç.a', 'Ç', 'C.a', 'C', 'Ş', 'B'];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();
    final maxV = math.max(daily.reduce(math.max), 1);
    final totalWeek = daily.fold<int>(0, (a, b) => a + b);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Son 7 gün qeydiyyatlar',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '+$totalWeek',
                style: textTheme.titleSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final v = daily[i];
                final h = (v / maxV) * 110;
                final day = now.subtract(Duration(days: 6 - i));
                final weekdayIdx = (day.weekday - 1).clamp(0, 6);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          v > 0 ? '$v' : '',
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: math.max(h, 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                AppColors.primary.withValues(alpha: 0.4),
                                AppColors.primary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _labels[weekdayIdx],
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBreakdownCard extends StatelessWidget {
  const _CategoryBreakdownCard({required this.items});

  final List<(JobCategoryId, int)> items;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (items.isEmpty) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ən populyar kateqoriyalar',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Hələ kifayət qədər elan yoxdur',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    final total = items.fold<int>(0, (a, e) => a + e.$2);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ən populyar kateqoriyalar',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          ...items.take(5).map((pair) {
            final cat = pair.$1;
            final n = pair.$2;
            final pct = total == 0 ? 0.0 : n / total;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(cat.icon, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          cat.labelAz,
                          style: textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '$n • ${(pct * 100).toStringAsFixed(0)}%',
                        style: textTheme.labelMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 8,
                      backgroundColor:
                          AppColors.outline.withValues(alpha: 0.5),
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _RecentCompletedJobsCard extends StatelessWidget {
  const _RecentCompletedJobsCard({required this.jobs});

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> jobs;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final sorted = [...jobs]..sort((a, b) {
        final ta = a.data()['completedAt'];
        final tb = b.data()['completedAt'];
        if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
        if (ta is Timestamp) return -1;
        if (tb is Timestamp) return 1;
        return 0;
      });
    final top = sorted.take(5).toList();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Son tamamlanmış işlər',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          if (top.isEmpty)
            Text(
              'Hələ tamamlanmış iş yoxdur',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else
            ...top.map((d) {
              final m = d.data();
              final title =
                  (m['title'] as String? ?? '').trim().isEmpty
                      ? 'Elan'
                      : (m['title'] as String);
              final price = (m['priceAzn'] as num?)?.toDouble() ?? 0;
              final ts = m['completedAt'];
              final dt = ts is Timestamp ? ts.toDate() : null;
              final dateStr = dt == null
                  ? ''
                  : '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 18,
                      color: Color(0xFF22C55E),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      dateStr,
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _fmtAzn(price),
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
