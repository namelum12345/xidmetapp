import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Full-width purple gradient CTA (rounded, keyboard-safe height).
class GradientPrimaryButton extends StatelessWidget {
  const GradientPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  static const LinearGradient _gradient = LinearGradient(
    colors: [
      Color(0xFF5B54E5),
      Color(0xFF6C63FF),
      Color(0xFF7D76FF),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  Widget build(BuildContext context) {
    final effectiveOnTap = onPressed;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: effectiveOnTap == null ? null : _gradient,
          color: effectiveOnTap == null ? const Color(0xFFE8EAEF) : null,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: effectiveOnTap == null
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: effectiveOnTap,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: Center(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: effectiveOnTap == null
                          ? const Color(0xFF9CA3AF)
                          : Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
