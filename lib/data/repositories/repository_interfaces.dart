import '../../core/error/result.dart';
import '../../models/academic_models.dart';
import '../../models/advanced_models.dart';
import '../../models/app_user.dart';
import '../../models/audit_log.dart';
import '../../models/campus_models.dart';
import '../../models/financial_models.dart';

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
