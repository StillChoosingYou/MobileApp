import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/route_names.dart';
import 'fcm_service.dart';
import 'local_notifications.dart';

/// Handles FCM foreground messages by showing local notifications.
class FcmForegroundHandler {
  FcmForegroundHandler._();

  static final _instance = FcmForegroundHandler._();
  static FcmForegroundHandler get instance => _instance;

  final LocalNotificationsService _local = LocalNotificationsService.instance;
  int _notificationId = 0;

  /// Call this once during app initialization to set up the listener.
  void initialize(Ref ref) {
    ref.listen<RemoteMessage?>(fcmForegroundMessageProvider, (prev, next) {
      if (next != null) {
        _showLocalNotification(ref, next);
      }
    });
  }

  void _showLocalNotification(Ref ref, RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    final title = notification?.title ?? data['title'] ?? 'PGPC Campus';
    final body = notification?.body ?? data['body'] ?? 'You have a new notification';

    // Determine category from data
    final category = (data['category'] ?? '').asNotificationCategory;

    // Generate unique ID
    final id = _notificationId++;

    // Payload for navigation on tap
    final route = data['route'] ?? '';
    final params = data['params'] ?? '';
    final payload = route.isNotEmpty ? 'route=$route&params=$params' : null;

    _local.show(
      id: id,
      title: title,
      body: body,
      payload: payload,
      category: category,
    );
  }
}

/// Handles navigation from FCM/local notification taps.
class NotificationNavigationHandler {
  NotificationNavigationHandler._();

  static final _instance = NotificationNavigationHandler._();
  static NotificationNavigationHandler get instance => _instance;

  /// Set up navigation callback for local notifications.
  void initialize() {
    LocalNotificationsService.instance.setNavigationCallback(_handlePayload);
  }

  /// Call this once during app initialization to listen for FCM navigation actions.
  void listenToFcmActions(Ref ref) {
    ref.listen<FcmNavigationAction?>(fcmNavigationActionProvider, (prev, next) {
      if (next != null) {
        _navigate(next.route, next.params);
        // Clear after handling
        ref.read(fcmNavigationActionProvider.notifier).state = null;
      }
    });
  }

  void _handlePayload(String payload) {
    // Parse payload: "route=/path&params=key=value,key2=value2"
    final uri = Uri.parse('app://?$payload');
    final route = uri.queryParameters['route'] ?? '';
    final paramsStr = uri.queryParameters['params'] ?? '';

    Map<String, String>? params;
    if (paramsStr.isNotEmpty) {
      params = {};
      for (final pair in paramsStr.split(',')) {
        final parts = pair.split('=');
        if (parts.length == 2) {
          params[parts[0]] = parts[1];
        }
      }
    }

    _navigate(route, params);
  }

  void _navigate(String route, Map<String, String>? params) {
    if (_routerDelegate != null) {
      final context = _getContextFromRouterDelegate();
      if (context != null) {
        if (params != null && params.isNotEmpty) {
          final queryParams = params.map((k, v) => MapEntry(k, v));
          context.push(route, extra: queryParams);
        } else {
          context.push(route);
        }
      } else {
        // Fallback: store for next navigation
        _pendingNavigation = (route, params);
      }
    } else {
      // Router delegate not set yet, store for later
      _pendingNavigation = (route, params);
    }
  }

  BuildContext? _getContextFromRouterDelegate() {
    try {
      // Try to get the navigator from the router delegate
      if (_routerDelegate is GoRouterDelegate) {
        return _routerDelegate!.navigatorKey.currentContext;
      }
    } catch (_) {}
    return null;
  }

  /// Pending navigation for when context becomes available.
  (String route, Map<String, String>? params)? _pendingNavigation;

  /// Try to execute pending navigation (call when router is ready).
  void tryPendingNavigation(BuildContext context) {
    if (_pendingNavigation != null) {
      final (route, params) = _pendingNavigation!;
      if (params != null && params.isNotEmpty) {
        final queryParams = params.map((k, v) => MapEntry(k, v));
        context.push(route, extra: queryParams);
      } else {
        context.push(route);
      }
      _pendingNavigation = null;
    }
  }

  /// Setter for the global router delegate.
  set routerDelegate(GoRouterDelegate? delegate) => _routerDelegate = delegate;

  /// Getter for the global router delegate.
  GoRouterDelegate? get routerDelegate => _routerDelegate;
}

/// Global router delegate reference for navigation without context.
/// Set this in app.dart after MaterialApp.router is built.
GoRouterDelegate? _routerDelegate;

/// Route handlers for specific notification types.
extension NotificationRouteHandler on String {
  /// Parse a notification route and return the go_router path.
  String get notificationRoute {
    switch (this) {
      case 'announcement':
        return Routes.student; // Announcements are on student home
      case 'grade':
        return Routes.student; // Grades tab
      case 'payment':
        return Routes.student; // Tuition tab
      case 'attendance':
        return Routes.student; // Attendance tab
      case 'message':
        return '/messages'; // Messages tab (to be added)
      case 'calendar':
        return '/calendar'; // Calendar tab (to be added)
      case 'enrollment':
        return Routes.student; // Enrollment tab
      default:
        return Routes.roleSelect;
    }
  }
}