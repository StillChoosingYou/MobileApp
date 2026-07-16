import 'package:flutter/material.dart';

import '../../core/widgets/role_nav_shell.dart';
import 'class_attendance_screen.dart';
import 'grade_encoding_screen.dart';

class FacultyShell extends StatefulWidget {
  const FacultyShell({super.key});

  @override
  State<FacultyShell> createState() => _FacultyShellState();
}

class _FacultyShellState extends State<FacultyShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return RoleNavShell(
      title: 'Faculty',
      currentIndex: _index,
      onTabSelected: (i) => setState(() => _index = i),
      tabs: const [
        NavTab(icon: Icons.class_outlined, label: 'Classes', screen: ClassAttendanceScreen()),
        NavTab(icon: Icons.grade_outlined, label: 'Grades', screen: GradeEncodingScreen()),
      ],
    );
  }
}
