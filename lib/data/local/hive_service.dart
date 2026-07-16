import 'package:hive_flutter/hive_flutter.dart';

/// Two untyped boxes are enough for this scaffold — everything stored here
/// is a JSON-ish Map (via each model's toJson), so no Hive TypeAdapter
/// codegen is needed. Add typed adapters later only if you need Hive to
/// hold large structured collections offline (e.g. a full grades cache).
class HiveService {
  HiveService._();

  static const sessionBoxName = 'pgpc_session';
  static const settingsBoxName = 'pgpc_settings';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(sessionBoxName);
    await Hive.openBox(settingsBoxName);
  }

  static Box get session => Hive.box(sessionBoxName);
  static Box get settings => Hive.box(settingsBoxName);
}
