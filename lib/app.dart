import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/offline_banner.dart';
import 'providers/feature_providers.dart';

class PgpcCampusApp extends ConsumerWidget {
  const PgpcCampusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeControllerProvider);

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
          // Global, connectivity-aware banner. Shows only when the device is
          // offline; auto-hides when connectivity returns.
          const OfflineBanner(),
        ],
      ),
    );
  }
}
