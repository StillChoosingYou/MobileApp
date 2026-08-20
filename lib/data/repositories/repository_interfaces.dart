import '../../core/error/result.dart';
import '../../models/academic_models.dart';
import '../../models/advanced_models.dart';
import '../../models/app_user.dart';
import '../../models/attendance_models.dart';
import '../../models/audit_log.dart';
import '../../models/campus_models.dart';
import '../../models/financial_models.dart';
import '../../models/messaging_models.dart';

abstract class AuthRepository {
  Future<Result<AppUser>> login({
    required UserRole role,
    required String loginId,
    required String password,
  });

  Future<Result<bool>> requestPasswordReset(String emailOrLoginId);

  /// Returns true if this device already has a biometric-enrolled session
  /// for [loginId] (mock: always false until [enableBiometric] is called).
  Future<bool> isBiometricEnabled(String loginId);

  Future<Result<bool>> enableBiometric(String loginId);
}

abstract class StudentRepository {
  Future<StudentProfile?> getStudentProfile(String studentId);
  Future<List<Section>> getEnrolledSections(String studentId, String term);
  Future<List<Grade>> getGrades(String studentId);
  Future<TuitionLedger> getLedger(String studentId, String term);
  Future<List<Payment>> getPaymentHistory(String studentId);
  Future<Enrollment?> getEnrollment(String studentId, String term);
  Future<List<Announcement>> getAnnouncements();
  Future<List<NotificationItem>> getNotifications(String studentId);

  /// Simple keyword-matched FAQ engine backing the AI Assistant screen.
  /// Swap for a real LLM call (e.g. the Claude API) when ready — see
  /// ARCHITECTURE notes in the README.
  Future<String> askAssistant(String studentId, String question);

  /// Rule-based elective suggestions: subjects the student hasn't taken
  /// whose prerequisites they've already passed.
  Future<List<Subject>> recommendElectives(String studentId);

  /// Degree audit — all subjects in the student's curriculum with status.
  Future<CurriculumChecklist> getCurriculumChecklist(String studentId);

  /// Academic calendar events.
  Future<List<CalendarEvent>> getCalendarEvents();

  /// Submit a faculty evaluation for a section.
  Future<Result<bool>> submitFacultyEvaluation(FacultyEvaluation evaluation);

  /// Mark a notification as read.
  Future<void> markNotificationRead(String studentId, String notificationId);
}

abstract class RegistrarRepository {
  Future<List<AppUser>> searchStudents(String query);
  Future<StudentProfile?> getStudentProfile(String studentId);
  Future<List<Grade>> getGrades(String studentId);
  Future<List<Enrollment>> getPendingEnrollments();
  Future<Result<bool>> approveEnrollment(String enrollmentId);
  Future<Result<bool>> rejectEnrollment(String enrollmentId, String reason);
  Future<List<Subject>> getSubjects();
  Future<List<Section>> getSections();

  /// Returns a human-readable conflict description, or null if the proposed
  /// section list is conflict-free and within the unit cap.
  String? checkEnrollmentConflicts(List<Section> proposedSections, {double maxUnits = 24});

  /// Subject CRUD
  Future<Result<bool>> addSubject(Subject subject);
  Future<Result<bool>> updateSubject(Subject subject);
  Future<Result<bool>> deleteSubject(String code);

  /// Section CRUD
  Future<Result<bool>> addSection(Section section);
  Future<Result<bool>> updateSection(Section section);

  /// Enrollment stats by program.
  Future<Map<String, int>> getEnrollmentStatsByProgram();

  /// Student population by year level.
  Future<Map<int, int>> getStudentPopulationByYear();
}

abstract class CashierRepository {
  Future<Result<Payment>> recordPayment({
    required String studentId,
    required String studentName,
    required double amount,
    required PaymentMethod method,
    required String recordedBy,
  });

  Future<List<Payment>> getTransactionHistory({DateTime? onDate});
  Future<double> getDailyCollectionTotal(DateTime date);
  Future<Result<bool>> refundPayment(String paymentId, String reason);

  /// Collection breakdown by payment method.
  Future<Map<String, double>> getCollectionByMethod();

  /// Daily collection totals for the past N days.
  Future<Map<String, double>> getCollectionTrend({int days = 7});

  /// Outstanding balance summary across all students.
  Future<double> getTotalOutstandingBalance();
}

abstract class FacultyRepository {
  Future<List<Section>> getSectionsTaught(String facultyName);
  Future<List<AppUser>> getRoster(String sectionId);
  Future<List<AttendanceRecord>> getAttendanceForSession(String sectionId, DateTime date);
  Future<Result<bool>> submitAttendance(List<AttendanceRecord> records);
  Future<Result<bool>> encodeGrade({
    required String studentId,
    required String sectionId,
    required double numericGrade,
  });

