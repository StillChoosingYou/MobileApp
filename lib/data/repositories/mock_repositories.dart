import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/error/result.dart';
import '../../core/utils/assistant_rules.dart';
import '../../models/academic_models.dart';
import '../../models/advanced_models.dart';
import '../../models/app_user.dart';
import '../../models/attendance_models.dart';
import '../../models/audit_log.dart';
import '../../models/campus_models.dart';
import '../../models/financial_models.dart';
import '../../models/messaging_models.dart';
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
  Future<List<CalendarEvent>> getCalendarEvents() async {
    await _delay();
    return List<CalendarEvent>.from(_seed.calendarEvents);
  }

  @override
  Future<CurriculumChecklist> getCurriculumChecklist(String studentId) async {
    await _delay();
    final profile = await getStudentProfile(studentId);
    if (profile == null) {
      return CurriculumChecklist(
        studentId: studentId,
        program: 'Unknown',
        totalUnitsRequired: 0,
        items: const [],
      );
    }
    final takenCodes = _seed.grades
        .where((g) => g.numericGrade != null && !g.isIncomplete)
        .map((g) => g.subjectCode)
        .toSet();

    final items = _seed.subjects.map((s) {
      final status = takenCodes.contains(s.code)
          ? ChecklistItemStatus.completed
          : ChecklistItemStatus.notTaken;
      final grade = takenCodes.contains(s.code)
          ? _seed.grades.firstWhere((g) => g.subjectCode == s.code).numericGrade
          : null;
      return CurriculumItem(
        subjectCode: s.code,
        subjectTitle: s.title,
        units: s.units,
        yearLevel: 1,
        semester: 1,
        status: status,
        grade: grade,
      );
    }).toList();

    final totalUnits = _seed.subjects.fold(0.0, (sum, s) => sum + s.units);
    return CurriculumChecklist(
      studentId: studentId,
      program: profile.program,
      totalUnitsRequired: totalUnits,
      items: items,
    );
  }

  @override
  Future<void> markNotificationRead(String studentId, String notificationId) async {
    await _delay();
    final list = _seed.notifications[studentId];
    if (list != null) {
      final idx = list.indexWhere((n) => n.id == notificationId);
      if (idx != -1) {
        _seed.notifications[studentId] = [
          ...list.sublist(0, idx),
          list[idx].markRead(),
          ...list.sublist(idx + 1),
        ];
      }
    }
  }

  @override
  Future<Result<bool>> submitFacultyEvaluation(FacultyEvaluation evaluation) async {
    await _delay();
    _seed.facultyEvaluations.add(evaluation);
    return Result.ok(true);
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

  @override
  Future<Result<bool>> addSubject(Subject subject) async {
    await _delay();
    if (_seed.subjects.any((s) => s.code == subject.code)) {
      return Result.error('Subject with code ${subject.code} already exists.');
    }
    _seed.subjects.add(subject);
    return Result.ok(true);
  }

  @override
  Future<Result<bool>> updateSubject(Subject subject) async {
    await _delay();
    final idx = _seed.subjects.indexWhere((s) => s.code == subject.code);
    if (idx == -1) return Result.error('Subject not found.');
    _seed.subjects[idx] = subject;
    return Result.ok(true);
  }

  @override
  Future<Result<bool>> deleteSubject(String code) async {
    await _delay();
    final idx = _seed.subjects.indexWhere((s) => s.code == code);
    if (idx == -1) return Result.error('Subject not found.');
    _seed.subjects.removeAt(idx);
    return Result.ok(true);
  }

  @override
  Future<Result<bool>> addSection(Section section) async {
    await _delay();
    if (_seed.sections.any((s) => s.id == section.id)) {
      return Result.error('Section with ID ${section.id} already exists.');
    }
    _seed.sections.add(section);
    return Result.ok(true);
  }

  @override
  Future<Result<bool>> updateSection(Section section) async {
    await _delay();
    final idx = _seed.sections.indexWhere((s) => s.id == section.id);
    if (idx == -1) return Result.error('Section not found.');
    _seed.sections[idx] = section;
    return Result.ok(true);
  }

  @override
  Future<Map<String, int>> getEnrollmentStatsByProgram() async {
    await _delay();
    final stats = <String, int>{};
    for (final profile in _seed.studentProfiles) {
      stats[profile.program] = (stats[profile.program] ?? 0) + 1;
    }
    return stats;
  }

  @override
  Future<Map<int, int>> getStudentPopulationByYear() async {
    await _delay();
    final stats = <int, int>{};
    for (final profile in _seed.studentProfiles) {
      stats[profile.yearLevel] = (stats[profile.yearLevel] ?? 0) + 1;
    }
    return stats;
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
  Future<Map<String, double>> getCollectionByMethod() async {
    await _delay();
    final totals = <String, double>{for (final m in PaymentMethod.values) m.name: 0.0};
    for (final p in _seed.payments) {
      totals[p.method.name] = totals[p.method.name]! + p.amount;
    }
    return totals;
  }

  @override
  Future<Map<String, double>> getCollectionTrend({int days = 7}) async {
    await _delay();
    final now = DateTime.now();
    final trend = <String, double>{
      for (var i = days - 1; i >= 0; i--) _dateOnly(now.subtract(Duration(days: i))): 0.0,
    };
    for (final p in _seed.payments) {
      final key = _dateOnly(p.timestamp);
      if (trend.containsKey(key)) trend[key] = trend[key]! + p.amount;
    }
    return trend;
  }

  @override
  Future<double> getTotalOutstandingBalance() async {
    await _delay();
    var total = 0.0;
    for (final ledger in _seed.ledgers.values) {
      final balance = ledger.tuitionFee +
          ledger.miscFees +
          ledger.labFees -
          ledger.scholarshipDiscount -
          ledger.totalPaid;
      if (balance > 0) total += balance;
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

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
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

  @override
  Future<List<AttendanceSummary>> getAttendanceSummary(String sectionId) async {
    await _delay();
    final roster = await getRoster(sectionId);
    return roster.map((student) {
      return AttendanceSummary(
        studentId: student.id,
        studentName: student.name,
        studentNumber: student.loginId,
        totalSessions: 20,
        presentCount: 18,
        absentCount: 1,
        lateCount: 1,
        excusedCount: 0,
      );
    }).toList();
  }

  @override
  Future<GradeDistribution> getGradeDistribution(String sectionId) async {
    await _delay();
    return GradeDistribution(
      sectionId: sectionId,
      subjectCode: _seed.sections
          .firstWhere(
            (s) => s.id == sectionId,
            orElse: () => _seed.sections.first,
          )
          .subjectCode,
      excellent: 5,
      good: 8,
      satisfactory: 6,
      passing: 4,
      failing: 2,
      incomplete: 1,
    );
  }

  @override
  Future<List<AppUser>> getAtRiskStudents(String sectionId) async {
    await _delay();
    final roster = await getRoster(sectionId);
    // Mock: students with academic warning status (demo: those with IDs ending in certain patterns)
    return roster.where((student) => student.id.endsWith('089') || student.id.endsWith('310')).toList();
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

  @override
  Future<Map<String, double>> getRevenueTrend() async {
    await _delay();
    return {
      'Jan': 45000,
      'Feb': 52000,
      'Mar': 48000,
      'Apr': 61000,
      'May': 55000,
      'Jun': 67000,
      'Jul': 72000,
      'Aug': 58000,
    };
  }

  @override
  Future<Map<String, int>> getRoleDistribution() async {
    await _delay();
    final stats = <String, int>{};
    for (final user in _seed.users) {
      final roleName = user.role.name;
      stats[roleName] = (stats[roleName] ?? 0) + 1;
    }
    return stats;
  }

  @override
  Future<Result<bool>> createAnnouncement(Announcement announcement) async {
    await _delay();
    _seed.announcements.add(announcement);
    return Result.ok(true);
  }

  @override
  Future<Result<bool>> deleteAnnouncement(String id) async {
    await _delay();
    final idx = _seed.announcements.indexWhere((a) => a.id == id);
    if (idx == -1) return Result.error('Announcement not found.');
    _seed.announcements.removeAt(idx);
    return Result.ok(true);
  }
}

// ---------------------------------------------------------------------------
// New: Notification Repository (Mock)
// ---------------------------------------------------------------------------

class MockNotificationRepository implements NotificationRepository {
  final Map<String, List<String>> _userTokens = {};

  @override
  Future<void> saveFcmToken(String userId, String token) async {
    await _delay();
    _userTokens.putIfAbsent(userId, () => []);
    if (!_userTokens[userId]!.contains(token)) {
      _userTokens[userId]!.add(token);
    }
  }

  @override
  Future<void> deleteFcmToken(String userId, String token) async {
    await _delay();
    _userTokens[userId]?.remove(token);
  }

  @override
  Future<void> deleteAllFcmTokens(String userId) async {
    await _delay();
    _userTokens.remove(userId);
  }

  @override
  Future<List<String>> getUserTokens(String userId) async {
    await _delay();
    return List<String>.from(_userTokens[userId] ?? const []);
  }

  @override
  Future<Result<bool>> sendPushNotification({
    required List<String> tokens,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    await _delay();
    debugPrint('Mock push sent to ${tokens.length} tokens: $title');
    return Result.ok(true);
  }

  @override
  Future<void> subscribeToTopic(String userId, String topic) async {
    await _delay();
    debugPrint('Mock: User $userId subscribed to $topic');
  }

  @override
  Future<void> unsubscribeFromTopic(String userId, String topic) async {
    await _delay();
    debugPrint('Mock: User $userId unsubscribed from $topic');
  }
}

// ---------------------------------------------------------------------------
// New: Message Repository (Mock)
// ---------------------------------------------------------------------------

class MockMessageRepository implements MessageRepository {
  final _seed = MockSeedData.instance;
  final List<Conversation> _conversations = [];
  final Map<String, List<Message>> _messages = {};

  @override
  Stream<List<Conversation>> watchConversations(String userId) async* {
    yield _getConversationsForUser(userId);
    await Future.delayed(const Duration(seconds: 1));
    // In a real implementation, this would be a real stream controller
    // For mock, we just yield once
  }

  @override
  Stream<List<Message>> watchMessages(String conversationId) async* {
    yield List<Message>.from(_messages[conversationId] ?? const []);
    await Future.delayed(const Duration(seconds: 1));
  }

  List<Conversation> _getConversationsForUser(String userId) {
    return _conversations
        .where((c) => c.participantIds.contains(userId) && !c.isArchived)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<Result<Conversation>> getOrCreateConversation(
    List<String> participantIds, {
    String? groupName,
    String? groupAvatarUrl,
  }) async {
    await _delay();

    // Check if 1:1 conversation already exists
    if (groupName != null && groupName.isNotEmpty && participantIds.length == 2) {
      for (final conv in _conversations) {
        if (!conv.isGroup &&
            conv.participantIds.toSet() == participantIds.toSet()) {
          return Result.ok(conv);
        }
      }
    }

    // Create new conversation
    final conv = Conversation(
      id: 'conv_${DateTime.now().microsecondsSinceEpoch}',
      participantIds: participantIds,
      groupName: groupName,
      groupAvatarUrl: groupAvatarUrl,
      updatedAt: DateTime.now(),
      unreadCounts: {for (final id in participantIds) id: 0},
    );
    _conversations.add(conv);
    return Result.ok(conv);
  }

  @override
  Future<Result<Message>> sendMessage(
    String conversationId,
    String senderId,
    String content, {
    MessageType type = MessageType.text,
    Map<String, String>? metadata,
  }) async {
    await _delay();

    final sender = _seed.users.firstWhere(
      (u) => u.id == senderId,
      orElse: () => AppUser(
        id: senderId,
        loginId: senderId,
        role: UserRole.student,
        name: 'Unknown',
        email: '',
      ),
    );

    final message = Message(
      id: 'msg_${DateTime.now().microsecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: senderId,
      senderName: sender.name,
      senderAvatarUrl: sender.photoUrl,
      type: type,
      content: content,
      metadata: metadata,
      sentAt: DateTime.now(),
      readBy: [senderId],
    );

    _messages.putIfAbsent(conversationId, () => []).add(message);

    // Update conversation last message and unread counts
    final convIdx = _conversations.indexWhere((c) => c.id == conversationId);
    if (convIdx != -1) {
      final conv = _conversations[convIdx];
      final newUnreadCounts = Map<String, int>.from(conv.unreadCounts);
      for (final participant in conv.participantIds) {
        if (participant != senderId) {
          newUnreadCounts[participant] = (newUnreadCounts[participant] ?? 0) + 1;
        }
      }
      _conversations[convIdx] = conv.copyWith(
        lastMessage: message,
        updatedAt: DateTime.now(),
        unreadCounts: newUnreadCounts,
      );
    }

    return Result.ok(message);
  }

  @override
  Future<void> markAsRead(String conversationId, String userId) async {
    await _delay();
    final messages = _messages[conversationId];
    if (messages != null) {
      for (final msg in messages) {
        if (!msg.readBy.contains(userId)) {
          final idx = messages.indexOf(msg);
          messages[idx] = msg.copyWith(readBy: [...msg.readBy, userId]);
        }
      }
    }

    final convIdx = _conversations.indexWhere((c) => c.id == conversationId);
    if (convIdx != -1) {
      final conv = _conversations[convIdx];
      final newUnreadCounts = Map<String, int>.from(conv.unreadCounts);
      newUnreadCounts[userId] = 0;
      _conversations[convIdx] = conv.copyWith(unreadCounts: newUnreadCounts);
    }
  }

  @override
  Future<Result<bool>> createGroupChat(
    String creatorId,
    List<String> participantIds,
    String groupName, {
    String? groupAvatarUrl,
  }) async {
    await _delay();
    final allParticipants = <String>{creatorId, ...participantIds}.toList();
    final conv = Conversation(
      id: 'conv_${DateTime.now().microsecondsSinceEpoch}',
      participantIds: allParticipants,
      groupName: groupName,
      groupAvatarUrl: groupAvatarUrl,
      updatedAt: DateTime.now(),
      unreadCounts: {for (final id in allParticipants) id: 0},
    );
    _conversations.add(conv);
    return Result.ok(true);
  }

  @override
  Future<List<AppUser>> getPotentialChatPartners(String userId) async {
    await _delay();
    // Return all other users as potential chat partners
    return _seed.users.where((u) => u.id != userId).toList();
  }

  @override
  Future<Result<bool>> deleteConversation(String conversationId, String userId) async {
    await _delay();
    final convIdx = _conversations.indexWhere((c) => c.id == conversationId);
    if (convIdx == -1) return Result.error('Conversation not found.');
    final conv = _conversations[convIdx];
    if (!conv.participantIds.contains(userId)) {
      return Result.error('Not a participant in this conversation.');
    }
    // Mark as archived for this user only (soft delete)
    // In a real app, you'd have a separate archived list per user
    return Result.ok(true);
  }
}

// ---------------------------------------------------------------------------
// New: Calendar Repository (Mock)
// ---------------------------------------------------------------------------

class MockCalendarRepository implements CalendarRepository {
  final _seed = MockSeedData.instance;
  final Map<String, List<Duration>> _userReminders = {};

  @override
  Future<List<CalendarEvent>> getEvents({DateTime? from, DateTime? to}) async {
    await _delay();
    var events = List<CalendarEvent>.from(_seed.calendarEvents);
    if (from != null) {
      events = events.where((e) => (e.endDate ?? e.date).isAfter(from)).toList();
    }
    if (to != null) {
      events = events.where((e) => e.date.isBefore(to)).toList();
    }
    events.sort((a, b) => a.date.compareTo(b.date));
    return events;
  }

  @override
  Stream<List<CalendarEvent>> watchEvents({DateTime? from, DateTime? to}) async* {
    yield await getEvents(from: from, to: to);
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<Result<CalendarEvent>> createEvent(CalendarEvent event) async {
    await _delay();
    _seed.calendarEvents.add(event);
    return Result.ok(event);
  }

  @override
  Future<Result<CalendarEvent>> updateEvent(CalendarEvent event) async {
    await _delay();
    final idx = _seed.calendarEvents.indexWhere((e) => e.id == event.id);
    if (idx == -1) return Result.error('Event not found.');
    _seed.calendarEvents[idx] = event;
    return Result.ok(event);
  }

  @override
  Future<Result<bool>> deleteEvent(String eventId) async {
    await _delay();
    final idx = _seed.calendarEvents.indexWhere((e) => e.id == eventId);
    if (idx == -1) return Result.error('Event not found.');
    _seed.calendarEvents.removeAt(idx);
    return Result.ok(true);
  }

  @override
  Future<Result<bool>> addReminder(String eventId, String userId, Duration before) async {
    await _delay();
    _userReminders.putIfAbsent(eventId, () => []);
    if (!_userReminders[eventId]!.contains(before)) {
      _userReminders[eventId]!.add(before);
    }
    return Result.ok(true);
  }

  @override
  Future<Result<bool>> removeReminder(String eventId, String userId) async {
    await _delay();
    _userReminders.remove(eventId);
    return Result.ok(true);
  }

  @override
  Future<List<Duration>> getUserReminders(String eventId, String userId) async {
    await _delay();
    return List<Duration>.from(_userReminders[eventId] ?? const []);
  }
}

// ---------------------------------------------------------------------------
// New: Attendance Repository (Mock)
// ---------------------------------------------------------------------------

class MockAttendanceRepository implements AttendanceRepository {
  final _seed = MockSeedData.instance;
  final Map<String, AttendanceSession> _activeSessions = {};
  final List<AttendanceRecord> _records = [];

  @override
  Future<Result<AttendanceSession>> startSession(
    String sectionId, {
    Duration duration = const Duration(minutes: 15),
    int rotationIntervalSeconds = 30,
  }) async {
    await _delay();
    final section = _seed.sections.firstWhere(
      (s) => s.id == sectionId,
      orElse: () => throw Exception('Section not found'),
    );

    final now = DateTime.now();
    final session = AttendanceSession(
      id: 'sess_${DateTime.now().microsecondsSinceEpoch}',
      sectionId: sectionId,
      sectionName: section.subjectCode,
      subjectCode: section.subjectCode,
      startedAt: now,
      expiresAt: now.add(duration),
      qrPayload: 'PGPC_ATTENDANCE|$sectionId|${now.millisecondsSinceEpoch}',
      rotationIntervalSeconds: rotationIntervalSeconds,
    );
    _activeSessions[sectionId] = session;
    return Result.ok(session);
  }

  @override
  Future<Result<bool>> endSession(String sectionId) async {
    await _delay();
    _activeSessions.remove(sectionId);
    return Result.ok(true);
  }

  @override
  Future<AttendanceSession?> getActiveSession(String sectionId) async {
    await _delay();
    final session = _activeSessions[sectionId];
    if (session != null && session.isSessionActive) {
      return session;
    }
    return null;
  }

  @override
  Stream<AttendanceSession?> watchActiveSession(String sectionId) async* {
    // For mock, we yield once with the current session
    final session = await getActiveSession(sectionId);
    yield session;
    // In real implementation, this would be a StreamController
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<List<AttendanceRecord>> getSessionRecords(String sessionId) async {
    await _delay();
    return _records.where((r) => r.sessionId == sessionId).toList();
  }

  @override
  Future<Result<AttendanceRecord>> submitAttendance(
    String studentId,
    String qrPayload,
  ) async {
    await _delay();

    final payload = QrPayload.decode(qrPayload);
    if (payload == null) {
      return Result.error('Invalid QR code.');
    }

    final session = _activeSessions[payload.sectionId];
    if (session == null || !session.isSessionActive) {
      return Result.error('No active attendance session.');
    }

    // Check if QR is expired (rotation)
    if (payload.isExpired(session.rotationIntervalSeconds)) {
      return Result.error('QR code has expired. Please scan the new code.');
    }

    // Check if already recorded
    final alreadyRecorded = _records.any(
      (r) => r.sessionId == session.id && r.studentId == studentId,
    );
    if (alreadyRecorded) {
      return Result.error('You have already marked attendance for this session.');
    }

    // Verify student is enrolled in this section
    final isEnrolled = _seed.enrollments.any(
      (e) => e.studentId == studentId && e.sectionIds.contains(payload.sectionId),
    );
    if (!isEnrolled) {
      return Result.error('You are not enrolled in this section.');
    }

    final student = _seed.users.firstWhere(
      (u) => u.id == studentId,
      orElse: () => AppUser(
        id: studentId,
        loginId: studentId,
        role: UserRole.student,
        name: 'Unknown',
        email: '',
      ),
    );

    final record = AttendanceRecord(
      id: 'att_${DateTime.now().microsecondsSinceEpoch}',
      sessionId: session.id,
      sectionId: payload.sectionId,
      studentId: studentId,
      studentName: student.name,
      status: AttendanceStatus.present,
      recordedAt: DateTime.now(),
    );
    _records.add(record);

    return Result.ok(record);
  }

  @override
  Future<List<AttendanceRecord>> getStudentAttendance(
    String studentId, {
    String? sectionId,
    DateTime? from,
    DateTime? to,
  }) async {
    await _delay();
    var records = _records.where((r) => r.studentId == studentId).toList();
    if (sectionId != null) {
      records = records.where((r) => r.sectionId == sectionId).toList();
    }
    if (from != null) {
      records = records.where((r) => r.recordedAt.isAfter(from)).toList();
    }
    if (to != null) {
      records = records.where((r) => r.recordedAt.isBefore(to)).toList();
    }
    records.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return records;
  }

  @override
  Future<List<AttendanceSummary>> getSectionAttendanceSummary(String sectionId) async {
    await _delay();
    final roster = _seed.users.where((u) => u.role == UserRole.student).take(20).toList();
    return roster.map((student) {
      final studentRecords = _records.where((r) => r.studentId == student.id && r.sectionId == sectionId).toList();
      final present = studentRecords.where((r) => r.status == AttendanceStatus.present).length;
      final late = studentRecords.where((r) => r.status == AttendanceStatus.late).length;
      final excused = studentRecords.where((r) => r.status == AttendanceStatus.excused).length;
      final absent = studentRecords.where((r) => r.status == AttendanceStatus.absent).length;
      final total = present + late + excused + absent;
      return AttendanceSummary(
        studentId: student.id,
        studentName: student.name,
        studentNumber: student.loginId,
        totalSessions: total > 0 ? total : 20,
        presentCount: present > 0 ? present : (total > 0 ? 0 : 18),
        absentCount: absent > 0 ? absent : (total > 0 ? 0 : 1),
        lateCount: late > 0 ? late : (total > 0 ? 0 : 1),
        excusedCount: excused > 0 ? excused : 0,
      );
    }).toList();
  }

  @override
  Future<List<AppUser>> getAtRiskStudents(
    String sectionId, {
    double threshold = 0.75,
  }) async {
    await _delay();
    final summaries = await getSectionAttendanceSummary(sectionId);
    final atRisk = summaries.where((s) => s.attendanceRate < threshold * 100).toList();
    return atRisk.map((s) {
      return _seed.users.firstWhere(
        (u) => u.id == s.studentId,
        orElse: () => AppUser(
          id: s.studentId,
          loginId: s.studentId,
          role: UserRole.student,
          name: s.studentName,
          email: '',
        ),
      );
    }).toList();
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
