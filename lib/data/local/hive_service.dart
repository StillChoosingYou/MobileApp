import 'package:hive_flutter/hive_flutter.dart';

/// Two untyped boxes are enough for this scaffold — everything stored here
/// is a JSON-ish Map (via each model's toJson), so no Hive TypeAdapter
/// codegen is needed. Add typed adapters later only if you need Hive to
/// hold large structured collections offline (e.g. a full grades cache).
class HiveService {
  HiveService._();

  static const sessionBoxName = 'pgpc_session';
  static const settingsBoxName = 'pgpc_settings';

  /// Untyped cache for last-known-good API responses — the offline fallback
  /// when the network is unavailable. Values are JSON-ish Maps/Lists stored by
  /// string key (see `lib/core/network/offline_cache.dart`).
  static const cacheBoxName = 'pgpc_cache';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(sessionBoxName);
    await Hive.openBox(settingsBoxName);
    await Hive.openBox(cacheBoxName);
  }

  static Box get session => Hive.box(sessionBoxName);
  static Box get settings => Hive.box(settingsBoxName);
  static Box get cache => Hive.box(cacheBoxName);
}
