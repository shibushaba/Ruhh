import 'package:ruhh/core/data/models/habit_local.dart';
import 'package:ruhh/features/habit/habit_extensions.dart';

/// Streak-style scheduling and streak rules (reference: Habit-Tracker / Streak).
abstract final class HabitLogic {
  static DateTime dayOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  static int epochDay(DateTime d) =>
      dayOnly(d).millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;

  static DateTime startedAt(HabitLocal habit, Iterable<DateTime> completionDays) {
    var first = dayOnly(habit.createdAt);
    for (final d in completionDays) {
      if (dayOnly(d).isBefore(first)) first = dayOnly(d);
    }
    return first;
  }

  static int spanDays(HabitLocal habit) => switch (habit.scheduleUnit) {
        ScheduleUnit.days => habit.scheduleEvery,
        ScheduleUnit.weeks => habit.scheduleEvery * 7,
        ScheduleUnit.months => habit.scheduleEvery * 31,
      };

  static bool isRestDay(HabitLocal habit, DateTime date) =>
      habit.restDays.contains(dayOnly(date).weekday);

  static bool isPausedOn(HabitLocal habit, DateTime date) =>
      isRestDay(habit, date) || habit.vacations.any((v) => v.contains(date));

  static bool isNeutralOn(
    HabitLocal habit,
    DateTime date,
    double? value, {
    required DateTime now,
  }) =>
      isPausedOn(habit, date) &&
      !isCompletedOn(habit, date, value, now: now);

  static bool isScheduledOn(HabitLocal habit, DateTime date) {
    final day = dayOnly(date);
    switch (habit.interval) {
      case HabitInterval.weekdays:
        return habit.scheduleWeekdays.contains(day.weekday);
      case HabitInterval.everyXDays:
        if (habit.scheduleEvery <= 0) return false;
        final start = dayOnly(habit.createdAt);
        if (day.isBefore(start)) return false;
        if (habit.scheduleUnit == ScheduleUnit.months) {
          final months =
              (day.year - start.year) * 12 + day.month - start.month;
          if (months < 0 || months % habit.scheduleEvery != 0) return false;
          final last = DateTime(day.year, day.month + 1, 0).day;
          return day.day == (start.day <= last ? start.day : last);
        }
        final diff = epochDay(day) - epochDay(start);
        return diff % spanDays(habit) == 0;
      case HabitInterval.daily:
      case HabitInterval.weekly:
      case HabitInterval.monthly:
        return true;
    }
  }

  static bool isCompletedOn(
    HabitLocal habit,
    DateTime date,
    double? value, {
    required DateTime now,
  }) {
    final day = dayOnly(date);
    final today = dayOnly(now);
    if (day.isAfter(today)) return false;

    if (habit.kind == HabitKind.negative) {
      final floor = dayOnly(habit.createdAt);
      if (day.isBefore(floor)) return false;
      return value == null;
    }
    if (value == null) return false;
    return value >= habit.targetPerDay;
  }

  static bool isRelapseOn(HabitLocal habit, double? value) =>
      habit.kind == HabitKind.negative && value != null;

  static int currentStreak(
    HabitLocal habit,
    Map<DateTime, double> byDay, {
    required DateTime now,
  }) {
    final floor = startedAt(habit, byDay.keys);
    final today = dayOnly(now);

    if (habit.kind == HabitKind.negative) {
      var cursor = today;
      var streak = 0;
      while (!cursor.isBefore(floor)) {
        final v = byDay[cursor];
        if (isNeutralOn(habit, cursor, v, now: now)) {
          // skip
        } else if (isCompletedOn(habit, cursor, v, now: now)) {
          streak++;
        } else {
          break;
        }
        cursor = cursor.subtract(const Duration(days: 1));
      }
      return streak;
    }

    if (byDay.isEmpty && habit.kind != HabitKind.negative) return 0;

    switch (habit.interval) {
      case HabitInterval.daily:
      case HabitInterval.weekdays:
      case HabitInterval.everyXDays:
        var cursor = today;
        final vToday = byDay[cursor];
        if (!isCompletedOn(habit, cursor, vToday, now: now) &&
            isScheduledOn(habit, cursor) &&
            !isPausedOn(habit, cursor)) {
          cursor = cursor.subtract(const Duration(days: 1));
          final v = byDay[cursor];
          if (!isCompletedOn(habit, cursor, v, now: now) &&
              isScheduledOn(habit, cursor)) {
            return 0;
          }
        }
        var streak = 0;
        while (!cursor.isBefore(floor)) {
          if (!isScheduledOn(habit, cursor)) {
            cursor = cursor.subtract(const Duration(days: 1));
            continue;
          }
          final v = byDay[cursor];
          if (isNeutralOn(habit, cursor, v, now: now)) {
            // skip
          } else if (isCompletedOn(habit, cursor, v, now: now)) {
            streak++;
          } else {
            break;
          }
          cursor = cursor.subtract(const Duration(days: 1));
        }
        return streak;
      case HabitInterval.weekly:
      case HabitInterval.monthly:
        return _periodStreak(habit, byDay, now: now, floor: floor);
    }
  }

  static int _periodStreak(
    HabitLocal habit,
    Map<DateTime, double> byDay, {
    required DateTime now,
    required DateTime floor,
  }) {
    var streak = 0;
    var cursor = dayOnly(now);
    while (!cursor.isBefore(floor)) {
      final start = habit.interval == HabitInterval.weekly
          ? cursor.subtract(Duration(days: cursor.weekday - 1))
          : DateTime(cursor.year, cursor.month, 1);
      final end = habit.interval == HabitInterval.weekly
          ? start.add(const Duration(days: 6))
          : DateTime(cursor.year, cursor.month + 1, 0);
      var count = 0;
      for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
        if (isCompletedOn(habit, d, byDay[dayOnly(d)], now: now)) count++;
      }
      if (count >= habit.targetFrequency) {
        streak++;
        cursor = habit.interval == HabitInterval.weekly
            ? start.subtract(const Duration(days: 1))
            : DateTime(cursor.year, cursor.month - 1, 1);
      } else {
        break;
      }
    }
    return streak;
  }

  static int consistencyPercent(
    HabitLocal habit,
    Map<DateTime, double> byDay, {
    required DateTime now,
    int windowDays = 30,
  }) {
    final floor = startedAt(habit, byDay.keys);
    final today = dayOnly(now);
    var score = 0.0;
    var norm = 0.0;
    for (var i = 0; i < windowDays; i++) {
      final day = today.subtract(Duration(days: i));
      if (day.isBefore(floor) ||
          !isScheduledOn(habit, day) ||
          isPausedOn(habit, day)) continue;
      norm += 1;
      if (isCompletedOn(habit, day, byDay[day], now: now)) score += 1;
    }
    if (norm == 0) return 0;
    return ((score / norm) * 100).round();
  }

  static ({int done, int total, double ratio}) todayProgress(
    List<HabitLocal> habits,
    Map<String, Map<DateTime, double>> completionMaps, {
    required DateTime now,
  }) {
    final today = dayOnly(now);
    var done = 0;
    var total = 0;
    for (final h in habits) {
      if (!isScheduledOn(h, today) || isPausedOn(h, today)) continue;
      total++;
      final map = completionMaps[h.remoteId] ?? {};
      if (isCompletedOn(h, today, map[today], now: now)) done++;
    }
    final ratio = total == 0 ? 0.0 : done / total;
    return (done: done, total: total, ratio: ratio);
  }
}
