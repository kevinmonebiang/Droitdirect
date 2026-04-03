import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../features/auth/presentation/pages/app_loading_page.dart';
import '../../features/auth/presentation/pages/auth_gateway_page.dart';
import '../../features/auth/presentation/providers/auth_session_provider.dart';
import '../../features/booking/presentation/pages/client_bookings_page.dart';
import '../../features/dashboard/presentation/pages/admin_home_page.dart';
import '../../features/dashboard/presentation/pages/client_home_page.dart';
import '../../features/dashboard/presentation/pages/professional_home_page.dart';
import '../../features/messaging/presentation/pages/messages_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/professionals/presentation/pages/professional_profile_page.dart';
import '../../models.dart';
import '../../screens/home_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = ValueNotifier<int>(0);
  ref.onDispose(refreshListenable.dispose);
  ref.listen<AuthSessionState>(authSessionProvider, (previous, next) {
    refreshListenable.value++;
  });

  String? redirect(BuildContext context, GoRouterState state) {
    final session = ref.read(authSessionProvider);
    final role = session.role;
    final isRootRoute = state.matchedLocation == '/';
    final isAuthRoute = state.matchedLocation == AppRoutes.login;
    final isAdminLoginRoute = state.matchedLocation == AppRoutes.adminLogin;
    final isLoadingRoute = state.matchedLocation == AppRoutes.loading;

    if (isRootRoute) {
      return AppRoutes.loading;
    }

    if (!session.isAuthenticated) {
      return isAuthRoute || isAdminLoginRoute || isLoadingRoute
          ? null
          : AppRoutes.login;
    }

    if (isAuthRoute || isAdminLoginRoute) {
      switch (role) {
        case UserRole.client:
          return AppRoutes.clientHome;
        case UserRole.professional:
          return AppRoutes.professionalHome;
        case UserRole.admin:
          return AppRoutes.adminHome;
        case null:
          return AppRoutes.login;
      }
    }

    if (state.matchedLocation.startsWith('/client') && role != UserRole.client) {
      return _defaultHome(role);
    }
    if (state.matchedLocation.startsWith('/professional') &&
        role != UserRole.professional) {
      return _defaultHome(role);
    }
    if (state.matchedLocation.startsWith('/admin') && role != UserRole.admin) {
      return _defaultHome(role);
    }

    return null;
  }

  return GoRouter(
    initialLocation: AppRoutes.loading,
    refreshListenable: refreshListenable,
    redirect: redirect,
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => AppRoutes.loading,
      ),
      GoRoute(
        path: AppRoutes.loading,
        pageBuilder: (context, state) => _buildTransitionPage(
          state: state,
          child: const AppLoadingPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => _buildTransitionPage(
          state: state,
          child: const AuthGatewayPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminLogin,
        pageBuilder: (context, state) => _buildTransitionPage(
          state: state,
          child: const AuthGatewayPage(
            availableRoles: [UserRole.admin],
            allowRegister: false,
            initialRole: UserRole.admin,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.clientHome,
        pageBuilder: (context, state) => _buildTransitionPage(
          state: state,
          child: const ClientHomePage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.clientBookings,
        pageBuilder: (context, state) => _buildTransitionPage(
          state: state,
          child: const ClientBookingsPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.clientMessages,
        pageBuilder: (context, state) => _buildTransitionPage(
          state: state,
          child: const MessagesPage(role: UserRole.client),
        ),
      ),
      GoRoute(
        path: AppRoutes.clientProfile,
        pageBuilder: (context, state) => _buildTransitionPage(
          state: state,
          child: const HomeShell(
            key: ValueKey('client-profile-shell'),
            role: UserRole.client,
            initialIndex: 3,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.clientNotifications,
        pageBuilder: (context, state) => _buildTransitionPage(
          state: state,
          child: const NotificationsPage(role: UserRole.client),
        ),
      ),
      GoRoute(
        path: AppRoutes.professionalHome,
        pageBuilder: (context, state) => _buildTransitionPage(
          state: state,
          child: const ProfessionalHomePage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.professionalBookings,
        pageBuilder: (context, state) => _buildTransitionPage(
          state: state,
          child: const HomeShell(
            key: ValueKey('professional-bookings-shell'),
            role: UserRole.professional,
            initialIndex: 1,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.professionalProfile,
        pageBuilder: (context, state) => _buildTransitionPage(
          state: state,
          child: const ProfessionalProfilePage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.professionalMessages,
        pageBuilder: (context, state) => _buildTransitionPage(
          state: state,
          child: const MessagesPage(role: UserRole.professional),
        ),
      ),
      GoRoute(
        path: AppRoutes.professionalNotifications,
        pageBuilder: (context, state) => _buildTransitionPage(
          state: state,
          child: const NotificationsPage(role: UserRole.professional),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminHome,
        pageBuilder: (context, state) => _buildTransitionPage(
          state: state,
          child: const AdminHomePage(),
        ),
      ),
    ],
  );
});

CustomTransitionPage<void> _buildTransitionPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );

      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.03, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

String _defaultHome(UserRole? role) {
  switch (role) {
    case UserRole.client:
      return AppRoutes.clientHome;
    case UserRole.professional:
      return AppRoutes.professionalHome;
    case UserRole.admin:
      return AppRoutes.adminHome;
    case null:
      return AppRoutes.login;
  }
}
