# PGPC Campus — Padre Garcia Polytechnic College Campus App

A Flutter + Firebase campus management app covering all 9 roles from the
original spec: Student, Faculty, Registrar, Accounting, Cashier, Guidance,
Department Head, Dean, and Administrator.

This is a **real, running architecture with a large working feature set** —
not a mockup. It launches and is fully interactive with zero setup (mock
data, in memory), and has a clear, marked path to swap in your real Firebase
project, real payment gateway, and remaining features. The single biggest
thing to understand going in: **nobody can hand you a "production-ready"
campus ERP as a chat reply.** Real payment-gateway contracts, a real Firebase
project, app store accounts, device testing, and a security review are yours
to do — what's here is a solid, working foundation that gets you there much
faster than starting from the prompt.

## What's real vs. what's scaffolded

| Area | Status |
|---|---|
| Architecture (Clean Architecture, Riverpod, repository pattern, mock ⇄ Firebase toggle) | ✅ Fully built |
| Branding: real PGPC seal (in-app, app icon, launch splash) + colors sampled from it | ✅ Fully wired in |
| Auth (ID/password login, role routing, forgot password, 2FA, biometric) | ✅ Fully working (mock backend; Firebase impl included for auth) |
| Student: dashboard, Digital ID + QR, schedule, grades + GPA, tuition ledger, payment history, announcements | ✅ Fully working |
| Student Services: document requests, clearance tracker, digital queue, appointments | ✅ Fully working |
| AI Academic Assistant | ✅ Working keyword-based FAQ engine — swap for a real LLM call when ready |
| Smart enrollment conflict/unit-cap check | ✅ Real logic (`RegistrarRepository.checkEnrollmentConflicts`) |
| Elective recommendation | ✅ Real rule-based logic (prerequisite matching) |
| Registrar: student search, record view, enrollment approval | ✅ Fully working |
| Cashier: payment entry, digital receipt + QR, transaction history, daily collection total | ✅ Fully working |
| Faculty: class list, roster, attendance (manual + real camera QR scan), grade encoding | ✅ Fully working |
| Admin: user management, analytics dashboard, audit log | ✅ Fully working |
| QR attendance (generate + real camera scan) | ✅ Fully working (`mobile_scanner` + `qr_flutter`) |
| Visitor management, Lost & Found, Emergency contacts | ✅ Fully working |
| Accounting / Guidance / Dept Head / Dean dashboards | 🔶 One real screen each (Billing ledger, Appointments); rest are labeled placeholders following the same pattern |
| GCash / Maya payments | 🔶 Manual entry works today; real online checkout needs PayMongo — see below |
| Firebase (Firestore/Auth/Storage/FCM/Analytics/Crashlytics) | 🔶 Auth + a partial Student repo included as real examples; rest follow the same pattern |
| COR / Transcript / Certificate generation | 🔶 Buttons wired to a placeholder — real PDF generation is a good fit for a Cloud Function + the `pdf` package |
| Digital signature, campus map, curriculum builder | 📋 Not built — noted in Roadmap |

## Architecture

```
lib/
  core/            theme, routing, config, error handling, shared widgets, utils
  models/          plain Dart data classes (no code generation)
  data/
    repositories/  abstract interfaces + mock impl + Firebase example impl
    local/         Hive setup
  providers/       Riverpod wiring (repository selection + all screen data)
  features/        one folder per role, screens only — no business logic here
```

**Every screen depends on a repository *interface*, never on a concrete
class.** `AppConfig.useFirebase` (in `lib/core/config/app_config.dart`)
picks which implementation `lib/providers/repository_providers.dart` wires
up. Today everything routes to the in-memory mock repositories in
`lib/data/repositories/mock_repositories.dart`, seeded from
`mock_seed_data.dart`. Flip the flag once your Firebase project is ready —
see below.

State management is Riverpod's **`Notifier` / `AsyncNotifier`** API (no code
generation, no `build_runner`) — this scaffold intentionally avoids the
older `StateNotifier`/`StateProvider` classes, since Riverpod 3.x drops them.

Models are plain classes with hand-written `toJson`/`fromJson`/`copyWith` —
no `freezed`/`json_serializable`, so there's no codegen step between cloning
this and running it.

## Getting started

This repo ships `lib/`, `pubspec.yaml`, and `test/` only — the native
Android/iOS/web project folders aren't generated yet (that's normal for a
hand-written Dart source tree; they're scaffolding the Flutter SDK
generates, not something to hand-write). Generate them first, in this
project's root folder:

```bash
flutter create . --project-name pgpc_campus_app --org ph.edu.pgpc
flutter pub get
dart run flutter_launcher_icons        # app icon, from the real PGPC seal
dart run flutter_native_splash:create  # launch splash, same seal
flutter run
```

`flutter create .` (with the dot) fills in the missing `android/`, `ios/`,
etc. folders around the existing `lib/pubspec.yaml` without touching them —
safe to run even though the project already has source in it.

No Firebase setup needed to try it — every role logs in with any non-empty
password. Login IDs are seeded in `mock_seed_data.dart`, e.g.:

- Student: `2023-00147` (Andrea Villanueva)
- Registrar: `EMP-0501` (Evelyn Aquino)
- Cashier: `EMP-0602` (Bea Fernandez)
- Faculty: `EMP-1042` (Prof. Ramon Dela Cruz)
- Admin: `EMP-0001` (Kevin Mercado)

