import 'package:flutter/material.dart';

import '../../core/widgets/role_nav_shell.dart';
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
      tabs: const [
        NavTab(icon: Icons.bar_chart_outlined, label: 'Analytics', screen: AnalyticsDashboardScreen()),
        NavTab(icon: Icons.manage_accounts_outlined, label: 'Users', screen: UserManagementScreen()),
      ],
    );
  }
}
