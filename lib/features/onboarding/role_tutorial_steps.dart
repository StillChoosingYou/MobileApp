import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import 'coach_mark_overlay.dart';

/// Global keys for coach mark targeting — attach these to widgets in role shells.
///
/// Example usage in a role shell:
/// ```dart
/// CoachMarkTarget(
///   key: RoleTutorialKeys.studentHomeTabKey,
///   child: NavigationBar(...),
/// )
/// ```
class RoleTutorialKeys {
  RoleTutorialKeys._();

  // Student keys
  static final GlobalKey studentHomeTabKey = GlobalKey();
  static final GlobalKey studentGradesTabKey = GlobalKey();
  static final GlobalKey studentScheduleTabKey = GlobalKey();
  static final GlobalKey studentTuitionTabKey = GlobalKey();
  static final GlobalKey studentServicesTabKey = GlobalKey();
  static final GlobalKey studentDigitalIdKey = GlobalKey();

  // Teacher keys
  static final GlobalKey teacherClassesTabKey = GlobalKey();
  static final GlobalKey teacherAttendanceTabKey = GlobalKey();
  static final GlobalKey teacherGradesTabKey = GlobalKey();
  static final GlobalKey teacherScheduleTabKey = GlobalKey();

  // Registrar keys
  static final GlobalKey registrarEnrollmentTabKey = GlobalKey();
  static final GlobalKey registrarRecordsTabKey = GlobalKey();
  static final GlobalKey registrarReportsTabKey = GlobalKey();

  // Accounting keys
  static final GlobalKey accountingLedgerTabKey = GlobalKey();
  static final GlobalKey accountingReportsTabKey = GlobalKey();
  static final GlobalKey accountingReconciliationTabKey = GlobalKey();

  // Cashier keys
  static final GlobalKey cashierPaymentEntryKey = GlobalKey();
  static final GlobalKey cashierReceiptsTabKey = GlobalKey();
  static final GlobalKey cashierSummaryTabKey = GlobalKey();

  // Guidance keys
  static final GlobalKey guidanceAppointmentsTabKey = GlobalKey();
  static final GlobalKey guidanceClearanceTabKey = GlobalKey();
  static final GlobalKey guidanceCasesTabKey = GlobalKey();

  // Dept Head keys
  static final GlobalKey deptHeadFacultyLoadKey = GlobalKey();
  static final GlobalKey deptHeadReportsKey = GlobalKey();
  static final GlobalKey deptHeadApprovalsKey = GlobalKey();

  // Dean keys
  static final GlobalKey deanOverviewKey = GlobalKey();
  static final GlobalKey deanProgramsKey = GlobalKey();
  static final GlobalKey deanFacultyKey = GlobalKey();

  // Admin keys
  static final GlobalKey adminUsersKey = GlobalKey();
  static final GlobalKey adminSettingsKey = GlobalKey();
  static final GlobalKey adminAuditKey = GlobalKey();
  static final GlobalKey adminHealthKey = GlobalKey();
}

/// Centralized definition of role-specific guided tour steps.
///
/// Each role gets a list of [CoachMarkStep]s that highlight key UI elements
/// on their main dashboard/shell. Target keys must be attached to widgets
/// via [CoachMarkTarget] in the respective role shell/screen.
class RoleTutorialSteps {
  RoleTutorialSteps._();

  /// Returns the tutorial steps for a given role.
  static List<CoachMarkStep> getStepsForRole(UserRole role) {
    switch (role) {
      case UserRole.student:
        return _studentSteps;
      case UserRole.teacher:
        return _teacherSteps;
      case UserRole.registrar:
        return _registrarSteps;
      case UserRole.accounting:
        return _accountingSteps;
      case UserRole.cashier:
        return _cashierSteps;
      case UserRole.guidance:
        return _guidanceSteps;
      case UserRole.deptHead:
        return _deptHeadSteps;
      case UserRole.dean:
        return _deanSteps;
      case UserRole.admin:
        return _adminSteps;
    }
  }

  /// Student: Home, Grades, Schedule, Tuition, Services tabs + Digital ID
  static final List<CoachMarkStep> _studentSteps = [
    CoachMarkStep(
      targetKey: RoleTutorialKeys.studentHomeTabKey,
      title: 'Home Dashboard',
      description: 'Your overview — quick stats, upcoming deadlines, and announcements.',
      shape: CoachMarkShape.roundedRect,
      alignment: Alignment.bottomCenter,
    ),
    CoachMarkStep(
      targetKey: RoleTutorialKeys.studentGradesTabKey,
      title: 'Grades',
      description: 'View all your grades by term. Tap a course for detailed breakdown.',
      shape: CoachMarkShape.roundedRect,
      alignment: Alignment.bottomCenter,
    ),
    CoachMarkStep(
      targetKey: RoleTutorialKeys.studentScheduleTabKey,
      title: 'Class Schedule',
      description: 'Weekly timetable with room, instructor, and time. Swipe to change weeks.',
      shape: CoachMarkShape.roundedRect,
      alignment: Alignment.bottomCenter,
    ),
    CoachMarkStep(
      targetKey: RoleTutorialKeys.studentTuitionTabKey,
      title: 'Tuition & Payments',
      description: 'Check balance, view payment history, and pay online via GCash or bank.',
      shape: CoachMarkShape.roundedRect,
      alignment: Alignment.bottomCenter,
    ),
    CoachMarkStep(
      targetKey: RoleTutorialKeys.studentServicesTabKey,
      title: 'Student Services',
      description: 'Request documents, view clearance status, and book guidance appointments.',
      shape: CoachMarkShape.roundedRect,
      alignment: Alignment.bottomCenter,
    ),
    CoachMarkStep(
      targetKey: RoleTutorialKeys.studentDigitalIdKey,
      title: 'Digital Campus ID',
      description: 'Your QR-based ID for gate entry, library, and events. Works offline!',
      alignment: Alignment.topCenter,
    ),
  ];

