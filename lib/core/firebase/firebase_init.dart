// Kept import-free by default so the project compiles with zero Firebase
// setup. Once you've run `flutterfire configure` (which generates
// lib/firebase_options.dart), do this:
//
//   1. Uncomment the two imports below.
//   2. Uncomment the body of initializeFirebase().
//   3. Flip AppConfig.useFirebase to true.
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
