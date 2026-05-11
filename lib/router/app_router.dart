import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/user_role.dart';
import '../screens/chat_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_profile_screen.dart';
import '../screens/admin/admin_reports_screen.dart';
import '../screens/admin/chats_monitor_screen.dart';
import '../screens/admin/jobs_management_screen.dart';
import '../screens/admin/users_management_screen.dart';
import '../screens/admin/workers_management_screen.dart';
import '../screens/create_job_screen.dart';
import '../screens/job_detail_screen.dart';
import '../screens/login_screen.dart';
import '../screens/messages_list_screen.dart';
import '../screens/register_form_screen.dart';
import '../screens/register_screen.dart';
import '../screens/role_selection_screen.dart';
import '../screens/user_home_screen.dart';
import '../screens/profile/change_password_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/profile_favorite_workers_screen.dart';
import '../screens/profile/profile_my_jobs_screen.dart';
import '../screens/profile/profile_notifications_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/profile_settings_screen.dart';
import '../screens/profile/profile_support_screen.dart';
import '../screens/worker/edit_worker_profile_screen.dart';
import '../screens/worker/worker_availability_screen.dart';
import '../screens/worker/worker_earnings_screen.dart';
import '../screens/worker/worker_location_screen.dart';
import '../screens/worker/worker_profile_screen.dart';
import '../screens/worker/worker_reviews_screen.dart';
import '../screens/worker/worker_skills_screen.dart';
import '../screens/worker_home_screen.dart';
import '../screens/superadmin/super_admin_dashboard_screen.dart';
import '../screens/superadmin/super_admin_management_screen.dart';
import '../screens/superadmin/super_analytics_screen.dart';
import '../screens/superadmin/super_audit_log_screen.dart';
import '../screens/superadmin/ban_management_screen.dart';
import '../screens/superadmin/super_notification_screen.dart';
import '../screens/superadmin/super_monetization_screen.dart';
import '../screens/superadmin/super_permissions_screen.dart';
import '../screens/superadmin/super_reports_screen.dart';
import '../screens/superadmin/super_system_settings_screen.dart';
import '../shells/admin_shell.dart';
import '../shells/role_main_shell.dart';
import '../services/auth_service.dart';
import '../services/role_router_service.dart';
import '../shells/super_admin_shell.dart';
import 'app_routes.dart';

final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

