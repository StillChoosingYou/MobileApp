import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/error/result.dart';
import '../models/app_user.dart';
import '../models/academic_models.dart';
import '../models/audit_log.dart';
import '../models/campus_models.dart';
import '../models/financial_models.dart';
import 'repository_providers.dart';

// ---------------------------------------------------------------------------
// Auth session
// ---------------------------------------------------------------------------

class AuthController extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async {
    // No persisted-session restore in this scaffold — every launch starts
    // at Role Select. Wire this to HiveService.session / FirebaseAuth's
    // authStateChanges() if you want auto-login.
    return null;
  }

  Future<Result<AppUser>> login({
    required UserRole role,
    required String loginId,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    final result = await ref.read(authRepositoryProvider).login(
          role: role,
          loginId: loginId,
          password: password,
        );
    state = AsyncValue.data(result.valueOrNull);
    return result;
  }

  void logout() {
    state = const AsyncValue.data(null);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AppUser?>(
  AuthController.new,
);

// ---------------------------------------------------------------------------
// Theme
// ---------------------------------------------------------------------------

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void toggle() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  void set(ThemeMode mode) => state = mode;
}

final themeModeControllerProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

// ---------------------------------------------------------------------------
// Student
// ---------------------------------------------------------------------------

final studentProfileProvider = FutureProvider.family<StudentProfile?, String>(
  (ref, studentId) => ref.watch(studentRepositoryProvider).getStudentProfile(studentId),
);

final studentSectionsProvider = FutureProvider.family<List<Section>, String>(
  (ref, studentId) => ref
      .watch(studentRepositoryProvider)
      .getEnrolledSections(studentId, AppConfig.currentTermLabel),
);

final studentGradesProvider = FutureProvider.family<List<Grade>, String>(
  (ref, studentId) => ref.watch(studentRepositoryProvider).getGrades(studentId),
);

final studentLedgerProvider = FutureProvider.family<TuitionLedger, String>(
  (ref, studentId) =>
      ref.watch(studentRepositoryProvider).getLedger(studentId, AppConfig.currentTermLabel),
);

final studentPaymentHistoryProvider = FutureProvider.family<List<Payment>, String>(
  (ref, studentId) => ref.watch(studentRepositoryProvider).getPaymentHistory(studentId),
);

final studentEnrollmentProvider = FutureProvider.family<Enrollment?, String>(
  (ref, studentId) =>
      ref.watch(studentRepositoryProvider).getEnrollment(studentId, AppConfig.currentTermLabel),
);

final announcementsProvider = FutureProvider<List<Announcement>>(
  (ref) => ref.watch(studentRepositoryProvider).getAnnouncements(),
);

final studentNotificationsProvider = FutureProvider.family<List<NotificationItem>, String>(
  (ref, studentId) => ref.watch(studentRepositoryProvider).getNotifications(studentId),
);

final electiveRecommendationsProvider = FutureProvider.family<List<Subject>, String>(
  (ref, studentId) => ref.watch(studentRepositoryProvider).recommendElectives(studentId),
);

// ---------------------------------------------------------------------------
// Registrar
// ---------------------------------------------------------------------------

final studentSearchProvider = FutureProvider.family<List<AppUser>, String>(
  (ref, query) => ref.watch(registrarRepositoryProvider).searchStudents(query),
);

final pendingEnrollmentsProvider = FutureProvider<List<Enrollment>>(
  (ref) => ref.watch(registrarRepositoryProvider).getPendingEnrollments(),
);

final allSubjectsProvider = FutureProvider<List<Subject>>(
  (ref) => ref.watch(registrarRepositoryProvider).getSubjects(),
);

final allSectionsProvider = FutureProvider<List<Section>>(
  (ref) => ref.watch(registrarRepositoryProvider).getSections(),
);

// ---------------------------------------------------------------------------
// Cashier
// ---------------------------------------------------------------------------

final transactionHistoryProvider = FutureProvider<List<Payment>>(
  (ref) => ref.watch(cashierRepositoryProvider).getTransactionHistory(),
);

final dailyCollectionTotalProvider = FutureProvider<double>(
  (ref) => ref.watch(cashierRepositoryProvider).getDailyCollectionTotal(DateTime.now()),
);

// ---------------------------------------------------------------------------
// Faculty
// ---------------------------------------------------------------------------

final facultySectionsProvider = FutureProvider.family<List<Section>, String>(
  (ref, facultyName) => ref.watch(facultyRepositoryProvider).getSectionsTaught(facultyName),
);

final sectionRosterProvider = FutureProvider.family<List<AppUser>, String>(
  (ref, sectionId) => ref.watch(facultyRepositoryProvider).getRoster(sectionId),
);

// ---------------------------------------------------------------------------
// Admin
// ---------------------------------------------------------------------------

final allUsersProvider = FutureProvider<List<AppUser>>(
  (ref) => ref.watch(adminRepositoryProvider).getAllUsers(),
);

final auditLogProvider = FutureProvider<List<AuditLogEntry>>(
  (ref) => ref.watch(adminRepositoryProvider).getAuditLog(),
);

final analyticsSummaryProvider = FutureProvider<Map<String, num>>(
  (ref) => ref.watch(adminRepositoryProvider).getAnalyticsSummary(),
);

final enrollmentTrendProvider = FutureProvider<Map<String, int>>(
  (ref) => ref.watch(adminRepositoryProvider).getEnrollmentTrend(),
);

// ---------------------------------------------------------------------------
// Campus services: documents, clearance, queue, appointments, visitors, L&F
// ---------------------------------------------------------------------------

final documentRequestsProvider = FutureProvider.family<List<DocumentRequest>, String>(
  (ref, studentId) => ref.watch(campusServicesRepositoryProvider).getDocumentRequests(studentId),
);

final clearanceProvider = FutureProvider.family<Clearance, String>(
  (ref, studentId) => ref
      .watch(campusServicesRepositoryProvider)
      .getClearance(studentId, AppConfig.currentTermLabel),
);

final queueStreamProvider = StreamProvider.family<List<QueueTicket>, QueueOffice>(
  (ref, office) => ref.watch(campusServicesRepositoryProvider).watchQueue(office),
);

final appointmentsProvider = FutureProvider.family<List<Appointment>, String>(
  (ref, studentId) => ref.watch(campusServicesRepositoryProvider).getAppointments(studentId),
);

final officeAppointmentsProvider = FutureProvider.family<List<Appointment>, AppointmentOffice>(
  (ref, office) => ref.watch(campusServicesRepositoryProvider).getAppointmentsForOffice(office),
);

final visitorLogsProvider = FutureProvider<List<VisitorLog>>(
  (ref) => ref.watch(campusServicesRepositoryProvider).getVisitorLogs(),
);

final lostFoundItemsProvider = FutureProvider<List<LostFoundItem>>(
  (ref) => ref.watch(campusServicesRepositoryProvider).getLostFoundItems(),
);
