import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/error/result.dart';
import '../core/network/api_client.dart';
import '../data/local/hive_service.dart';
import '../models/academic_models.dart';
import '../models/advanced_models.dart';
import '../models/app_user.dart';
import '../models/attendance_models.dart';
import '../models/audit_log.dart';
import '../models/campus_models.dart';
import '../models/financial_models.dart';
import '../models/messaging_models.dart';
import 'notification_providers.dart';
import 'repository_providers.dart';

// ---------------------------------------------------------------------------
// Auth session
// ---------------------------------------------------------------------------

class AuthController extends AsyncNotifier<AppUser?> {
  static const _userKey = 'current_user';

  @override
  Future<AppUser?> build() async {
    // Restore a persisted session so users stay signed in across launches.
    // Wrapped in try/catch: a corrupt or unreadable Hive box must never
    // crash app startup — we fall back to a logged-out state instead.
    try {
      final stored = HiveService.session.get(_userKey) as Map?;
      if (stored == null) return null;
      return AppUser.fromJson(Map<String, dynamic>.from(stored));
    } catch (_) {
      await HiveService.session.delete(_userKey);
      return null;
    }
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
    final user = result.valueOrNull;
    if (user != null) {
      try {
        HiveService.session.put(_userKey, user.toJson());
      } catch (_) {
        // Non-fatal: the in-memory session still works for this launch.
      }
      // Register this device's FCM token so the backend can target pushes
      // to the signed-in user. Best-effort: a failure here (e.g. FCM not
      // initialized in mock mode) must not block login.
      ref.read(registerFcmTokenProvider(user.id).future).ignore();
      // Subscribe to role-relevant broadcast topics (announcements, etc.).
      for (final topic in NotificationTopics.forRole(user.role)) {
        ref.read(subscribeToTopicProvider(topic).future).ignore();
      }
    }
    state = AsyncValue.data(user);
    return result;
  }

  void logout() {
    try {
      HiveService.session.delete(_userKey);
    } catch (_) {
      // Non-fatal.
    }
    // Drop FCM tokens so we stop receiving pushes for this device/user.
    ref.read(unregisterFcmTokenProvider.future).ignore();
    ApiClient.clearToken();
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
  static const _prefKey = 'theme_mode';

  @override
  ThemeMode build() {
    final stored = HiveService.settings.get(_prefKey) as String?;
    return switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  void _persist(ThemeMode mode) =>
      HiveService.settings.put(_prefKey, mode.name);

  void toggle() {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = next;
    _persist(next);
  }

  void set(ThemeMode mode) {
    state = mode;
    _persist(mode);
  }
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

// ---------------------------------------------------------------------------
// Messaging
// ---------------------------------------------------------------------------

final conversationsProvider = StreamProvider.family<List<Conversation>, String>(
  (ref, userId) => ref.watch(messageRepositoryProvider).watchConversations(userId),
);

final messagesProvider = StreamProvider.family<List<Message>, String>(
  (ref, conversationId) => ref.watch(messageRepositoryProvider).watchMessages(conversationId),
);

final potentialChatPartnersProvider = FutureProvider.family<List<AppUser>, String>(
  (ref, userId) => ref.watch(messageRepositoryProvider).getPotentialChatPartners(userId),
);

// ---------------------------------------------------------------------------
// Calendar
// ---------------------------------------------------------------------------

final calendarEventsProvider = FutureProvider.family<List<CalendarEvent>, ({
  DateTime? from,
  DateTime? to,
})>((ref, params) => ref.watch(calendarRepositoryProvider).getEvents(from: params.from, to: params.to));

final calendarEventsStreamProvider = StreamProvider.family<List<CalendarEvent>, ({
  DateTime? from,
  DateTime? to,
})>((ref, params) => ref.watch(calendarRepositoryProvider).watchEvents(from: params.from, to: params.to));

// ---------------------------------------------------------------------------
// Attendance
// ---------------------------------------------------------------------------

final activeAttendanceSessionProvider = StreamProvider.family<AttendanceSession?, String>(
  (ref, sectionId) => ref.watch(attendanceRepositoryProvider).watchActiveSession(sectionId),
);

final studentAttendanceProvider = FutureProvider.family<List<AttendanceRecord>, ({
  String studentId,
  String? sectionId,
  DateTime? from,
  DateTime? to,
})>((ref, params) => ref.watch(attendanceRepositoryProvider).getStudentAttendance(
      params.studentId,
      sectionId: params.sectionId,
      from: params.from,
      to: params.to,
    ));

final sectionAttendanceSummaryProvider = FutureProvider.family<List<AttendanceSummary>, String>(
  (ref, sectionId) => ref.watch(attendanceRepositoryProvider).getSectionAttendanceSummary(sectionId),
);

final atRiskStudentsProvider = FutureProvider.family<List<AppUser>, ({
  String sectionId,
  double threshold,
})>((ref, params) => ref.watch(attendanceRepositoryProvider).getAtRiskStudents(
      params.sectionId,
      threshold: params.threshold,
    ));
