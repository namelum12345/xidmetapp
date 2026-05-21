import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../services/jobs_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class JobDetailScreen extends StatefulWidget {
  final String jobId;
  const JobDetailScreen({required this.jobId, super.key});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  JobModel? _job;
  List<Map<String, dynamic>> _applicants = [];
  bool _loading = true;
  bool _loadingApplicants = false;
  String? _error;

  bool get _isOwner => _job?.userId == AuthService.instance.user?.id;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final job = await JobsService.instance.get(widget.jobId);
      if (mounted) {
        setState(() { _job = job; _loading = false; });
        if (_job!.userId == AuthService.instance.user?.id) {
          _loadApplicants();
        }
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _loadApplicants() async {
    setState(() => _loadingApplicants = true);
    try {
      final apps = await JobsService.instance.getJobApplications(widget.jobId);
      if (mounted) setState(() { _applicants = apps; _loadingApplicants = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingApplicants = false);
    }
  }

  Future<void> _updateStatus(String appId, String status) async {
    try {
      await JobsService.instance.updateApplicationStatus(widget.jobId, appId, status);
      _loadApplicants();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'accepted' ? 'İşçi qəbul edildi!' : 'Müraciət rədd edildi'),
            backgroundColor: status == 'accepted' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xəta: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('İş Elanı'),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: kTextSecondary),
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: kTextSecondary)),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: _load, child: const Text('Yenilə')),
                    ],
                  ),
                )
              : _job == null
                  ? const Center(child: Text('İş tapılmadı'))
                  : _isOwner
                      ? _buildOwnerView()
                      : _buildWorkerView(),
      bottomNavigationBar: _job != null && !_isOwner && !_job!.hasApplied
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: () => _showApplyDialog(context),
                style: FilledButton.styleFrom(
                  backgroundColor: kPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Müraciət Et', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            )
          : null,
    );
  }

  // ── Owner view: job info + applicants ────────────────────────────────────

  Widget _buildOwnerView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Job summary card
        _JobSummaryCard(job: _job!),
        const SizedBox(height: 16),

        // Applicants section
        Row(
          children: [
            const Text('Müraciət edənlər',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_applicants.length}',
                style: const TextStyle(fontSize: 13, color: kPrimary, fontWeight: FontWeight.w700),
              ),
            ),
            const Spacer(),
            if (_loadingApplicants)
              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ),
        const SizedBox(height: 12),

        if (!_loadingApplicants && _applicants.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: const Column(
              children: [
                Text('👥', style: TextStyle(fontSize: 40)),
                SizedBox(height: 8),
                Text('Hələ müraciət yoxdur',
                    style: TextStyle(color: kTextSecondary, fontSize: 14)),
                SizedBox(height: 4),
                Text('İşçilər elanınızı gördükdə müraciət edəcəklər',
                    style: TextStyle(color: kTextSecondary, fontSize: 12),
                    textAlign: TextAlign.center),
              ],
            ),
          ),

        ..._applicants.map((app) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ApplicantCard(
                applicant: app,
                onAccept: () => _updateStatus(app['id'], 'accepted'),
                onReject: () => _updateStatus(app['id'], 'rejected'),
              ),
            )),
      ],
    );
  }

  // ── Worker view: job info + apply ────────────────────────────────────────

  Widget _buildWorkerView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_job!.title,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _Tag(label: _job!.category, color: kPrimary, bg: const Color(0xFFEBF5FF)),
                              if (_job!.isUrgent) ...[
                                const SizedBox(width: 8),
                                _Tag(
                                    label: '🔥 Fövqəladə',
                                    color: Colors.red,
                                    bg: Colors.red.withOpacity(0.1)),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_job!.hasApplied)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('✓ Müraciət etdiniz',
                            style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Theme.of(context).colorScheme.outline),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Stat(label: 'Bütçə', value: _job!.budgetRange, valueColor: Colors.green),
                  Container(height: 30, width: 1, color: Colors.grey.shade300),
                  _Stat(label: 'Müraciətlər', value: '${_job!.applicationsCount}', valueColor: kPrimary),
                  Container(height: 30, width: 1, color: Colors.grey.shade300),
                  _Stat(
                    label: 'Status',
                    value: _job!.status == 'open' ? 'Açıq' : 'Bağlı',
                    valueColor: _job!.status == 'open' ? Colors.green : Colors.orange,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Təsvir', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  _job!.description.isEmpty ? 'Təsvir yoxdur' : _job!.description,
                  style: const TextStyle(fontSize: 14, color: kTextSecondary, height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Address
          if (_job!.address.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ünvan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: kPrimary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_job!.address,
                            style: const TextStyle(fontSize: 14, color: kTextSecondary)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Employer info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Theme.of(context).colorScheme.outline),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage:
                        _job!.userPhoto.isNotEmpty ? NetworkImage(_job!.userPhoto) : null,
                    child: _job!.userPhoto.isEmpty
                        ? Text(_job!.userName.isNotEmpty ? _job!.userName[0].toUpperCase() : 'U')
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_job!.userName,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        Text(
                          _job!.userIsOnline ? 'Onlayn' : 'Oflayn',
                          style: TextStyle(
                              fontSize: 12,
                              color: _job!.userIsOnline ? Colors.green : kTextSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  void _showApplyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _ApplyDialog(job: _job!, onApply: _load),
    );
  }
}

// ── Job summary card (owner view) ─────────────────────────────────────────

class _JobSummaryCard extends StatelessWidget {
  const _JobSummaryCard({required this.job});
  final JobModel job;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(job.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Row(
            children: [
              _Tag(label: job.category, color: kPrimary, bg: const Color(0xFFEBF5FF)),
              if (job.isUrgent) ...[
                const SizedBox(width: 6),
                _Tag(label: '🔥 Fövqəladə', color: Colors.red, bg: Colors.red.withOpacity(0.1)),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.attach_money_rounded, size: 16, color: Colors.green),
              const SizedBox(width: 4),
              Text(job.budgetRange,
                  style: const TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.w700)),
              const SizedBox(width: 16),
              const Icon(Icons.people_outline_rounded, size: 16, color: kTextSecondary),
              const SizedBox(width: 4),
              Text('${job.applicationsCount} müraciət',
                  style: const TextStyle(fontSize: 13, color: kTextSecondary)),
            ],
          ),
          if (job.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(job.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: kTextSecondary)),
          ],
        ],
      ),
    );
  }
}