  /// Teacher/Faculty: Classes, Attendance, Grades, Schedule tabs
  static final List<CoachMarkStep> _teacherSteps = [
    CoachMarkStep(
      targetKey: RoleTutorialKeys.teacherClassesTabKey,
      title: 'My Classes',
      description: 'All your assigned sections. Tap to manage attendance and grades.',
      shape: CoachMarkShape.roundedRect,
      alignment: Alignment.bottomCenter,
    ),
    CoachMarkStep(
      targetKey: RoleTutorialKeys.teacherAttendanceTabKey,
      title: 'Attendance',
      description: 'Mark attendance with one tap. Supports late/excused/absent statuses.',
      shape: CoachMarkShape.roundedRect,
      alignment: Alignment.bottomCenter,
    ),
    CoachMarkStep(
      targetKey: RoleTutorialKeys.teacherGradesTabKey,
      title: 'Grade Encoding',
      description: 'Enter and publish grades. Auto-saves drafts — no lost work.',
      shape: CoachMarkShape.roundedRect,
      alignment: Alignment.bottomCenter,
    ),
    CoachMarkStep(
      targetKey: RoleTutorialKeys.teacherScheduleTabKey,
      title: 'Teaching Schedule',
      description: 'Your weekly teaching load with rooms and sections.',
      shape: CoachMarkShape.roundedRect,
      alignment: Alignment.bottomCenter,
    ),
  ];

  /// Registrar: Enrollment Approval, Student Records, Reports tabs
  static final List<CoachMarkStep> _registrarSteps = [
    CoachMarkStep(
      targetKey: RoleTutorialKeys.registrarEnrollmentTabKey,
      title: 'Enrollment Approval',
      description: 'Review and approve/deny student enrollment requests in bulk.',
      shape: CoachMarkShape.roundedRect,
      alignment: Alignment.bottomCenter,
    ),
    CoachMarkStep(
      targetKey: RoleTutorialKeys.registrarRecordsTabKey,
      title: 'Student Records',
      description: 'Search, filter, and export student records. Advanced filters available.',
      shape: CoachMarkShape.roundedRect,
      alignment: Alignment.bottomCenter,
    ),
    CoachMarkStep(
      targetKey: RoleTutorialKeys.registrarReportsTabKey,
      title: 'Reports & Analytics',
      description: 'Generate enrollment stats, demographic reports, and compliance docs.',
      shape: CoachMarkShape.roundedRect,
      alignment: Alignment.bottomCenter,
    ),
  ];

  /// Accounting: Ledger, Reports, Reconciliation tabs
  static final List<CoachMarkStep> _accountingSteps = [
    CoachMarkStep(
      targetKey: RoleTutorialKeys.accountingLedgerTabKey,
      title: 'General Ledger',
      description: 'View all transactions. Filter by date, type, account, or department.',
      shape: CoachMarkShape.roundedRect,
      alignment: Alignment.bottomCenter,
    ),
    CoachMarkStep(
      targetKey: RoleTutorialKeys.accountingReportsTabKey,
      title: 'Financial Reports',
      description: 'Trial balance, income statement, cash flow — export to PDF/Excel.',
      shape: CoachMarkShape.roundedRect,
      alignment: Alignment.bottomCenter,
    ),
    CoachMarkStep(
      targetKey: RoleTutorialKeys.accountingReconciliationTabKey,
      title: 'Bank Reconciliation',
      description: 'Match bank statements to ledger entries. Auto-match suggestions.',
      shape: CoachMarkShape.roundedRect,
      alignment: Alignment.bottomCenter,
    ),
  ];

  /// Cashier: Payment Entry, Receipts, Daily Summary tabs
  static final List<CoachMarkStep> _cashierSteps = [
    CoachMarkStep(
      targetKey: RoleTutorialKeys.cashierPaymentEntryKey,
      title: 'Record Payment',
      description: 'Enter cash, GCash, or bank payments. Auto-generates official receipt.',
      shape: CoachMarkShape.roundedRect,
      alignment: Alignment.topCenter,
    ),
    CoachMarkStep(
      targetKey: RoleTutorialKeys.cashierReceiptsTabKey,
      title: 'Receipt History',
      description: 'Search and reprint any receipt. Filter by student, date, or amount.',
      shape: CoachMarkShape.roundedRect,
      alignment: Alignment.bottomCenter,
    ),
    CoachMarkStep(
      targetKey: RoleTutorialKeys.cashierSummaryTabKey,
      title: 'Daily Summary',
      description: 'End-of-day totals by payment method. Print or export for audit.',
      shape: CoachMarkShape.roundedRect,
      alignment: Alignment.bottomCenter,
    ),
  ];

