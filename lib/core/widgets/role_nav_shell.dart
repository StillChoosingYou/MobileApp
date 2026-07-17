import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../routing/route_names.dart';
import '../../providers/feature_providers.dart';

class NavTab {
  const NavTab({required this.icon, required this.label, required this.screen});
  final IconData icon;
  final String label;
  final Widget screen;
}

/// One AppBar + bottom [NavigationBar] driving an [IndexedStack] of tabs.
/// Each role Shell (Student, Registrar, Cashier, Faculty, Admin) owns its
/// own tab list and current-index state, and wraps it in this widget —
/// see `features/student/student_shell.dart` for the pattern.
class RoleNavShell extends StatelessWidget {
  const RoleNavShell({
    super.key,
    required this.title,
    required this.tabs,
    required this.currentIndex,
    required this.onTabSelected,
  });

  final String title;
  final List<NavTab> tabs;
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: const [LogoutButton()],
      ),
      body: IndexedStack(
        index: currentIndex,
        children: tabs.map((t) => t.screen).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTabSelected,
        destinations: tabs
            .map((t) => NavigationDestination(icon: Icon(t.icon), label: t.label))
            .toList(),
      ),
    );
  }
}

/// Shared logout icon for every role's AppBar — clears the auth session and
/// returns to Role Select.
class LogoutButton extends ConsumerWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.logout),
      tooltip: 'Log out',
      onPressed: () {
        ref.read(authControllerProvider.notifier).logout();
        context.go(Routes.roleSelect);
      },
    );
  }
}