  /// Faculty-generated rotating QR payload for a class session — students
  /// scan this to mark themselves present.
  String generateSessionQrPayload(String sectionId);

  /// Attendance summary per student for a section.
  Future<List<AttendanceSummary>> getAttendanceSummary(String sectionId);

  /// Grade distribution for a section.
  Future<GradeDistribution> getGradeDistribution(String sectionId);

  /// Students with attendance below threshold or failing grades.
  Future<List<AppUser>> getAtRiskStudents(String sectionId);
}

abstract class AdminRepository {
  Future<List<AppUser>> getAllUsers();
  Future<Result<bool>> addUser(AppUser user);
  Future<Result<bool>> setUserActive(String userId, bool active);
  Future<List<AuditLogEntry>> getAuditLog();
  Future<Map<String, num>> getAnalyticsSummary();
  Future<Map<String, int>> getEnrollmentTrend();

  /// Revenue trend over months.
  Future<Map<String, double>> getRevenueTrend();

  /// User count by role.
  Future<Map<String, int>> getRoleDistribution();

  /// Create/edit an announcement.
  Future<Result<bool>> createAnnouncement(Announcement announcement);
  Future<Result<bool>> deleteAnnouncement(String id);
}

abstract class CampusServicesRepository {
  Future<List<DocumentRequest>> getDocumentRequests(String studentId);
  Future<Result<DocumentRequest>> submitDocumentRequest(
    String studentId,
    DocumentType type,
    String purpose,
  );

  Future<Clearance> getClearance(String studentId, String term);

  Future<QueueTicket> issueQueueTicket(String studentId, String studentName, QueueOffice office);
  Stream<List<QueueTicket>> watchQueue(QueueOffice office);
  Future<Result<bool>> callNextInQueue(QueueOffice office);

  Future<List<Appointment>> getAppointments(String studentId);
  Future<List<Appointment>> getAppointmentsForOffice(AppointmentOffice office);
  Future<Result<Appointment>> bookAppointment(
    String studentId,
    AppointmentOffice office,
    String purpose,
    DateTime when,
  );

  Future<List<VisitorLog>> getVisitorLogs();
  Future<Result<VisitorLog>> checkInVisitor(String name, String purpose, String host);
  Future<Result<bool>> checkOutVisitor(String id);

  Future<List<LostFoundItem>> getLostFoundItems();
  Future<Result<LostFoundItem>> reportLostFoundItem(LostFoundItem item);
  Future<Result<bool>> markItemClaimed(String itemId);
}

// ---------------------------------------------------------------------------
// New role-specific repositories
// ---------------------------------------------------------------------------

abstract class AccountingRepository {
  Future<List<ScholarshipProgram>> getScholarships();
  Future<List<ScholarshipApplication>> getScholarshipApplications();
  Future<Result<bool>> updateScholarshipStatus(String applicationId, ScholarshipStatus status);

  Future<List<InstallmentPlan>> getInstallmentPlans();
  Future<InstallmentPlan?> getStudentInstallmentPlan(String studentId);
  Future<Result<bool>> createInstallmentPlan(InstallmentPlan plan);

  Future<FinancialReport> getFinancialReport(String period);
  Future<Map<String, double>> getLabFeesByDepartment();
}

abstract class GuidanceRepository {
  Future<List<CounselingRecord>> getCounselingRecords({String? studentId});
  Future<Result<CounselingRecord>> addCounselingRecord(CounselingRecord record);
  Future<Result<bool>> resolveCounselingRecord(String recordId);

  /// Sign off a student's clearance for a given office.
  Future<Result<bool>> signClearance(String studentId, String term, String office);
  Future<List<Clearance>> getPendingClearances(String term);
}

abstract class DeptHeadRepository {
  Future<List<AppUser>> getDepartmentFaculty(String department);
  Future<DepartmentPerformance> getDepartmentPerformance(String department);
  Future<List<CurriculumItem>> getCurriculumReview(String department);
}

abstract class DeanRepository {
  Future<Map<String, num>> getCollegeOverview();
  Future<List<GraduationEvaluation>> getGraduationEvaluations(String term);
  Future<GraduationEvaluation> evaluateGraduation(String studentId);
}

// ---------------------------------------------------------------------------
// Notification Repository
// ---------------------------------------------------------------------------

abstract class NotificationRepository {
  /// Save an FCM token for a user (multi-device support).
  Future<void> saveFcmToken(String userId, String token);

