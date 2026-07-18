import 'dart:async';

import '../../core/error/result.dart';
import '../../core/utils/assistant_rules.dart';
import '../../models/app_user.dart';
import '../../models/academic_models.dart';
import '../../models/financial_models.dart';
import '../../models/campus_models.dart';
import '../../models/audit_log.dart';
import 'mock_seed_data.dart';
import 'repository_interfaces.dart';

Future<void> _delay([int ms = 300]) => Future.delayed(Duration(milliseconds: ms));

class MockAuthRepository implements AuthRepository {
  final _seed = MockSeedData.instance;
  final Set<String> _biometricEnabled = {};

  @override
  Future<Result<AppUser>> login({
    required UserRole role,
    required String loginId,
    required String password,
  }) async {
    await _delay();
    if (password.trim().isEmpty) {
      return Result.error('Enter your password.');
    }
    final matches = _seed.users.where(
      (u) => u.role == role && u.loginId.toLowerCase() == loginId.trim().toLowerCase(),
    );
    if (matches.isEmpty) {
      return Result.error('No ${role.label} account found for that ID.');
    }
    return Result.ok(matches.first);
  }

  @override
  Future<Result<bool>> requestPasswordReset(String emailOrLoginId) async {
    await _delay();
    final exists = _seed.users.any(
      (u) => u.email == emailOrLoginId || u.loginId == emailOrLoginId,
    );
    if (!exists) return Result.error('We could not find an account with that email or ID.');
    return Result.ok(true);
  }

  @override
  Future<bool> isBiometricEnabled(String loginId) async => _biometricEnabled.contains(loginId);

  @override
  Future<Result<bool>> enableBiometric(String loginId) async {
    await _delay(150);
    _biometricEnabled.add(loginId);
    return Result.ok(true);
  }
}

class MockStudentRepository implements StudentRepository {
  final _seed = MockSeedData.instance;

  @override
  Future<StudentProfile?> getStudentProfile(String studentId) async {
    await _delay();
    for (final p in _seed.studentProfiles) {
      if (p.studentId == studentId) return p;
    }
    return null;
  }

  @override
  Future<List<Section>> getEnrolledSections(String studentId, String term) async {
    await _delay();
    final matching = _seed.enrollments.where((e) => e.studentId == studentId && e.term == term);
    if (matching.isEmpty) return [];
    final ids = matching.first.sectionIds;
    return _seed.sections.where((s) => ids.contains(s.id)).toList();
  }

  @override
  Future<List<Grade>> getGrades(String studentId) async {
    await _delay();
    return List<Grade>.from(_seed.grades);
  }

  @override
  Future<TuitionLedger> getLedger(String studentId, String term) async {
    await _delay();
    return _seed.ledgers[studentId] ??
        TuitionLedger(
          studentId: studentId,
          term: term,
          tuitionFee: 0,
          miscFees: 0,
          labFees: 0,
          scholarshipDiscount: 0,
          totalPaid: 0,
        );
  }

  @override
  Future<List<Payment>> getPaymentHistory(String studentId) async {
    await _delay();
    return _seed.payments.where((p) => p.studentId == studentId).toList();
  }

  @override
  Future<Enrollment?> getEnrollment(String studentId, String term) async {
    await _delay();
    for (final e in _seed.enrollments) {
      if (e.studentId == studentId && e.term == term) return e;
    }
    return null;
  }

  @override
  Future<List<Announcement>> getAnnouncements() async {
    await _delay();
    final list = List<Announcement>.from(_seed.announcements);
    list.sort((a, b) => b.postedAt.compareTo(a.postedAt));
    return list;
  }

  @override
  Future<List<NotificationItem>> getNotifications(String studentId) async {
    await _delay();
    final list = List<NotificationItem>.from(_seed.notifications[studentId] ?? const []);
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  @override
  Future<String> askAssistant(String studentId, String question) async {
    await _delay(500);
    final sections = await getEnrolledSections(studentId, MockSeedData.term);
    final ledger = await getLedger(studentId, MockSeedData.term);
    return AssistantRules.answerQuestion(
      question: question,
      term: MockSeedData.term,
      enrolledSections: sections,
      ledger: ledger,
    );
  }

  @override
  Future<List<Subject>> recommendElectives(String studentId) async {
    await _delay();
    return AssistantRules.recommendElectives(
      grades: _seed.grades,
      allSubjects: _seed.subjects,
    );
  }
}

class MockRegistrarRepository implements RegistrarRepository {
  final _seed = MockSeedData.instance;

