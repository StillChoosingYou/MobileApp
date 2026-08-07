import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/routing/route_names.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/app_user.dart';

class RoleSelectScreen extends StatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen> {
  static const _roleIcons = {
    UserRole.student: Icons.school,
    UserRole.teacher: Icons.co_present,
    UserRole.registrar: Icons.badge,
    UserRole.accounting: Icons.calculate,
    UserRole.cashier: Icons.point_of_sale,
    UserRole.guidance: Icons.support_agent,
    UserRole.deptHead: Icons.groups_2,
    UserRole.dean: Icons.account_balance,
    UserRole.admin: Icons.admin_panel_settings,
  };

  static const _roleDescriptions = {
    UserRole.student: 'Grades, schedule, tuition & enrollment',
    UserRole.teacher: 'Class lists, attendance & grade encoding',
    UserRole.registrar: 'Enrollment approval & student records',
    UserRole.accounting: 'Ledger management & financial reports',
    UserRole.cashier: 'Payment recording & receipt generation',
    UserRole.guidance: 'Counseling appointments & clearance',
    UserRole.deptHead: 'Department oversight & faculty load',
    UserRole.dean: 'College-level administration',
    UserRole.admin: 'System settings, users & audit logs',
  };

  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.82);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final compactHeight = Responsive.isCompactHeight(context);
    final landscape = Responsive.isLandscape(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: Responsive.contentMaxWidth(context).clamp(0, 520)),
            child: landscape && compactHeight
                ? _CompactLandscapeRoleSelect(
                    scheme: scheme,
                    textTheme: textTheme,
                    roleIcons: _roleIcons,
                    roleDescriptions: _roleDescriptions,
                  )
                : Column(
              children: [
                if (!compactHeight) const _PromoTicker(),

                // ── Header ──
                Padding(
                  padding: EdgeInsets.fromLTRB(24, compactHeight ? 12 : 20, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.asset(
                              'assets/images/pgpc_logo.png',
                              width: compactHeight ? 44 : 52,
                              height: compactHeight ? 44 : 52,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('PGPC Campus', style: textTheme.titleLarge),
                                Text(
                                  AppConfig.collegeFullName,
                                  style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                                  maxLines: compactHeight ? 1 : 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: compactHeight ? 16 : 28),
                      Text(
                        'Welcome back',
                        style: compactHeight ? textTheme.titleLarge : textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Select your role to continue — ${AppConfig.currentTermLabel}',
                        style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: compactHeight ? 12 : 24),

                // ── Role Slider ──
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) => setState(() => _currentPage = index),
                          itemCount: UserRole.values.length,
                          itemBuilder: (context, index) {
                            final role = UserRole.values[index];
                            return FadeSlideIn(
                              index: index,
                              child: _LandscapeRoleCard(
                                role: role,
                                icon: _roleIcons[role]!,
                                description: _roleDescriptions[role] ?? '',
                                compact: compactHeight,
                                onTap: () => context.push(Routes.login, extra: role),
                              ),
                            );
                          },
                        ),
                      ),

                      // ── Page Indicator Dots ──
                      Padding(
                        padding: EdgeInsets.only(top: compactHeight ? 8 : 12, bottom: compactHeight ? 12 : 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            UserRole.values.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: _currentPage == index ? 24 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _currentPage == index
                                    ? scheme.primary
                                    : scheme.outlineVariant,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Side-by-side layout for landscape phones — keeps all roles reachable without
/// vertical overflow from the promo ticker + page dots stack.
class _CompactLandscapeRoleSelect extends StatelessWidget {
  const _CompactLandscapeRoleSelect({
    required this.scheme,
    required this.textTheme,
    required this.roleIcons,
    required this.roleDescriptions,
  });

  final ColorScheme scheme;
  final TextTheme textTheme;
  final Map<UserRole, IconData> roleIcons;
  final Map<UserRole, String> roleDescriptions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/pgpc_logo.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('PGPC Campus', style: textTheme.titleMedium),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Welcome back', style: textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'Select your role — ${AppConfig.currentTermLabel}',
                  style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 6,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
            itemCount: UserRole.values.length,
            itemBuilder: (context, index) {
              final role = UserRole.values[index];
              return FadeSlideIn(
                index: index,
                child: _LandscapeRoleCard(
                  role: role,
                  icon: roleIcons[role]!,
                  description: roleDescriptions[role] ?? '',
                  compact: true,
                  onTap: () => context.push(Routes.login, extra: role),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// A horizontally-scrolling ticker that auto-rotates campus promos/announcements.
class _PromoTicker extends StatefulWidget {
  const _PromoTicker();

  @override
  State<_PromoTicker> createState() => _PromoTickerState();
}

class _PromoTickerState extends State<_PromoTicker> with SingleTickerProviderStateMixin {
  static const _promos = [
    '📢 Enrollment for A.Y. 2026–2027, 2nd Semester opens soon!',
    '🎓 Foundation Week — Aug 18-22 | Sportsfest & Talent Night',
    '💳 Pay tuition via GCash, bank transfer, or at the Cashier window',
    '📱 Download the PGPC Campus App for mobile access',
    '🏆 PGPC ranked Top 10 Polytechnic Colleges in CALABARZON',
  ];

  late final AnimationController _controller;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _currentIndex = (_currentIndex + 1) % _promos.length);
          _controller.forward(from: 0);
        }
      });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.royalBlueSeed,
            AppColors.royalBlueSeed.withValues(alpha: 0.85),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.goldAccentDark,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'NEW',
              style: TextStyle(
                color: Color(0xFF102A6D),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.6),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Text(
                _promos[_currentIndex],
                key: ValueKey<int>(_currentIndex),
                style: TextStyle(
                  color: scheme.surface,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A landscape-oriented role card displayed in the horizontal slider.
class _LandscapeRoleCard extends StatelessWidget {
  const _LandscapeRoleCard({
    required this.role,
    required this.icon,
    required this.description,
    required this.onTap,
    this.compact = false,
  });

  final UserRole role;
  final IconData icon;
  final String description;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final iconSize = compact ? 44.0 : 56.0;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: compact ? 4 : 8),
      child: Card(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(compact ? 16 : 20),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(compact ? 16 : 20),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 24, vertical: compact ? 12 : 20),
            child: Row(
              children: [
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(compact ? 12 : 16),
                  ),
                  child: Icon(icon, color: scheme.onSecondaryContainer, size: compact ? 22 : 28),
                ),
                SizedBox(width: compact ? 14 : 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        role.label,
                        style: compact
                            ? Theme.of(context).textTheme.titleMedium
                            : Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                        maxLines: compact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
