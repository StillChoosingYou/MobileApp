import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/constants/firestore_collections.dart';
import '../../core/error/result.dart';
import '../../models/app_user.dart';
import '../../models/academic_models.dart';
import '../../models/campus_models.dart';
import '../../models/financial_models.dart';
import 'repository_interfaces.dart';

/// A real implementation, ready to use once `AppConfig.backendMode = BackendMode.firebase`
/// and `flutterfire configure` has been run. Firebase Auth signs in by
/// email, so login-by-student-number/employee-ID first resolves the email
/// via a Firestore lookup, then authenticates normally.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Future<Result<AppUser>> login({
    required UserRole role,
    required String loginId,
    required String password,
  }) async {
    try {
      final query = await _firestore
          .collection(FirestoreCollections.users)
          .where('loginId', isEqualTo: loginId.trim())
          .where('role', isEqualTo: role.name)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return Result.error('No ${role.label} account found for that ID.');
      }

      final data = query.docs.first.data();
      final email = data['email'] as String;

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        return Result.error('Sign-in failed. Please try again.');
      }

      return Result.ok(AppUser.fromJson(data));
    } on FirebaseAuthException catch (e) {
      return Result.error(e.message ?? 'Sign-in failed. Please check your credentials.');
    } catch (_) {
      return Result.error('Something went wrong. Please try again.');
    }
  }

  @override
  Future<Result<bool>> requestPasswordReset(String emailOrLoginId) async {
    try {
      String email = emailOrLoginId;
      if (!emailOrLoginId.contains('@')) {
        final query = await _firestore
            .collection(FirestoreCollections.users)
            .where('loginId', isEqualTo: emailOrLoginId.trim())
            .limit(1)
            .get();
        if (query.docs.isEmpty) {
          return Result.error('We could not find an account with that ID.');
        }
        email = query.docs.first.data()['email'] as String;
      }
      await _auth.sendPasswordResetEmail(email: email);
      return Result.ok(true);
    } on FirebaseAuthException catch (e) {
      return Result.error(e.message ?? 'Could not send the reset email.');
    }
  }

  @override
  Future<bool> isBiometricEnabled(String loginId) async {
    final query = await _firestore
        .collection(FirestoreCollections.users)
        .where('loginId', isEqualTo: loginId.trim())
        .limit(1)
        .get();
    if (query.docs.isEmpty) return false;
    return query.docs.first.data()['biometricEnabled'] as bool? ?? false;
  }

  @override
  Future<Result<bool>> enableBiometric(String loginId) async {
    try {
      final query = await _firestore
          .collection(FirestoreCollections.users)
          .where('loginId', isEqualTo: loginId.trim())
          .limit(1)
          .get();
      if (query.docs.isEmpty) return Result.error('Account not found.');
      await query.docs.first.reference.update({'biometricEnabled': true});
      return Result.ok(true);
    } catch (_) {
      return Result.error('Could not enable biometric login.');
    }
  }
}

/// Partial example — `getGrades`, `getAnnouncements`, `getLedger`, and
/// `getEnrolledSections` show the real Firestore read pattern. The rest
/// throw [UnimplementedError] with a pointer back to that same pattern;
/// fill them in the same way before switching `AppConfig.backendMode` to `BackendMode.firebase`
/// for the Student module.
class FirestoreStudentRepository implements StudentRepository {
  FirestoreStudentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static Never _todo(String method) => throw UnimplementedError(
        '$method: implement following the Firestore read pattern used in '
        'getGrades()/getAnnouncements() in this same file.',
      );

  @override
  Future<List<Grade>> getGrades(String studentId) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.grades)
        .doc(studentId)
        .collection('records')
        .get();

    return snapshot.docs.map((doc) {
      final d = doc.data();
      return Grade(
        subjectCode: d['subjectCode'] as String,
        subjectTitle: d['subjectTitle'] as String,
        units: (d['units'] as num).toDouble(),
        term: d['term'] as String,
        numericGrade: (d['numericGrade'] as num?)?.toDouble(),
        isIncomplete: d['isIncomplete'] as bool? ?? false,
      );
    }).toList();
  }

  @override
  Future<List<Announcement>> getAnnouncements() async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.announcements)
        .orderBy('postedAt', descending: true)
        .limit(50)
        .get();

    return snapshot.docs.map((doc) {
      final d = doc.data();
      return Announcement(
        id: doc.id,
        title: d['title'] as String,
        body: d['body'] as String,
        category: d['category'] as String,
        postedAt: (d['postedAt'] as Timestamp).toDate(),
      );
    }).toList();
  }

  @override
  Future<TuitionLedger> getLedger(String studentId, String term) async {
    final doc = await _firestore
        .collection(FirestoreCollections.ledgers)
        .doc('${studentId}_$term')
        .get();

    final d = doc.data();
    if (d == null) {
      return TuitionLedger(
        studentId: studentId,
        term: term,
        tuitionFee: 0,
        miscFees: 0,
        labFees: 0,
        scholarshipDiscount: 0,
        totalPaid: 0,
      );
    }
    return TuitionLedger(
      studentId: studentId,
      term: term,
      tuitionFee: (d['tuitionFee'] as num).toDouble(),
      miscFees: (d['miscFees'] as num).toDouble(),
      labFees: (d['labFees'] as num).toDouble(),
      scholarshipDiscount: (d['scholarshipDiscount'] as num).toDouble(),
      totalPaid: (d['totalPaid'] as num).toDouble(),
    );
  }

  @override
  Future<List<Section>> getEnrolledSections(String studentId, String term) async {
    final enrollmentQuery = await _firestore
        .collection(FirestoreCollections.enrollments)
        .where('studentId', isEqualTo: studentId)
        .where('term', isEqualTo: term)
        .limit(1)
        .get();

    if (enrollmentQuery.docs.isEmpty) return [];
    final sectionIds = List<String>.from(enrollmentQuery.docs.first.data()['sectionIds'] as List);
    if (sectionIds.isEmpty) return [];

    final sectionsQuery = await _firestore
        .collection(FirestoreCollections.sections)
        .where(FieldPath.documentId, whereIn: sectionIds)
        .get();

    return sectionsQuery.docs.map((doc) {
      final d = doc.data();
      return Section(
        id: doc.id,
        subjectCode: d['subjectCode'] as String,
        sectionLabel: d['sectionLabel'] as String,
        facultyName: d['facultyName'] as String,
        dayPattern: d['dayPattern'] as String,
        startTime: d['startTime'] as String,
        endTime: d['endTime'] as String,
        room: d['room'] as String,
        slotsTotal: d['slotsTotal'] as int,
        slotsTaken: d['slotsTaken'] as int,
      );
    }).toList();
  }

  @override
  Future<StudentProfile?> getStudentProfile(String studentId) => _todo('getStudentProfile');

  @override
  Future<List<Payment>> getPaymentHistory(String studentId) => _todo('getPaymentHistory');

  @override
  Future<Enrollment?> getEnrollment(String studentId, String term) => _todo('getEnrollment');

  @override
  Future<List<NotificationItem>> getNotifications(String studentId) =>
      _todo('getNotifications');

  @override
  Future<String> askAssistant(String studentId, String question) =>
      _todo('askAssistant (wire this to a real LLM API instead of Firestore)');

  @override
  Future<List<Subject>> recommendElectives(String studentId) => _todo('recommendElectives');
}
