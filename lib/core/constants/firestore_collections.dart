/// Suggested Firestore schema (each a top-level collection unless noted).
/// This is the schema the example Firebase repositories in
/// `firebase_repositories_example.dart` assume — adjust to taste, this is a
/// starting point, not a migration you're locked into.
///
/// users/{uid}                    — AppUser.toJson(), doc id = Firebase Auth uid
/// studentProfiles/{studentId}    — program, yearLevel, blockSection, scholarshipLabel
/// subjects/{code}                — catalog subjects
/// sections/{sectionId}           — offered classes, references subjectCode
/// enrollments/{enrollmentId}     — studentId, term, sectionIds[], status
/// grades/{studentId}/records/{gradeId}  — per-student subcollection
/// payments/{paymentId}           — studentId, amount, method, receiptNumber...
/// ledgers/{studentId}_{term}     — tuition assessment + running totalPaid
/// announcements/{id}             — title, body, category, postedAt
/// notifications/{studentId}/items/{id}  — per-student subcollection
/// documentRequests/{id}          — studentId, type, status
/// clearances/{studentId}_{term}  — steps[]
/// queues/{office}/tickets/{id}   — per-office subcollection, watch with
///                                  .orderBy('issuedAt').snapshots()
/// appointments/{id}
/// auditLog/{id}
/// visitorLogs/{id}
/// lostFoundItems/{id}
class FirestoreCollections {
  FirestoreCollections._();

  static const users = 'users';
  static const studentProfiles = 'studentProfiles';
  static const subjects = 'subjects';
  static const sections = 'sections';
  static const enrollments = 'enrollments';
  static const grades = 'grades';
  static const payments = 'payments';
  static const ledgers = 'ledgers';
  static const announcements = 'announcements';
  static const notifications = 'notifications';
  static const documentRequests = 'documentRequests';
  static const clearances = 'clearances';
  static const queues = 'queues';
  static const appointments = 'appointments';
  static const auditLog = 'auditLog';
  static const visitorLogs = 'visitorLogs';
  static const lostFoundItems = 'lostFoundItems';
}
