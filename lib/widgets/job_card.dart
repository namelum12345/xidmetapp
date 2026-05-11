import 'package:flutter/material.dart';

import '../models/job_listing.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';

/// Marketplace job row card — distance, price, time row.
class JobCard extends StatelessWidget {
  const JobCard({
    super.key,
    required this.job,
    required this.onTap,
    this.showMatchBadge = false,
  });

  final JobListing job;
  final VoidCallback onTap;
  final bool showMatchBadge;

  String get _priceLine {
    final p = job.priceAzn;
    if (p == null) return 'Qiymət razılaşma ilə';
    return '${p.toStringAsFixed(0)} ₼';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AppCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      job.shortDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        if (showMatchBadge &&
                            job.distanceKm > 0)
                          _MetaChip(
                            icon: Icons.near_me_outlined,
                            label: '${job.distanceKm.toStringAsFixed(1)} km',
                          )
                        else if (!showMatchBadge &&
                            job.locationLabel.trim().isNotEmpty)
                          _MetaChip(
                            icon: Icons.place_outlined,
                            label: job.locationLabel.trim(),
                          )
                        else if (showMatchBadge)
                          _MetaChip(
                            icon: Icons.location_searching,
                            label: 'Profilinə məkan əlavə et',
                          ),
                        _MetaChip(
                          icon: Icons.payments_outlined,
                          label: _priceLine,
                        ),
                        _MetaChip(
                          icon: Icons.schedule_rounded,
                          label: job.postedLabel,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (showMatchBadge && job.recommendForWorker)
                Positioned(
                  top: 10,
                  right: 10,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.matchBadge,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.matchBadge.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: Text(
                        'Sənə uyğun',
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.onMatchBadge,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 140),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }
}