  @override
  Future<List<AppUser>> searchStudents(String query) async {
    await _delay();
    final q = query.trim().toLowerCase();
    final students = _seed.users.where((u) => u.role == UserRole.student);
    if (q.isEmpty) return students.toList();
    return students
        .where((u) => u.name.toLowerCase().contains(q) || u.loginId.toLowerCase().contains(q))
        .toList();
  }

  @override
  Future<StudentProfile?> getStudentProfile(String studentId) async {
    await _delay();
    for (final p in _seed.studentProfiles) {
      if (p.studentId == studentId) return p;
    }
    return null;
  }

  @override
  Future<List<Grade>> getGrades(String studentId) async {
    await _delay();
    return List<Grade>.from(_seed.grades);
  }

  @override
  Future<List<Enrollment>> getPendingEnrollments() async {
    await _delay();
    return _seed.enrollments.where((e) => e.status == EnrollmentStatus.pending).toList();
  }

  @override
  Future<Result<bool>> approveEnrollment(String enrollmentId) async {
    await _delay();
    final idx = _seed.enrollments.indexWhere((e) => e.id == enrollmentId);
    if (idx == -1) return Result.error('Enrollment not found.');
    _seed.enrollments[idx] = _seed.enrollments[idx].copyWith(status: EnrollmentStatus.enrolled);
    _seed.auditLog.insert(
      0,
      AuditLogEntry(
        id: 'log_${DateTime.now().microsecondsSinceEpoch}',
        actor: 'Registrar',
        action: 'Approved enrollment',
        target: enrollmentId,
        timestamp: DateTime.now(),
      ),
    );
    return Result.ok(true);
  }

  @override
  Future<Result<bool>> rejectEnrollment(String enrollmentId, String reason) async {
    await _delay();
    final idx = _seed.enrollments.indexWhere((e) => e.id == enrollmentId);
    if (idx == -1) return Result.error('Enrollment not found.');
    _seed.enrollments[idx] =
        _seed.enrollments[idx].copyWith(status: EnrollmentStatus.rejected, remarks: reason);
    return Result.ok(true);
  }

  @override
  Future<List<Subject>> getSubjects() async {
    await _delay();
    return List<Subject>.from(_seed.subjects);
  }

  @override
  Future<List<Section>> getSections() async {
    await _delay();
    return List<Section>.from(_seed.sections);
  }

  @override
  String? checkEnrollmentConflicts(List<Section> proposedSections, {double maxUnits = 24}) {
    for (var i = 0; i < proposedSections.length; i++) {
      for (var j = i + 1; j < proposedSections.length; j++) {
        if (proposedSections[i].conflictsWith(proposedSections[j])) {
          return '${proposedSections[i].subjectCode} conflicts with '
              '${proposedSections[j].subjectCode} on schedule.';
        }
      }
    }
    var totalUnits = 0.0;
    for (final s in proposedSections) {
      final match = _seed.subjects.where((sub) => sub.code == s.subjectCode);
      if (match.isNotEmpty) totalUnits += match.first.units;
    }
    if (totalUnits > maxUnits) {
      return 'Total load of $totalUnits units exceeds the $maxUnits-unit cap.';
    }
    return null;
  }
}

class MockCashierRepository implements CashierRepository {
  final _seed = MockSeedData.instance;
  int _receiptCounter = 1045;