// ── Applicant card ─────────────────────────────────────────────────────────

class _ApplicantCard extends StatelessWidget {
  const _ApplicantCard({
    required this.applicant,
    required this.onAccept,
    required this.onReject,
  });
  final Map<String, dynamic> applicant;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final status = applicant['status'] as String? ?? 'pending';
    final name = applicant['worker_name'] as String? ?? 'İşçi';
    final photo = applicant['worker_photo'] as String? ?? '';
    final rating = (applicant['worker_rating'] as num?)?.toDouble() ?? 0.0;
    final ratingCount = applicant['worker_rating_count'] as int? ?? 0;
    final coverLetter = applicant['cover_letter'] as String? ?? '';

    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: status == 'accepted'
              ? Colors.green.withOpacity(0.4)
              : status == 'rejected'
                  ? Colors.red.withOpacity(0.2)
                  : cs.outline,
          width: status == 'accepted' ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                child: photo.isEmpty
                    ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'İ',
                        style: const TextStyle(fontWeight: FontWeight.w700))
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    if (ratingCount > 0)
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                          const SizedBox(width: 3),
                          Text(
                            '${rating.toStringAsFixed(1)} ($ratingCount rəy)',
                            style: const TextStyle(fontSize: 12, color: kTextSecondary),
                          ),
                        ],
                      )
                    else
                      const Text('Rəy yoxdur', style: TextStyle(fontSize: 12, color: kTextSecondary)),
                  ],
                ),
              ),
              _StatusPill(status: status),
            ],
          ),
          if (coverLetter.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                '"$coverLetter"',
                style: const TextStyle(fontSize: 13, color: kTextSecondary, fontStyle: FontStyle.italic),
              ),
            ),
          ],
          if (status == 'pending') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('Rədd et', style: TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: onAccept,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('Qəbul et', style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    if (status == 'pending') return const SizedBox.shrink();
    final color = status == 'accepted' ? Colors.green : Colors.red;
    final label = status == 'accepted' ? '✓ Qəbul' : '✗ Rədd';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700)),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color, required this.bg});
  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.valueColor});
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: kTextSecondary)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: valueColor)),
      ],
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
            const SizedBox(height: 16),
            const Text('Özünüz haqqında (isteğe bağlı):',
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
