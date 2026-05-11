import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/user_role.dart';
import '../services/chat_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Bottom navigation: Ana səhifə + Mesajlar (user / worker shells).
class RoleMainShell extends StatelessWidget {
  const RoleMainShell({
    super.key,
    required this.navigationShell,
    required this.role,
  });

  final StatefulNavigationShell navigationShell;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ChatService.instance,
      builder: (context, _) {
        final unread = ChatService.instance.unreadCount(role);
        return Scaffold(
          backgroundColor: AppColors.background,
          body: navigationShell,
          bottomNavigationBar: _BottomBar(
            navigationShell: navigationShell,
            currentIndex: navigationShell.currentIndex,
            unreadMessages: unread,
          ),
        );
      },
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.navigationShell,
    required this.currentIndex,
    required this.unreadMessages,
  });

  final StatefulNavigationShell navigationShell;
  final int currentIndex;
  final int unreadMessages;

  /// [StatefulShellRoute] üçün `go()` əvəzinə — tab dəyişməsi və eyni tabda kökə qayıdış düzgün işləyir.
  void _goTab(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Ana səhifə',
                  selected: currentIndex == 0,
                  onTap: () => _goTab(0),
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Mesajlar',
                  selected: currentIndex == 1,
                  badgeCount: unreadMessages,
                  onTap: () => _goTab(1),
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Profil',
                  selected: currentIndex == 2,
                  onTap: () => _goTab(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    color: selected ? AppColors.primary : AppColors.textSecondary,
                    size: 26,
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          badgeCount > 9 ? '9+' : '$badgeCount',
                          textAlign: TextAlign.center,
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.onPrimary,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
