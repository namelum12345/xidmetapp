import 'package:flutter/material.dart';

import '../models/admin_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';

class AdminWorkerRow extends StatelessWidget {
  const AdminWorkerRow({
    super.key,
    required this.worker,
    required this.onApprove,
    required this.onDisable,
  });

  final AdminWorkerRecord worker;
  final VoidCallback onApprove;
  final VoidCallback onDisable;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final skills = worker.skills.join(' • ');

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
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    worker.name.isNotEmpty ? worker.name[0].toUpperCase() : '?',
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        worker.name,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        skills,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 18,
                            color: Colors.amber.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            worker.rating.toStringAsFixed(1),
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (worker.approved)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.matchBadge.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Təsdiqlənib',
                                style: textTheme.labelSmall?.copyWith(
                                  color: AppColors.matchBadge,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          if (worker.disabled)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                'Deaktiv',
                                style: textTheme.labelSmall?.copyWith(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MiniAction(
                    label: 'Təsdiqlə',
                    enabled: !worker.approved && !worker.disabled,
                    primary: true,
                    onTap: onApprove,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniAction(
                    label: 'Deaktiv et',
                    enabled: !worker.disabled,
                    danger: true,
                    onTap: onDisable,
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

class _MiniAction extends StatelessWidget {
  const _MiniAction({
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.primary = false,
    this.danger = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final bool primary;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    if (!enabled) {
      bg = AppColors.outline.withValues(alpha: 0.35);
      fg = AppColors.textSecondary;
    } else if (danger) {
      bg = Colors.red.shade50;
      fg = Colors.red.shade800;
    } else if (primary) {
      bg = AppColors.primary.withValues(alpha: 0.12);
      fg = AppColors.primary;
    } else {
      bg = AppColors.surface;
      fg = AppColors.textPrimary;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: AppColors.outline.withValues(alpha: enabled ? 1 : 0.5),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