  @override
  Future<Result<Payment>> recordPayment({
    required String studentId,
    required String studentName,
    required double amount,
    required PaymentMethod method,
    required String recordedBy,
  }) async {
    await _delay();
    if (amount <= 0) return Result.error('Amount must be greater than zero.');

    final receiptNumber = 'OR-2026-${(_receiptCounter++).toString().padLeft(5, '0')}';
    final payment = Payment(
      id: 'pay_${DateTime.now().microsecondsSinceEpoch}',
      studentId: studentId,
      studentName: studentName,
      amount: amount,
      method: method,
      receiptNumber: receiptNumber,
      timestamp: DateTime.now(),
      recordedBy: recordedBy,
    );
    _seed.payments.insert(0, payment);

    final ledger = _seed.ledgers[studentId];
    if (ledger != null) {
      _seed.ledgers[studentId] = TuitionLedger(
        studentId: ledger.studentId,
        term: ledger.term,
        tuitionFee: ledger.tuitionFee,
        miscFees: ledger.miscFees,
        labFees: ledger.labFees,
        scholarshipDiscount: ledger.scholarshipDiscount,
        totalPaid: ledger.totalPaid + amount,
      );
    }

    _seed.auditLog.insert(
      0,
      AuditLogEntry(
        id: 'log_${DateTime.now().microsecondsSinceEpoch}',
        actor: recordedBy,
        action: 'Recorded payment',
        target: '$receiptNumber — ₱${amount.toStringAsFixed(2)} (${method.label})',
        timestamp: DateTime.now(),
      ),
    );

    return Result.ok(payment);
  }

  @override
  Future<List<Payment>> getTransactionHistory({DateTime? onDate}) async {
    await _delay();
    if (onDate == null) return List<Payment>.from(_seed.payments);
    return _seed.payments
        .where((p) =>
            p.timestamp.year == onDate.year &&
            p.timestamp.month == onDate.month &&
            p.timestamp.day == onDate.day)
        .toList();
  }

  @override
  Future<double> getDailyCollectionTotal(DateTime date) async {
    final txns = await getTransactionHistory(onDate: date);
    var total = 0.0;
    for (final p in txns) {
      total += p.amount;
    }
    return total;
  }

  @override
  Future<Result<bool>> refundPayment(String paymentId, String reason) async {
    await _delay();
    final idx = _seed.payments.indexWhere((p) => p.id == paymentId);
    if (idx == -1) return Result.error('Payment not found.');
    final old = _seed.payments[idx];
    _seed.payments[idx] = Payment(
      id: old.id,
      studentId: old.studentId,
      studentName: old.studentName,
      amount: old.amount,
      method: old.method,
      receiptNumber: old.receiptNumber,
      timestamp: old.timestamp,
      recordedBy: old.recordedBy,
      status: PaymentStatus.refunded,
      gatewayReference: old.gatewayReference,
    );
    return Result.ok(true);
  }
}

class MockFacultyRepository implements FacultyRepository {
  final _seed = MockSeedData.instance;

  @override
  Future<List<Section>> getSectionsTaught(String facultyName) async {
    await _delay();
    return _seed.sections.where((s) => s.facultyName == facultyName).toList();
  }

  @override
  Future<List<AppUser>> getRoster(String sectionId) async {
    await _delay();
    final studentIds = _seed.enrollments
        .where((e) => e.sectionIds.contains(sectionId))
        .map((e) => e.studentId)
        .toSet();
    if (studentIds.isEmpty) {
      // Demo fallback so the screen has something to show even before any
      // enrollment references this exact section id.
      return _seed.users.where((u) => u.role == UserRole.student).toList();
    }
    return _seed.users.where((u) => studentIds.contains(u.id)).toList();
  }

  @override
  Future<List<AttendanceRecord>> getAttendanceForSession(String sectionId, DateTime date) async {
    await _delay();
    return const [];
  }

  @override
  Future<Result<bool>> submitAttendance(List<AttendanceRecord> records) async {
    await _delay();
    return Result.ok(true);
  }

  @override
  Future<Result<bool>> encodeGrade({
    required String studentId,
    required String sectionId,
    required double numericGrade,
  }) async {
    await _delay();
    if (numericGrade < 1.0 || numericGrade > 5.0) {
      return Result.error('Enter a grade between 1.00 and 5.00.');
    }
    return Result.ok(true);
  }

