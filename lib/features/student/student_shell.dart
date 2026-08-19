import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/role_nav_shell.dart';
import '../../features/onboarding/coach_mark_overlay.dart';
import '../../features/onboarding/role_tutorial_steps.dart';
import '../../features/onboarding/tutorial_providers.dart';
import '../../models/app_user.dart';
import '../../providers/feature_providers.dart';
import 'digital_id_screen.dart';
import 'schedule_grades_screen.dart';
import 'services_screen.dart';
import 'student_home_screen.dart';
import 'tuition_wallet_screen.dart';

class StudentShell extends ConsumerStatefulWidget {
  const StudentShell({super.key});

  @override
  ConsumerState<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends ConsumerState<StudentShell> {
  int _index = 0;
  bool _tutorialStarted = false;

  @override
  void initState() {
    super.initState();
    _checkAndStartTutorial();
  }

  Future<void> _checkAndStartTutorial() async {
    // Get current user from auth controller
    final authState = ref.read(authControllerProvider);
    final user = authState.value;
    if (user == null) return;

    // Check if tutorial completed
    final completed = await ref.read(roleTutorialCompletedProvider(
      (userId: user.id, role: user.role),
    ).future);

    if (!completed && mounted && !_tutorialStarted) {
      _tutorialStarted = true;
      // Wait for first frame to ensure keys are registered
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _startTutorial();
        }
      });
    }
  }

  void _startTutorial() {
    final steps = RoleTutorialSteps.getStepsForRole(UserRole.student);
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
        icon: Icons.home_outlined,
        label: 'Home',
        screen: CoachMarkTarget(key: RoleTutorialKeys.studentHomeTabKey, child: const StudentHomeScreen()),
        coachMarkKey: RoleTutorialKeys.studentHomeTabKey,
      ),
      NavTab(
        icon: Icons.grade_outlined,
        label: 'Grades',
        screen: CoachMarkTarget(key: RoleTutorialKeys.studentGradesTabKey, child: const ScheduleGradesScreen()),
        coachMarkKey: RoleTutorialKeys.studentGradesTabKey,
      ),
      NavTab(
        icon: Icons.schedule_outlined,
        label: 'Schedule',
        screen: CoachMarkTarget(key: RoleTutorialKeys.studentScheduleTabKey, child: const ScheduleGradesScreen()),
        coachMarkKey: RoleTutorialKeys.studentScheduleTabKey,
      ),
      NavTab(
        icon: Icons.account_balance_wallet_outlined,
        label: 'Tuition',
        screen: CoachMarkTarget(key: RoleTutorialKeys.studentTuitionTabKey, child: const TuitionWalletScreen()),
        coachMarkKey: RoleTutorialKeys.studentTuitionTabKey,
      ),
      NavTab(
        icon: Icons.miscellaneous_services_outlined,
        label: 'Services',
        screen: CoachMarkTarget(key: RoleTutorialKeys.studentServicesTabKey, child: const ServicesScreen()),
        coachMarkKey: RoleTutorialKeys.studentServicesTabKey,
      ),
      NavTab(
        icon: Icons.badge_outlined,
        label: 'Digital ID',
        screen: CoachMarkTarget(key: RoleTutorialKeys.studentDigitalIdKey, child: const DigitalIdScreen()),
        coachMarkKey: RoleTutorialKeys.studentDigitalIdKey,
      ),
    ];

    return RoleNavShell(
      currentIndex: _index,
      onTabSelected: (i) => setState(() => _index = i),
      tabs: tabs,
    );
  }
}
