import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../services/jobs_service.dart';
import '../../services/workers_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<JobModel> _allJobs = [];
  List<Map<String, dynamic>> _applications = [];
  WorkerModel? _workerProfile;
  bool _loadingJobs = true;
  bool _loadingApps = true;
  String? _jobsError;
  String? _appsError;
  String? _filterCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _init();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final profile = await WorkersService.instance.getMyProfile();
      if (mounted) setState(() => _workerProfile = profile);
    } catch (_) {}
    _loadJobs();
    _loadApplications();
  }

  Future<void> _loadJobs() async {
    setState(() { _loadingJobs = true; _jobsError = null; });
    try {
      final jobs = await JobsService.instance.getAll(status: 'open');
      if (mounted) setState(() { _allJobs = jobs; _loadingJobs = false; });
    } catch (e) {
      if (mounted) setState(() { _jobsError = e.toString(); _loadingJobs = false; });
    }
  }

  Future<void> _loadApplications() async {
    setState(() { _loadingApps = true; _appsError = null; });
    try {
      final apps = await JobsService.instance.getMyApplications();
      if (mounted) setState(() { _applications = apps; _loadingApps = false; });
    } catch (e) {
      if (mounted) setState(() { _appsError = e.toString(); _loadingApps = false; });
    }
  }

  List<String> get _myCategories => _workerProfile?.categories ?? [];

  List<JobModel> get _filteredJobs {
    if (_filterCategory != null) {
      return _allJobs.where((j) => j.category == _filterCategory).toList();
    }
    if (_myCategories.isNotEmpty) {
      final matching = _allJobs.where((j) => _myCategories.contains(j.category)).toList();
      final others = _allJobs.where((j) => !_myCategories.contains(j.category)).toList();
      return [...matching, ...others];
    }
    return _allJobs;
  }

  int get _matchingCount =>
      _myCategories.isEmpty ? 0 : _allJobs.where((j) => _myCategories.contains(j.category)).length;

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.user;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPrimary, kPrimary.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Salam, ${user?.name ?? 'İşçi'} 👷',
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _matchingCount > 0
                              ? '$_matchingCount uyğun iş elanı var'
                              : 'İş elanlarını kəşf edin',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
                    child: user?.photoUrl == null
                        ? Text(
                            user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'W',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
                          )
                        : null,
                  ),
                ],
              ),
            ),

            // Tabs
            Container(
              color: kPrimary,
              child: TabBar(
                controller: _tabController,
                tabs: [
                  const Tab(text: 'İş Elanları', icon: Icon(Icons.work_outline_rounded, size: 20)),
                  Tab(
                    text: 'Müraciətlərim (${_applications.length})',
                    icon: const Icon(Icons.send_rounded, size: 20),
                  ),
                ],
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                indicatorColor: Colors.white,
                indicatorSize: TabBarIndicatorSize.tab,
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildJobsTab(), _buildApplicationsTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobsTab() {
    if (_loadingJobs) return const Center(child: CircularProgressIndicator());
    if (_jobsError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: kTextSecondary),
            const SizedBox(height: 12),
            Text(_jobsError!, style: const TextStyle(color: kTextSecondary)),
            const SizedBox(height: 16),
            FilledButton(onPressed: _loadJobs, child: const Text('Yenilə')),
          ],
        ),
      );
    }

    final filtered = _filteredJobs;

    return Column(
      children: [
        // Category filter chips
        if (_myCategories.isNotEmpty)
          Container(
            height: 46,
            color: Theme.of(context).colorScheme.surface,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                _CategoryChip(
                  label: 'Hamısı (${_allJobs.length})',
                  selected: _filterCategory == null,
                  onTap: () => setState(() => _filterCategory = null),
                ),
                const SizedBox(width: 6),
                ..._myCategories.map((cat) {
                  final count = _allJobs.where((j) => j.category == cat).length;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _CategoryChip(
                      label: '${kCategoryIcons[cat] ?? ''} $cat ($count)',
                      selected: _filterCategory == cat,
                      highlighted: true,
                      onTap: () => setState(() => _filterCategory = cat),
                    ),
                  );
                }),
              ],
            ),
          ),

        // Match info
        if (_filterCategory == null && _matchingCount > 0)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.star_rounded, size: 15, color: Colors.green),
                const SizedBox(width: 6),
                Text(
                  'İlk $_matchingCount elan sizin ixtisasınıza uyğundur',
                  style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

        // Job list
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('💼', style: TextStyle(fontSize: 56)),
                      const SizedBox(height: 12),
                      Text(
                        _filterCategory != null
                            ? '$_filterCategory kateqoriyasında elan yoxdur'
                            : 'Hələ iş elanı yoxdur',
                        style: const TextStyle(color: kTextSecondary, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () {
                          setState(() => _filterCategory = null);
                          _loadJobs();
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Yenilə'),
                        style: FilledButton.styleFrom(backgroundColor: kPrimary),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadJobs,
                  color: kPrimary,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final job = filtered[i];
                      return _JobCard(
                        job: job,
                        isMatching: _myCategories.contains(job.category),
                        onTap: () => context.push('/job/${job.id}'),
                        onApply: () {
                          _loadJobs();
                          _loadApplications();
                        },
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildApplicationsTab() {
    if (_loadingApps) return const Center(child: CircularProgressIndicator());
    if (_appsError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: kTextSecondary),
            const SizedBox(height: 12),
            Text(_appsError!, style: const TextStyle(color: kTextSecondary)),
            const SizedBox(height: 16),
            FilledButton(onPressed: _loadApplications, child: const Text('Yenilə')),
          ],
        ),
      );
    }
    if (_applications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📋', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            const Text('Hələ heç bir işə müraciət etməmisiniz',
                style: TextStyle(color: kTextSecondary, fontSize: 16)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _tabController.animateTo(0),
              icon: const Icon(Icons.search_rounded),
              label: const Text('İş Axtar'),
              style: FilledButton.styleFrom(backgroundColor: kPrimary),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadApplications,
      color: kPrimary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _applications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _ApplicationCard(application: _applications[i]),
      ),
    );
  }
}

