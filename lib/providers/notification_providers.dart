import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/notifications/fcm_service.dart';
import '../core/notifications/local_notifications.dart';
import '../core/notifications/notification_handlers.dart';
import '../data/datasources/fcm_datasource.dart';
import '../models/app_user.dart';
import '../providers/feature_providers.dart';
import '../providers/repository_providers.dart';

// ============================================================================
// FCM Service Providers
// ============================================================================

/// Provider for foreground message handling — UI can listen and show local notification.
/// Defined in fcm_service.dart, re-exported here.

/// Initialize local notifications on app startup.
Future<void> initializeLocalNotifications() async {
  if (AppConfig.backendMode == BackendMode.mock) {
    debugPrint('Local notifications initialized in mock mode');
  }
  await LocalNotificationsService.instance.initialize();
}

/// Initialize all notification handlers (FCM foreground, navigation callbacks).
Future<void> initializeNotificationHandlers(Ref ref) async {
  // Initialize local notifications first
  await initializeLocalNotifications();

  // Set up navigation callback
  NotificationNavigationHandler.instance.initialize();

  // Set up FCM foreground handler
  FcmForegroundHandler.instance.initialize(ref);

  // Set up FCM navigation listener
  NotificationNavigationHandler.instance.listenToFcmActions(ref);
}

/// Provider that triggers FCM initialization on app startup.
/// Use this in a ProviderScope wrapper or app initialization.
final fcmInitializationProvider = FutureProvider<void>((ref) async {
  await initializeFcm(ref);
});

/// Provider that triggers notification handlers initialization.
final notificationHandlersInitializationProvider = FutureProvider<void>((ref) async {
  await initializeNotificationHandlers(ref);
});

// ============================================================================
// FCM Token Management Providers
// ============================================================================

/// Current user's FCM token (updated on refresh).
final currentFcmTokenProvider = StateProvider<String?>((ref) => null);

/// Provider to save FCM token for current user.
final saveFcmTokenProvider = FutureProvider.family<void, String>((ref, token) async {
  final authState = ref.read(authControllerProvider);
  final user = authState.value;
  if (user != null) {
    await ref.read(notificationRepositoryProvider).saveFcmToken(user.id, token);
    ref.read(currentFcmTokenProvider.notifier).state = token;
  }
});

/// Provider to delete FCM token on logout.
final deleteFcmTokenProvider = FutureProvider.family<void, String>((ref, token) async {
  final authState = ref.read(authControllerProvider);
  final user = authState.value;
  if (user != null) {
    await ref.read(notificationRepositoryProvider).deleteFcmToken(user.id, token);
    ref.read(currentFcmTokenProvider.notifier).state = null;
  }
});

/// Provider to delete all FCM tokens for current user (logout).
final deleteAllFcmTokensProvider = FutureProvider<void>((ref) async {
  final authState = ref.read(authControllerProvider);
  final user = authState.value;
  if (user != null) {
    await ref.read(notificationRepositoryProvider).deleteAllFcmTokens(user.id);
    ref.read(currentFcmTokenProvider.notifier).state = null;
  }
});

/// Register current user's FCM token (called after login).
/// Gets token from FCM service and saves to backend.
final registerFcmTokenProvider = FutureProvider.family<void, String>((ref, userId) async {
  if (AppConfig.backendMode == BackendMode.mock) {
    return;
  }
  final token = await FcmService.instance.getToken();
  if (token != null) {
    await ref.read(notificationRepositoryProvider).saveFcmToken(userId, token);
    ref.read(currentFcmTokenProvider.notifier).state = token;
  }
});

/// Unregister all FCM tokens for current user (called on logout).
final unregisterFcmTokenProvider = FutureProvider<void>((ref) async {
  final authState = ref.read(authControllerProvider);
  final user = authState.value;
  if (user != null) {
    await ref.read(notificationRepositoryProvider).deleteAllFcmTokens(user.id);
    ref.read(currentFcmTokenProvider.notifier).state = null;
  }
});

// ============================================================================
// Notification Permission Providers
// ============================================================================

/// Notification permission status.
enum NotificationPermissionStatus {
  granted,
  denied,
  provisional,
  notDetermined,
}

