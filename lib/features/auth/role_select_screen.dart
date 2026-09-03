
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/app_config.dart';
import '../../core/routing/route_names.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/app_user.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Announcement data model & mock data
// ─────────────────────────────────────────────────────────────────────────────

enum AnnouncementCategory {
  general,
  finance,
  academics,
  facilities,
  studentLife,
}

class _AnnouncementData {
  const _AnnouncementData({
    required this.title,
    required this.category,
    required this.description,
    required this.date,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final AnnouncementCategory category;
  final String description;
  final String date;
  final IconData icon;
  final Color iconColor;
}

const _categoryLabels = {
  AnnouncementCategory.general: 'GENERAL',
  AnnouncementCategory.finance: 'FINANCE',
  AnnouncementCategory.academics: 'ACADEMICS',
  AnnouncementCategory.facilities: 'FACILITIES',
  AnnouncementCategory.studentLife: 'STUDENT LIFE',
};

const _categoryColors = {
  AnnouncementCategory.general: Color(0xFF1565C0),
  AnnouncementCategory.finance: Color(0xFF2E7D32),
  AnnouncementCategory.academics: Color(0xFFE65100),
  AnnouncementCategory.facilities: Color(0xFF00838F),
  AnnouncementCategory.studentLife: Color(0xFFC62828),
};

const _mockAnnouncements = [
  _AnnouncementData(
    title: 'Enrollment for A.Y. 2026–2027, 1st Semester',
    category: AnnouncementCategory.general,
    description:
        'Online enrollment is now open. Make sure to enroll on or before May 30, 2026 to avoid late fees.',
    date: 'May 14, 2026',
    icon: Icons.school_outlined,
    iconColor: Color(0xFF1565C0),
  ),
  _AnnouncementData(
    title: 'Payment Deadline: Tuition Fee – 1st Installment',
    category: AnnouncementCategory.finance,
    description:
        'The deadline for the 1st installment payment is on May 16, 2026. Please settle your fees on time.',
    date: 'May 14, 2026',
    icon: Icons.account_balance_wallet_outlined,
    iconColor: Color(0xFF2E7D32),
  ),
  _AnnouncementData(
    title: 'Midterm Examinations',
    category: AnnouncementCategory.academics,
    description:
        'Midterm exams will be conducted from May 20–23, 2026. Please review your schedule.',
    date: 'May 13, 2026',
    icon: Icons.menu_book_outlined,
    iconColor: Color(0xFFE65100),
  ),
  _AnnouncementData(
    title: 'Library Hours Update',
    category: AnnouncementCategory.facilities,
    description:
        'The library will be open from 7:00 AM to 7:00 PM starting May 15, 2026.',
    date: 'May 12, 2026',
    icon: Icons.local_library_outlined,
    iconColor: Color(0xFF00838F),
  ),
  _AnnouncementData(
    title: 'Intramurals 2026',
    category: AnnouncementCategory.studentLife,
    description:
        'Join us this June! More details and sign-up forms will be announced soon.',
    date: 'May 10, 2026',
    icon: Icons.emoji_events_outlined,
    iconColor: Color(0xFFC62828),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Main screen
// ─────────────────────────────────────────────────────────────────────────────

class RoleSelectScreen extends StatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen> {
  bool _showPromo = true;

  @override
  void initState() {
    super.initState();
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

  void _showLoginRoleSheet() {
    showModalBottomSheet<UserRole>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _RolePickerSheet(),
    ).then((role) {
      if (role != null && mounted) {
        context.push(Routes.login, extra: role);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWide = Responsive.isTabletOrWider(context);

    return Scaffold(
      body: Column(
        children: [
          // ── Promo Banner ──
          if (_showPromo)
            _EnhancedPromoBanner(onDismiss: _dismissPromo),

          // ── Scrollable content ──
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ── Header ──
                  _LandingHeader(onLogin: _showLoginRoleSheet),

                  // ── Body ──
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isWide ? 40 : 20,
                          vertical: isWide ? 32 : 20,
                        ),
                        child: isWide
                            ? _WideLayout(onLogin: _showLoginRoleSheet)
                            : _NarrowLayout(onLogin: _showLoginRoleSheet),
                      ),
                    ),
                  ),

                  // ── Footer ──
                  const _LandingFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Wide (tablet/desktop) two-column layout
// ─────────────────────────────────────────────────────────────────────────────

class _WideLayout extends StatelessWidget {
  const _WideLayout({required this.onLogin});
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column: hero
        Expanded(
          flex: 4,
          child: _WelcomeHero(onLogin: onLogin),
        ),
        const SizedBox(width: 48),
        // Right column: announcements
        const Expanded(
          flex: 6,
          child: _AnnouncementsSection(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Narrow (mobile) stacked layout
// ─────────────────────────────────────────────────────────────────────────────

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({required this.onLogin});
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WelcomeHero(onLogin: onLogin),
        const SizedBox(height: 32),
        const _AnnouncementsSection(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Enhanced Promo Banner
// ─────────────────────────────────────────────────────────────────────────────

class _EnhancedPromoBanner extends StatelessWidget {
  const _EnhancedPromoBanner({required this.onDismiss});
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final isWide = Responsive.isTabletOrWider(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 24 : 14,
        vertical: 10,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D1B4A), Color(0xFF162D6E)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // NEW badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.goldAccentDark,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'NEW!',
                style: TextStyle(
                  color: Color(0xFF102A6D),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Main text
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Download the PGPC Campus App for mobile access  ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isWide)
                      const TextSpan(
                        text: 'Stay Connected. Anytime, Anywhere.',
                        style: TextStyle(
                          color: AppColors.goldAccentDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isWide) ...[
              const SizedBox(width: 16),
              // QR / Store badges area
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white38),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'pgpc.edu.ph/app',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const _StoreBadge(label: 'Google Play', icon: Icons.android),
                  const SizedBox(width: 6),
                  const _StoreBadge(label: 'App Store', icon: Icons.apple),
                ],
              ),
            ],
            const SizedBox(width: 8),
            // Close
            InkWell(
              onTap: onDismiss,
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.close, color: Colors.white70, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreBadge extends StatelessWidget {
  const _StoreBadge({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Landing Header
// ─────────────────────────────────────────────────────────────────────────────

class _LandingHeader extends StatelessWidget {
  const _LandingHeader({required this.onLogin});
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isWide = Responsive.isTabletOrWider(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 40 : 20,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3)),
        ),

      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Row(
            children: [
              // Logo + name
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/pgpc_logo.png',
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'PGPC Campus',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    Text(
                      AppConfig.collegeFullName,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Login button
              OutlinedButton.icon(
                onPressed: onLogin,
                icon: const Icon(Icons.person_outline, size: 18),
                label: const Text('Log In'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: scheme.primary,
                  side: BorderSide(color: scheme.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Welcome Hero (left column)
// ─────────────────────────────────────────────────────────────────────────────

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero({required this.onLogin});
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isWide = Responsive.isTabletOrWider(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Heading
        Text(
          'Welcome to PGPC Campus',
          style: (isWide ? textTheme.headlineMedium : textTheme.headlineSmall)
              ?.copyWith(fontWeight: FontWeight.w700, color: scheme.onSurface),
        ),
        const SizedBox(height: 8),
        Text(
          'Your all-in-one platform for school updates,\nannouncements, and important information.',
          style: textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),

        // School photo
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: double.infinity,
            height: isWide ? 260 : 220,
            child: const _CampusIllustration(),
          ),
        ),
        const SizedBox(height: 28),

        // Stay informed CTA
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.notifications_active_outlined,
                  color: scheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stay informed',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Log in to access your classes, grades, schedule, and more personalized features.',
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: onLogin,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: scheme.primary,
                          side: BorderSide(color: scheme.primary, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Log In to Continue',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: scheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 18, color: scheme.primary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Campus Photo (replaces the old CustomPainter illustration)
// ─────────────────────────────────────────────────────────────────────────────

class _CampusIllustration extends StatelessWidget {
  const _CampusIllustration();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset(
        'assets/images/campus_bg.jpg',
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Announcements Section (right column)
// ─────────────────────────────────────────────────────────────────────────────

class _AnnouncementsSection extends StatelessWidget {
  const _AnnouncementsSection();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Icon(Icons.campaign_outlined, color: scheme.primary, size: 26),
            const SizedBox(width: 10),
            Text(
              'Announcements',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Stay updated with the latest important announcements.',
          style: textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        // Announcement cards
        ...List.generate(_mockAnnouncements.length, (index) {
          return FadeSlideIn(
            index: index,
            child: _AnnouncementCard(data: _mockAnnouncements[index]),
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual Announcement Card
// ─────────────────────────────────────────────────────────────────────────────

class _AnnouncementCard extends StatefulWidget {
  const _AnnouncementCard({required this.data});
  final _AnnouncementData data;

  @override
  State<_AnnouncementCard> createState() => _AnnouncementCardState();
}

class _AnnouncementCardState extends State<_AnnouncementCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final catColor = _categoryColors[widget.data.category] ?? scheme.primary;
    final catLabel = _categoryLabels[widget.data.category] ?? '';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: _hovered
              ? scheme.surfaceContainerLow
              : scheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hovered
                ? scheme.outlineVariant
                : scheme.outlineVariant.withValues(alpha: 0.3),
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: scheme.shadow.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(widget.data.icon, color: catColor, size: 22),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row + date
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              widget.data.title,
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            // Category badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: catColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                catLabel,
                                style: TextStyle(
                                  color: catColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.data.date,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.data.description,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Landing Footer
// ─────────────────────────────────────────────────────────────────────────────

class _LandingFooter extends StatelessWidget {
  const _LandingFooter();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      child: Center(
        child: Text(
          '© 2026 PGPC Campus. All rights reserved.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Role Picker Bottom Sheet (for Log In flow)
// ─────────────────────────────────────────────────────────────────────────────

class _RolePickerSheet extends StatelessWidget {
  const _RolePickerSheet();

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

  static const _roleColors = {
    UserRole.student: Color(0xFF102A6D),
    UserRole.teacher: Color(0xFF1B3A8C),
    UserRole.registrar: Color(0xFF2646A8),
    UserRole.accounting: Color(0xFFB8860B),
    UserRole.cashier: Color(0xFFDABD64),
    UserRole.guidance: Color(0xFF0D4A6B),
    UserRole.deptHead: Color(0xFF1A5C8A),
    UserRole.dean: Color(0xFF0A3D62),
    UserRole.admin: Color(0xFF1F3A5F),
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(Icons.login, color: scheme.primary, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Select your role to log in',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              AppConfig.currentTermLabel,
              style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          // Role list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + bottomPadding),
              itemCount: UserRole.values.length,
              itemBuilder: (context, index) {
                final role = UserRole.values[index];
                final color = _roleColors[role] ?? scheme.primary;
                final isDark = scheme.brightness == Brightness.dark;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    onTap: () => Navigator.pop(context, role),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    tileColor: isDark
                        ? color.withValues(alpha: 0.12)
                        : color.withValues(alpha: 0.06),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark
                            ? color.withValues(alpha: 0.2)
                            : color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _roleIcons[role],
                        color: color,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      role.label,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      _roleDescriptions[role] ?? '',
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}