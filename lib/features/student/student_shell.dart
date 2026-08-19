import 'package:flutter/material.dart';

import '../../core/widgets/role_nav_shell.dart';
import '../../features/onboarding/role_tutorial_steps.dart';
import 'digital_id_screen.dart';
import 'schedule_grades_screen.dart';
import 'services_screen.dart';
import 'student_home_screen.dart';
import 'tuition_wallet_screen.dart';

class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return RoleNavShell(
      currentIndex: _index,
      onTabSelected: (i) => setState(() => _index = i),
      tabs: [
        NavTab(
          icon: Icons.home_outlined,
          label: 'Home',
          screen: const StudentHomeScreen(),
          coachMarkKey: RoleTutorialKeys.studentHomeTabKey,
        ),
        NavTab(
          icon: Icons.grade_outlined,
          label: 'Grades',
          screen: const ScheduleGradesScreen(),
          coachMarkKey: RoleTutorialKeys.studentGradesTabKey,
        ),
        NavTab(
          icon: Icons.schedule_outlined,
          label: 'Schedule',
          screen: const ScheduleGradesScreen(),
          coachMarkKey: RoleTutorialKeys.studentScheduleTabKey,
        ),
        NavTab(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Tuition',
          screen: const TuitionWalletScreen(),
          coachMarkKey: RoleTutorialKeys.studentTuitionTabKey,
        ),
        NavTab(
          icon: Icons.miscellaneous_services_outlined,
          label: 'Services',
          screen: const ServicesScreen(),
          coachMarkKey: RoleTutorialKeys.studentServicesTabKey,
        ),
        NavTab(
          icon: Icons.badge_outlined,
          label: 'Digital ID',
          screen: const DigitalIdScreen(),
          coachMarkKey: RoleTutorialKeys.studentDigitalIdKey,
        ),
      ],
    );
  }
}
