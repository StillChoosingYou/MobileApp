import '../../core/config/app_config.dart';
import '../../core/error/result.dart';
import '../../core/network/api_client.dart';
import '../../core/network/connectivity_service.dart';
import '../../core/network/offline_cache.dart';
import '../../core/utils/assistant_rules.dart';
import '../../models/academic_models.dart';
import '../../models/advanced_models.dart';
import '../../models/app_user.dart';
import '../../models/campus_models.dart';
import '../../models/financial_models.dart';
import 'repository_interfaces.dart';

/// Talks to your own Flask + Postgres (Supabase) API — see `api/` at the
/// project root for the matching server code, and `api/schema.sql` for the
/// database schema this expects. Active when
/// `AppConfig.backendMode == BackendMode.restApi`.
///
/// Every method here mirrors one Flask route almost 1:1 — if you rename or
/// restructure a route in `api/routes/`, update the matching path string
/// here too. There's no code generation tying the two together, so this is
/// the one place a client/server drift would show up (as an [ApiException]
/// with a 404, typically).
///
/// **Offline behavior:** every read caches its last successful JSON response in
/// [OfflineCache] (Hive). If the network is unavailable, the repository serves
/// the cached copy so screens still render with stale-but-usable data instead
/// of an error. Writes (payments, evaluations, ...) still require the network
/// and surface an [ApiException] when offline — a write queue is a larger
/// feature tagged in the README roadmap.
class ApiAuthRepository implements AuthRepository {
  @override
  Future<Result<AppUser>> login({
    required UserRole role,
    required String loginId,
    required String password,
  }) async {
    try {
      final json = await ApiClient.post('/auth/login', {
        'role': role.name,
        'loginId': loginId,
        'password': password,
      }) as Map<String, dynamic>;

      ApiClient.saveToken(json['token'] as String);
      return Result.ok(AppUser.fromJson(json['user'] as Map<String, dynamic>));
    } on ApiException catch (e) {
      // Login can't fall back to a cache — it needs the live server to verify
      // credentials. Surface the friendly error so the login screen can show it.
      return Result.error(e.message);
    }
  }

  @override
  Future<Result<bool>> requestPasswordReset(String emailOrLoginId) async {
    try {
      await ApiClient.post('/auth/forgot-password', {'emailOrLoginId': emailOrLoginId});
      return Result.ok(true);
    } on ApiException catch (e) {
      return Result.error(e.message);
    }
  }

  @override
  Future<bool> isBiometricEnabled(String loginId) async {
    // The Flask backend flips this flag on the *user's account*
    // (see routes/auth.py's enable-biometric route), but nothing currently
    // exposes a "get my own user record" read endpoint to check it back —
    // add one (`GET /api/auth/me`) if you need this to reflect real state
    // instead of always reporting false.
    return false;
  }

  @override
  Future<Result<bool>> enableBiometric(String loginId) async {
    try {
      await ApiClient.post('/auth/enable-biometric', {});
      return Result.ok(true);
    } on ApiException catch (e) {
      return Result.error(e.message);
    }
  }
}

class ApiStudentRepository implements StudentRepository {
  static const _profileKey = 'student_profile:';
  static const _sectionsKey = 'student_sections:';
  static const _gradesKey = 'student_grades:';
  static const _ledgerKey = 'student_ledger:';
  static const _paymentsKey = 'student_payments:';
  static const _enrollmentKey = 'student_enrollment:';
  static const _announcementsKey = 'announcements';
  static const _notificationsKey = 'student_notifications:';
  static const _calendarKey = 'calendar_events';
  static const _checklistKey = 'curriculum_checklist:';

  @override
  Future<StudentProfile?> getStudentProfile(String studentId) async {
    final key = '$_profileKey$studentId';
    try {
      final json = await ApiClient.get('/student/$studentId/profile');
      if (json == null) {
        OfflineCache.instance.save(key, null);
        return null;
      }
      OfflineCache.instance.save(key, json);
      return StudentProfile.fromJson(json as Map<String, dynamic>);
    } on ApiException {
      final cached = OfflineCache.instance.get(key);
      if (cached == null) rethrow;
      return cached is Map
          ? StudentProfile.fromJson(cached as Map<String, dynamic>)
          : null;
    }
  }

