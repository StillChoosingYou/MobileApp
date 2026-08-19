import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/role_nav_shell.dart';
import '../../features/onboarding/coach_mark_overlay.dart';
import '../../features/onboarding/role_tutorial_steps.dart';
import '../../features/onboarding/tutorial_providers.dart';
import '../../models/app_user.dart';
import '../../providers/feature_providers.dart';
import 'analytics_dashboard_screen.dart';
import 'user_management_screen.dart';

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _index = 0;
  bool _tutorialStarted = false;

  @override
  void initState() {
    super.initState();
    _checkAndStartTutorial();
  }

  Future<void> _checkAndStartTutorial() async {
    final authState = ref.read(authControllerProvider);
    final user = authState.value;
    if (user == null) return;

    final completed = await ref.read(roleTutorialCompletedProvider(
      (userId: user.id, role: user.role),
    ).future);

    if (!completed && mounted && !_tutorialStarted) {
      _tutorialStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _startTutorial();
        }
      });
    }
  }

  void _startTutorial() {
    final steps = RoleTutorialSteps.getStepsForRole(UserRole.admin);
    CoachMarkOverlay.show(
      context: context,
      steps: steps,
      onComplete: () async {
        final authState = ref.read(authControllerProvider);
        final user = authState.value;
        if (user != null) {
          await ref.read(markRoleTutorialCompletedProvider)(
            user.id,
            user.role,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      NavTab(
        icon: Icons.bar_chart_outlined,
        label: 'Analytics',
        screen: CoachMarkTarget(key: RoleTutorialKeys.adminUsersKey, child: const AnalyticsDashboardScreen()),
        coachMarkKey: RoleTutorialKeys.adminUsersKey,
      ),
      NavTab(
        icon: Icons.settings_outlined,
        label: 'Settings',
        screen: CoachMarkTarget(key: RoleTutorialKeys.adminSettingsKey, child: const UserManagementScreen()),
        coachMarkKey: RoleTutorialKeys.adminSettingsKey,
      ),
      NavTab(
        icon: Icons.history_outlined,
        label: 'Audit Logs',
        screen: CoachMarkTarget(key: RoleTutorialKeys.adminAuditKey, child: const AnalyticsDashboardScreen()),
        coachMarkKey: RoleTutorialKeys.adminAuditKey,
      ),
      NavTab(
        icon: Icons.monitor_heart_outlined,
        label: 'Health',
        screen: CoachMarkTarget(key: RoleTutorialKeys.adminHealthKey, child: const UserManagementScreen()),
        coachMarkKey: RoleTutorialKeys.adminHealthKey,
      ),
    ];

    return RoleNavShell(
      title: 'Administrator',
      currentIndex: _index,
      onTabSelected: (i) => setState(() => _index = i),
      tabs: tabs,
    );
  }
}
