import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

/// Routes notification taps (foreground, background, cold start).
class NotificationNavigation {
  NotificationNavigation._();

  static GoRouter? _router;
  static String? _pendingPayload;

  static void bindRouter(GoRouter router) {
    _router = router;
    final pending = _pendingPayload;
    if (pending != null) {
      _pendingPayload = null;
      _navigate(pending);
    }
  }

  static void handlePayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    if (_router == null) {
      _pendingPayload = payload;
      return;
    }
    _navigate(payload);
  }

  static void _navigate(String payload) {
    final router = _router;
    if (router == null) return;

    try {
      final action = routeActionForPayload(payload);
      if (action == null) {
        if (kDebugMode) {
          debugPrint('Unknown notification payload: $payload');
        }
        return;
      }
      switch (action.kind) {
        case NotificationRouteKind.go:
          router.go(action.path);
        case NotificationRouteKind.push:
          router.push(action.path);
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Notification navigation failed: $e\n$st');
      }
    }
  }

  static Future<void> handleLaunchDetails(
    FlutterLocalNotificationsPlugin plugin,
  ) async {
    final details = await plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      handlePayload(details!.notificationResponse?.payload);
    }
  }
}

enum NotificationRouteKind { go, push }

class NotificationRouteAction {
  const NotificationRouteAction(this.kind, this.path);

  final NotificationRouteKind kind;
  final String path;
}

/// Pure routing table for notification payloads (testable).
NotificationRouteAction? routeActionForPayload(String payload) {
  if (payload.startsWith('/')) {
    return NotificationRouteAction(NotificationRouteKind.go, payload);
  }
  final parts = payload.split(':');
  if (parts.isEmpty) return null;
  switch (parts[0]) {
    case 'prayer':
      return const NotificationRouteAction(NotificationRouteKind.go, '/prayer');
    case 'habit':
      if (parts.length > 1 && parts[1].isNotEmpty) {
        return NotificationRouteAction(
          NotificationRouteKind.push,
          '/habit/${parts[1]}',
        );
      }
      return const NotificationRouteAction(NotificationRouteKind.go, '/habit');
    case 'budget':
      return const NotificationRouteAction(NotificationRouteKind.go, '/budget');
    case 'movie':
      return const NotificationRouteAction(NotificationRouteKind.go, '/movie');
    case 'home':
      return const NotificationRouteAction(NotificationRouteKind.go, '/home');
    default:
      return null;
  }
}

/// Whether the evening streak-protection alarm should be scheduled.
bool shouldScheduleStreakProtection({
  required bool channelEnabled,
  required int habitsDone,
  required int habitsDueToday,
  required bool prayerComplete,
}) {
  if (!channelEnabled) return false;
  if (habitsDueToday > 0 && habitsDone < habitsDueToday) return true;
  if (!prayerComplete) return true;
  return false;
}

/// Budget alert tier for a category after an expense (null = no alert).
String? budgetAlertTier({required double spent, required double limit}) {
  if (limit <= 0) return null;
  final pct = spent / limit;
  if (pct >= 1) return 'over';
  if (pct >= 0.8) return 'nearing';
  return null;
}
