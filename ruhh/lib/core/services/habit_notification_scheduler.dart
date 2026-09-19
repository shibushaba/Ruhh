import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruhh/core/data/models/habit_local.dart';
import 'package:ruhh/core/data/models/habit_reminder.dart';
import 'package:ruhh/core/services/notification_service.dart';
import 'package:ruhh/core/services/reminder_schedule.dart';
import 'package:ruhh/features/habit/habit_extensions.dart';
import 'package:ruhh/features/habit/habit_logic.dart';
import 'package:ruhh/features/habit/habit_repository.dart';
import 'package:ruhh/features/settings/settings_controller.dart';

class HabitNotificationScheduler {
  HabitNotificationScheduler(this._notifications, this._settings);

  final NotificationService _notifications;
  final ModuleSettings _settings;

  Future<void> refreshAll(HabitRepository repo) async {
    if (!_settings.notifyHabit) {
      await _notifications.cancelRange(20000, 29999);
      return;
    }
    final habits = await repo.activeHabits();
    final keep = <int>{};
    for (final h in habits) {
      if (h.isOnVacation) {
        await _cancelForHabit(h);
        continue;
      }
      for (final r in h.reminders) {
        if (r.isInterval) continue;
        for (final wd in r.days) {
          final id = ReminderSchedule.habitReminderId(h.remoteId, r.id, wd);
          keep.add(id);
          await _notifications.scheduleWeekly(
            id: id,
            title: h.name,
            body: r.message.isEmpty ? 'Time for ${h.name}' : r.message,
            weekday: wd,
            hour: r.hour,
            minute: r.minute,
            payload: '/habit',
          );
        }
      }
      if (h.reminders.isEmpty && h.reminderMinute != null) {
        final m = h.reminderMinute!;
        final id = ReminderSchedule.habitReminderId(h.remoteId, 'legacy', 0);
        keep.add(id);
        await _notifications.scheduleDaily(
          id: id,
          title: h.name,
          body: 'Check in on ${h.name}',
          hour: m ~/ 60,
          minute: m % 60,
          payload: '/habit',
        );
      }
    }
    await _notifications.cancelExcept(keep, minId: 20000, maxId: 29999);
  }

  Future<void> _cancelForHabit(HabitLocal h) async {
    for (final r in h.reminders) {
      for (final wd in r.days) {
        await _notifications.cancel(
          ReminderSchedule.habitReminderId(h.remoteId, r.id, wd),
        );
      }
    }
    await _notifications.cancel(
      ReminderSchedule.habitReminderId(h.remoteId, 'legacy', 0),
    );
  }
}

final habitNotificationSchedulerProvider =
    FutureProvider<HabitNotificationScheduler>((ref) async {
  final n = await ref.watch(notificationServiceProvider.future);
  final s = ref.watch(settingsControllerProvider);
  return HabitNotificationScheduler(n, s);
});

Future<void> refreshHabitNotifications(WidgetRef ref) async {
  final sched = await ref.read(habitNotificationSchedulerProvider.future);
  final repo = await ref.read(habitRepositoryProvider.future);
  await sched.refreshAll(repo);
}
