import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/job_category.dart';
import '../models/job_listing.dart';
import '../models/user_role.dart';
import '../router/app_routes.dart';
import '../services/job_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';
import 'app_create_fab.dart';
import 'category_item.dart';
import 'custom_search_bar.dart';
import 'job_card.dart';

/// Shared marketplace shell: location bar, search, categories, job list, optional FAB.
class MarketplaceDashboardPage extends StatefulWidget {
  const MarketplaceDashboardPage({
    super.key,
    required this.viewerRole,
    required this.jobsProvider,
    this.showCreateFab = false,
    this.showWorkerMatchBadges = false,
  });

  final UserRole viewerRole;
  /// Return fresh job lists (məs. [JobService]) yenidən qurulanda.
  final List<JobListing> Function() jobsProvider;
  final bool showCreateFab;
  final bool showWorkerMatchBadges;

  @override
  State<MarketplaceDashboardPage> createState() =>
      _MarketplaceDashboardPageState();
}

class _MarketplaceDashboardPageState extends State<MarketplaceDashboardPage> {
  final _search = TextEditingController();
  JobCategoryId? _categoryFilter;
  var _locationIndex = 0;

  static const _locations = [
    'Bakı — mərkəz',
    'Sumqayıt',
    'Gəncə',
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<JobListing> get _filtered {
    var list = widget.jobsProvider();
    final q = _search.text.trim().toLowerCase();
    if (_categoryFilter != null) {
      list = list.where((j) => j.categoryId == _categoryFilter).toList();
    }
    if (q.isNotEmpty) {
      list = list
          .where(
            (j) =>
                j.title.toLowerCase().contains(q) ||
                j.shortDescription.toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

  Future<void> _openCreateJob() async {
    final created = await context.push<bool>(AppRoutes.createJob);
    if (created == true && mounted) setState(() {});
  }

  void _openJob(JobListing job) {
    context.push(
      AppRoutes.jobDetail(job.id),
      extra: widget.viewerRole,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final jobs = _filtered;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('jobs')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          debugPrint('[jobs] ui stream error: ${snap.error}');
        } else if (snap.hasData) {
          debugPrint('[jobs] ui stream size: ${snap.data!.docs.length}');
        }
        return SafeArea(
          bottom: false,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(child: _LocationButton(
                        label: _locations[_locationIndex],
                        onTap: _pickLocation,
                      )),
                      const SizedBox(width: 12),
                      _CircleIconButton(
                        icon: Icons.notifications_none_rounded,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Bildirişlər tezliklə'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: CustomSearchBar(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      CategoryItem(
                        category: null,
                        label: 'Hamısı',
                        selected: _categoryFilter == null,
                        onTap: () => setState(() => _categoryFilter = null),
                      ),
                      ...JobCategoryId.values.map(
                        (c) => CategoryItem(
                          category: c,
                          label: c.labelAz,
                          selected: _categoryFilter == c,
                          onTap: () =>
                              setState(() => _categoryFilter = c),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: (snap.connectionState == ConnectionState.waiting &&
                          !snap.hasData)
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2.5,
                          ),
                        )
                      : !JobService.instance.hasJobsCatalogSynced
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2.5,
                          ),
                        )
                      : jobs.isEmpty
                          ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              'Elan yoxdur',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.fromLTRB(
                            20,
                            4,
                            20,
                            widget.showCreateFab ? 100 + bottomPad : 24 + bottomPad,
                          ),
                          itemCount: jobs.length,
                          itemBuilder: (context, i) {
                            final job = jobs[i];
                            return JobCard(
                              job: job,
                              showMatchBadge: widget.showWorkerMatchBadges,
                              onTap: () => _openJob(job),
                            );
                          },
                        ),
                ),
              ],
              ),
              if (widget.showCreateFab)
                Positioned(
                  right: 20,
                  bottom: 24 + bottomPad,
                  child: AppCreateFab(onPressed: _openCreateJob),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickLocation() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.paddingOf(ctx).bottom + 16,
          ),
          child: AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Məkan',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 16),
                ...List.generate(_locations.length, (i) {
                  final sel = i == _locationIndex;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() => _locationIndex = i);
                          Navigator.pop(ctx);
                        },
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMd),
                        child: Ink(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                            border: Border.all(
                              color: sel
                                  ? AppColors.primary
                                  : AppColors.outline,
                              width: sel ? 2 : 1,
                            ),
                            color: sel
                                ? AppColors.primary.withValues(alpha: 0.06)
                                : AppColors.background,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.place_outlined,
                                color: sel
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _locations[i],
                                  style: Theme.of(ctx)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                ),
                              ),
                              if (sel)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.primary,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LocationButton extends StatelessWidget {
  const _LocationButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppColors.outline),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.place_rounded,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      elevation: 0,
      shadowColor: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Ink(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.outline),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