/// Single router instance — stable across rebuilds.
final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.login,
  refreshListenable: AuthService.instance,
  redirect: (context, state) {
    return RoleRouterService.redirectForRouterState(
      matchedLocation: state.matchedLocation,
      authed: AuthService.instance.firebaseUser != null,
      profile: AuthService.instance.profile,
    );
  },
  routes: [
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/super',
      redirect: (context, state) {
        if (state.matchedLocation == '/super') {
          return AppRoutes.superDashboard;
        }
        return null;
      },
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return SuperAdminShell(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: 'dashboard',
                  builder: (context, state) =>
                      const SuperAdminDashboardScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: 'admins',
                  builder: (context, state) =>
                      const SuperAdminManagementScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: 'analytics',
                  builder: (context, state) =>
                      const SuperAnalyticsScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: 'settings',
                  builder: (context, state) =>
                      const SuperSystemSettingsScreen(),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: 'reports',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const SuperReportsScreen(),
        ),
        GoRoute(
          path: 'monetization',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const SuperMonetizationScreen(),
        ),
        GoRoute(
          path: 'permissions',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const SuperPermissionsScreen(),
        ),
        GoRoute(
          path: 'audit',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const SuperAuditLogScreen(),
        ),
        GoRoute(
          path: 'ban',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const BanManagementScreen(),
        ),
        GoRoute(
          path: 'notifications',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const SuperNotificationScreen(),
        ),
        GoRoute(
          path: 'manage/users',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const UsersManagementScreen(),
        ),
        GoRoute(
          path: 'manage/workers',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const WorkersManagementScreen(),
        ),
        GoRoute(
          path: 'manage/jobs',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const JobsManagementScreen(),
        ),
        GoRoute(
          path: 'manage/chats',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const ChatsMonitorScreen(),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: AppRoutes.roleSelection,
      builder: (context, state) => const RoleSelectionScreen(),
    ),
    GoRoute(
      path: AppRoutes.registerForm,
      builder: (context, state) {
        final role = state.extra as UserRole? ?? UserRole.user;
        return RegisterFormScreen(role: role);
      },
    ),
    GoRoute(
      path: AppRoutes.createJob,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const CreateJobScreen(),
    ),
    GoRoute(
      path: '/job/:id',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        final viewer = state.extra as UserRole? ?? UserRole.user;
        return JobDetailScreen(jobId: id, viewerRole: viewer);
      },
    ),
    GoRoute(
      path: '/chat/:threadId',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['threadId']!;
        final role = state.extra as UserRole? ?? UserRole.user;
        return ChatScreen(threadId: id, viewerRole: role);
      },
    ),
    GoRoute(
      path: '/admin',
      redirect: (context, state) {
        if (state.matchedLocation == '/admin') {
          return AppRoutes.adminDashboard;
        }
        return null;
      },
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return AdminShell(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: 'dashboard',
                  builder: (context, state) => const AdminDashboardScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: 'users',
                  builder: (context, state) => const UsersManagementScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: 'workers',
                  builder: (context, state) => const WorkersManagementScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: 'jobs',
                  builder: (context, state) => const JobsManagementScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: 'chats',
                  builder: (context, state) => const ChatsMonitorScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: 'profile',
                  builder: (context, state) => const AdminProfileScreen(),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: 'reports',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const AdminReportsScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/admin/chat/:threadId',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['threadId']!;
        return ChatScreen(
          threadId: id,
          viewerRole: UserRole.user,
          readOnly: true,
        );
      },
    ),
    GoRoute(
      path: '/user',
      redirect: (context, state) {
        if (state.matchedLocation == '/user') {
          return AppRoutes.userHome;
        }
        return null;
      },
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return RoleMainShell(
              navigationShell: navigationShell,
              role: UserRole.user,
            );
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: 'home',
                  builder: (context, state) => const UserHomeScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: 'messages',
                  builder: (context, state) => const MessagesListScreen(
                    viewerRole: UserRole.user,
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: 'profile',
                  builder: (context, state) =>
                      const ProfileScreen(viewerRole: UserRole.user),
                  routes: [
                    GoRoute(
                      path: 'edit',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) =>
                          const EditProfileScreen(viewerRole: UserRole.user),
                    ),
                    GoRoute(
                      path: 'change-password',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) =>
                          const ChangePasswordScreen(),
                    ),
                    GoRoute(
                      path: 'my-jobs',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) =>
                          const ProfileMyJobsScreen(viewerRole: UserRole.user),
                    ),
                    GoRoute(
                      path: 'favorites',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) =>
                          const ProfileFavoriteWorkersScreen(),
                    ),
                    GoRoute(
                      path: 'notifications',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) =>
                          const ProfileNotificationsScreen(
                        viewerRole: UserRole.user,
                      ),
                    ),
                    GoRoute(
                      path: 'settings',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) =>
                          const ProfileSettingsScreen(),
                    ),
                    GoRoute(
                      path: 'support',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) =>
                          const ProfileSupportScreen(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/worker',
      redirect: (context, state) {
        if (state.matchedLocation == '/worker') {
          return AppRoutes.workerHome;
        }
        return null;
      },
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return RoleMainShell(
              navigationShell: navigationShell,
              role: UserRole.worker,
            );
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: 'home',
                  builder: (context, state) => const WorkerHomeScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: 'messages',
                  builder: (context, state) => const MessagesListScreen(
                    viewerRole: UserRole.worker,
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: 'profile',
                  builder: (context, state) => const WorkerProfileScreen(),
                  routes: [
                    GoRoute(
                      path: 'edit',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) => const EditWorkerProfileScreen(),
                    ),
                    GoRoute(
                      path: 'skills',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) => const WorkerSkillsScreen(),
                    ),
                    GoRoute(
                      path: 'availability',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) => const WorkerAvailabilityScreen(),
                    ),
                    GoRoute(
                      path: 'earnings',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) => const WorkerEarningsScreen(),
                    ),
                    GoRoute(
                      path: 'reviews',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) => const WorkerReviewsScreen(),
                    ),
                    GoRoute(
                      path: 'location',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) => const WorkerLocationScreen(),
                    ),
                    GoRoute(
                      path: 'change-password',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) =>
                          const ChangePasswordScreen(),
                    ),
                    GoRoute(
                      path: 'my-jobs',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) =>
                          const ProfileMyJobsScreen(viewerRole: UserRole.worker),
                    ),
                    GoRoute(
                      path: 'favorites',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) =>
                          const ProfileFavoriteWorkersScreen(),
                    ),
                    GoRoute(
                      path: 'notifications',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) =>
                          const ProfileNotificationsScreen(
                        viewerRole: UserRole.worker,
                      ),
                    ),
                    GoRoute(
                      path: 'settings',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) =>
                          const ProfileSettingsScreen(),
                    ),
                    GoRoute(
                      path: 'support',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) =>
                          const ProfileSupportScreen(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
