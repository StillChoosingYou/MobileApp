import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Distinct brand-harmonious colors per role (derived from navy/gold palette)
  static const _roleColors = {
    UserRole.student: Color(0xFF102A6D),       // Navy
    UserRole.teacher: Color(0xFF1B3A8C),       // Navy + blue
    UserRole.registrar: Color(0xFF2646A8),     // Royal blue
    UserRole.accounting: Color(0xFFB8860B),    // Gold accent
    UserRole.cashier: Color(0xFFDABD64),       // Gold seed
    UserRole.guidance: Color(0xFF0D4A6B),      // Teal-navy
    UserRole.deptHead: Color(0xFF1A5C8A),      // Blue-navy
    UserRole.dean: Color(0xFF0A3D62),          // Deep navy
    UserRole.admin: Color(0xFF1F3A5F),         // Dark navy
  };

  // Role groupings for mobile layout
  static const _roleGroups = [
    _RoleGroup(
      title: 'Academic',
      roles: [UserRole.student, UserRole.teacher, UserRole.registrar],
    ),
    _RoleGroup(
      title: 'Finance & Administration',
      roles: [UserRole.accounting, UserRole.cashier, UserRole.admin],
    ),
    _RoleGroup(
      title: 'Academic Leadership',
      roles: [UserRole.guidance, UserRole.deptHead, UserRole.dean],
    ),
  ];

  late final PageController _pageController;
  int _currentPage = 0;
  bool _showPromo = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.82);
    _loadPromoState();
  }

  Future<void> _loadPromoState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showPromo = !(prefs.getBool('promo_dismissed') ?? false);
    });
  }

  Future<void> _dismissPromo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('promo_dismissed', true);
    setState(() => _showPromo = false);
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
    final isWide = Responsive.isTabletOrWider(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: Responsive.contentMaxWidth(context).clamp(0, 960)),
            child: landscape && compactHeight
                ? _CompactLandscapeRoleSelect(
                    scheme: scheme,
                    textTheme: textTheme,
                    roleIcons: _roleIcons,
                    roleDescriptions: _roleDescriptions,
                    roleColors: _roleColors,
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final showGrid = isWide && !landscape;
                      return SingleChildScrollView(
                        padding: Responsive.formPadding(context),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_showPromo && !compactHeight) _DismissiblePromoTicker(onDismiss: _dismissPromo),

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

                            SizedBox(height: compactHeight ? 8 : 16),

                            // ── Role Cards ──
                            if (showGrid)
                              _RoleGrid(
                                roles: UserRole.values,
                                roleIcons: _roleIcons,
                                roleDescriptions: _roleDescriptions,
                                roleColors: _roleColors,
                                compact: compactHeight,
                                onTap: (role) => context.push(Routes.login, extra: role),
                              )
                            else
                              _RoleCarousel(
                                roleGroups: _roleGroups,
                                roleIcons: _roleIcons,
                                roleDescriptions: _roleDescriptions,
                                roleColors: _roleColors,
                                compact: compactHeight,
                                pageController: _pageController,
                                currentPage: _currentPage,
                                onPageChanged: (index) => setState(() => _currentPage = index),
                                onTap: (role) => context.push(Routes.login, extra: role),
                              ),

                            SizedBox(height: compactHeight ? 8 : 16),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

/// Side-by-side layout for landscape phones
class _CompactLandscapeRoleSelect extends StatelessWidget {
  const _CompactLandscapeRoleSelect({
    required this.scheme,
    required this.textTheme,
    required this.roleIcons,
    required this.roleDescriptions,
    required this.roleColors,
  });

  final ColorScheme scheme;
  final TextTheme textTheme;
  final Map<UserRole, IconData> roleIcons;
  final Map<UserRole, String> roleDescriptions;
  final Map<UserRole, Color> roleColors;

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
                child: _RoleCard(
                  role: role,
                  icon: roleIcons[role]!,
                  description: roleDescriptions[role] ?? '',
                  color: roleColors[role]!,
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

/// Dismissible promo banner with local storage persistence
class _DismissiblePromoTicker extends StatefulWidget {
  const _DismissiblePromoTicker({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  State<_DismissiblePromoTicker> createState() => _DismissiblePromoTickerState();
}

class _DismissiblePromoTickerState extends State<_DismissiblePromoTicker> with SingleTickerProviderStateMixin {
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
      duration: const Duration(seconds: 5),
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
          IconButton(
            icon: Icon(Icons.close, color: scheme.surface, size: 20),
            onPressed: widget.onDismiss,
            tooltip: 'Dismiss',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

/// Grid layout for tablet/desktop
class _RoleGrid extends StatelessWidget {
  const _RoleGrid({
    required this.roles,
    required this.roleIcons,
    required this.roleDescriptions,
    required this.roleColors,
    required this.compact,
    required this.onTap,
  });

  final List<UserRole> roles;
  final Map<UserRole, IconData> roleIcons;
  final Map<UserRole, String> roleDescriptions;
  final Map<UserRole, Color> roleColors;
  final bool compact;
  final void Function(UserRole) onTap;

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = Responsive.gridCrossAxisCount(context);
    final aspectRatio = Responsive.gridChildAspectRatio(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: aspectRatio,
      ),
      itemCount: roles.length,
      itemBuilder: (context, index) {
        final role = roles[index];
        return FadeSlideIn(
          index: index,
          child: _RoleCard(
            role: role,
            icon: roleIcons[role]!,
            description: roleDescriptions[role] ?? '',
            color: roleColors[role]!,
            compact: compact,
            onTap: () => onTap(role),
          ),
        );
      },
    );
  }
}

/// Carousel with grouped sections for mobile
class _RoleCarousel extends StatelessWidget {
  const _RoleCarousel({
    required this.roleGroups,
    required this.roleIcons,
    required this.roleDescriptions,
    required this.roleColors,
    required this.compact,
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
    required this.onTap,
  });

  final List<_RoleGroup> roleGroups;
  final Map<UserRole, IconData> roleIcons;
  final Map<UserRole, String> roleDescriptions;
  final Map<UserRole, Color> roleColors;
  final bool compact;
  final PageController pageController;
  final int currentPage;
  final void Function(int) onPageChanged;
  final void Function(UserRole) onTap;

  @override
  Widget build(BuildContext context) {
    // Flatten all roles for page indexing
    final allRoles = roleGroups.expand((g) => g.roles).toList();

    return Column(
      children: [
        SizedBox(
          height: compact ? 200 : 260,
          child: PageView.builder(
            controller: pageController,
            onPageChanged: onPageChanged,
            itemCount: allRoles.length,
            itemBuilder: (context, index) {
              final role = allRoles[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: FadeSlideIn(
                  index: index,
                  child: _RoleCard(
                    role: role,
                    icon: roleIcons[role]!,
                    description: roleDescriptions[role] ?? '',
                    color: roleColors[role]!,
                    compact: compact,
                    onTap: () => onTap(role),
                  ),
                ),
              );
            },
          ),
        ),
        // Page indicator dots
        Padding(
          padding: EdgeInsets.only(top: compact ? 8 : 12, bottom: compact ? 12 : 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              allRoles.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: currentPage == index
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Grouped role section for mobile carousel
class _RoleGroup {
  const _RoleGroup({required this.title, required this.roles});

  final String title;
  final List<UserRole> roles;
}

/// Enhanced role card with distinct color, full pressable area, and hover/press states
class _RoleCard extends StatefulWidget {
  const _RoleCard({
    required this.role,
    required this.icon,
    required this.description,
    required this.color,
    required this.onTap,
    this.compact = false,
  });

  final UserRole role;
  final IconData icon;
  final String description;
  final Color color;
  final VoidCallback onTap;
  final bool compact;

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final iconSize = widget.compact ? 44.0 : 56.0;
    final borderRadius = widget.compact ? 16.0 : 20.0;
    final padding = widget.compact
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 16)
        : const EdgeInsets.symmetric(horizontal: 24, vertical: 24);

    // Derive container color from role color
    final containerColor = isDark
        ? widget.color.withValues(alpha: 0.18)
        : widget.color.withValues(alpha: 0.10);
    final borderColor = isDark
        ? widget.color.withValues(alpha: 0.35)
        : widget.color.withValues(alpha: 0.25);
    final iconBgColor = isDark
        ? widget.color.withValues(alpha: 0.25)
        : widget.color.withValues(alpha: 0.15);
    final iconColor = widget.color;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : (_hovered ? 1.01 : 1.0),
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: borderColor, width: _hovered ? 2 : 1),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: widget.color.withValues(alpha: isDark ? 0.25 : 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            padding: padding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(widget.compact ? 12 : 16),
                  ),
                  child: Icon(widget.icon, color: iconColor, size: widget.compact ? 22 : 28),
                ),
                SizedBox(height: widget.compact ? 10 : 14),
                Text(
                  widget.role.label,
                  style: widget.compact
                      ? Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          )
                      : Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                  maxLines: widget.compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}