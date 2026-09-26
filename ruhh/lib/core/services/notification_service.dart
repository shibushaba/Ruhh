import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:ruhh/core/services/notification_channels.dart';
import 'package:ruhh/core/services/notification_navigation.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService(this._plugin, {required this.enabled});

  final FlutterLocalNotificationsPlugin _plugin;
  final bool enabled;

  FlutterLocalNotificationsPlugin get plugin => _plugin;

  static Future<void> configureTimeZones() async {
    tz.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Timezone fallback to local offset: $e');
      }
      tz.setLocalLocation(tz.local);
    }
  }

  static Future<NotificationService> create() async {
    await configureTimeZones();
    final plugin = FlutterLocalNotificationsPlugin();
    var enabled = false;

    void onResponse(NotificationResponse r) {
      NotificationNavigation.handlePayload(r.payload);
    }

    if (Platform.isAndroid) {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      await plugin.initialize(
        const InitializationSettings(android: android),
        onDidReceiveNotificationResponse: onResponse,
        onDidReceiveBackgroundNotificationResponse: onBackgroundNotification,
      );
      enabled = true;
    } else if (Platform.isIOS) {
      await plugin.initialize(
        const InitializationSettings(
          iOS: DarwinInitializationSettings(),
        ),
        onDidReceiveNotificationResponse: onResponse,
      );
      enabled = true;
    }

    await NotificationNavigation.handleLaunchDetails(plugin);
    return NotificationService(plugin, enabled: enabled);
  }

  Future<bool> canScheduleExact() async {
    if (!Platform.isAndroid) return true;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.canScheduleExactNotifications() ?? false;
  }

  AndroidScheduleMode _scheduleMode() {
    if (!Platform.isAndroid) return AndroidScheduleMode.exactAllowWhileIdle;
    return AndroidScheduleMode.exactAllowWhileIdle;
  }

  NotificationDetails _details(String channelId) => NotificationDetails(
        android: RuhhNotificationChannels.androidDetails(channelId),
        iOS: const DarwinNotificationDetails(),
      );

  Future<void> cancelAllPending() async {
    if (!enabled) return;
    await _plugin.cancelAll();
  }

  Future<void> showInstant({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = RuhhNotificationChannels.system,
  }) async {
    if (!enabled) return;
    await _plugin.show(
      id,
      title,
      body,
      _details(channelId),
      payload: payload,
    );
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
    String channelId = RuhhNotificationChannels.habit,
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
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      _details(channelId),
      androidScheduleMode: _scheduleMode(),
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
    String channelId = RuhhNotificationChannels.habit,
  }) async {
    if (!enabled) return;
    final scheduled = tz.TZDateTime.from(when, tz.local);
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      _details(channelId),
      androidScheduleMode: _scheduleMode(),
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
    String channelId = RuhhNotificationChannels.system,
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
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      _details(channelId),
      androidScheduleMode: _scheduleMode(),
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }
}

@pragma('vm:entry-point')
void onBackgroundNotification(NotificationResponse response) {
  NotificationNavigation.handlePayload(response.payload);
}

final notificationServiceProvider =
    FutureProvider<NotificationService>((ref) async {
  return NotificationService.create();
});
