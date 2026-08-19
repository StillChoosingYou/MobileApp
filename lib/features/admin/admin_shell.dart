import 'package:flutter/material.dart';

import '../../core/widgets/role_nav_shell.dart';
import '../../features/onboarding/role_tutorial_steps.dart';
import 'analytics_dashboard_screen.dart';
import 'user_management_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return RoleNavShell(
      title: 'Administrator',
      currentIndex: _index,
      onTabSelected: (i) => setState(() => _index = i),
      tabs: [
        NavTab(
          icon: Icons.bar_chart_outlined,
          label: 'Analytics',
          screen: const AnalyticsDashboardScreen(),
          coachMarkKey: RoleTutorialKeys.adminUsersKey,
        ),
        NavTab(
          icon: Icons.settings_outlined,
          label: 'Settings',
          screen: const UserManagementScreen(),
          coachMarkKey: RoleTutorialKeys.adminSettingsKey,
        ),
        NavTab(
          icon: Icons.history_outlined,
          label: 'Audit Logs',
          screen: const AnalyticsDashboardScreen(),
          coachMarkKey: RoleTutorialKeys.adminAuditKey,
        ),
        NavTab(
          icon: Icons.monitor_heart_outlined,
          label: 'Health',
          screen: const UserManagementScreen(),
          coachMarkKey: RoleTutorialKeys.adminHealthKey,
        ),
      ],
    );
  }
}