  @override
  String generateSessionQrPayload(String sectionId) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return 'PGPC-ATT|$sectionId|$ts';
  }
}

class MockAdminRepository implements AdminRepository {
  final _seed = MockSeedData.instance;

  @override
  Future<List<AppUser>> getAllUsers() async {
    await _delay();
    return List<AppUser>.from(_seed.users);
  }

  @override
  Future<Result<bool>> addUser(AppUser user) async {
    await _delay();
    if (_seed.users.any((u) => u.loginId == user.loginId)) {
      return Result.error('That login ID is already in use.');
    }
    _seed.users.add(user);
    return Result.ok(true);
  }

  @override
  Future<Result<bool>> setUserActive(String userId, bool active) async {
    await _delay();
    _seed.auditLog.insert(
      0,
      AuditLogEntry(
        id: 'log_${DateTime.now().microsecondsSinceEpoch}',
        actor: 'Admin',
        action: active ? 'Reactivated account' : 'Deactivated account',
        target: userId,
        timestamp: DateTime.now(),
      ),
    );
    return Result.ok(true);
  }

  @override
  Future<List<AuditLogEntry>> getAuditLog() async {
    await _delay();
    return List<AuditLogEntry>.from(_seed.auditLog);
  }

  @override
  Future<Map<String, num>> getAnalyticsSummary() async {
    await _delay();
    var todaysCollections = 0.0;
    final now = DateTime.now();
    for (final p in _seed.payments) {
      if (p.timestamp.year == now.year && p.timestamp.month == now.month && p.timestamp.day == now.day) {
        todaysCollections += p.amount;
      }
    }
    return {
      'totalStudents': _seed.users.where((u) => u.role == UserRole.student).length,
      'totalFaculty': _seed.users.where((u) => u.role == UserRole.teacher).length,
      'pendingEnrollments':
          _seed.enrollments.where((e) => e.status == EnrollmentStatus.pending).length,
      'todaysCollections': todaysCollections,
    };
  }

  @override
  Future<Map<String, int>> getEnrollmentTrend() async {
    await _delay();
    return {'Aug': 410, 'Sep': 60, 'Oct': 15, 'Nov': 8, 'Dec': 5, 'Jan': 430};
  }
}

class MockCampusServicesRepository implements CampusServicesRepository {
  final _seed = MockSeedData.instance;
  final Map<QueueOffice, StreamController<List<QueueTicket>>> _queueControllers = {};

  StreamController<List<QueueTicket>> _controllerFor(QueueOffice office) {
    return _queueControllers.putIfAbsent(
      office,
      () => StreamController<List<QueueTicket>>.broadcast(),
    );
  }

  void _emitQueue(QueueOffice office) {
    final controller = _queueControllers[office];
    if (controller != null && !controller.isClosed) {
      controller.add(List<QueueTicket>.from(_seed.queues[office] ?? const []));
    }
  }

  @override
  Future<List<DocumentRequest>> getDocumentRequests(String studentId) async {
    await _delay();
    return List<DocumentRequest>.from(_seed.documentRequests[studentId] ?? const []);
  }

  @override
  Future<Result<DocumentRequest>> submitDocumentRequest(
    String studentId,
    DocumentType type,
    String purpose,
  ) async {
    await _delay();
    final req = DocumentRequest(
      id: 'doc_${DateTime.now().microsecondsSinceEpoch}',
      studentId: studentId,
      type: type,
      purpose: purpose,
      requestedAt: DateTime.now(),
      status: RequestStatus.submitted,
    );
    _seed.documentRequests.putIfAbsent(studentId, () => []).insert(0, req);
    return Result.ok(req);
  }

  @override
  Future<Clearance> getClearance(String studentId, String term) async {
    await _delay();
    return _seed.clearances[studentId] ??
        Clearance(
          studentId: studentId,
          term: term,
          steps: const [
            ClearanceStep(office: 'Library', cleared: false),
            ClearanceStep(office: 'Laboratory', cleared: false),
            ClearanceStep(office: 'Accounting', cleared: false),
            ClearanceStep(office: 'Guidance', cleared: false),
          ],
        );
  }