/// Provider for notification permission status.
final notificationPermissionProvider = FutureProvider<NotificationPermissionStatus>((ref) async {
  if (AppConfig.backendMode == BackendMode.mock) {
    return NotificationPermissionStatus.granted; // Mock mode assumes granted
  }

  final messaging = FirebaseMessaging.instance;
  final settings = await messaging.requestPermission();

  switch (settings.authorizationStatus) {
    case AuthorizationStatus.authorized:
      return NotificationPermissionStatus.granted;
    case AuthorizationStatus.denied:
      return NotificationPermissionStatus.denied;
    case AuthorizationStatus.notDetermined:
      return NotificationPermissionStatus.notDetermined;
    case AuthorizationStatus.provisional:
      return NotificationPermissionStatus.provisional;
  }
});

/// Request notification permission.
final requestNotificationPermissionProvider = FutureProvider<NotificationPermissionStatus>((ref) async {
  if (AppConfig.backendMode == BackendMode.mock) {
    return NotificationPermissionStatus.granted;
  }

  final messaging = FirebaseMessaging.instance;
  final settings = await messaging.requestPermission(
    provisional: true,
  );

  switch (settings.authorizationStatus) {
    case AuthorizationStatus.authorized:
      return NotificationPermissionStatus.granted;
    case AuthorizationStatus.denied:
      return NotificationPermissionStatus.denied;
    case AuthorizationStatus.notDetermined:
      return NotificationPermissionStatus.notDetermined;
    case AuthorizationStatus.provisional:
      return NotificationPermissionStatus.provisional;
  }
});

// ============================================================================
// Topic Subscription Providers
// ============================================================================

/// Subscribe to a topic (e.g., "announcements", "grade_updates", "payments").
final subscribeToTopicProvider = FutureProvider.family<void, String>((ref, topic) async {
  if (AppConfig.backendMode == BackendMode.mock) {
    debugPrint('Mock: Subscribed to topic $topic');
    return;
  }

  final authState = ref.read(authControllerProvider);
  final user = authState.value;
  if (user != null) {
    await ref.read(notificationRepositoryProvider).subscribeToTopic(user.id, topic);
    await FirebaseMessaging.instance.subscribeToTopic(topic);
  }
});

/// Unsubscribe from a topic.
final unsubscribeFromTopicProvider = FutureProvider.family<void, String>((ref, topic) async {
  if (AppConfig.backendMode == BackendMode.mock) {
    debugPrint('Mock: Unsubscribed from topic $topic');
    return;
  }

  final authState = ref.read(authControllerProvider);
  final user = authState.value;
  if (user != null) {
    await ref.read(notificationRepositoryProvider).unsubscribeFromTopic(user.id, topic);
    await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
  }
});

/// Common topic names for the app.
class NotificationTopics {
  static const announcements = 'announcements';
  static const gradeUpdates = 'grade_updates';
  static const paymentReminders = 'payment_reminders';
  static const attendance = 'attendance';
  static const calendar = 'calendar';
  static const messages = 'messages';

  /// Get topics relevant to a user's role.
  static List<String> forRole(UserRole role) {
    switch (role) {
      case UserRole.student:
        return [announcements, gradeUpdates, paymentReminders, attendance, calendar, messages];
      case UserRole.teacher:
        return [announcements, attendance, calendar, messages];
      case UserRole.registrar:
      case UserRole.admin:
      case UserRole.dean:
      case UserRole.deptHead:
      case UserRole.accounting:
      case UserRole.guidance:
      case UserRole.cashier:
        return [announcements, messages];
    }
  }
}

// ============================================================================
// Local Notification Providers
// ============================================================================

/// Provider for the local notifications service.
final localNotificationsServiceProvider = Provider<LocalNotificationsService>((ref) {
  return LocalNotificationsService.instance;
});

/// Parameters for scheduling a local notification.
typedef ScheduleLocalNotificationParams = ({
  int id,
  String title,
  String body,
  DateTime scheduledDate,
  String? payload,
  NotificationCategory category,
});

/// Schedule a local notification.
final scheduleLocalNotificationProvider = FutureProvider.family<void, ScheduleLocalNotificationParams>(
  (ref, params) async {
    await ref.read(localNotificationsServiceProvider).schedule(
      id: params.id,
      title: params.title,
      body: params.body,
      scheduledDate: params.scheduledDate,
      payload: params.payload,
      category: params.category,
    );
  },
);

/// Parameters for scheduling a daily reminder.
typedef ScheduleDailyReminderParams = ({
  int id,
  String title,
  String body,
  TimeOfDay time,
  String? payload,
  NotificationCategory category,
});

/// Schedule a daily reminder.
final scheduleDailyReminderProvider = FutureProvider.family<void, ScheduleDailyReminderParams>(
  (ref, params) async {
    await ref.read(localNotificationsServiceProvider).scheduleDaily(
      id: params.id,
      title: params.title,
      body: params.body,
      time: params.time,
      payload: params.payload,
      category: params.category,
    );
  },
);

