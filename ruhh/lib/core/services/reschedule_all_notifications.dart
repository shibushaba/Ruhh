import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruhh/core/data/models/prayer_local.dart';
import 'package:ruhh/core/services/habit_notification_scheduler.dart';
import 'package:ruhh/core/services/notification_channels.dart';
import 'package:ruhh/core/services/notification_navigation.dart';
import 'package:ruhh/core/services/notification_prefs.dart';
import 'package:ruhh/core/services/notification_service.dart';
import 'package:ruhh/features/habit/habit_repository.dart';
import 'package:ruhh/features/habit/tracker/habit_calculations.dart';
import 'package:ruhh/features/prayer/prayer_repository.dart';
import 'package:ruhh/features/prayer/tracker/prayer_calculations.dart';
import 'package:ruhh/features/prayer/tracker/prayer_domain.dart';
import 'package:ruhh/features/prayer/tracker/prayer_theme.dart';
import 'package:ruhh/features/settings/settings_controller.dart';

/// Cancels all pending notifications and rebuilds today + tomorrow schedules.
class RescheduleAllNotifications {
  RescheduleAllNotifications(
    this._notifications,
    this._settings,
    this._habitScheduler,
    this._habitRepo,
    this._prayerRepo,
  );

  final NotificationService _notifications;
  final ModuleSettings _settings;
  final HabitNotificationScheduler _habitScheduler;
  final HabitRepository _habitRepo;
  final PrayerRepository _prayerRepo;

  static const streakTaskId = 1004;
  static const recommendationsId = 1005;
  static const systemPermissionId = 1006;
  static const prayerIdBase = 30000;

  Future<void> run() async {
    await _notifications.cancelAllPending();

    if (_settings.notifyPrayer) {
      await _schedulePrayerWindow();
    }
    if (_settings.notifyHabit) {
      await _habitScheduler.refreshAll(_habitRepo);
    } else {
      await _notifications.cancelRange(20000, 29999);
    }

    await syncStreakProtectionAlarm();

    if (_settings.notifyRecommendations) {
      await _notifications.scheduleWeekly(
        id: recommendationsId,
        title: 'Your week in RUHH',
        body: 'See what stood out across habits, prayer, and more.',
        weekday: DateTime.sunday,
        hour: 19,
        minute: 0,
        payload: '/home',
        channelId: RuhhNotificationChannels.recommendations,
      );
    }
  }

  /// Exact daily alarm at the user's streak time; cancelled when today is complete.
  Future<void> syncStreakProtectionAlarm() async {
    await _notifications.cancel(streakTaskId);
    if (!_settings.notifyStreakProtection) return;
    if (!await _hasOpenItemsToday()) return;

    final minute = await NotificationPrefs.streakMinuteOfDay();
    final body = await _openStreakSummary();
    await _notifications.scheduleDaily(
      id: streakTaskId,
      title: 'Finish strong tonight',
      body: body,
      hour: minute ~/ 60,
      minute: minute % 60,
      payload: 'home',
      channelId: RuhhNotificationChannels.streak,
    );
  }

  /// Backup if the exact alarm was dropped (battery/OS); only near streak time.
  Future<void> maybeFireStreakProtectionNow() async {
    if (!_settings.notifyStreakProtection) return;
    final minute = await NotificationPrefs.streakMinuteOfDay();
    final now = DateTime.now();
    final nowMinute = now.hour * 60 + now.minute;
    if (nowMinute < minute - 10 || nowMinute > minute + 45) return;
    if (!await _hasOpenItemsToday()) return;
    final streak = await _openStreakSummary();
    await _notifications.showInstant(
      id: streakTaskId + 1,
      title: 'Streak still open',
      body: streak,
      payload: 'home',
      channelId: RuhhNotificationChannels.streak,
    );
  }

  Future<bool> _hasOpenItemsToday() async {
    var habitsDone = 0;
    var habitsDue = 0;
    var prayerComplete = true;
    try {
      final habits = await _habitRepo.activeHabits();
      final logs = await _habitRepo.allLogViews();
      final score = todayScore(habits, logs, _habitRepo.todayKey);
      habitsDone = score.done;
      habitsDue = score.total;
    } catch (_) {}
    try {
      final logs = await _prayerRepo.allDailyLogsMap();
      final today = resolveDayLog(
        _prayerRepo.todayKey,
        logs,
        _prayerRepo.todayKey,
      );
      prayerComplete = isFullyPrayed(today);
    } catch (_) {}
    return shouldScheduleStreakProtection(
      channelEnabled: true,
      habitsDone: habitsDone,
      habitsDueToday: habitsDue,
      prayerComplete: prayerComplete,
    );
  }

  Future<String> _openStreakSummary() async {
    try {
      final best = await _habitRepo.bestStreakAmongActive();
      if (best >= 2) {
        return 'Your $best-day habit streak is still open today.';
      }
    } catch (_) {}
    return 'A few check-ins are still waiting for you tonight.';
  }

  Future<void> _schedulePrayerWindow() async {
    final now = DateTime.now();
    for (var offset = 0; offset <= 1; offset++) {
      final day = DateTime(now.year, now.month, now.day)
          .add(Duration(days: offset));
      final times = await _prayerRepo.displayTimesForDay(day);
      final logs = await _prayerRepo.allDailyLogsMap();
      final dayKey = dateKeyFrom(day);
      final log = resolveDayLog(dayKey, logs, _prayerRepo.todayKey);
      for (var i = 0; i < prayerOrder.length; i++) {
        final p = prayerOrder[i];
        if (log.statuses[p] == TrackerPrayerStatus.prayed) continue;
        final at = prayerOccurrenceAt(day, p, times);
        if (at == null || at.isBefore(now)) continue;
        final id = prayerIdBase + offset * 10 + i;
        await _notifications.scheduleTodoAt(
          id: id,
          title: 'Time for ${PrayerTheme.label(p)}',
          body: 'Tap to log ${PrayerTheme.label(p)}.',
          when: at,
          payload: 'prayer:${p.name}',
          channelId: RuhhNotificationChannels.prayer,
        );
      }
    }
  }
}

final rescheduleAllNotificationsProvider =
    FutureProvider<RescheduleAllNotifications>((ref) async {
  final notifications = await ref.watch(notificationServiceProvider.future);
  final settings = ref.watch(settingsControllerProvider);
  final habitSched = await ref.watch(habitNotificationSchedulerProvider.future);
  final habitRepo = await ref.watch(habitRepositoryProvider.future);
  final prayerRepo = await ref.watch(prayerRepositoryProvider.future);
  return RescheduleAllNotifications(
    notifications,
    settings,
    habitSched,
    habitRepo,
    prayerRepo,
  );
});

Future<void> rescheduleAllNotifications(WidgetRef ref) async {
  final r = await ref.read(rescheduleAllNotificationsProvider.future);
  await r.run();
}

Future<void> refreshStreakProtectionAlarm(WidgetRef ref) async {
  final r = await ref.read(rescheduleAllNotificationsProvider.future);
  await r.syncStreakProtectionAlarm();
}
