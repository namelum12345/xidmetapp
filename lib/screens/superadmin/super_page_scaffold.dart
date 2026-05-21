import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_routes.dart';
import '../../theme/app_colors.dart';

/// Superadmin alt-ekranları üçün ümumi Scaffold + AppBar.
///
/// Hər super manage/əməliyyat ekranı root navigator-da açıldığı üçün
/// onları bu wrapper-də göstərib geri düyməsini standartlaşdırırıq.
/// Stack varsa `pop`, yoxdursa Dashboard-a qayıdırıq ki, istifadəçi heç vaxt
/// boş ekranda «qıfıllı» qalmasın.
class SuperPageScaffold extends StatelessWidget {
  const SuperPageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => _safePop(context),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: actions,
      ),
      body: child,
    );
  }

  static void _safePop(BuildContext context) {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(AppRoutes.superDashboard);
    }
  }
}
