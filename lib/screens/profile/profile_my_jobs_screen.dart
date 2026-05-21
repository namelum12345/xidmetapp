import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_router.dart' show appRouter;

import '../../models/job_listing.dart';
import '../../models/user_role.dart';
import '../../router/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/job_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';

/// Elanlarım — aktiv / tamamlanmış.
class ProfileMyJobsScreen extends StatefulWidget {
  const ProfileMyJobsScreen({super.key, required this.viewerRole});

  final UserRole viewerRole;

  @override
  State<ProfileMyJobsScreen> createState() => _ProfileMyJobsScreenState();
}

class _ProfileMyJobsScreenState extends State<ProfileMyJobsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  StreamSubscription<Set<String>>? _appSub;
  Set<String> _workerJobIds = {};

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    final uid = AuthService.instance.firebaseUser?.uid;
    if (widget.viewerRole == UserRole.worker && uid != null) {
      _appSub = JobService.instance
          .jobIdsWithWorkerApplicationStream(uid)
          .listen((ids) {
        if (mounted) setState(() => _workerJobIds = ids);
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final q = GoRouterState.of(context).uri.queryParameters['tab'];
      if (q == 'completed' && _tabs.index != 1) {
        _tabs.animateTo(1);
      }
    });
  }

  @override
  void dispose() {
    _appSub?.cancel();
    _tabs.dispose();
    super.dispose();
  }

  List<JobListing> _mergedWorkerJobs(String uid) {
    final byId = <String, JobListing>{};
    for (final j in JobService.instance.allJobs()) {
      if (j.selectedWorkerId == uid) {
        byId[j.id] = j;
      }
    }
    for (final id in _workerJobIds) {
      final j = JobService.instance.getById(id);
      if (j != null) {
        byId[j.id] = j;
      }
    }
    final list = byId.values.toList();
    list.sort((a, b) => a.title.compareTo(b.title));
    return list;
  }

  List<JobListing> _sourceList() {
    final uid = AuthService.instance.firebaseUser?.uid;
    if (uid == null) return [];
    if (widget.viewerRole == UserRole.user) {
      return JobService.instance.jobsCreatedBy(uid);
    }
    return _mergedWorkerJobs(uid);
  }

  List<JobListing> _filtered(String status) {
    return _sourceList().where((j) => j.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Elanlarım'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => appRouter.pop(),
        ),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Aktiv'),
            Tab(text: 'Tamamlanıb'),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: JobService.instance,
        builder: (context, _) {
          return TabBarView(
            controller: _tabs,
            children: [
              _JobList(
                jobs: _filtered('active'),
                viewerRole: widget.viewerRole,
              ),
              _JobList(
                jobs: _filtered('completed'),
                viewerRole: widget.viewerRole,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _JobList extends StatelessWidget {
  const _JobList({
    required this.jobs,
    required this.viewerRole,
  });

  final List<JobListing> jobs;
  final UserRole viewerRole;

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return Center(
        child: Text(
          'Bu bölmədə elan yoxdur',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: jobs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final j = jobs[i];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => appRouter.push(AppRoutes.jobDetail(j.id), extra: viewerRole),
            child: AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    j.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    j.locationLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    j.postedLabel,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
