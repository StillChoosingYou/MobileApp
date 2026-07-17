/// Central switches for the app. Flip these once your own backend is ready —
/// nothing else in the codebase needs to change, because every screen talks
/// to a repository *interface*, never to Firebase or mock data directly.
class AppConfig {
  AppConfig._();

  /// When false (the default), every repository is backed by in-memory mock
  /// data seeded in `lib/data/repositories/mock_seed_data.dart`. The app is
  /// fully interactive this way with zero setup — good for demos, UI review,
  /// and offline development.
  ///
  /// When true, repositories that have a Firebase implementation
  /// (see `lib/data/repositories/firebase_repositories_example.dart`) talk to
  /// your real Firebase project instead. Requires:
  ///   1. `flutterfire configure` run in this project (generates
  ///      lib/firebase_options.dart)
  ///   2. The matching uncomment in lib/core/firebase/firebase_init.dart
  static const bool useFirebase = false;

  /// Toggles the PayMongo-backed cashier flow. Off by default because it
  /// needs a real PayMongo account + API keys (see PaymentGatewayService).
  static const bool useRealPaymentGateway = false;

  static const String appName = 'PGPC Campus';
  static const String collegeFullName = 'Padre Garcia Polytechnic College';

  /// Academic term shown across mock data / headers. Update per term.
  static const String currentTermLabel = 'A.Y. 2026–2027, 1st Semester';
}
