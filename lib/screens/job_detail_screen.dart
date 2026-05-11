import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../models/job_listing.dart';
import '../models/user_role.dart';
import '../router/app_routes.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/job_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/gradient_primary_button.dart';

class JobDetailScreen extends StatefulWidget {
  const JobDetailScreen({
    super.key,
    required this.jobId,
    required this.viewerRole,
  });

  final String jobId;
  final UserRole viewerRole;

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  final _offerPrice = TextEditingController();

  @override
  void dispose() {
    _offerPrice.dispose();
    super.dispose();
  }

  String? _offerValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Təklif məbləği daxil edin';
    final n = double.tryParse(v.trim().replaceAll(',', '.'));
    if (n == null || n <= 0) return 'Düzgün məbləğ';
    return null;
  }

  Future<void> _sendOffer() async {
    final err = _offerValidator(_offerPrice.text);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    final amount = double.tryParse(
      _offerPrice.text.trim().replaceAll(',', '.'),
    );
    if (amount == null || amount <= 0) return;

    try {
      final threadId = await ChatService.instance.createThreadFromWorkerOffer(
        jobId: widget.jobId,
        offerAmount: amount,
      );
      if (!mounted) return;
      context.push(AppRoutes.chat(threadId), extra: UserRole.worker);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _selectWorker(String workerId) async {
    try {
      await JobService.instance.selectWorker(widget.jobId, workerId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İcraçı seçildi')),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<void> _rateAndComplete(JobListing job) async {
    final starsNotifier = ValueNotifier<int>(5);
    final commentController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Qiymətləndirmə'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('İcraçının işini qiymətləndirin (1–5)'),
              const SizedBox(height: 12),
              ValueListenableBuilder<int>(
                valueListenable: starsNotifier,
                builder: (context, value, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final n = i + 1;
                      return IconButton(
                        onPressed: () => starsNotifier.value = n,
                        icon: Icon(
                          n <= value ? Icons.star_rounded : Icons.star_outline,
                          color: AppColors.primary,
                          size: 32,
                        ),
                      );
                    }),
                  );
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                maxLines: 3,
                maxLength: 2000,
                decoration: const InputDecoration(
                  labelText: 'Rəy (istəyə bağlı)',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ləğv'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tamamla'),
          ),
        ],
      ),
    );
    final stars = starsNotifier.value;
    final reviewComment = commentController.text.trim();
    starsNotifier.dispose();
    commentController.dispose();
    if (ok != true || !mounted) return;

    try {
      await JobService.instance.completeJobWithRating(
        jobId: job.id,
        rating: stars,
        reviewComment: reviewComment.isEmpty ? null : reviewComment,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elan tamamlandı')),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<String?> _workerDisplayName(String workerId) async {
    final d =
        await FirebaseFirestore.instance.collection('users').doc(workerId).get();
    if (!d.exists) return null;
    final m = d.data()!;
    final n = '${m['name'] ?? ''} ${m['surname'] ?? ''}'.trim();
    return n.isEmpty ? workerId : n;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final uid = AuthService.instance.firebaseUser?.uid;

    return ListenableBuilder(
      listenable: JobService.instance,
      builder: (context, _) {
        final catalog = JobService.instance;
        final job = catalog.getById(widget.jobId);

        if (job == null) {
          final loading = !catalog.hasJobsCatalogSynced;
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.pop(),
              ),
              title: const Text('Elan'),
            ),
            body: Center(
              child: loading
                  ? const CircularProgressIndicator(color: AppColors.primary)
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Elan tapılmadı və ya silinib.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
            ),
          );
        }

        final priceLine = job.priceAzn == null
            ? 'Razılaşma ilə'
            : '${job.priceAzn!.toStringAsFixed(0)} ₼';

        final showWorkerPanel = widget.viewerRole == UserRole.worker;
        final isOwner = uid != null && uid == job.createdBy;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
            ),
            title: Text(
              job.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          resizeToAvoidBottomInset: true,
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job.title,
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              job.fullDescription,
                              style: textTheme.bodyLarge?.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DetailRow(
                              icon: Icons.place_outlined,
                              label: 'Ünvan',
                              value: job.locationLabel,
                            ),
                            const Divider(height: 28),
                            _DetailRow(
                              icon: Icons.payments_outlined,
                              label: 'Büdcə',
                              value: priceLine,
                            ),
                            const Divider(height: 28),
                            _DetailRow(
                              icon: Icons.schedule_rounded,
                              label: 'Yerləşdirmə',
                              value: job.postedLabel,
                            ),
                            const Divider(height: 28),
                            _DetailRow(
                              icon: Icons.person_outline_rounded,
                              label: 'Paylaşan',
                              value: job.posterName,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              job.posterHint,
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppCard(
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.12),
                              child: Text(
                                job.posterName.isNotEmpty
                                    ? job.posterName[0].toUpperCase()
                                    : '?',
                                style: textTheme.titleLarge?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    job.posterName,
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    job.posterHint,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isOwner && job.status == 'active') ...[
                        const SizedBox(height: 16),
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Təkliflər',
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 12),
                              StreamBuilder<List<Map<String, dynamic>>>(
                                stream: JobService.instance
                                    .applicationsStream(widget.jobId),
                                builder: (context, snap) {
                                  if (snap.connectionState ==
                                          ConnectionState.waiting &&
                                      !snap.hasData) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 24,
                                      ),
                                      child: Center(
                                        child: SizedBox(
                                          width: 28,
                                          height: 28,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  if (!snap.hasData || snap.data!.isEmpty) {
                                    return Text(
                                      'Hələ təklif yoxdur.',
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    );
                                  }
                                  final apps = snap.data!;
                                  return Column(
                                    children: apps.map((a) {
                                      final wid = a['workerId'] as String? ??
                                          a['id'] as String? ??
                                          '';
                                      final offer = (a['offerAmount'] as num?)
                                          ?.toDouble();
                                      final st = a['status'] as String? ??
                                          'pending';
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 10),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: FutureBuilder<String?>(
                                                future: _workerDisplayName(
                                                  wid,
                                                ),
                                                builder: (ctx, sn) {
                                                  final name =
                                                      sn.data ?? wid;
                                                  return Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        name,
                                                        style: textTheme
                                                            .titleSmall
                                                            ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                      if (offer != null)
                                                        Text(
                                                          '$offer ₼',
                                                          style: textTheme
                                                              .bodySmall,
                                                        ),
                                                      Text(
                                                        st,
                                                        style: textTheme
                                                            .labelSmall
                                                            ?.copyWith(
                                                          color: AppColors
                                                              .textSecondary,
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              ),
                                            ),
                                            if (job.selectedWorkerId ==
                                                    null &&
                                                st == 'pending')
                                              TextButton(
                                                onPressed: () =>
                                                    _selectWorker(wid),
                                                child: const Text('Seç'),
                                              ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        if (job.selectedWorkerId != null &&
                            job.userRating == null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: GradientPrimaryButton(
                              label: 'Tamamla və qiymətləndir',
                              onPressed: () => _rateAndComplete(job),
                            ),
                          ),
                      ],
                      if (showWorkerPanel) const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
              if (showWorkerPanel && job.status == 'active')
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: _offerPrice,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[\d.,]'),
                              ),
                            ],
                            style: textTheme.bodyLarge,
                            decoration: InputDecoration(
                              labelText: 'Təklif məbləği (₼)',
                              hintText: 'Məs: 45',
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusMd),
                                borderSide:
                                    const BorderSide(color: AppColors.outline),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusMd),
                                borderSide:
                                    const BorderSide(color: AppColors.outline),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusMd),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          GradientPrimaryButton(
                            label: 'Təklif göndər',
                            onPressed: _sendOffer,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
