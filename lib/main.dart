import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/firebase/firebase_init.dart';
import 'data/local/hive_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();

  if (AppConfig.backendMode == BackendMode.firebase) {
    await initializeFirebase();
  }

  runApp(const ProviderScope(child: PgpcCampusApp()));
}
