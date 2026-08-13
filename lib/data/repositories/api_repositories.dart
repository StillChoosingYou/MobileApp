import '../../core/config/app_config.dart';
import '../../core/error/result.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/assistant_rules.dart';
import '../../models/app_user.dart';
import '../../models/academic_models.dart';
import '../../models/financial_models.dart';
import '../../models/campus_models.dart';
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
  @override
  Future<StudentProfile?> getStudentProfile(String studentId) async {
    final json = await ApiClient.get('/student/$studentId/profile');
    if (json == null) return null;
    return StudentProfile.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<List<Section>> getEnrolledSections(String studentId, String term) async {
    final json = await ApiClient.get('/student/$studentId/sections', query: {'term': term});
    return (json as List).map((e) => Section.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<Grade>> getGrades(String studentId) async {
    final json = await ApiClient.get('/student/$studentId/grades');
    return (json as List).map((e) => Grade.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<TuitionLedger> getLedger(String studentId, String term) async {
    final json = await ApiClient.get('/student/$studentId/ledger', query: {'term': term});
    return TuitionLedger.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<List<Payment>> getPaymentHistory(String studentId) async {
    final json = await ApiClient.get('/student/$studentId/payments');
    return (json as List).map((e) => Payment.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Enrollment?> getEnrollment(String studentId, String term) async {
    final json = await ApiClient.get('/student/$studentId/enrollment', query: {'term': term});
    if (json == null) return null;
    return Enrollment.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<List<Announcement>> getAnnouncements() async {
    final json = await ApiClient.get('/announcements');
    return (json as List).map((e) => Announcement.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<NotificationItem>> getNotifications(String studentId) async {
    final json = await ApiClient.get('/student/$studentId/notifications');
    return (json as List).map((e) => NotificationItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<String> askAssistant(String studentId, String question) async {
    // Kept client-side rather than a Flask route — it's pure logic with no
    // persistence of its own. It still reflects real data, since the two
    // network calls below hit the real backend.
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
}

class ApiCashierRepository implements CashierRepository {
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
    final json = await ApiClient.get(
      '/cashier/transactions',
      query: onDate == null ? null : {'date': _dateOnly(onDate)},
    );
    return (json as List).map((e) => Payment.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<double> getDailyCollectionTotal(DateTime date) async {
    final json = await ApiClient.get('/cashier/daily-total', query: {'date': _dateOnly(date)})
        as Map<String, dynamic>;
    return (json['total'] as num).toDouble();
  }

  @override
  Future<Map<String, double>> getCollectionByMethod() async {
    final json = await ApiClient.get('/cashier/collection-by-method') as Map<String, dynamic>;
    return json.map((key, value) => MapEntry(key, (value as num).toDouble()));
  }

  @override
  Future<Map<String, double>> getCollectionTrend({int days = 7}) async {
    final json = await ApiClient.get(
      '/cashier/collection-trend',
      query: {'days': '$days'},
    ) as Map<String, dynamic>;
    return json.map((key, value) => MapEntry(key, (value as num).toDouble()));
  }

  @override
  Future<double> getTotalOutstandingBalance() async {
    final json = await ApiClient.get('/cashier/outstanding-balance') as Map<String, dynamic>;
    return (json['total'] as num).toDouble();
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