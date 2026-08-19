import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../routing/route_names.dart';
import '../utils/responsive.dart';
import '../../features/onboarding/coach_mark_overlay.dart';
import '../../providers/feature_providers.dart';

class NavTab {
  const NavTab({
    required this.icon,
    required this.label,
    required this.screen,
    this.appBarBottom,
    this.coachMarkKey, // Key for coach mark targeting
  });

  final IconData icon;
  final String label;
  final Widget screen;

  /// Optional [TabBar] or other widget placed under the AppBar title.
  final PreferredSizeWidget? appBarBottom;

  /// Optional GlobalKey for coach mark tutorial targeting.
  final GlobalKey? coachMarkKey;
}

/// One AppBar + bottom [NavigationBar] or side [NavigationRail] driving an
/// [IndexedStack] of tabs. Each role Shell (Student, Registrar, Cashier,
/// Faculty, Admin) owns its own tab list and current-index state, and wraps
/// it in this widget — see `features/student/student_shell.dart` for the
/// pattern.
class RoleNavShell extends StatelessWidget {
  const RoleNavShell({
    required this.tabs,
    required this.currentIndex,
    required this.onTabSelected,
    super.key,
    this.title,
  });

  /// Fallback title when [NavTab.label] should not be used as the AppBar title.
  final String? title;
  final List<NavTab> tabs;
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  String get _appBarTitle => title ?? tabs[currentIndex].label;

  @override
  Widget build(BuildContext context) {
    final useSideNav = Responsive.useSideNavigation(context);
    final extendRail = Responsive.shouldExtendNavigationRail(context);
    final destinations = tabs
        .map((t) => NavigationDestination(icon: Icon(t.icon), label: t.label))
        .toList();
    final railDestinations = tabs
        .map(
          (t) => NavigationRailDestination(
            icon: Icon(t.icon),
            label: Text(t.label),
          ),
        )
        .toList();

    final body = IndexedStack(
      index: currentIndex,
      children: tabs.map((t) => t.screen).toList(),
    );

    if (useSideNav) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_appBarTitle),
          bottom: tabs[currentIndex].appBarBottom,
          actions: const [LogoutButton()],
        ),
        body: SafeArea(
          child: Row(
            children: [
              NavigationRail(
                selectedIndex: currentIndex,
                onDestinationSelected: onTabSelected,
                extended: extendRail,
                labelType: extendRail
                    ? NavigationRailLabelType.none
                    : NavigationRailLabelType.selected,
                destinations: railDestinations,
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: ResponsiveContent(child: body),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle),
        bottom: tabs[currentIndex].appBarBottom,
        actions: const [LogoutButton()],
      ),
      body: SafeArea(
        child: ResponsiveContent(child: body),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTabSelected,
        labelBehavior: Responsive.isCompactHeight(context)
            ? NavigationDestinationLabelBehavior.onlyShowSelected
            : NavigationDestinationLabelBehavior.alwaysShow,
        destinations: destinations,
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