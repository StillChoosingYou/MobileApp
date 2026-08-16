import '../../data/local/hive_service.dart';

/// Read-through cache for the REST repositories' last-known-good responses.
///
/// The REST backend (`AppConfig.backendMode == BackendMode.restApi`) reads live
/// data; when the network is down, `ApiClient` surfaces an [ApiException] and
/// the repository falls back to whatever we last persisted here — so screens
/// still render (stale, but usable) instead of an error. The mock backend
/// never touches this; it has no network to lose.
///
/// Keys are free-form strings the repositories define per call (e.g.
/// `student_profile:2023-00147`). Values are JSON-ish Maps/Lists. No Hive
/// TypeAdapters are needed — everything stored here is already JSON-serializable.
class OfflineCache {
  OfflineCache._();
  static final OfflineCache instance = OfflineCache._();

  static const String _staleSuffix = '__savedAt';

  /// Persist a successful response. Call this from a repository right after a
  /// successful network read. Swallows any Hive error so caching never breaks
  /// the happy path.
  void save(String key, dynamic value) {
    try {
      HiveService.cache.put(key, value);
      HiveService.cache.put('$key$_staleSuffix', DateTime.now().toIso8601String());
    } catch (_) {
      // Non-fatal: a cache miss just means we show an error if we go offline.
    }
  }

  /// Return the last cached value for [key], or `null` if none.
  dynamic get(String key) {
    try {
      return HiveService.cache.get(key);
    } catch (_) {
      return null;
    }
  }

  /// When the value was last saved, or `null` if never cached.
  DateTime? savedAt(String key) {
    final raw = HiveService.cache.get('$key$_staleSuffix') as String?;
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  /// True when cached data exists for [key].
  bool has(String key) => get(key) != null;
}