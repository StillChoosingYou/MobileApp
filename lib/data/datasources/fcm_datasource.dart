import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/config/app_config.dart';

/// Local storage for FCM tokens using Hive.
/// Used when backend is in mock mode or for offline token persistence.
class FcmTokenDatasource {
  static const _boxName = 'fcm_tokens';
  static const _tokenKey = 'user_tokens';

  Box<Map>? _box;

  Future<void> init() async {
    _box = await Hive.openBox<Map>(_boxName);
  }

  /// Save a token for a user (supports multiple devices).
  Future<void> saveToken(String userId, String token) async {
    if (_box == null) await init();
    final tokens = Map<String, List<String>>.from(_box!.get(_tokenKey) ?? {});
    final userTokens = tokens[userId] ?? [];
    if (!userTokens.contains(token)) {
      userTokens.add(token);
      tokens[userId] = userTokens;
      await _box!.put(_tokenKey, tokens);
    }
  }

  /// Remove a specific token for a user.
  Future<void> removeToken(String userId, String token) async {
    if (_box == null) await init();
    final tokens = Map<String, List<String>>.from(_box!.get(_tokenKey) ?? {});
    final userTokens = tokens[userId] ?? [];
    userTokens.remove(token);
    if (userTokens.isEmpty) {
      tokens.remove(userId);
    } else {
      tokens[userId] = userTokens;
    }
    await _box!.put(_tokenKey, tokens);
  }

  /// Remove all tokens for a user (on logout).
  Future<void> removeAllTokens(String userId) async {
    if (_box == null) await init();
    final tokens = Map<String, List<String>>.from(_box!.get(_tokenKey) ?? {});
    tokens.remove(userId);
    await _box!.put(_tokenKey, tokens);
  }

  /// Get all tokens for a user.
  Future<List<String>> getTokens(String userId) async {
    if (_box == null) await init();
    final tokens = Map<String, List<String>>.from(_box!.get(_tokenKey) ?? {});
    return List<String>.from(tokens[userId] ?? []);
  }

  /// Clear all stored tokens.
  Future<void> clearAll() async {
    if (_box == null) await init();
    await _box!.clear();
  }
}

/// Provider for the FCM token datasource.
final fcmTokenDatasourceProvider = Provider<FcmTokenDatasource>((ref) {
  return FcmTokenDatasource();
});

/// Initialize the datasource on app startup.
Future<void> initializeFcmTokenDatasource() async {
  if (AppConfig.backendMode == BackendMode.mock) {
    await FcmTokenDatasource().init();
  }
}