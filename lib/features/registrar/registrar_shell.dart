import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/responsive.dart';
import '../../core/widgets/role_nav_shell.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../features/onboarding/coach_mark_overlay.dart';
import '../../features/onboarding/role_tutorial_steps.dart';
import '../../features/onboarding/tutorial_providers.dart';
import '../../models/app_user.dart';
import '../../providers/feature_providers.dart';
import 'enrollment_approval_screen.dart';
import 'student_records_screen.dart';

class RegistrarShell extends ConsumerStatefulWidget {
  const RegistrarShell({super.key});

  @override
  ConsumerState<RegistrarShell> createState() => _RegistrarShellState();
}

class _RegistrarShellState extends ConsumerState<RegistrarShell> {
  int _index = 0;
  bool _tutorialStarted = false;

  @override
  void initState() {
    super.initState();
    _checkAndStartTutorial();
  }

  Future<void> _checkAndStartTutorial() async {
    final authState = ref.read(authControllerProvider);
    final user = authState.value;
    if (user == null) return;

    final completed = await ref.read(roleTutorialCompletedProvider(
      (userId: user.id, role: user.role),
    ).future);

    if (!completed && mounted && !_tutorialStarted) {
      _tutorialStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _startTutorial();
        }
      });
    }
  }

  void _startTutorial() {
    final steps = RoleTutorialSteps.getStepsForRole(UserRole.registrar);
    CoachMarkOverlay.show(
      context: context,
      steps: steps,
      onComplete: () async {
        final authState = ref.read(authControllerProvider);
        final user = authState.value;
        if (user != null) {
          await ref.read(markRoleTutorialCompletedProvider)(
            user.id,
            user.role,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      NavTab(
        icon: Icons.dashboard_outlined,
        label: 'Home',
        screen: CoachMarkTarget(key: RoleTutorialKeys.registrarEnrollmentTabKey, child: const _RegistrarHomeScreen()),
        coachMarkKey: RoleTutorialKeys.registrarEnrollmentTabKey,
      ),
      NavTab(
        icon: Icons.folder_shared_outlined,
        label: 'Records',
        screen: CoachMarkTarget(key: RoleTutorialKeys.registrarRecordsTabKey, child: const StudentRecordsScreen()),
        coachMarkKey: RoleTutorialKeys.registrarRecordsTabKey,
      ),
      NavTab(
        icon: Icons.fact_check_outlined,
        label: 'Enrollment',
        screen: CoachMarkTarget(key: RoleTutorialKeys.registrarReportsTabKey, child: const EnrollmentApprovalScreen()),
        coachMarkKey: RoleTutorialKeys.registrarReportsTabKey,
      ),
    ];

    return RoleNavShell(
      title: 'Registrar',
      currentIndex: _index,
      onTabSelected: (i) => setState(() => _index = i),
      tabs: tabs,
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
      padding: Responsive.scrollPadding(context),
      children: [
        Text('Registrar Overview', style: Theme.of(context).textTheme.headlineSmall),
        SizedBox(height: Responsive.spacing(context)),
        ResponsiveStatRow(
          children: [
            pending.when(
              data: (list) => StatCard(
                icon: Icons.pending_actions_outlined,
                label: 'Pending Enrollments',
                value: '${list.length}',
                color: list.isEmpty ? null : Colors.orange,
              ),
              loading: () => const StatCard(icon: Icons.pending_actions_outlined, label: 'Pending Enrollments', value: '…'),
              error: (_, __) => const StatCard(icon: Icons.pending_actions_outlined, label: 'Pending Enrollments', value: '—'),
            ),
            subjects.when(
              data: (list) => StatCard(icon: Icons.menu_book_outlined, label: 'Subjects Offered', value: '${list.length}'),
              loading: () => const StatCard(icon: Icons.menu_book_outlined, label: 'Subjects Offered', value: '…'),
              error: (_, __) => const StatCard(icon: Icons.menu_book_outlined, label: 'Subjects Offered', value: '—'),
            ),
          ],
        ),
        Padding(
          padding: Responsive.pagePadding(context).copyWith(top: 12),
          child: sections.when(
            data: (list) => StatCard(icon: Icons.event_seat_outlined, label: 'Active Sections', value: '${list.length}'),
            loading: () => const StatCard(icon: Icons.event_seat_outlined, label: 'Active Sections', value: '…'),
            error: (_, __) => const StatCard(icon: Icons.event_seat_outlined, label: 'Active Sections', value: '—'),
          ),
        ),
        SizedBox(height: Responsive.spacing(context, normal: 24, compact: 16)),
        Padding(
          padding: Responsive.pagePadding(context),
          child: Text(
            'Curriculum management, COR issuance, transcript and certificate generation, and '
            'graduation evaluation share the same Records screen pattern — extend '
            'StudentRecordsScreen / RegistrarRepository the same way once you need them.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }
}