// ── Category filter chip ─────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.highlighted = false,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? kPrimary
              : (highlighted ? Colors.green.withOpacity(0.08) : Colors.grey.withOpacity(0.08)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? kPrimary
                : (highlighted ? Colors.green.withOpacity(0.4) : Colors.grey.shade300),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected
                ? Colors.white
                : (highlighted ? Colors.green.shade700 : kTextSecondary),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ── Job card ─────────────────────────────────────────────────────────────────

class _JobCard extends StatelessWidget {
  const _JobCard({
    required this.job,
    required this.onTap,
    required this.onApply,
    this.isMatching = false,
  });
  final JobModel job;
  final VoidCallback onTap;
  final VoidCallback onApply;
  final bool isMatching;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMatching ? Colors.green.withOpacity(0.4) : cs.outline,
          width: isMatching ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Matching badge
              if (isMatching)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded, size: 11, color: Colors.green),
                            SizedBox(width: 3),
                            Text(
                              'Sizə uyğun',
                              style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEBF5FF),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                job.category,
                                style: const TextStyle(fontSize: 11, color: kPrimary, fontWeight: FontWeight.w600),
                              ),
                            ),
                            if (job.isUrgent) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '🔥 Fövqəladə',
                                  style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (job.hasApplied)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '✓ Müraciət',
                        style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (job.description.isNotEmpty)
                Text(
                  job.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: kTextSecondary),
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: job.userPhoto.isNotEmpty ? NetworkImage(job.userPhoto) : null,
                    child: job.userPhoto.isEmpty
                        ? Text(
                            job.userName.isNotEmpty ? job.userName[0].toUpperCase() : 'U',
                            style: const TextStyle(fontSize: 12),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(job.userName,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis),
                        Text('${job.applicationsCount} müraciət',
                            style: const TextStyle(fontSize: 11, color: kTextSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      job.budgetRange,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.green),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (!job.hasApplied)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _showApplyDialog(context, job, onApply),
                    style: FilledButton.styleFrom(
                      backgroundColor: isMatching ? Colors.green : kPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    child: Text(
                      isMatching ? '⭐ Müraciət et' : 'Müraciət et',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showApplyDialog(BuildContext context, JobModel job, VoidCallback onApply) {
    showDialog(
      context: context,
      builder: (context) => _ApplyDialog(job: job, onApply: onApply),
    );
  }
}

// ── Application card ─────────────────────────────────────────────────────────

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.application});
  final Map<String, dynamic> application;

  @override
  Widget build(BuildContext context) {
    final status = application['application_status'] as String? ?? 'pending';
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    application['title'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Kateqoriya: ${application['category'] ?? ''}',
              style: const TextStyle(fontSize: 12, color: kTextSecondary),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bütçə: ${application['budget_min']}₼ – ${application['budget_max']}₼',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green),
                ),
                if (application['applied_at'] != null)
                  Text(
                    _formatDate(application['applied_at']),
                    style: const TextStyle(fontSize: 11, color: kTextSecondary),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      return '${d.day}.${d.month}.${d.year}';
    } catch (_) {
      return dateStr;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = status == 'accepted'
        ? Colors.green
        : status == 'rejected'
            ? Colors.red
            : Colors.orange;
    final label = status == 'accepted'
        ? '✓ Qəbul'
        : status == 'rejected'
            ? '✗ Rədd'
            : '⏳ Gözləmə';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Apply dialog ─────────────────────────────────────────────────────────────

class _ApplyDialog extends StatefulWidget {
  const _ApplyDialog({required this.job, required this.onApply});
  final JobModel job;
  final VoidCallback onApply;

  @override
  State<_ApplyDialog> createState() => _ApplyDialogState();
}

class _ApplyDialogState extends State<_ApplyDialog> {
  final _ctrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    setState(() => _loading = true);
    try {
      await JobsService.instance.applyToJob(widget.job.id, coverLetter: _ctrl.text);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Müraciətiniz qəbul edildi!'), backgroundColor: Colors.green),
        );
        widget.onApply();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xəta: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('İşə müraciət edin'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.job.title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 4),
            Text(widget.job.budgetRange,
                style: const TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            const Text('Özünüz haqqında qısa məlumat (isteğe bağlı):',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _ctrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Niyə bu iş üçün əlverişlisiniz?',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Ləğv et'),
        ),
        FilledButton(
          onPressed: _loading ? null : _apply,
          style: FilledButton.styleFrom(backgroundColor: kPrimary),
          child: _loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Müraciət et'),
        ),
      ],
    );
  }
}