  @override
  Future<List<Section>> getEnrolledSections(String studentId, String term) async {
    final key = '$_sectionsKey$studentId:$term';
    try {
      final json = await ApiClient.get('/student/$studentId/sections', query: {'term': term});
      OfflineCache.instance.save(key, json);
      return (json as List).map((e) => Section.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException {
      final cached = OfflineCache.instance.get(key);
      if (cached == null) rethrow;
      return (cached as List).map((e) => Section.fromJson(e as Map<String, dynamic>)).toList();
    }
  }

  @override
  Future<List<Grade>> getGrades(String studentId) async {
    final key = '$_gradesKey$studentId';
    try {
      final json = await ApiClient.get('/student/$studentId/grades');
      OfflineCache.instance.save(key, json);
      return (json as List).map((e) => Grade.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException {
      final cached = OfflineCache.instance.get(key);
      if (cached == null) rethrow;
      return (cached as List).map((e) => Grade.fromJson(e as Map<String, dynamic>)).toList();
    }
  }

  @override
  Future<TuitionLedger> getLedger(String studentId, String term) async {
    final key = '$_ledgerKey$studentId:$term';
    try {
      final json = await ApiClient.get('/student/$studentId/ledger', query: {'term': term});
      OfflineCache.instance.save(key, json);
      return TuitionLedger.fromJson(json as Map<String, dynamic>);
    } on ApiException {
      final cached = OfflineCache.instance.get(key);
      if (cached == null) rethrow;
      return TuitionLedger.fromJson(cached as Map<String, dynamic>);
    }
  }

  @override
  Future<List<Payment>> getPaymentHistory(String studentId) async {
    final key = '$_paymentsKey$studentId';
    try {
      final json = await ApiClient.get('/student/$studentId/payments');
      OfflineCache.instance.save(key, json);
      return (json as List).map((e) => Payment.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException {
      final cached = OfflineCache.instance.get(key);
      if (cached == null) rethrow;
      return (cached as List).map((e) => Payment.fromJson(e as Map<String, dynamic>)).toList();
    }
  }

  @override
  Future<Enrollment?> getEnrollment(String studentId, String term) async {
    final key = '$_enrollmentKey$studentId:$term';
    try {
      final json = await ApiClient.get('/student/$studentId/enrollment', query: {'term': term});
      if (json == null) {
        OfflineCache.instance.save(key, null);
        return null;
      }
      OfflineCache.instance.save(key, json);
      return Enrollment.fromJson(json as Map<String, dynamic>);
    } on ApiException {
      final cached = OfflineCache.instance.get(key);
      if (cached == null) rethrow;
      return cached is Map
          ? Enrollment.fromJson(cached as Map<String, dynamic>)
          : null;
    }
  }

  @override
  Future<List<Announcement>> getAnnouncements() async {
    try {
      final json = await ApiClient.get('/announcements');
      OfflineCache.instance.save(_announcementsKey, json);
      return (json as List).map((e) => Announcement.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException {
      final cached = OfflineCache.instance.get(_announcementsKey);
      if (cached == null) rethrow;
      return (cached as List).map((e) => Announcement.fromJson(e as Map<String, dynamic>)).toList();
    }
  }

  @override
  Future<List<NotificationItem>> getNotifications(String studentId) async {
    final key = '$_notificationsKey$studentId';
    try {
      final json = await ApiClient.get('/student/$studentId/notifications');
      OfflineCache.instance.save(key, json);
      return (json as List).map((e) => NotificationItem.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException {
      final cached = OfflineCache.instance.get(key);
      if (cached == null) rethrow;
      return (cached as List).map((e) => NotificationItem.fromJson(e as Map<String, dynamic>)).toList();
    }
  }

  @override
  Future<String> askAssistant(String studentId, String question) async {
    // Kept client-side rather than a Flask route — it's pure logic with no
    // persistence of its own. It still reflects real data, since the two
    // network calls below hit the real backend (with offline fallback).
    final sections = await getEnrolledSections(studentId, AppConfig.currentTermLabel);
    final ledger = await getLedger(studentId, AppConfig.currentTermLabel);
    return AssistantRules.answerQuestion(
      question: question,
      term: AppConfig.currentTermLabel,
      enrolledSections: sections,
      ledger: ledger,
    );
  }

  @override
  Future<List<Subject>> recommendElectives(String studentId) async {
    final grades = await getGrades(studentId);
    final json = await ApiClient.get('/subjects');
    final subjects = (json as List).map((e) => Subject.fromJson(e as Map<String, dynamic>)).toList();
    return AssistantRules.recommendElectives(grades: grades, allSubjects: subjects);
  }

  @override
  Future<List<CalendarEvent>> getCalendarEvents() async {
    try {
      final json = await ApiClient.get('/calendar/events');
      OfflineCache.instance.save(_calendarKey, json);
      return (json as List).map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException {
      final cached = OfflineCache.instance.get(_calendarKey);
      if (cached == null) rethrow;
      return (cached as List).map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>)).toList();
    }
  }

  @override
  Future<CurriculumChecklist> getCurriculumChecklist(String studentId) async {
    final key = '$_checklistKey$studentId';
    try {
      final json = await ApiClient.get('/student/$studentId/curriculum-checklist');
      OfflineCache.instance.save(key, json);
      return CurriculumChecklist.fromJson(json as Map<String, dynamic>);
    } on ApiException {
      final cached = OfflineCache.instance.get(key);
      if (cached == null) rethrow;
      return CurriculumChecklist.fromJson(cached as Map<String, dynamic>);
    }
  }

  @override
  Future<void> markNotificationRead(String studentId, String notificationId) async {
    // Optimistic offline-friendly write: if the network is down we don't have a
    // pending-write queue yet, so just let it fail loudly — the read path
    // above still serves cached notifications.
    await ApiClient.post('/student/$studentId/notifications/$notificationId/read', {});
  }

  @override
  Future<Result<bool>> submitFacultyEvaluation(FacultyEvaluation evaluation) async {
    try {
      await ApiClient.post('/student/faculty-evaluation', evaluation.toJson());
      return Result.ok(true);
    } on ApiException catch (e) {
      return Result.error(e.message);
    }
  }
}

class ApiCashierRepository implements CashierRepository {
  static const _txnKey = 'cashier_transactions';
  static const _dailyKey = 'cashier_daily:';
  static const _byMethodKey = 'cashier_by_method';
  static const _trendKey = 'cashier_trend:';
  static const _outstandingKey = 'cashier_outstanding';

  @override
  Future<Result<Payment>> recordPayment({
    required String studentId,
    required String studentName,
    required double amount,
    required PaymentMethod method,
    required String recordedBy,
  }) async {
    try {
      final json = await ApiClient.post('/cashier/payments', {
        'studentId': studentId,
        'studentName': studentName,
        'amount': amount,
        'method': method.name,
        'recordedBy': recordedBy,
      }) as Map<String, dynamic>;
      return Result.ok(Payment.fromJson(json));
    } on ApiException catch (e) {
      return Result.error(e.message);
    }
  }

  @override
  Future<List<Payment>> getTransactionHistory({DateTime? onDate}) async {
    final key = onDate == null ? _txnKey : '$_dailyKey${_dateOnly(onDate)}';
    try {
      final json = await ApiClient.get(
        '/cashier/transactions',
        query: onDate == null ? null : {'date': _dateOnly(onDate)},
      );
      OfflineCache.instance.save(key, json);
      return (json as List).map((e) => Payment.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException {
      final cached = OfflineCache.instance.get(key);
      if (cached == null) rethrow;
      return (cached as List).map((e) => Payment.fromJson(e as Map<String, dynamic>)).toList();
    }
  }

  @override
  Future<double> getDailyCollectionTotal(DateTime date) async {
    final key = '$_dailyKey${_dateOnly(date)}';
    try {
      final json = await ApiClient.get('/cashier/daily-total', query: {'date': _dateOnly(date)})
          as Map<String, dynamic>;
      OfflineCache.instance.save(key, json);
      return (json['total'] as num).toDouble();
    } on ApiException {
      final cached = OfflineCache.instance.get(key);
      if (cached == null) rethrow;
      return (cached as Map<String, dynamic>)['total'] as double;
    }
  }

  @override
  Future<Map<String, double>> getCollectionByMethod() async {
    try {
      final json = await ApiClient.get('/cashier/collection-by-method') as Map<String, dynamic>;
      OfflineCache.instance.save(_byMethodKey, json);
      return json.map((key, value) => MapEntry(key, (value as num).toDouble()));
    } on ApiException {
      final cached = OfflineCache.instance.get(_byMethodKey);
      if (cached == null) rethrow;
      return (cached as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, (value as num).toDouble()));
    }
  }

  @override
  Future<Map<String, double>> getCollectionTrend({int days = 7}) async {
    final key = '$_trendKey$days';
    try {
      final json = await ApiClient.get(
        '/cashier/collection-trend',
        query: {'days': '$days'},
      ) as Map<String, dynamic>;
      OfflineCache.instance.save(key, json);
      return json.map((key, value) => MapEntry(key, (value as num).toDouble()));
    } on ApiException {
      final cached = OfflineCache.instance.get(key);
      if (cached == null) rethrow;
      return (cached as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, (value as num).toDouble()));
    }
  }

  @override
  Future<double> getTotalOutstandingBalance() async {
    try {
      final json = await ApiClient.get('/cashier/outstanding-balance') as Map<String, dynamic>;
      OfflineCache.instance.save(_outstandingKey, json);
      return (json['total'] as num).toDouble();
    } on ApiException {
      final cached = OfflineCache.instance.get(_outstandingKey);
      if (cached == null) rethrow;
      return (cached as Map<String, dynamic>)['total'] as double;
    }
  }

  @override
  Future<Result<bool>> refundPayment(String paymentId, String reason) async {
    try {
      await ApiClient.post('/cashier/payments/$paymentId/refund', {'reason': reason});
      return Result.ok(true);
    } on ApiException catch (e) {
      return Result.error(e.message);
    }
  }

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Small helper used by screens/providers that want to short-circuit a network
/// call when we already know we're offline (avoids a slow connection-timeout
/// round trip before falling back). Returns `true` if connectivity is
/// currently unavailable.
Future<bool> isOffline() async {
  final results = await ConnectivityService.instance.check();
  return !ConnectivityService.isOnline(results);
}