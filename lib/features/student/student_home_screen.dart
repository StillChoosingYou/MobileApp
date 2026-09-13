import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_utils.dart';
import '../../core/utils/gpa_calculator.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/academic_models.dart';
import '../../models/campus_models.dart';
import '../../providers/feature_providers.dart';
import 'ai_assistant_screen.dart';
import 'widgets/promotional_ticker.dart';

class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    if (user == null) return const LoadingView();
    final profileAsync = ref.watch(studentProfileProvider(user.id));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(studentGradesProvider(user.id));
        ref.invalidate(studentLedgerProvider(user.id));
        ref.invalidate(studentEnrollmentProvider(user.id));
        ref.invalidate(announcementsProvider);
        ref.invalidate(promotionalAnnouncementsProvider);
        ref.invalidate(studentNotificationsProvider(user.id));
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // Top Promotional Announcement Ticker
          const PromotionalTicker(),
          Padding(
            padding: Responsive.pagePadding(context).copyWith(top: 20, bottom: 8),
            child: Row(
              children: [
                InitialsAvatar(name: user.name, radius: 26),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: Theme.of(context).textTheme.titleLarge),
                      profileAsync.when(
                        data: (profile) => Text(
                          profile == null
                              ? user.loginId
                              : '${profile.program} • Year ${profile.yearLevel} • ${profile.blockSection}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        loading: () => const SizedBox(height: 14),
                        error: (_, __) => Text(user.loginId),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ResponsiveStatRow(
            children: [
              FadeSlideIn(index: 0, child: _GpaStatCard(studentId: user.id)),
              FadeSlideIn(index: 1, child: _TuitionStatCard(studentId: user.id)),
              FadeSlideIn(index: 2, child: _EnrollmentStatCard(studentId: user.id)),
            ],
          ),
          const SizedBox(height: 20),
          const _DashboardLowerSection(),
        ],
      ),
    );
  }
}

/// Lower half of the home dashboard: the AI assistant card + announcements.
/// Splits into two columns on wide layouts (the AI card is a fixed side rail,
/// announcements take the rest); stacks vertically on narrow ones.
class _DashboardLowerSection extends ConsumerWidget {
  const _DashboardLowerSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gutter = Responsive.pagePadding(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        if (wide) {
          // Wide: same gutter once around the whole row; the announcements
          // column is "flush" because its parent already supplies it.
          return Padding(
            padding: gutter,
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 320, child: _AiAssistantCard()),
                SizedBox(width: 20),
                Expanded(child: _AnnouncementsSection(flush: true)),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(padding: gutter, child: const _AiAssistantCard()),
            const _AnnouncementsSection(),
          ],
        );
      },
    );
  }
}

class _AiAssistantCard extends StatelessWidget {
  const _AiAssistantCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: scheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Icon(Icons.smart_toy_outlined, color: scheme.onPrimaryContainer),
        title: Text(
          'Ask the AI Academic Assistant',
          style: TextStyle(
            color: scheme.onPrimaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Schedules, requirements, enrollment steps, tuition questions',
          style: TextStyle(color: scheme.onPrimaryContainer),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
        ),
      ),
    );
  }
}

class _AnnouncementsSection extends ConsumerWidget {
  const _AnnouncementsSection({this.flush = false});

  /// When true, adds no horizontal gutter — the parent already supplies it
  /// (the wide two-column layout).
  final bool flush;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sidePadding = flush ? EdgeInsets.zero : Responsive.pagePadding(context);
    final announcements = ref.watch(announcementsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Announcements',
          padding: flush ? const EdgeInsets.only(top: 20, bottom: 8) : null,
        ),
        announcements.when(
          data: (list) => list.isEmpty
              ? Padding(
                  padding: sidePadding,
                  child: const EmptyState(
                    icon: Icons.campaign_outlined,
                    title: 'No announcements yet',
                    message: 'Check back later for updates from the college.',
                  ),
                )
              : Column(
                  children: list
                      .take(4)
                      .map((a) => _AnnouncementTile(
                            announcement: a,
                            padding: flush
                                ? const EdgeInsets.symmetric(vertical: 4)
                                : null,
                          ))
                      .toList(),
                ),
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: LoadingView(),
          ),
          error: (e, _) => Padding(
            padding: sidePadding,
            child: const ErrorView(message: 'Could not load announcements.'),
          ),
        ),
      ],
    );
  }
}

class _GpaStatCard extends ConsumerWidget {
  const _GpaStatCard({required this.studentId});
  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grades = ref.watch(studentGradesProvider(studentId));
    return grades.when(
      data: (list) {
        final gpa = GpaCalculator.compute(list);
        return StatCard(
          icon: Icons.grade_outlined,
          label: 'GPA',
          value: gpa == null ? '—' : gpa.toStringAsFixed(2),
        );
      },
      loading: () => const StatCard(icon: Icons.grade_outlined, label: 'GPA', value: '…'),
      error: (_, __) => const StatCard(icon: Icons.grade_outlined, label: 'GPA', value: '—'),
    );
  }
}

class _TuitionStatCard extends ConsumerWidget {
  const _TuitionStatCard({required this.studentId});
  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(studentLedgerProvider(studentId));
    return ledger.when(
      data: (l) => StatCard(
        icon: Icons.account_balance_wallet_outlined,
        label: 'Balance',
        value: '₱${l.balance.toStringAsFixed(0)}',
        color: l.isFullyPaid ? Colors.green : null,
      ),
      loading: () => const StatCard(icon: Icons.account_balance_wallet_outlined, label: 'Balance', value: '…'),
      error: (_, __) => const StatCard(icon: Icons.account_balance_wallet_outlined, label: 'Balance', value: '—'),
    );
  }
}

class _EnrollmentStatCard extends ConsumerWidget {
  const _EnrollmentStatCard({required this.studentId});
  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrollment = ref.watch(studentEnrollmentProvider(studentId));
    return enrollment.when(
      data: (e) => StatCard(
        icon: Icons.how_to_reg_outlined,
        label: 'Enrollment',
        value: e == null ? 'None' : _statusLabel(e.status),
      ),
      loading: () => const StatCard(icon: Icons.how_to_reg_outlined, label: 'Enrollment', value: '…'),
      error: (_, __) => const StatCard(icon: Icons.how_to_reg_outlined, label: 'Enrollment', value: '—'),
    );
  }

  String _statusLabel(EnrollmentStatus status) => status.name;
}

class _AnnouncementTile extends StatelessWidget {
  const _AnnouncementTile({required this.announcement, this.padding});

  final Announcement announcement;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding:
          padding ?? Responsive.pagePadding(context).copyWith(top: 4, bottom: 4),
      child: Card(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  StatusPill(label: announcement.category, color: scheme.primary),
                  const Spacer(),
                  Text(
                    AppDateUtils.relative(announcement.postedAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(announcement.title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(
                announcement.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}