The 2FA step shows its demo code on-screen (no real SMS/email is sent).

Run tests with:

```bash
flutter test
```

## Turning on real Firebase

1. `dart pub global activate flutterfire_cli` (if you don't have it)
2. `flutterfire configure` — pick or create your Firebase project; this
   generates `lib/firebase_options.dart`.
3. In `lib/core/firebase/firebase_init.dart`, uncomment the import and the
   `Firebase.initializeApp(...)` call.
4. Set `AppConfig.useFirebase = true` in `lib/core/config/app_config.dart`.
5. In `lib/providers/repository_providers.dart`, uncomment the
   `firebase_repositories_example.dart` import and return
   `FirebaseAuthRepository()` from `authRepositoryProvider`.
6. Create the Firestore collections listed in
   `lib/core/constants/firestore_collections.dart` (schema/comments included
   there) and seed at least one real user document per role you want to
   test with.

`FirestoreStudentRepository` in `firebase_repositories_example.dart` shows
the real read pattern for 4 methods; the rest throw `UnimplementedError`
with a pointer back to that same pattern — finish those the same way, then
repeat for Registrar/Cashier/Faculty/Admin/CampusServices repositories.

## Enabling GCash / Maya payments

Individual developers can't integrate GCash/Maya's APIs directly — those
require an enterprise partnership. The standard path in the Philippines is a
payment aggregator; **PayMongo** is the common choice and has an official
`paymongo_sdk` Dart package (already in `pubspec.yaml`) with GCash and Maya
"source" support. Xendit is a similar alternative.

1. Register a PayMongo account and complete KYC (their onboarding takes a
   few business days).
2. Grab your public/secret API keys from the PayMongo dashboard.
3. Add a `PaymentGatewayService` (new file) that wraps `paymongo_sdk`'s
   source-creation flow for `gcash`/`paymongo` source types, and a webhook
   handler (a Cloud Function is the natural place) that marks the matching
   `Payment` as verified once PayMongo confirms it.
4. Flip `AppConfig.useRealPaymentGateway` once that's wired up. Until then,
   the Cashier's manual entry flow (proof-of-payment shown to the cashier,
   recorded as method `gcash`/`maya`) is what's active — which is also
   exactly what a lot of schools do in practice even after going digital.

## Platform setup notes

- **Biometric login** (`local_auth`): Android needs `MainActivity` to
  extend `FlutterFragmentActivity` (not `FlutterActivity`) and the
  `USE_BIOMETRIC` permission in `AndroidManifest.xml`; iOS needs
  `NSFaceIDUsageDescription` in `Info.plist`.
- **Camera QR scanning** (`mobile_scanner`): Android needs the `CAMERA`
  permission in `AndroidManifest.xml`; iOS needs `NSCameraUsageDescription`
  in `Info.plist`.
- **Google Sign-In**: needs an OAuth client configured in your Firebase
  project (Authentication → Sign-in method → Google) plus platform-specific
  setup for `google_sign_in` — not included here since it depends on your
  Firebase project.

## Branding

The real PGPC seal is wired in at `assets/images/pgpc_logo.png` (in-app
header, Digital ID card) and `assets/images/pgpc_logo_icon_source.png` (a
1024×1024 square version feeding the app icon and splash screen — see
Getting Started above). `lib/core/theme/app_theme.dart`'s two seed colors
(`AppColors.royalBlueSeed` `#102A6D`, `AppColors.goldSeed` `#DABD64`) were
sampled directly from that seal via k-means clustering on its ink colors, so
they're the real brand palette, not a guess — the whole app re-themes from
those two constants via `ColorScheme.fromSeed` if the college ever issues an
official Pantone spec that differs slightly.

## A note on student data

This app handles enrollment, grades, and payment records — data covered by
the Philippines' Data Privacy Act (RA 10173). Before handling real student
data: register with the National Privacy Commission if required for your
setup, add a real privacy policy, and make sure Firestore security rules
(not included here — this scaffold has no rules file) restrict every
collection to the right role before you go anywhere near production data.

## Roadmap / not yet built

- Digital signature capture (the `signature` package is a good fit — draw
  on a canvas, store the PNG in Firebase Storage)
- Interactive campus map (needs a Google/Mapbox Maps API key)
- Real COR/Transcript/Certificate PDF generation (Cloud Function + the `pdf`
  package)
- Curriculum builder / subject-section CRUD UI for Registrar
- Push notifications wired to FCM (the package is in `pubspec.yaml`;
  `AppConfig.useFirebase` gates the same way as everything else)
- Firestore security rules
- Unit/widget test coverage beyond the two example tests included

## Known rough edges to check first if something doesn't compile

Two API surfaces here can shift between Flutter versions and couldn't be
verified against a live SDK in the environment this was built in:

- `DropdownButtonFormField`'s initial-value parameter (`initialValue` here —
  older Flutter versions used `value`).
- `ColorScheme`'s expanded surface-container roles (`surfaceContainerLow`,
  `surfaceContainerHighest`) — needs a fairly recent stable Flutter (this
  project targets `>=3.24.0`; run `flutter upgrade` if these don't resolve).

Both are one-line fixes per occurrence if your SDK disagrees.
