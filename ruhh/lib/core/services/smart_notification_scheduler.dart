import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruhh/core/services/notification_service.dart';
import 'package:ruhh/features/settings/settings_controller.dart';

/// Schedules baseline reminders respecting enabled modules / toggles.
class SmartNotificationScheduler {
  SmartNotificationScheduler(this._notifications, this._settings);

  final NotificationService _notifications;
  final ModuleSettings _settings;

  Future<void> refreshAll() async {
    if (_settings.notifyBudget && _settings.budgetEnabled) {
      await _notifications.scheduleDaily(
        id: 1001,
        title: 'Log today\'s spending',
        body: 'No expenses logged yet — add a quick transaction.',
        hour: 20,
        minute: 0,
        payload: '/budget',
      );
    }
    if (_settings.notifyPrayer) {
      await _notifications.scheduleDaily(
        id: 1002,
        title: 'Prayer reminder',
        body: 'Check in with today\'s salah.',
        hour: 12,
        minute: 30,
        payload: '/prayer',
      );
    }
    if (_settings.notifyMovie) {
      await _notifications.scheduleDaily(
        id: 1003,
        title: 'Watch something tonight?',
        body: 'Pick a title from your watchlist.',
        hour: 19,
        minute: 0,
        payload: '/movie',
      );
    }
  }
}

final smartNotificationSchedulerProvider =
    FutureProvider<SmartNotificationScheduler>((ref) async {
  final notifications = await ref.watch(notificationServiceProvider.future);
  final settings = ref.watch(settingsControllerProvider);
  return SmartNotificationScheduler(notifications, settings);
});