  /// Guidance: Appointments, Clearance, Cases tabs
  static final List<CoachMarkStep> _guidanceSteps = [
    CoachMarkStep(
      targetKey: RoleTutorialKeys.guidanceAppointmentsTabKey,
      title: 'Counseling Appointments',
      description: 'View and manage student appointments. Send reminders via push.',
      shape: CoachMarkShape.roundedRect,
      alignment: Alignment.bottomCenter,
    ),
    CoachMarkStep(
      targetKey: RoleTutorialKeys.guidanceClearanceTabKey,
      title: 'Student Clearance',
      description: 'Track clearance progress. Approve or request additional requirements.',
      shape: CoachMarkShape.roundedRect,
      alignment: Alignment.bottomCenter,
    ),
    CoachMarkStep(
      targetKey: RoleTutorialKeys.guidanceCasesTabKey,
      title: 'Case Management',
      description: 'Log and track counseling cases. Confidential — role-restricted access.',
      shape: CoachMarkShape.roundedRect,
      alignment: Alignment.bottomCenter,
    ),
  ];

  /// Dept Head: Faculty Load, Department Reports, Approvals tabs
  static final List<CoachMarkStep> _deptHeadSteps = [
    CoachMarkStep(
      targetKey: RoleTutorialKeys.deptHeadFacultyLoadKey,
      title: 'Faculty Teaching Load',
      description: 'Monitor faculty assignments. Ensure equitable distribution.',
      shape: CoachMarkShape.roundedRect,
      alignment: Alignment.bottomCenter,
    ),
    CoachMarkStep(
      targetKey: RoleTutorialKeys.deptHeadReportsKey,
      title: 'Department Reports',
      description: 'Enrollment trends, grade distributions, faculty performance metrics.',
      shape: CoachMarkShape.roundedRect,
      alignment: Alignment.bottomCenter,
    ),
    CoachMarkStep(
      targetKey: RoleTutorialKeys.deptHeadApprovalsKey,
      title: 'Approvals Queue',
      description: 'Review overload requests, schedule changes, and leave applications.',
      shape: CoachMarkShape.roundedRect,
      alignment: Alignment.bottomCenter,
    ),
  ];

  /// Dean: College Overview, Program Management, Faculty tabs
  static final List<CoachMarkStep> _deanSteps = [
    CoachMarkStep(
      targetKey: RoleTutorialKeys.deanOverviewKey,
      title: 'College Dashboard',
      description: 'High-level KPIs: enrollment, retention, graduation rates by program.',
      shape: CoachMarkShape.roundedRect,
      alignment: Alignment.bottomCenter,
    ),
    CoachMarkStep(
      targetKey: RoleTutorialKeys.deanProgramsKey,
      title: 'Program Management',
      description: 'Curriculum mapping, course offerings, and accreditation tracking.',
      shape: CoachMarkShape.roundedRect,
      alignment: Alignment.bottomCenter,
    ),
    CoachMarkStep(
      targetKey: RoleTutorialKeys.deanFacultyKey,
      title: 'Faculty Overview',
      description: 'Tenure status, research output, teaching evaluations summary.',
      shape: CoachMarkShape.roundedRect,
      alignment: Alignment.bottomCenter,
    ),
  ];

  /// Admin: Users, Settings, Audit Logs, System Health tabs
  static final List<CoachMarkStep> _adminSteps = [
    CoachMarkStep(
      targetKey: RoleTutorialKeys.adminUsersKey,
      title: 'User Management',
      description: 'Create, edit, deactivate accounts. Assign roles and permissions.',
      shape: CoachMarkShape.roundedRect,
      alignment: Alignment.bottomCenter,
    ),
    CoachMarkStep(
      targetKey: RoleTutorialKeys.adminSettingsKey,
      title: 'System Settings',
      description: 'Configure terms, fees, notifications, and integrations (GCash, SMS).',
      shape: CoachMarkShape.roundedRect,
      alignment: Alignment.bottomCenter,
    ),
    CoachMarkStep(
      targetKey: RoleTutorialKeys.adminAuditKey,
      title: 'Audit Logs',
      description: 'Searchable trail of all sensitive actions. Filter by user, date, action.',
      shape: CoachMarkShape.roundedRect,
      alignment: Alignment.bottomCenter,
    ),
    CoachMarkStep(
      targetKey: RoleTutorialKeys.adminHealthKey,
      title: 'System Health',
      description: 'Monitor API latency, database performance, and error rates.',
      shape: CoachMarkShape.roundedRect,
      alignment: Alignment.bottomCenter,
    ),
  ];
}