/// Parameters for scheduling a reminder before an event.
typedef ScheduleEventReminderParams = ({
  int id,
  String title,
  String body,
  DateTime eventTime,
  Duration before,
  String? payload,
  NotificationCategory category,
});

/// Schedule a reminder before an event.
final scheduleEventReminderProvider = FutureProvider.family<void, ScheduleEventReminderParams>(
  (ref, params) async {
    await ref.read(localNotificationsServiceProvider).scheduleBeforeEvent(
      id: params.id,
      title: params.title,
      body: params.body,
      eventTime: params.eventTime,
    before: params.before,
    payload: params.payload,
    category: params.category,
  );
});

/// Cancel a scheduled notification.
final cancelLocalNotificationProvider = FutureProvider.family<void, int>((ref, id) async {
  await ref.read(localNotificationsServiceProvider).cancel(id);
});

/// Cancel all scheduled notifications.
final cancelAllLocalNotificationsProvider = FutureProvider<void>((ref) async {
  await ref.read(localNotificationsServiceProvider).cancelAll();
});

// ============================================================================
// Notification Center Providers (In-App Notification History)
// ============================================================================

/// In-app notification item for the notification center.
@immutable
class InAppNotification {
  const InAppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.timestamp,
    this.isRead = false,
    this.payload,
    this.data,
  });

  final String id;
  final String title;
  final String body;
  final NotificationCategory category;
  final DateTime timestamp;
  final bool isRead;
  final String? payload;
  final Map<String, String>? data;

  InAppNotification copyWith({
    String? id,
    String? title,
    String? body,
    NotificationCategory? category,
    DateTime? timestamp,
    bool? isRead,
    String? payload,
    Map<String, String>? data,
  }) {
    return InAppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      payload: payload ?? this.payload,
      data: data ?? this.data,
    );
  }
}

/// Provider for in-app notification history (loaded from local storage).
final inAppNotificationsProvider = StateNotifierProvider<InAppNotificationsController, AsyncValue<List<InAppNotification>>>((ref) {
  return InAppNotificationsController(ref);
});

class InAppNotificationsController extends StateNotifier<AsyncValue<List<InAppNotification>>> {
  InAppNotificationsController(this.ref) : super(const AsyncValue.loading()) {
    loadNotifications();
  }

  final Ref ref;

  Future<void> loadNotifications() async {
    state = const AsyncValue.loading();
    try {
      // In a real app, load from Hive/SharedPreferences
      // For now, return empty list
      state = const AsyncValue.data([]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addNotification(InAppNotification notification) async {
    final current = state.value ?? [];
    final updated = [notification, ...current].take(100).toList(); // Keep last 100
    state = AsyncValue.data(updated);
    await _persist(updated);
  }

  Future<void> markAsRead(String id) async {
    final current = state.value ?? [];
    final updated = current.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList();
    state = AsyncValue.data(updated);
    await _persist(updated);
  }

  Future<void> markAllAsRead() async {
    final current = state.value ?? [];
    final updated = current.map((n) => n.copyWith(isRead: true)).toList();
    state = AsyncValue.data(updated);
    await _persist(updated);
  }

  Future<void> deleteNotification(String id) async {
    final current = state.value ?? [];
    final updated = current.where((n) => n.id != id).toList();
    state = AsyncValue.data(updated);
    await _persist(updated);
  }

  Future<void> clearAll() async {
    state = const AsyncValue.data([]);
    await _persist(const []);
  }

  Future<void> _persist(List<InAppNotification> notifications) async {
    // In a real app, save to Hive/SharedPreferences
    // For mock, we just keep in memory
  }
}

/// Unread notification count for badge.
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(inAppNotificationsProvider);
  return notifications.when(
    data: (list) => list.where((n) => !n.isRead).length,
    loading: () => 0,
    error: (error, stack) => 0,
  );
});

// ============================================================================
// FCM Datasource Providers
// ============================================================================

/// Provider for the FCM token datasource.
final fcmTokenDatasourceProvider = Provider<FcmTokenDatasource>((ref) {
  return FcmTokenDatasource();
});

/// Initialize the datasource on app startup.
final initializeFcmTokenDatasourceProvider = FutureProvider<void>((ref) async {
  if (AppConfig.backendMode == BackendMode.mock) {
    await FcmTokenDatasource().init();
  }
});

// ============================================================================
// Helper Extensions
// ============================================================================

extension StringNullOrBlank on String? {
  bool get isNullOrBlank => this == null || this!.trim().isEmpty;
}