  /// Delete a specific FCM token for a user.
  Future<void> deleteFcmToken(String userId, String token);

  /// Delete all FCM tokens for a user (on logout).
  Future<void> deleteAllFcmTokens(String userId);

  /// Get all FCM tokens for a user.
  Future<List<String>> getUserTokens(String userId);

  /// Send a push notification to multiple tokens.
  /// Returns success status.
  Future<Result<bool>> sendPushNotification({
    required List<String> tokens,
    required String title,
    required String body,
    Map<String, String>? data,
  });

  /// Subscribe user to a topic (e.g., "announcements", "grade_updates").
  Future<void> subscribeToTopic(String userId, String topic);

  /// Unsubscribe user from a topic.
  Future<void> unsubscribeFromTopic(String userId, String topic);
}

// ---------------------------------------------------------------------------
// Messaging Repository
// ---------------------------------------------------------------------------

abstract class MessageRepository {
  /// Watch conversations for a user (real-time stream).
  Stream<List<Conversation>> watchConversations(String userId);

  /// Watch messages in a conversation (real-time stream).
  Stream<List<Message>> watchMessages(String conversationId);

  /// Get or create a 1:1 or group conversation.
  Future<Result<Conversation>> getOrCreateConversation(
    List<String> participantIds, {
    String? groupName,
    String? groupAvatarUrl,
  });

  /// Send a message in a conversation.
  Future<Result<Message>> sendMessage(
    String conversationId,
    String senderId,
    String content, {
    MessageType type = MessageType.text,
    Map<String, String>? metadata,
  });

  /// Mark messages as read for a user in a conversation.
  Future<void> markAsRead(String conversationId, String userId);

  /// Create a group chat.
  Future<Result<bool>> createGroupChat(
    String creatorId,
    List<String> participantIds,
    String groupName, {
    String? groupAvatarUrl,
  });

  /// Get potential chat partners (classmates, faculty in same sections).
  Future<List<AppUser>> getPotentialChatPartners(String userId);

  /// Delete a conversation (for current user only).
  Future<Result<bool>> deleteConversation(String conversationId, String userId);
}

// ---------------------------------------------------------------------------
// Calendar Repository
// ---------------------------------------------------------------------------

abstract class CalendarRepository {
  /// Get events within a date range.
  Future<List<CalendarEvent>> getEvents({DateTime? from, DateTime? to});

  /// Watch events (real-time stream).
  Stream<List<CalendarEvent>> watchEvents({DateTime? from, DateTime? to});

  /// Create a new event (admin/registrar/faculty).
  Future<Result<CalendarEvent>> createEvent(CalendarEvent event);

  /// Update an existing event.
  Future<Result<CalendarEvent>> updateEvent(CalendarEvent event);

  /// Delete an event.
  Future<Result<bool>> deleteEvent(String eventId);

  /// Add a reminder for a user for an event.
  Future<Result<bool>> addReminder(String eventId, String userId, Duration before);

  /// Remove a reminder.
  Future<Result<bool>> removeReminder(String eventId, String userId);

  /// Get user's reminders for an event.
  Future<List<Duration>> getUserReminders(String eventId, String userId);
}

// ---------------------------------------------------------------------------
// Attendance Repository
// ---------------------------------------------------------------------------

abstract class AttendanceRepository {
  // Faculty methods
  /// Start an attendance session for a section (generates rotating QR).
  Future<Result<AttendanceSession>> startSession(
    String sectionId, {
    Duration duration = const Duration(minutes: 15),
    int rotationIntervalSeconds = 30,
  });

  /// End an active attendance session.
  Future<Result<bool>> endSession(String sectionId);

  /// Get the active session for a section.
  Future<AttendanceSession?> getActiveSession(String sectionId);

  /// Watch active session (real-time, includes rotating QR).
  Stream<AttendanceSession?> watchActiveSession(String sectionId);

  /// Get attendance records for a session.
  Future<List<AttendanceRecord>> getSessionRecords(String sessionId);

  // Student methods
  /// Submit attendance by scanning QR payload.
  Future<Result<AttendanceRecord>> submitAttendance(
    String studentId,
    String qrPayload,
  );

  /// Get student's attendance history.
  Future<List<AttendanceRecord>> getStudentAttendance(
    String studentId, {
    String? sectionId,
    DateTime? from,
    DateTime? to,
  });

  // Analytics (Faculty/Admin)
  /// Get attendance summary per student for a section.
  Future<List<AttendanceSummary>> getSectionAttendanceSummary(String sectionId);

  /// Get students at risk (attendance below threshold).
  Future<List<AppUser>> getAtRiskStudents(
    String sectionId, {
    double threshold = 0.75,
  });
}
