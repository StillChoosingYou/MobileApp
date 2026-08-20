import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../config/app_config.dart';

/// Service for displaying local notifications (works offline, no FCM needed).
class LocalNotificationsService {
  LocalNotificationsService._();

  static final _instance = LocalNotificationsService._();
  static LocalNotificationsService get instance => _instance;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Initialize the local notifications plugin.
  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
      macOS: iosInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: _onNotificationTap,
    );

    // Request exact alarm permission on Android 12+
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestExactAlarmsPermission();
    }

    _initialized = true;
    debugPrint('Local notifications initialized');
  }

  /// Show an immediate notification.
  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationCategory category = NotificationCategory.general,
  }) async {
    await _show(
      id: id,
      title: title,
      body: body,
      payload: payload,
      category: category,
      scheduledDate: null,
    );
  }

  /// Schedule a notification for a future time.
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    NotificationCategory category = NotificationCategory.general,
  }) async {
    await _show(
      id: id,
      title: title,
      body: body,
      payload: payload,
      category: category,
      scheduledDate: scheduledDate,
    );
  }

  /// Cancel a scheduled notification by ID.
  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }

  /// Cancel all scheduled notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Get pending notification requests (for debugging).
  Future<List<PendingNotificationRequest>> getPending() async {
    return _plugin.pendingNotificationRequests();
  }

  /// Schedule a recurring daily reminder.
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    String? payload,
    NotificationCategory category = NotificationCategory.general,
  }) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      _buildDetails(category),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // daily
      payload: payload,
    );
  }

  /// Schedule a reminder before an event (e.g., 30 min before class).
  Future<void> scheduleBeforeEvent({
    required int id,
    required String title,
    required String body,
    required DateTime eventTime,
    required Duration before,
    String? payload,
    NotificationCategory category = NotificationCategory.general,
  }) async {
    final scheduledDate = eventTime.subtract(before);
    if (scheduledDate.isBefore(DateTime.now())) {
      debugPrint('Skipped past reminder for $title');
      return;
    }
    await schedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      payload: payload,
      category: category,
    );
  }

  Future<void> _show({
    required int id,
    required String title,
    required String body,
    String? payload,
    required NotificationCategory category,
    DateTime? scheduledDate,
  }) async {
    if (!_initialized) await initialize();

    final details = _buildDetails(category);

    if (scheduledDate != null) {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } else {
      await _plugin.show(id, title, body, details, payload: payload);
    }
  }

  NotificationDetails _buildDetails(NotificationCategory category) {
    final androidDetails = AndroidNotificationDetails(
      _channelId(category),
      _channelName(category),
      channelDescription: _channelDescription(category),
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF102A6D), // AppColors.royalBlueSeed
      colorized: true,
      visibility: NotificationVisibility.public,
      category: _androidCategory(category),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
    );

    return NotificationDetails(android: androidDetails, iOS: iosDetails, macOS: iosDetails);
  }

  String _channelId(NotificationCategory category) => 'pgpc_${category.name}';
  String _channelName(NotificationCategory category) => 'PGPC ${category.label}';
  String _channelDescription(NotificationCategory category) => 'Notifications for ${category.label.toLowerCase()}';

  AndroidNotificationCategory? _androidCategory(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.announcement:
        return AndroidNotificationCategory.recommendation;
      case NotificationCategory.gradeUpdate:
        return AndroidNotificationCategory.status;
      case NotificationCategory.paymentReminder:
        return AndroidNotificationCategory.reminder;
      case NotificationCategory.attendance:
        return AndroidNotificationCategory.call;
      case NotificationCategory.message:
        return AndroidNotificationCategory.message;
      case NotificationCategory.calendar:
        return AndroidNotificationCategory.event;
      case NotificationCategory.general:
        return null;
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Local notification tapped: ${response.payload}');
    // Navigation is handled by the app's router via a provider callback
    // (set up in app.dart or a navigation service)
    if (response.payload != null) {
      _navigationCallback?.call(response.payload!);
    }
  }

  /// Optional callback for navigation — set by the app on startup.
  void Function(String payload)? _navigationCallback;

  void setNavigationCallback(void Function(String payload) callback) {
    _navigationCallback = callback;
  }
}

/// Categories for notification channels and styling.
enum NotificationCategory {
  general('General'),
  announcement('Announcements'),
  gradeUpdate('Grade Updates'),
  paymentReminder('Payment Reminders'),
  attendance('Attendance'),
  message('Messages'),
  calendar('Calendar');

  const NotificationCategory(this.label);
  final String label;
}

/// Extension to parse category from string (e.g., from FCM data).
extension NotificationCategoryX on String? {
  NotificationCategory get asNotificationCategory {
    if (this == null) return NotificationCategory.general;
    return NotificationCategory.values.firstWhere(
      (c) => c.name == this,
      orElse: () => NotificationCategory.general,
    );
  }
}

/// Provider for the local notifications service.
final localNotificationsServiceProvider = Provider<LocalNotificationsService>((ref) {
  return LocalNotificationsService.instance;
});

/// Initialize local notifications on app startup.
Future<void> initializeLocalNotifications() async {
  if (AppConfig.backendMode == BackendMode.mock) {
    debugPrint('Local notifications initialized in mock mode');
  }
  await LocalNotificationsService.instance.initialize();
}