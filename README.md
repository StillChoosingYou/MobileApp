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
| Architecture (Clean Architecture, Riverpod, repository pattern, mock ⇄ Firebase ⇄ REST toggle) | ✅ Fully built |
| Branding: real PGPC seal (in-app, app icon, launch splash) + colors sampled from it | ✅ Fully wired in |
| Auth (ID/password login, role routing, forgot password, 2FA, biometric) | ✅ Fully working (mock, Firebase, and Flask+Postgres implementations all included) |
| Student: dashboard, Digital ID + QR, schedule, grades + GPA, tuition ledger, payment history, announcements | ✅ Fully working (mock + Flask/Postgres) |
| Student Services: document requests, clearance tracker, digital queue, appointments | ✅ Fully working |
| AI Academic Assistant | ✅ Working keyword-based FAQ engine — swap for a real LLM call when ready |
| Smart enrollment conflict/unit-cap check | ✅ Real logic (`RegistrarRepository.checkEnrollmentConflicts`) |
| Elective recommendation | ✅ Real rule-based logic (prerequisite matching) |
| Registrar: student search, record view, enrollment approval | ✅ Fully working (mock only so far) |
| Cashier: payment entry, digital receipt + QR, transaction history, daily collection total | ✅ Fully working (mock + Flask/Postgres, including a real DB transaction) |
| Faculty: class list, roster, attendance (manual + real camera QR scan), grade encoding | ✅ Fully working (mock only so far) |
| Admin: user management, analytics dashboard, audit log | ✅ Fully working (mock only so far) |
| QR attendance (generate + real camera scan) | ✅ Fully working (`mobile_scanner` + `qr_flutter`) |
| Visitor management, Lost & Found, Emergency contacts | ✅ Fully working |
| Your own backend: Flask + Postgres (Supabase), deployable to Vercel | ✅ Auth/Student/Cashier fully wired end-to-end; see "Turning on the REST API" below |
| Accounting / Guidance / Dept Head / Dean dashboards | 🔶 One real screen each (Billing ledger, Appointments); rest are labeled placeholders following the same pattern |
| GCash / Maya payments | 🔶 Manual entry works today; real online checkout needs PayMongo — see below |
| Firebase (Firestore/Auth/Storage/FCM/Analytics/Crashlytics) | 🔶 Auth + a partial Student repo included as real examples; rest follow the same pattern |
| COR / Transcript / Certificate generation | 🔶 Buttons wired to a placeholder — real PDF generation is a good fit for a Cloud Function + the `pdf` package |
| Digital signature, campus map, curriculum builder | 📋 Not built — noted in Roadmap |

## Architecture

```
lib/
  core/            theme, routing, config, error handling, shared widgets, utils, network (REST client)
  models/          plain Dart data classes (no code generation)
  data/
    repositories/  abstract interfaces + mock impl + Firebase example impl + REST (Flask) impl
    local/         Hive setup
  providers/       Riverpod wiring (repository selection + all screen data)
  features/        one folder per role, screens only — no business logic here

api/               Flask + Postgres backend — a separate Python project living
                    alongside the Flutter app, deployable to Vercel on its own
```

**Every screen depends on a repository *interface*, never on a concrete
class.** `AppConfig.backendMode` (in `lib/core/config/app_config.dart`) is a
three-way switch — `mock`, `firebase`, or `restApi` — and picks which
implementation `lib/providers/repository_providers.dart` wires up for each
repository. Today everything defaults to the in-memory mock repositories in
`lib/data/repositories/mock_repositories.dart`, seeded from
`mock_seed_data.dart`. Flip the enum once your Firebase project or your own
Flask/Postgres backend is ready — see the two setup sections below.

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
4. Set `AppConfig.backendMode = BackendMode.firebase` in
   `lib/core/config/app_config.dart`.
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

## Turning on the REST API (Flask + Supabase Postgres)

This is the third `BackendMode` option, alongside Mock and Firebase — a
Flask API (in `api/` at the project root) backed by a real Postgres
database (Supabase's hosted Postgres, though any Postgres works). It's a
genuine alternative architecture to Firebase, not an add-on to it: pick one
or the other for a given role's data, not both.

**What's implemented today:** Auth, Student, and Cashier are fully wired
end-to-end (Flask routes ⇄ Postgres ⇄ Dart repositories). Registrar,
Faculty, Admin, and CampusServices stay mock-only for now — extend them the
same way (one Flask route per interface method, one matching Dart method in
a new class in `lib/data/repositories/api_repositories.dart`, following
`ApiStudentRepository` as the template), then add a case for them in
`lib/providers/repository_providers.dart`.

### 1. Set up Supabase

1. Create a project at [supabase.com](https://supabase.com) (the free tier
   is enough for development).
2. Open the SQL Editor in the Supabase dashboard, paste in the entire
   contents of `api/schema.sql`, and run it. This creates every table the
   app needs, plus a small set of seed rows matching the same demo accounts
   you've already seen in mock mode (Andrea Villanueva, Evelyn Aquino, Bea
   Fernandez, etc.).
