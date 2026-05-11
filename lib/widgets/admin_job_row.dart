import 'package:flutter/material.dart';

import '../models/admin_models.dart';
import '../models/job_listing.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';

class AdminJobRow extends StatelessWidget {
  const AdminJobRow({
    super.key,
    required this.job,
    required this.lifecycle,
    required this.onDelete,
    required this.onEdit,
    required this.onToggleCompleted,
  });

  final JobListing job;
  final AdminJobLifecycle lifecycle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onToggleCompleted;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final active = lifecycle == AdminJobLifecycle.active;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    job.title,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.matchBadge.withValues(alpha: 0.15)
                        : AppColors.textSecondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    active ? 'Aktiv' : 'Tamamlanıb',
                    style: textTheme.labelSmall?.copyWith(
                      color: active ? AppColors.matchBadge : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              job.shortDescription,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              job.locationLabel,
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _JobBtn(
                    label: active ? 'Tamamla' : 'Aktiv et',
                    onTap: onToggleCompleted,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _JobBtn(
                    label: 'Redaktə',
                    secondary: true,
                    onTap: onEdit,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _JobBtn(
                    label: 'Sil',
                    danger: true,
                    onTap: onDelete,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _JobBtn extends StatelessWidget {
  const _JobBtn({
    required this.label,
    required this.onTap,
    this.secondary = false,
    this.danger = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool secondary;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    if (danger) {
      bg = Colors.red.shade50;
      fg = Colors.red.shade800;
    } else if (secondary) {
      bg = AppColors.background;
      fg = AppColors.primary;
    } else {
      bg = AppColors.primary.withValues(alpha: 0.1);
      fg = AppColors.primary;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppColors.outline),
          ),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
