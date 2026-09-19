import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService(this._plugin, {required this.enabled});

  final FlutterLocalNotificationsPlugin _plugin;
  final bool enabled;

  static Future<NotificationService> create() async {
    tz.initializeTimeZones();
    final plugin = FlutterLocalNotificationsPlugin();
    var enabled = false;

    if (Platform.isAndroid) {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      await plugin.initialize(
        const InitializationSettings(android: android),
        onDidReceiveNotificationResponse: (_) {},
      );
      enabled = true;
    } else if (Platform.isIOS) {
      await plugin.initialize(
        const InitializationSettings(
          iOS: DarwinInitializationSettings(),
        ),
        onDidReceiveNotificationResponse: (_) {},
      );
      enabled = true;
    }

    return NotificationService(plugin, enabled: enabled);
  }

  Future<void> showInstant({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!enabled) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'ruhh_general',
        'RUHH Reminders',
        channelDescription: 'Smart reminders across trackers',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    );
    await _plugin.show(id, title, body, details, payload: payload);
  }

  Future<void> cancel(int id) async {
    if (!enabled) return;
    await _plugin.cancel(id);
  }

  Future<void> cancelRange(int minId, int maxId) async {
    if (!enabled) return;
    for (var i = minId; i <= maxId; i++) {
      await _plugin.cancel(i);
    }
  }

  Future<void> cancelExcept(Set<int> keep, {required int minId, required int maxId}) async {
    if (!enabled) return;
    for (var i = minId; i <= maxId; i++) {
      if (!keep.contains(i)) await _plugin.cancel(i);
    }
  }

  Future<void> scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required int weekday,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    if (!enabled) return;
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    while (scheduled.weekday != weekday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
      scheduled = tz.TZDateTime(
        tz.local,
        scheduled.year,
        scheduled.month,
        scheduled.day,
        hour,
        minute,
      );
    }
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'ruhh_habit',
        'Habit reminders',
        channelDescription: 'Per-habit scheduled reminders',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: payload,
    );
  }

  Future<void> scheduleTodoAt({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    String? payload,
  }) async {
    if (!enabled) return;
    final scheduled = tz.TZDateTime.from(when, tz.local);
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'ruhh_todo',
        'Todo reminders',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    if (!enabled) return;
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'ruhh_scheduled',
        'RUHH Scheduled',
        channelDescription: 'Scheduled tracker reminders',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }
}

final notificationServiceProvider =
    FutureProvider<NotificationService>((ref) async {
  return NotificationService.create();
});
