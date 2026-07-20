// Kept import-free by default so the project compiles with zero Firebase
// setup — the firebase_* packages are currently commented out in
// pubspec.yaml (their native plugin code broke both the Windows and Web
// builds on this project's Flutter SDK version). Once you've decided to
// take that on and run `flutterfire configure` (which generates
// lib/firebase_options.dart), do this:
//
//   1. Uncomment the firebase_* dependencies in pubspec.yaml, then
//      `flutter pub get`.
//   2. Uncomment the two imports below.
//   3. Uncomment the body of initializeFirebase().
//   4. Flip AppConfig.backendMode to BackendMode.firebase.
//
// import 'package:firebase_core/firebase_core.dart';
// import '../../firebase_options.dart';

Future<void> initializeFirebase() async {
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );
  throw UnimplementedError(
    'Run `flutterfire configure` in this project, then uncomment the code '
    'in lib/core/firebase/firebase_init.dart.',
  );
}