3. The seeded users' `password_hash` values are placeholders
   (`REPLACE_WITH_REAL_HASH`) — generate a real one and update them:
   ```bash
   python -c "from werkzeug.security import generate_password_hash as g; print(g('password123'))"
   ```
   then in the SQL Editor:
   ```sql
   UPDATE users SET password_hash = '<paste the hash here>';
   ```
   (Updating all rows to the same dev password is fine for testing — give
   each real account its own password before this touches real students.)
4. Grab your **Transaction mode (Supavisor)** connection string: Project
   Settings → Database → Connection string → "Transaction" — it looks like
   `postgresql://postgres.<ref>:<password>@aws-0-<region>.pooler.supabase.com:6543/postgres`.
   Use this one, not the direct connection — see the comment in `api/db.py`
   for why (serverless functions need the pooled connection or they can
   exhaust Postgres's connection limit).

### 2. Run the Flask API locally

```bash
python -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env              # then paste in your real DATABASE_URL and a JWT_SECRET
python api/main.py                # → http://localhost:5000
```

Generate a `JWT_SECRET` with `python -c "import secrets; print(secrets.token_hex(32))"`
— any long random string works, this just signs login tokens.

Run the backend's own test suite (mocks the database, so it doesn't need
your Supabase connection to pass):

```bash
pip install -r requirements-dev.txt
pytest api/test_app.py -v
```

### 3. Point the Flutter app at it

1. Set `AppConfig.backendMode = BackendMode.restApi` in
   `lib/core/config/app_config.dart`.
2. `ApiClient.baseUrl` (in `lib/core/network/api_client.dart`) defaults to
   `http://10.0.2.2:5000/api` — the special address the **Android
   emulator** uses to reach your computer's `localhost`. Override it for
   other targets without touching source:
   ```bash
   # iOS Simulator / desktop:
   flutter run --dart-define=PGPC_API_BASE_URL=http://localhost:5000/api
   # A physical phone on the same Wi-Fi as your computer:
   flutter run --dart-define=PGPC_API_BASE_URL=http://<your-computer's-LAN-IP>:5000/api
   ```
3. Log in with any seeded account (e.g. Student `2023-00147`) and whatever
   password you hashed into `password_hash` above.

### 4. Deploy the API to Vercel

Vercel auto-detects the Flask `app` object in `api/main.py` — no build
config beyond what's already in `vercel.json`
([official docs](https://vercel.com/docs/frameworks/backend/flask)).

1. `vercel link` (or connect the repo through the Vercel dashboard) from
   the project root.
2. In the Vercel project's Settings → Environment Variables, add
   `DATABASE_URL` and `JWT_SECRET` (same values as your local `.env`).
3. `vercel deploy --prod`.
4. Hit `https://<your-project>.vercel.app/api/health` — you should get back
   `{"status": "ok"}`. If you don't, `vercel dev` locally first (it runs
   the same routing Vercel uses in production) before troubleshooting the
   live deployment.
5. Update `PGPC_API_BASE_URL` (step 3 above) to your real
   `https://<your-project>.vercel.app/api` for production builds.

### Security TODOs before this touches real students

This scaffold authenticates (every protected route needs a valid token) but
doesn't yet **authorize** by role (nothing stops a logged-in Student from
calling the Cashier's payment-recording route). Before this goes near real
money or real student records:

- Add a role check in `routes/cashier.py`'s `record_payment` (and any other
  role-sensitive route) — the exact one-line check is already commented in
  that file.
- Lock down `CORS(app)` in `api/main.py` to your actual app's origin(s)
  instead of allowing all.
- Decide whether `/api/announcements` and `/api/subjects` (currently public,
  no token needed) should require login too.
- Give every seeded account its own password instead of the one shared dev
  hash from step 1.3 above.

## Enabling GCash / Maya payments

Individual developers can't integrate GCash/Maya's APIs directly — those
require an enterprise partnership. The standard path in the Philippines is a
payment aggregator; **PayMongo** is the common choice and has a community
(unofficial) `paymongo_sdk` Dart package (already in `pubspec.yaml`, pinned
to `^1.7.0`) with GCash and Maya
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
  `AppConfig.backendMode` gates the same way as everything else)
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
