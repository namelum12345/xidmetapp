import 'package:flutter/material.dart';

import '../models/job_category.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Horizontal category chip (icon + label) for the marketplace dashboard.
class CategoryItem extends StatelessWidget {
  const CategoryItem({
    super.key,
    required this.category,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  /// When null, this represents “Hamısı” / all categories.
  final JobCategoryId? category;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.outline,
                width: selected ? 1.8 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (category != null) ...[
                  Icon(
                    category!.icon,
                    size: 22,
                    color: selected ? AppColors.primary : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                ] else ...[
                  Icon(
                    Icons.grid_view_rounded,
                    size: 22,
                    color: selected ? AppColors.primary : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color:
                            selected ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
