import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../data/repositories/repository_interfaces.dart';
import '../data/repositories/mock_repositories.dart';
// Once `flutterfire configure` has been run and AppConfig.useFirebase is
// flipped to true, uncomment this import and the two lines it enables below.
// import '../data/repositories/firebase_repositories_example.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConfig.useFirebase) {
    throw UnimplementedError(
      'Uncomment the firebase_repositories_example import above and return '
      'FirebaseAuthRepository() here.',
    );
    // return FirebaseAuthRepository();
  }
  return MockAuthRepository();
});

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  // Swap for FirestoreStudentRepository() once AppConfig.useFirebase is on
  // and you've finished the remaining methods flagged with UnimplementedError.
  return MockStudentRepository();
});

final registrarRepositoryProvider = Provider<RegistrarRepository>((ref) {
  return MockRegistrarRepository();
});

final cashierRepositoryProvider = Provider<CashierRepository>((ref) {
  return MockCashierRepository();
});

final facultyRepositoryProvider = Provider<FacultyRepository>((ref) {
  return MockFacultyRepository();
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return MockAdminRepository();
});

/// Single repository backing announcements, document requests, clearance,
/// the digital queue, appointments, visitor logs, and lost & found — these
/// are grouped because they're all "campus services" rather than belonging
/// to one role.
final campusServicesRepositoryProvider = Provider<CampusServicesRepository>((ref) {
  return MockCampusServicesRepository();
});
