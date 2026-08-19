import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/tutorial_state.dart';
import '../../models/app_user.dart';

/// Provider for the tutorial state service (Hive-backed, offline-first).
/// Uses the static methods directly since TutorialStateService has a private constructor.
final tutorialStateServiceProvider = Provider<void>((ref) {
  // Service uses static methods only; no instance needed.
});

/// Checks if the app-level first-launch onboarding has been seen.
final appIntroSeenProvider = FutureProvider<bool>((ref) async {
  return TutorialStateService.isAppIntroSeen();
});

/// Marks the app-level intro as seen.
final markAppIntroSeenProvider = Provider<Future<void> Function()>((ref) {
  return () => TutorialStateService.markAppIntroSeen();
});

/// Resets the app-level intro (for testing or replay).
final resetAppIntroProvider = Provider<Future<void> Function()>((ref) {
  return () => TutorialStateService.resetAppIntro();
});

/// Checks if a role-specific tutorial has been completed for the current user.
final roleTutorialCompletedProvider = FutureProvider.family<bool, ({String userId, UserRole role})>((ref, params) async {
  return TutorialStateService.isCompleted(params.userId, params.role);
});

/// Marks a role-specific tutorial as completed.
final markRoleTutorialCompletedProvider = Provider<Function>((ref) {
  return (String userId, UserRole role) =>
      TutorialStateService.markCompleted(userId, role);
});

/// Resets a role-specific tutorial so it can be replayed (used by "Replay tutorial" menu).
final resetRoleTutorialProvider = Provider<Function>((ref) {
  return (String userId, UserRole role) =>
      TutorialStateService.reset(userId, role);
});

/// Combined provider that gives tutorial status for the current authenticated user + role.
///
/// Usage:
/// ```dart
/// final tutorialStatus = ref.watch(currentUserTutorialStatusProvider);
/// tutorialStatus.when(
///   data: (status) {
///     if (!status.appIntroSeen) showAppOnboarding();
///     if (!status.roleTutorialCompleted) showRoleTutorial();
///   },
///   loading: () => const CircularProgressIndicator(),
///   error: (e, _) => Text('Error: $e'),
/// );
/// ```
final currentUserTutorialStatusProvider = FutureProvider<TutorialStatus>((ref) async {
  // This would typically come from your auth provider
  // For now, we'll expose a way to check with explicit parameters
  throw UnimplementedError('Use explicit providers with userId/role parameters');
});

/// Tutorial status for a specific user+role combination.
class TutorialStatus {
  const TutorialStatus({
    required this.appIntroSeen,
    required this.roleTutorialCompleted,
  });

  final bool appIntroSeen;
  final bool roleTutorialCompleted;

  bool get needsAppIntro => !appIntroSeen;
  bool get needsRoleTutorial => !roleTutorialCompleted;
  bool get needsAnyTutorial => needsAppIntro || needsRoleTutorial;
}

/// Provider to check tutorial status for a specific user+role.
final tutorialStatusProvider = FutureProvider.family<TutorialStatus, ({String userId, UserRole role})>((ref, params) async {
  final appIntroSeen = await TutorialStateService.isAppIntroSeen();
  final roleCompleted = await TutorialStateService.isCompleted(params.userId, params.role);
  return TutorialStatus(
    appIntroSeen: appIntroSeen,
    roleTutorialCompleted: roleCompleted,
  );
});