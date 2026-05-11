/// Central route paths for [GoRouter] configuration.
abstract final class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String roleSelection = '/role';
  static const String registerForm = '/register/form';

  /// Main tabs — use after login (StatefulShell).
  static const String userHome = '/user/home';
  static const String userMessages = '/user/messages';
  static const String userProfile = '/user/profile';
  static const String workerHome = '/worker/home';
  static const String workerMessages = '/worker/messages';
  static const String workerProfile = '/worker/profile';

  /// Profil alt səhifələri (user / worker prefix ilə).
  static String profileEdit(bool isWorker) =>
      isWorker ? '/worker/profile/edit' : '/user/profile/edit';
  static String profileChangePassword(bool isWorker) =>
      isWorker ? '/worker/profile/change-password' : '/user/profile/change-password';
  static String profileMyJobs(bool isWorker) =>
      isWorker ? '/worker/profile/my-jobs' : '/user/profile/my-jobs';
  static String profileFavorites(bool isWorker) =>
      isWorker ? '/worker/profile/favorites' : '/user/profile/favorites';
  static String profileNotifications(bool isWorker) =>
      isWorker ? '/worker/profile/notifications' : '/user/profile/notifications';
  static String profileSettings(bool isWorker) =>
      isWorker ? '/worker/profile/settings' : '/user/profile/settings';
  static String profileSupport(bool isWorker) =>
      isWorker ? '/worker/profile/support' : '/user/profile/support';

  /// İcraçı profil alt səhifələri.
  static const String workerSkills = '/worker/profile/skills';
  static const String workerAvailability = '/worker/profile/availability';
  static const String workerEarnings = '/worker/profile/earnings';
  static const String workerReviews = '/worker/profile/reviews';
  static const String workerChangeLocation = '/worker/profile/location';

  static const String createJob = '/job/create';

  static String jobDetail(String id) => '/job/$id';

  static String chat(String threadId) => '/chat/$threadId';

  /// Admin panel (StatefulShell).
  static const String adminDashboard = '/admin/dashboard';
  static const String adminUsers = '/admin/users';
  static const String adminJobs = '/admin/jobs';
  static const String adminChats = '/admin/chats';
  static const String adminProfile = '/admin/profile';
  static const String adminWorkers = '/admin/workers';
  static const String adminReports = '/admin/reports';

  static String adminChat(String threadId) => '/admin/chat/$threadId';

  /// Superadmin control plane (StatefulShell — 4 tabs).
  static const String superDashboard = '/super/dashboard';
  static const String superAdmins = '/super/admins';
  static const String superAnalytics = '/super/analytics';
  static const String superSettings = '/super/settings';

  /// Full-screen routes under `/super`.
  static const String superReports = '/super/reports';
  static const String superMonetization = '/super/monetization';
  static const String superPermissions = '/super/permissions';
  static const String superAudit = '/super/audit';
  static const String superGlobalBan = '/super/ban';
  static const String superNotifications = '/super/notifications';

  /// Superadmin üçün idarəetmə ekranları (`/admin` seqmentinə çıxmadan).
  static const String superManageUsers = '/super/manage/users';
  static const String superManageWorkers = '/super/manage/workers';
  static const String superManageJobs = '/super/manage/jobs';
  static const String superManageChats = '/super/manage/chats';
}
