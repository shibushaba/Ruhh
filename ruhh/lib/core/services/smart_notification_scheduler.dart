import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruhh/core/services/reschedule_all_notifications.dart';

/// Schedules reminders respecting enabled modules / toggles.
class SmartNotificationScheduler {
  SmartNotificationScheduler(this._reschedule);

  final RescheduleAllNotifications _reschedule;

  Future<void> refreshAll() => _reschedule.run();
}

final smartNotificationSchedulerProvider =
    FutureProvider<SmartNotificationScheduler>((ref) async {
  final reschedule = await ref.watch(rescheduleAllNotificationsProvider.future);
  return SmartNotificationScheduler(reschedule);
});
