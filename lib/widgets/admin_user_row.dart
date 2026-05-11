import 'package:flutter/material.dart';

import '../models/admin_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';

class AdminUserRow extends StatelessWidget {
  const AdminUserRow({
    super.key,
    required this.user,
    required this.onBan,
    required this.onDelete,
  });

  final AdminUserRecord user;
  final VoidCallback onBan;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
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
                        user.name,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.phone,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          user.roleLabel,
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (user.banned) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Bloklanıb',
                          style: textTheme.labelSmall?.copyWith(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _AdminChipButton(
                    label: user.banned ? 'Bloklanıb' : 'Blokla',
                    outlined: true,
                    enabled: !user.banned,
                    onTap: user.banned ? null : onBan,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _AdminChipButton(
                    label: 'Sil',
                    outlined: false,
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

class _AdminChipButton extends StatelessWidget {
  const _AdminChipButton({
    required this.label,
    required this.onTap,
    this.outlined = true,
    this.enabled = true,
    this.danger = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool outlined;
  final bool enabled;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final bg = danger
        ? Colors.red.shade50
        : (outlined ? AppColors.surface : AppColors.primary);
    final fg = danger
        ? Colors.red.shade800
        : (outlined ? AppColors.primary : AppColors.onPrimary);
    final border = outlined ? AppColors.primary.withValues(alpha: 0.45) : Colors.transparent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: enabled ? bg : AppColors.outline.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: border),
          ),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: enabled ? fg : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
