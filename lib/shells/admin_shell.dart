import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// [AdminShell] daxilindəki istənilən kontekstdən [StatefulNavigationShell] götürür
/// (`maybeOf` bəzən tab məzmununda null qayıdır).
class AdminNavScope extends InheritedWidget {
  const AdminNavScope({
    super.key,
    required this.navigationShell,
    required super.child,
  });

  final StatefulNavigationShell navigationShell;

  static StatefulNavigationShell? shellOf(BuildContext context) {
    return context
        .getInheritedWidgetOfExactType<AdminNavScope>()
        ?.navigationShell;
  }

  @override
  bool updateShouldNotify(AdminNavScope oldWidget) =>
      navigationShell != oldWidget.navigationShell;
}

/// Admin panel — alt naviqasiya [StatefulNavigationShell.goBranch] ilə (indexed stack düzgün sinxron qalır).
class AdminShell extends StatelessWidget {
  const AdminShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  static const int tabDashboard = 0;
  static const int tabUsers = 1;
  static const int tabWorkers = 2;
  static const int tabJobs = 3;
  static const int tabChats = 4;
  static const int tabProfile = 5;

  static const _paths = <String>[
    AppRoutes.adminDashboard,
    AppRoutes.adminUsers,
    AppRoutes.adminWorkers,
    AppRoutes.adminJobs,
    AppRoutes.adminChats,
    AppRoutes.adminProfile,
  ];

  static const _labels = [
    'Panel',
    'İstifadəçilər',
    'İcraçılar',
    'Elanlar',
    'Mesajlar',
    'Profil',
  ];

  static const _icons = [
    Icons.dashboard_outlined,
    Icons.group_outlined,
    Icons.engineering_outlined,
    Icons.work_outline_rounded,
    Icons.chat_bubble_outline_rounded,
    Icons.person_outline_rounded,
  ];

  static const _iconsSel = [
    Icons.dashboard_rounded,
    Icons.group_rounded,
    Icons.engineering_rounded,
    Icons.work_rounded,
    Icons.chat_bubble_rounded,
    Icons.person_rounded,
  ];

  /// Dashboard kartları və alt menyu üçün — `go()` indexed shell-də tabı dəyişmir.
  static void goToTab(BuildContext context, int index) {
    assert(index >= 0 && index < _paths.length);
    final shellWidget = AdminNavScope.shellOf(context);
    final shellState = StatefulNavigationShell.maybeOf(context);
    if (shellWidget != null) {
      shellWidget.goBranch(
        index,
        initialLocation: index == shellWidget.currentIndex,
      );
    } else if (shellState != null) {
      shellState.goBranch(
        index,
        initialLocation: index == shellState.currentIndex,
      );
    } else {
      GoRouter.of(context).go(_paths[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminNavScope(
      navigationShell: navigationShell,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: navigationShell,
        bottomNavigationBar: DecoratedBox(
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
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
              child: Row(
                children: List.generate(6, (i) {
                  final sel = navigationShell.currentIndex == i;
                  return Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => goToTab(context, i),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMd),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                sel ? _iconsSel[i] : _icons[i],
                                size: 22,
                                color: sel
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _labels[i],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: sel
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                      fontWeight: sel
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      fontSize: 10,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
