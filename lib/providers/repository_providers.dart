import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../data/repositories/repository_interfaces.dart';
import '../data/repositories/mock_repositories.dart';
import '../data/repositories/api_repositories.dart';
// Once `flutterfire configure` has been run and AppConfig.backendMode is
// set to BackendMode.firebase, uncomment this import and the branch it
// enables below.
// import '../data/repositories/firebase_repositories_example.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  switch (AppConfig.backendMode) {
    case BackendMode.mock:
      return MockAuthRepository();
    case BackendMode.restApi:
      return ApiAuthRepository();
    case BackendMode.firebase:
      throw UnimplementedError(
        'Uncomment the firebase_repositories_example import above and return '
        'FirebaseAuthRepository() here.',
      );
    // return FirebaseAuthRepository();
  }
});

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  switch (AppConfig.backendMode) {
    case BackendMode.mock:
      return MockStudentRepository();
    case BackendMode.restApi:
      return ApiStudentRepository();
    case BackendMode.firebase:
      // Swap for FirestoreStudentRepository() once you've finished the
      // remaining methods flagged with UnimplementedError in
      // firebase_repositories_example.dart.
      throw UnimplementedError('Return FirestoreStudentRepository() here.');
  }
});

final registrarRepositoryProvider = Provider<RegistrarRepository>((ref) {
  // Registrar stays mock-only for now — follow the pattern in
  // api_repositories.dart (ApiStudentRepository) to add a REST-backed
  // version: one Flask route per interface method in api/routes/, one
  // matching method here calling ApiClient.
  return MockRegistrarRepository();
});

final cashierRepositoryProvider = Provider<CashierRepository>((ref) {
  switch (AppConfig.backendMode) {
    case BackendMode.mock:
      return MockCashierRepository();
    case BackendMode.restApi:
      return ApiCashierRepository();
    case BackendMode.firebase:
      throw UnimplementedError('No Firebase Cashier implementation yet.');
  }
});

final facultyRepositoryProvider = Provider<FacultyRepository>((ref) {
  // Faculty stays mock-only for now — same extension pattern as Registrar above.
  return MockFacultyRepository();
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  // Admin stays mock-only for now — same extension pattern as Registrar above.
  return MockAdminRepository();
});

/// Single repository backing announcements, document requests, clearance,
/// the digital queue, appointments, visitor logs, and lost & found — these
/// are grouped because they're all "campus services" rather than belonging
/// to one role. Stays mock-only for now — same extension pattern as
/// Registrar above.
final campusServicesRepositoryProvider = Provider<CampusServicesRepository>((ref) {
  return MockCampusServicesRepository();
});
