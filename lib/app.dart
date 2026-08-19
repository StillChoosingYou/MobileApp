import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/offline_banner.dart';
import 'features/onboarding/app_onboarding_carousel.dart';
import 'features/onboarding/tutorial_providers.dart';
import 'providers/feature_providers.dart';

class PgpcCampusApp extends ConsumerWidget {
  const PgpcCampusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeControllerProvider);
    final appIntroSeen = ref.watch(appIntroSeenProvider);

    return appIntroSeen.when(
      data: (seen) {
        if (!seen) {
          return const AppOnboardingCarousel();
        }
        return _AppWithRouter(themeMode: themeMode);
      },
      loading: () => const _LoadingScaffold(),
      error: (_, __) => _AppWithRouter(themeMode: themeMode),
    );
  }
}

class _AppWithRouter extends StatelessWidget {
  const _AppWithRouter({required this.themeMode});

  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
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