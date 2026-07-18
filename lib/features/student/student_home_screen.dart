import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_utils.dart';
import '../../core/utils/gpa_calculator.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/academic_models.dart';
import '../../models/campus_models.dart';
import '../../providers/feature_providers.dart';
import 'ai_assistant_screen.dart';

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
        ref.invalidate(studentNotificationsProvider(user.id));
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(child: _GpaStatCard(studentId: user.id)),
                const SizedBox(width: 12),
                Expanded(child: _TuitionStatCard(studentId: user.id)),
                const SizedBox(width: 12),
                Expanded(child: _EnrollmentStatCard(studentId: user.id)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: Icon(Icons.smart_toy_outlined, color: Theme.of(context).colorScheme.onPrimaryContainer),
                title: Text(
                  'Ask the AI Academic Assistant',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Schedules, requirements, enrollment steps, tuition questions',
                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
                ),
              ),
            ),
          ),
          const SectionHeader(title: 'Announcements'),
          Consumer(
            builder: (context, ref, _) {
              final announcements = ref.watch(announcementsProvider);
              return announcements.when(
                data: (list) => list.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: EmptyState(
                          icon: Icons.campaign_outlined,
                          title: 'No announcements yet',
                          message: 'Check back later for updates from the college.',
                        ),
                      )
                    : Column(
                        children: list.take(4).map((a) => _AnnouncementTile(announcement: a)).toList(),
                      ),
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: LoadingView(),
                ),
                error: (e, _) => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: ErrorView(message: 'Could not load announcements.'),
                ),
              );
            },
          ),
        ],
      ),
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
  const _AnnouncementTile({required this.announcement});
  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
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
