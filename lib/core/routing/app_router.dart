import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/app_user.dart';
import '../../features/auth/role_select_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/two_factor_screen.dart';
import '../../features/student/student_shell.dart';
import '../../features/registrar/registrar_shell.dart';
import '../../features/cashier/cashier_shell.dart';
import '../../features/faculty/faculty_shell.dart';
import '../../features/admin/admin_shell.dart';
import '../../features/other_roles/other_role_screens.dart';
import '../../features/common/emergency_visitor_lostfound_screens.dart';
import 'route_names.dart';

/// This is a deliberately flat router: one top-level GoRoute per role
/// landing page. Each role's *internal* tabs (Home, Grades, Tuition, ...)
/// are managed inside that role's Shell widget with a plain IndexedStack,
/// and secondary screens (a student's detail page, a receipt) are pushed
/// with plain `Navigator.push` from inside the shell rather than modeled as
/// nested go_router routes.
///
/// This trades away deep-linking into a specific tab for a much simpler,
/// lower-risk router — reasonable for a scaffold. If you need shareable
/// URLs per tab later, migrate each Shell to `StatefulShellRoute.indexedStack`.
///
/// Auth guarding is intentionally not wired through `redirect` here — see
/// the README "Hardening for production" section.
final GoRouter appRouter = GoRouter(
  initialLocation: Routes.roleSelect,
  routes: [
    GoRoute(
      path: Routes.roleSelect,
      builder: (context, state) => const RoleSelectScreen(),
    ),
    GoRoute(
      path: Routes.login,
      builder: (context, state) => LoginScreen(role: state.extra as UserRole),
    ),
    GoRoute(
      path: Routes.forgotPassword,
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: Routes.twoFactor,
      builder: (context, state) => TwoFactorScreen(pendingUser: state.extra as AppUser),
    ),
    GoRoute(
      path: Routes.student,
      builder: (context, state) => const StudentShell(),
    ),
    GoRoute(
      path: Routes.registrar,
      builder: (context, state) => const RegistrarShell(),
    ),
    GoRoute(
      path: Routes.cashier,
      builder: (context, state) => const CashierShell(),
    ),
    GoRoute(
      path: Routes.faculty,
      builder: (context, state) => const FacultyShell(),
    ),
    GoRoute(
      path: Routes.admin,
      builder: (context, state) => const AdminShell(),
    ),
    GoRoute(
      path: Routes.roleDashboard,
      builder: (context, state) => GenericRoleDashboard(role: state.extra as UserRole),
    ),
    GoRoute(
      path: Routes.emergency,
      builder: (context, state) => const EmergencyScreen(),
    ),
    GoRoute(
      path: Routes.visitorPass,
      builder: (context, state) => const VisitorPassScreen(),
    ),
    GoRoute(
      path: Routes.lostFound,
      builder: (context, state) => const LostFoundScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(child: Text('Route not found: ${state.uri}')),
  ),
);

/// Sends a freshly authenticated user to their role's landing page.
void goToRoleHome(BuildContext context, AppUser user) {
  switch (user.role) {
    case UserRole.student:
      context.go(Routes.student);
      break;
    case UserRole.teacher:
      context.go(Routes.faculty);
      break;
    case UserRole.registrar:
      context.go(Routes.registrar);
      break;
    case UserRole.cashier:
      context.go(Routes.cashier);
      break;
    case UserRole.admin:
      context.go(Routes.admin);
      break;
    case UserRole.accounting:
    case UserRole.guidance:
    case UserRole.deptHead:
    case UserRole.dean:
      context.go(Routes.roleDashboard, extra: user.role);
      break;
  }
}
