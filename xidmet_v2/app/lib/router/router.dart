import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/auth_service.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/user_home_screen.dart';
import '../screens/home/worker_home_screen.dart';
import '../screens/chat/messages_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/change_password_screen.dart';
import '../screens/profile/my_jobs_screen.dart';
import '../screens/profile/settings_screen.dart';
import '../screens/profile/support_screen.dart';
import '../screens/profile/notifications_screen.dart';
import '../screens/worker/worker_profile_screen.dart';
import '../screens/worker/worker_edit_screen.dart';
import '../screens/worker/worker_skills_screen.dart';
import '../screens/worker/worker_availability_screen.dart';
import '../screens/worker/worker_earnings_screen.dart';
import '../screens/worker/worker_reviews_screen.dart';
import '../screens/home/listing_detail_screen.dart';
import '../screens/home/create_listing_screen.dart';
import '../screens/jobs/job_detail_screen.dart';
import '../screens/jobs/create_job_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_users_screen.dart';
import '../screens/admin/admin_workers_screen.dart';
import '../screens/admin/admin_jobs_screen.dart';
import '../screens/admin/admin_chats_screen.dart';
import '../screens/admin/admin_profile_screen.dart';
import '../screens/superadmin/super_dashboard_screen.dart';
import '../screens/superadmin/super_admins_screen.dart';
import '../screens/superadmin/super_analytics_screen.dart';
import '../screens/superadmin/super_settings_screen.dart';
import '../screens/superadmin/super_audit_screen.dart';
import '../shells/user_shell.dart';
import '../shells/admin_shell.dart';
import '../shells/super_shell.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/login',
  refreshListenable: AuthService.instance,
  redirect: _redirect,
  routes: [
    // ── Auth ─────────────────────────────────────────────────────────────
    GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
    GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),

    // ── User Shell (3 tabs: home / messages / profile) ───────────────────
    StatefulShellRoute.indexedStack(
      builder: (ctx, state, shell) => UserShell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/home', builder: (c, s) => const UserHomeScreen()),
          GoRoute(path: '/job/create', builder: (c, s) => const CreateJobScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/messages', builder: (c, s) => const MessagesScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/profile', builder: (c, s) => const ProfileScreen()),
        ]),
      ],
    ),

    // ── Worker Shell (3 tabs: home / messages / profile) ─────────────────
    StatefulShellRoute.indexedStack(
      builder: (ctx, state, shell) => WorkerShell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/w/home', builder: (c, s) => const WorkerHomeScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/w/messages', builder: (c, s) => const MessagesScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/w/profile', builder: (c, s) => const WorkerProfileScreen()),
        ]),
      ],
    ),

    // ── Admin Shell (6 tabs) ──────────────────────────────────────────────
    StatefulShellRoute.indexedStack(
      builder: (ctx, state, shell) => AdminShell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/a/dashboard', builder: (c, s) => const AdminDashboardScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/a/users', builder: (c, s) => const AdminUsersScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/a/workers', builder: (c, s) => const AdminWorkersScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/a/jobs', builder: (c, s) => const AdminJobsScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/a/chats', builder: (c, s) => const AdminChatsScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/a/profile', builder: (c, s) => const AdminProfileScreen()),
        ]),
      ],
    ),

    // ── SuperAdmin Shell (4 tabs) ─────────────────────────────────────────
    StatefulShellRoute.indexedStack(
      builder: (ctx, state, shell) => SuperShell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/sa/dashboard', builder: (c, s) => const SuperDashboardScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/sa/admins', builder: (c, s) => const SuperAdminsScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/sa/analytics', builder: (c, s) => const SuperAnalyticsScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/sa/settings', builder: (c, s) => const SuperSettingsScreen()),
        ]),
      ],
    ),

    // ── Shared detail routes (top-level, renders above shells) ────────────
    GoRoute(
      path: '/listing/create',
      builder: (c, s) => const CreateListingScreen(),
    ),
    GoRoute(
      path: '/listing/:id',
      builder: (c, s) => ListingDetailScreen(listingId: s.pathParameters['id']!),
    ),
    GoRoute(
      path: '/job/:id',
      builder: (c, s) => JobDetailScreen(jobId: s.pathParameters['id']!),
    ),
    GoRoute(
      path: '/chat/:threadId',
      builder: (c, s) => ChatScreen(threadId: s.pathParameters['threadId']!),
    ),

    // ── Profile sub-pages (top-level, rendered above shell) ───────────────
    GoRoute(path: '/profile/edit', builder: (c, s) => const EditProfileScreen()),
    GoRoute(path: '/profile/change-password', builder: (c, s) => const ChangePasswordScreen()),
    GoRoute(path: '/profile/my-jobs', builder: (c, s) => const MyJobsScreen()),
    GoRoute(path: '/profile/settings', builder: (c, s) => const SettingsScreen()),
    GoRoute(path: '/profile/support', builder: (c, s) => const SupportScreen()),
    GoRoute(path: '/profile/notifications', builder: (c, s) => const NotificationsScreen()),

    // ── Worker sub-pages ──────────────────────────────────────────────────
    GoRoute(path: '/w/profile/edit', builder: (c, s) => const WorkerEditScreen()),
    GoRoute(path: '/w/profile/skills', builder: (c, s) => const WorkerSkillsScreen()),
    GoRoute(path: '/w/profile/availability', builder: (c, s) => const WorkerAvailabilityScreen()),
    GoRoute(path: '/w/profile/earnings', builder: (c, s) => const WorkerEarningsScreen()),
    GoRoute(path: '/w/profile/reviews', builder: (c, s) => const WorkerReviewsScreen()),
    GoRoute(path: '/w/profile/my-jobs', builder: (c, s) => const MyJobsScreen()),
    GoRoute(path: '/w/profile/settings', builder: (c, s) => const SettingsScreen()),
    GoRoute(path: '/w/profile/support', builder: (c, s) => const SupportScreen()),
    GoRoute(path: '/w/profile/notifications', builder: (c, s) => const NotificationsScreen()),
    GoRoute(path: '/w/profile/change-password', builder: (c, s) => const ChangePasswordScreen()),

    // ── SuperAdmin sub-pages ──────────────────────────────────────────────
    GoRoute(path: '/sa/audit', builder: (c, s) => const SuperAuditScreen()),
  ],
);

