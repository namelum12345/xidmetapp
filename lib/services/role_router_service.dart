import '../models/user_profile.dart';
import '../models/user_role.dart';
import '../router/app_routes.dart';

/// Rol əsaslı marshrutların **vahid** məntiqi — bütün hədəf yollar [AppRoutes] üzərindən.
///
/// Firestore `users/{uid}` `role` sahəsi: `superadmin` | `super_admin` | `admin` |
/// `worker` | `user` (və ya defolt marketplace istifadəçisi).
abstract final class RoleRouterService {
  static const Set<String> _publicExactPaths = {
    AppRoutes.login,
    AppRoutes.register,
    AppRoutes.roleSelection,
    AppRoutes.registerForm,
  };

  static bool isPublicExactPath(String matchedLocation) =>
      _publicExactPaths.contains(matchedLocation);

  /// Girişdən sonra açılacaq əsas panel (Firestore profilinə əsasən).
  static String homeDashboardLocation(UserProfile profile) {
    if (profile.isSuperAdmin) return AppRoutes.superDashboard;
    if (profile.isAdmin) return AppRoutes.adminDashboard;
    if (profile.role == 'worker') return AppRoutes.workerHome;
    return AppRoutes.userHome;
  }

  /// Chat / elan ekranları üçün marketplace baxış rolü (staff üçün `user` tərəfi).
  static UserRole marketplaceViewerRole(UserProfile? profile) {
    if (profile == null) return UserRole.user;
    if (profile.isSuperAdmin || profile.isAdmin) return UserRole.user;
    if (profile.role == 'worker') return UserRole.worker;
    return UserRole.user;
  }

  /// [GoRouter.redirect] üçün — hər rol yalnız öz seqmentinə düşür.
  static String? redirectForRouterState({
    required String matchedLocation,
    required bool authed,
    UserProfile? profile,
  }) {
    final loc = matchedLocation;

    if (!authed) {
      if (isPublicExactPath(loc)) return null;
      return AppRoutes.login;
    }

    if (profile == null) return null;

    if (isPublicExactPath(loc)) {
      return homeDashboardLocation(profile);
    }

    if (loc.startsWith('/super')) {
      if (!profile.isSuperAdmin) return homeDashboardLocation(profile);
      return null;
    }

    if (loc.startsWith('/admin')) {
      if (profile.isSuperAdmin) return AppRoutes.superDashboard;
      if (!profile.isAdmin) return homeDashboardLocation(profile);
      return null;
    }

    if (loc.startsWith('/user')) {
      if (profile.isSuperAdmin) return AppRoutes.superDashboard;
      if (profile.isAdmin) return AppRoutes.adminDashboard;
      if (profile.role == 'worker') return AppRoutes.workerHome;
      return null;
    }

    if (loc.startsWith('/worker')) {
      if (profile.isSuperAdmin) return AppRoutes.superDashboard;
      if (profile.isAdmin) return AppRoutes.adminDashboard;
      if (profile.role != 'worker') return AppRoutes.userHome;
      return null;
    }

    if (loc == AppRoutes.createJob || loc.startsWith('/job/')) {
      if (profile.isSuperAdmin) return AppRoutes.superDashboard;
      if (profile.isAdmin) return AppRoutes.adminDashboard;
      return null;
    }

    if (loc.startsWith('/chat/')) {
      if (profile.isSuperAdmin) return AppRoutes.superDashboard;
      if (profile.isAdmin) return AppRoutes.adminDashboard;
      return null;
    }

    return null;
  }
}