  @override
  Future<QueueTicket> issueQueueTicket(
    String studentId,
    String studentName,
    QueueOffice office,
  ) async {
    await _delay();
    final ticket = QueueTicket(
      id: 'q_${DateTime.now().microsecondsSinceEpoch}',
      studentId: studentId,
      studentName: studentName,
      office: office,
      number: _seed.nextQueueNumber(),
      issuedAt: DateTime.now(),
      status: QueueStatus.waiting,
    );
    _seed.queues.putIfAbsent(office, () => []).add(ticket);
    _emitQueue(office);
    return ticket;
  }

  @override
  Stream<List<QueueTicket>> watchQueue(QueueOffice office) {
    final controller = _controllerFor(office);
    Future.microtask(() => _emitQueue(office));
    return controller.stream;
  }

  @override
  Future<Result<bool>> callNextInQueue(QueueOffice office) async {
    await _delay();
    final list = _seed.queues[office];
    if (list == null || list.isEmpty) return Result.error('Queue is empty.');
    final idx = list.indexWhere((t) => t.status == QueueStatus.waiting);
    if (idx == -1) return Result.error('No one is waiting.');
    list[idx] = list[idx].copyWith(status: QueueStatus.called);
    _emitQueue(office);
    return Result.ok(true);
  }

  @override
  Future<List<Appointment>> getAppointments(String studentId) async {
    await _delay();
    return _seed.appointments.where((a) => a.studentId == studentId).toList();
  }

  @override
  Future<List<Appointment>> getAppointmentsForOffice(AppointmentOffice office) async {
    await _delay();
    return _seed.appointments.where((a) => a.office == office).toList();
  }

  @override
  Future<Result<Appointment>> bookAppointment(
    String studentId,
    AppointmentOffice office,
    String purpose,
    DateTime when,
  ) async {
    await _delay();
    final appt = Appointment(
      id: 'appt_${DateTime.now().microsecondsSinceEpoch}',
      studentId: studentId,
      office: office,
      purpose: purpose,
      requestedFor: when,
      status: AppointmentStatus.pending,
    );
    _seed.appointments.add(appt);
    return Result.ok(appt);
  }

  @override
  Future<List<VisitorLog>> getVisitorLogs() async {
    await _delay();
    return List<VisitorLog>.from(_seed.visitorLogs.reversed);
  }

  @override
  Future<Result<VisitorLog>> checkInVisitor(String name, String purpose, String host) async {
    await _delay();
    final log = VisitorLog(
      id: 'vis_${DateTime.now().microsecondsSinceEpoch}',
      visitorName: name,
      purpose: purpose,
      hostName: host,
      checkIn: DateTime.now(),
    );
    _seed.visitorLogs.add(log);
    return Result.ok(log);
  }

  @override
  Future<Result<bool>> checkOutVisitor(String id) async {
    await _delay();
    final idx = _seed.visitorLogs.indexWhere((v) => v.id == id);
    if (idx == -1) return Result.error('Visitor log not found.');
    final old = _seed.visitorLogs[idx];
    _seed.visitorLogs[idx] = VisitorLog(
      id: old.id,
      visitorName: old.visitorName,
      purpose: old.purpose,
      hostName: old.hostName,
      checkIn: old.checkIn,
      checkOut: DateTime.now(),
    );
    return Result.ok(true);
  }

  @override
  Future<List<LostFoundItem>> getLostFoundItems() async {
    await _delay();
    return List<LostFoundItem>.from(_seed.lostFoundItems.reversed);
  }

  @override
  Future<Result<LostFoundItem>> reportLostFoundItem(LostFoundItem item) async {
    await _delay();
    _seed.lostFoundItems.add(item);
    return Result.ok(item);
  }

  @override
  Future<Result<bool>> markItemClaimed(String itemId) async {
    await _delay();
    final idx = _seed.lostFoundItems.indexWhere((i) => i.id == itemId);
    if (idx == -1) return Result.error('Item not found.');
    _seed.lostFoundItems[idx] = _seed.lostFoundItems[idx].copyWith(claimed: true);
    return Result.ok(true);
  }
}
