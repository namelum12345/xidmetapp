import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// [SuperAdminShell] alt ağacından [StatefulNavigationShell] (tab keçidləri üçün).
class SuperNavScope extends InheritedWidget {
  const SuperNavScope({
    super.key,
    required this.navigationShell,
    required super.child,
  });

  final StatefulNavigationShell navigationShell;

  static StatefulNavigationShell? shellOf(BuildContext context) {
    return context
        .getInheritedWidgetOfExactType<SuperNavScope>()
        ?.navigationShell;
  }

  @override
  bool updateShouldNotify(SuperNavScope oldWidget) =>
      navigationShell != oldWidget.navigationShell;
}

/// Superadmin — alt naviqasiya [StatefulNavigationShell.goBranch] ilə.
class SuperAdminShell extends StatelessWidget {
  const SuperAdminShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  static const int tabDashboard = 0;
  static const int tabAdmins = 1;
  static const int tabAnalytics = 2;
  static const int tabSettings = 3;

  static const _paths = <String>[
    AppRoutes.superDashboard,
    AppRoutes.superAdmins,
    AppRoutes.superAnalytics,
    AppRoutes.superSettings,
  ];

  static const _labels = [
    'Dashboard',
    'Adminlər',
    'Analitika',
    'Parametrlər',
  ];

  static const _icons = [
    Icons.space_dashboard_outlined,
    Icons.admin_panel_settings_outlined,
    Icons.insights_outlined,
    Icons.tune_rounded,
  ];

  static const _sel = [
    Icons.space_dashboard_rounded,
    Icons.admin_panel_settings_rounded,
    Icons.insights_rounded,
    Icons.tune_rounded,
  ];

  static void goToTab(BuildContext context, int index) {
    assert(index >= 0 && index < _paths.length);
    final shellWidget = SuperNavScope.shellOf(context);
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
    return SuperNavScope(
      navigationShell: navigationShell,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: navigationShell,
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.09),
                blurRadius: 26,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Row(
                children: List.generate(4, (i) {
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
                                sel ? _sel[i] : _icons[i],
                                size: 24,
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
                                      fontSize: 10,
                                      color: sel
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                      fontWeight: sel
                                          ? FontWeight.w800
                                          : FontWeight.w500,
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