String? _redirect(BuildContext context, GoRouterState state) {
  final authed = AuthService.instance.isLoggedIn;
  final role = AuthService.instance.user?.role ?? '';
  final loc = state.matchedLocation;

  const publicPaths = {'/login', '/register'};
  final isPublic = publicPaths.contains(loc);

  if (!authed) {
    return isPublic ? null : '/login';
  }

  if (isPublic) {
    return _homeFor(role);
  }

  // Role-based path guarding
  if (loc.startsWith('/sa') && role != 'superadmin') return _homeFor(role);
  if (loc.startsWith('/a/') && role != 'admin') return _homeFor(role);
  if ((loc.startsWith('/w/') || loc == '/w') && role != 'worker') return _homeFor(role);
  if (!loc.startsWith('/w') && !loc.startsWith('/a') && !loc.startsWith('/sa') &&
      !publicPaths.contains(loc) && !loc.startsWith('/listing') &&
      !loc.startsWith('/job') && !loc.startsWith('/chat') && !loc.startsWith('/profile')) {
    if (role == 'worker') return _homeFor(role);
    if (role == 'admin') return _homeFor(role);
    if (role == 'superadmin') return _homeFor(role);
  }

  return null;
}

String _homeFor(String role) {
  return switch (role) {
    'superadmin' => '/sa/dashboard',
    'admin' => '/a/dashboard',
    'worker' => '/w/home',
    _ => '/home',
  };
}
