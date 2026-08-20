import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/role_nav_shell.dart';
import '../../features/calendar/calendar_screen.dart';
import '../../features/onboarding/coach_mark_overlay.dart';
import '../../features/onboarding/role_tutorial_steps.dart';
import '../../features/onboarding/tutorial_providers.dart';
import '../../models/app_user.dart';
import '../../providers/feature_providers.dart';
import 'class_attendance_screen.dart';
import 'grade_encoding_screen.dart';
import '../messaging/message_list_screen.dart';

class FacultyShell extends ConsumerStatefulWidget {
  const FacultyShell({super.key});

  @override
  ConsumerState<FacultyShell> createState() => _FacultyShellState();
}

class _FacultyShellState extends ConsumerState<FacultyShell> {
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
    final steps = RoleTutorialSteps.getStepsForRole(UserRole.teacher);
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
        icon: Icons.class_outlined,
        label: 'Classes',
        screen: CoachMarkTarget(key: RoleTutorialKeys.teacherClassesTabKey, child: const ClassAttendanceScreen()),
        coachMarkKey: RoleTutorialKeys.teacherClassesTabKey,
      ),
      NavTab(
        icon: Icons.grade_outlined,
        label: 'Grades',
        screen: CoachMarkTarget(key: RoleTutorialKeys.teacherGradesTabKey, child: const GradeEncodingScreen()),
        coachMarkKey: RoleTutorialKeys.teacherGradesTabKey,
      ),
      NavTab(
        icon: Icons.schedule_outlined,
        label: 'Schedule',
        screen: CoachMarkTarget(key: RoleTutorialKeys.teacherScheduleTabKey, child: const ClassAttendanceScreen()),
        coachMarkKey: RoleTutorialKeys.teacherScheduleTabKey,
      ),
      NavTab(
        icon: Icons.calendar_month_outlined,
        label: 'Calendar',
        screen: CoachMarkTarget(key: RoleTutorialKeys.teacherCalendarTabKey, child: const CalendarScreen()),
        coachMarkKey: RoleTutorialKeys.teacherCalendarTabKey,
      ),
      NavTab(
        icon: Icons.chat_outlined,
        label: 'Messages',
        screen: CoachMarkTarget(key: RoleTutorialKeys.teacherMessagesTabKey, child: const MessageListScreen()),
        coachMarkKey: RoleTutorialKeys.teacherMessagesTabKey,
      ),
    ];

    return RoleNavShell(
      title: 'Faculty',
      currentIndex: _index,
      onTabSelected: (i) => setState(() => _index = i),
      tabs: tabs,
    );
  }
}
