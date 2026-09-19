import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruhh/core/services/habit_notification_scheduler.dart';
import 'package:ruhh/core/services/notification_service.dart';
import 'package:ruhh/features/habit/habit_repository.dart';
import 'package:ruhh/features/settings/settings_controller.dart';

/// Schedules baseline reminders respecting enabled modules / toggles.
class SmartNotificationScheduler {
  SmartNotificationScheduler(
    this._notifications,
    this._settings,
    this._habitScheduler,
    this._habitRepo,
  );

  final NotificationService _notifications;
  final ModuleSettings _settings;
  final HabitNotificationScheduler _habitScheduler;
  final HabitRepository _habitRepo;

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
    if (_settings.notifyHabit) {
      await _habitScheduler.refreshAll(_habitRepo);
    } else {
      await _notifications.cancelRange(20000, 29999);
    }
  }
}

final smartNotificationSchedulerProvider =
    FutureProvider<SmartNotificationScheduler>((ref) async {
  final notifications = await ref.watch(notificationServiceProvider.future);
  final settings = ref.watch(settingsControllerProvider);
  final habitSched = await ref.watch(habitNotificationSchedulerProvider.future);
  final habitRepo = await ref.watch(habitRepositoryProvider.future);
  return SmartNotificationScheduler(
    notifications,
    settings,
    habitSched,
    habitRepo,
  );
});
