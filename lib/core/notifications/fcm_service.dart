import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../providers/feature_providers.dart';
import '../../providers/repository_providers.dart';

/// Background message handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized in the background isolate.
  await Firebase.initializeApp();
  debugPrint('FCM background message: ${message.messageId}');
}

/// Provider for foreground message handling — UI can listen and show local notification.
final fcmForegroundMessageProvider = StateProvider<RemoteMessage?>((ref) => null);

/// Navigation action passed from FCM notification tap.
class FcmNavigationAction {
  const FcmNavigationAction({required this.route, this.params});

  final String route;
  final Map<String, String>? params;
}

/// Provider for navigation actions from FCM/local notification taps.
final fcmNavigationActionProvider = StateProvider<FcmNavigationAction?>((ref) => null);

/// Service that manages Firebase Cloud Messaging lifecycle.
class FcmService {
  FcmService._();

  static final _instance = FcmService._();
  static FcmService get instance => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSub;
  StreamSubscription<String?>? _onTokenRefreshSub;

  bool _initialized = false;
  String? _currentToken;

  /// Initialize FCM: request permission, get token, set up listeners.
  Future<void> initialize(Ref ref) async {
    if (_initialized) return;

    // Request permission (iOS/macOS/Web)
    final settings = await _messaging.requestPermission();
    debugPrint('FCM permission: ${settings.authorizationStatus}');

    // Get initial token
    _currentToken = await _messaging.getToken();
    debugPrint('FCM token: $_currentToken');

    // Listen for token refresh
    _onTokenRefreshSub = _messaging.onTokenRefresh.listen((token) {
      _currentToken = token;
      debugPrint('FCM token refreshed: $token');
      _persistToken(ref, token);
    });

    // Foreground messages
    _onMessageSub = FirebaseMessaging.onMessage.listen((message) {
      debugPrint('FCM foreground message: ${message.messageId}');
      _handleForegroundMessage(ref, message);
    });

    // Background -> app opened via notification tap
    _onMessageOpenedAppSub = FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('FCM notification opened app: ${message.messageId}');
      _handleNotificationTap(ref, message);
    });

    // Handle cold start from notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('FCM cold start from notification: ${initialMessage.messageId}');
      // Defer to next frame so router is ready
      Future.microtask(() => _handleNotificationTap(ref, initialMessage));
    }

    _initialized = true;
  }

  /// Get current FCM token (fetches if not cached).
  Future<String?> getToken() async {
    _currentToken ??= await _messaging.getToken();
    return _currentToken;
  }

  /// Subscribe to a topic (e.g., "announcements", "grade_updates").
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('FCM subscribed to topic: $topic');
  }

  /// Unsubscribe from a topic.
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('FCM unsubscribed from topic: $topic');
  }

  /// Persist token to backend via repository.
  Future<void> _persistToken(Ref ref, String token) async {
    final authState = ref.read(authControllerProvider);
    final user = authState.value;
    if (user != null) {
      await ref.read(notificationRepositoryProvider).saveFcmToken(user.id, token);
    }
  }

  /// Handle foreground message — show local notification, update UI.
  void _handleForegroundMessage(Ref ref, RemoteMessage message) {
    // Delegate to local notifications service for display
    // (import is avoided here to break circular dependency; use a callback pattern)
    ref.read(fcmForegroundMessageProvider.notifier).state = message;
  }

  /// Handle notification tap — navigate to relevant screen.
  void _handleNotificationTap(Ref ref, RemoteMessage message) {
    final data = message.data;
    final route = data['route'];
    final params = data['params'];

    if (route != null) {
      // Use go_router to navigate — requires context.
      // We'll push to a navigation handler provider.
      ref.read(fcmNavigationActionProvider.notifier).state = FcmNavigationAction(
        route: route,
        params: params != null ? Map<String, String>.from(params) : null,
      );
    }
  }

  /// Clean up subscriptions.
  void dispose() {
    _onMessageSub?.cancel();
    _onMessageOpenedAppSub?.cancel();
    _onTokenRefreshSub?.cancel();
    _initialized = false;
  }
}

/// Initialize FCM on app startup (called from main or app bootstrap).
Future<void> initializeFcm(Ref ref) async {
  if (AppConfig.backendMode == BackendMode.mock) {
    debugPrint('FCM skipped: mock backend mode');
    return;
  }
  await FcmService.instance.initialize(ref);
}