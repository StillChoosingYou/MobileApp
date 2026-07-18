/// Which backend every repository provider talks to. See
/// `lib/providers/repository_providers.dart` — each repository provider
/// switches on this to pick its concrete implementation. Screens never
/// check this directly; they only ever see the repository *interface*.
enum BackendMode {
  /// In-memory mock data, seeded in
  /// `lib/data/repositories/mock_seed_data.dart`. Fully interactive with
  /// zero setup — good for demos, UI review, and offline development.
  mock,

  /// Firebase (Firestore/Auth). See
  /// `lib/data/repositories/firebase_repositories_example.dart`. Requires
  /// `flutterfire configure` and the matching uncomment in
  /// `lib/core/firebase/firebase_init.dart`.
  firebase,

  /// Your own Flask + Postgres (Supabase) REST API. See
  /// `lib/data/repositories/api_repositories.dart` and `api/` at the
  /// project root. Requires `ApiClient.baseUrl` to point at your running
  /// Flask server (local or deployed on Vercel) and the Postgres schema in
  /// `api/schema.sql` to be applied to your Supabase database.
  restApi,
}

/// Central switches for the app. Flip [backendMode] once your own backend
/// is ready — nothing else in the codebase needs to change, because every
/// screen talks to a repository *interface*, never to Firebase, Postgres,
/// or mock data directly.
class AppConfig {
  AppConfig._();

  static const BackendMode backendMode = BackendMode.mock;

  /// Toggles the PayMongo-backed cashier flow. Off by default because it
  /// needs a real PayMongo account + API keys (see PaymentGatewayService).
  static const bool useRealPaymentGateway = false;

  static const String appName = 'PGPC Campus';
  static const String collegeFullName = 'Padre Garcia Polytechnic College';

  /// Academic term shown across mock data / headers. Update per term.
  static const String currentTermLabel = 'A.Y. 2026–2027, 1st Semester';
}
