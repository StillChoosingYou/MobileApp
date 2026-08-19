import 'hive_service.dart';
import '../../models/app_user.dart';

/// Local-only tutorial completion state, persisted in Hive.
/// Key format: `${userId}_${roleName}` — one flag per (user, role) pair.
/// Works fully offline, no backend sync required.
class TutorialStateService {
  TutorialStateService._();

  /// Check if a specific tutorial has been completed for (user, role).
  static Future<bool> isCompleted(String userId, UserRole role) async {
    final box = HiveService.tutorialState;
    final key = _key(userId, role);
    return box.get(key, defaultValue: false) as bool;
  }

  /// Mark a tutorial as completed for (user, role).
  static Future<void> markCompleted(String userId, UserRole role) async {
    final box = HiveService.tutorialState;
    final key = _key(userId, role);
    await box.put(key, true);
  }

  /// Reset a tutorial so it can be replayed (used by "Replay tutorial" menu entry).
  static Future<void> reset(String userId, UserRole role) async {
    final box = HiveService.tutorialState;
    final key = _key(userId, role);
    await box.delete(key);
  }

  /// Check if the app-level first-launch intro has been seen.
  static Future<bool> isAppIntroSeen() async {
    final box = HiveService.tutorialState;
    return box.get('app_intro_seen', defaultValue: false) as bool;
  }

  /// Mark the app-level intro as seen.
  static Future<void> markAppIntroSeen() async {
    final box = HiveService.tutorialState;
    await box.put('app_intro_seen', true);
  }

  /// Reset app-level intro (for testing or on-demand replay).
  static Future<void> resetAppIntro() async {
    final box = HiveService.tutorialState;
    await box.delete('app_intro_seen');
  }

  static String _key(String userId, UserRole role) => '${userId}_${role.name}';
}