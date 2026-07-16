import '../../core/error/result.dart';
import '../../models/app_user.dart';
import '../../models/academic_models.dart';
import '../../models/financial_models.dart';
import '../../models/campus_models.dart';
import '../../models/audit_log.dart';

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
}

abstract class AdminRepository {
  Future<List<AppUser>> getAllUsers();
  Future<Result<bool>> addUser(AppUser user);
  Future<Result<bool>> setUserActive(String userId, bool active);
  Future<List<AuditLogEntry>> getAuditLog();
  Future<Map<String, num>> getAnalyticsSummary();
  Future<Map<String, int>> getEnrollmentTrend();
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
