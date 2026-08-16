import 'package:flutter/material.dart';

import '../../core/widgets/role_nav_shell.dart';
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
      tabs: const [
        NavTab(icon: Icons.home_outlined, label: 'PGPC Campus', screen: StudentHomeScreen()),
        NavTab(icon: Icons.badge_outlined, label: 'Digital ID', screen: DigitalIdScreen()),
        NavTab(icon: Icons.event_note_outlined, label: 'Schedule & Grades', screen: ScheduleGradesScreen()),
        NavTab(icon: Icons.account_balance_wallet_outlined, label: 'Tuition & Wallet', screen: TuitionWalletScreen()),
        NavTab(icon: Icons.miscellaneous_services_outlined, label: 'Services', screen: ServicesScreen()),
      ],
    );
  }
}
