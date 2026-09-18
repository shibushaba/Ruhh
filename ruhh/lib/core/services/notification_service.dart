import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static Future<NotificationService> create() async {
    tz.initializeTimeZones();
    final plugin = FlutterLocalNotificationsPlugin();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: android);
    await plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (_) {},
    );
    return NotificationService(plugin);
  }

  Future<void> showInstant({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
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

  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
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
