import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/config/app_config.dart';
import 'core/notifications/notification_handlers.dart';
import 'core/routing/app_router.dart';
import 'core/routing/route_names.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/offline_banner.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/role_select_screen.dart';
import 'features/onboarding/app_onboarding_carousel.dart';
import 'features/onboarding/tutorial_providers.dart';
import 'models/app_user.dart';
import 'providers/feature_providers.dart';
import 'providers/notification_providers.dart'
    hide initializeLocalNotifications;

class PgpcCampusApp extends ConsumerWidget {
  const PgpcCampusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeControllerProvider);
    final appIntroSeen = ref.watch(appIntroSeenProvider);

    return appIntroSeen.when(
      data: (seen) {
        if (!seen) {
          return _OnboardingApp(themeMode: themeMode);
        }
        return _AppWithRouter(themeMode: themeMode);
      },
      loading: () => const _LoadingScaffold(),
      error: (_, __) => _AppWithRouter(themeMode: themeMode),
    );
  }
}

/// A minimal router for the app-level onboarding flow.
/// Shows the carousel first, then navigates to role select.
final _onboardingRouter = GoRouter(
  initialLocation: '/onboarding',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const AppOnboardingCarousel(),
    ),
    GoRoute(
      path: Routes.roleSelect,
      builder: (context, state) => const RoleSelectScreen(),
    ),
    // Allow navigating to login from role select
    GoRoute(
      path: Routes.login,
      builder: (context, state) => LoginScreen(role: state.extra as UserRole),
    ),
  ],
);

class _OnboardingApp extends ConsumerWidget {
  const _OnboardingApp({required this.themeMode});

  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: _onboardingRouter,
    );
  }
}

class _AppWithRouter extends ConsumerStatefulWidget {
  const _AppWithRouter({required this.themeMode});

  final ThemeMode themeMode;

  @override
  ConsumerState<_AppWithRouter> createState() => _AppWithRouterState();
}

class _AppWithRouterState extends ConsumerState<_AppWithRouter> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    if (_initialized) return;
    _initialized = true;

    // Initialize notification handlers (local notifications + FCM handlers)
    await initializeNotificationHandlers(ref as Ref);

    // Set the global router delegate for navigation from notifications
    NotificationNavigationHandler.instance.routerDelegate = appRouter.routerDelegate;
  }

  @override
  Widget build(BuildContext context) {
    // Try pending navigation after router is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationNavigationHandler.instance.tryPendingNavigation(context);
    });

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: widget.themeMode,
      routerConfig: appRouter,
      builder: (context, child) => Stack(
        children: [
          child ?? const SizedBox.shrink(),
          const OfflineBanner(),
        ],
      ),
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}