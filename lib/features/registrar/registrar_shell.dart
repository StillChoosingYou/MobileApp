import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/role_nav_shell.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../providers/feature_providers.dart';
import 'student_records_screen.dart';
import 'enrollment_approval_screen.dart';

class RegistrarShell extends StatefulWidget {
  const RegistrarShell({super.key});

  @override
  State<RegistrarShell> createState() => _RegistrarShellState();
}

class _RegistrarShellState extends State<RegistrarShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return RoleNavShell(
      title: 'Registrar',
      currentIndex: _index,
      onTabSelected: (i) => setState(() => _index = i),
      tabs: const [
        NavTab(icon: Icons.dashboard_outlined, label: 'Home', screen: _RegistrarHomeScreen()),
        NavTab(icon: Icons.folder_shared_outlined, label: 'Records', screen: StudentRecordsScreen()),
        NavTab(icon: Icons.fact_check_outlined, label: 'Enrollment', screen: EnrollmentApprovalScreen()),
      ],
    );
  }
}

class _RegistrarHomeScreen extends ConsumerWidget {
  const _RegistrarHomeScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingEnrollmentsProvider);
    final subjects = ref.watch(allSubjectsProvider);
    final sections = ref.watch(allSectionsProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Registrar Overview', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: pending.when(
                data: (list) => StatCard(
                  icon: Icons.pending_actions_outlined,
                  label: 'Pending Enrollments',
                  value: '${list.length}',
                  color: list.isEmpty ? null : Colors.orange,
                ),
                loading: () => const StatCard(icon: Icons.pending_actions_outlined, label: 'Pending Enrollments', value: '…'),
                error: (_, __) => const StatCard(icon: Icons.pending_actions_outlined, label: 'Pending Enrollments', value: '—'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: subjects.when(
                data: (list) => StatCard(icon: Icons.menu_book_outlined, label: 'Subjects Offered', value: '${list.length}'),
                loading: () => const StatCard(icon: Icons.menu_book_outlined, label: 'Subjects Offered', value: '…'),
                error: (_, __) => const StatCard(icon: Icons.menu_book_outlined, label: 'Subjects Offered', value: '—'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        sections.when(
          data: (list) => StatCard(icon: Icons.event_seat_outlined, label: 'Active Sections', value: '${list.length}'),
          loading: () => const StatCard(icon: Icons.event_seat_outlined, label: 'Active Sections', value: '…'),
          error: (_, __) => const StatCard(icon: Icons.event_seat_outlined, label: 'Active Sections', value: '—'),
        ),
        const SizedBox(height: 24),
        Text(
          'Curriculum management, COR issuance, transcript and certificate generation, and '
          'graduation evaluation share the same Records screen pattern — extend '
          'StudentRecordsScreen / RegistrarRepository the same way once you need them.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
