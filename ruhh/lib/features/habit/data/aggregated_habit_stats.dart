import 'package:ruhh/core/data/models/habit_local.dart';
import 'package:ruhh/features/habit/habit_logic.dart';
import 'package:ruhh/features/habit/habit_repository.dart';

class AggregatedHabitStats {
  const AggregatedHabitStats({
    required this.weekday,
    required this.streakSeries,
    required this.total,
    required this.bestStreak,
    required this.consistency,
    required this.perfectDays,
  });

  final List<int> weekday;
  final List<double> streakSeries;
  final int total;
  final int bestStreak;
  final int consistency;
  final int perfectDays;

  static Future<AggregatedHabitStats> compute(HabitRepository repo) async {
    final habits = await repo.activeHabits();
    final now = DateTime.now();
    final weekday = List<int>.filled(7, 0);
    var total = 0;
    var best = 0;
    var consistencySum = 0;
    final series = List<double>.filled(90, 0);

    for (final h in habits) {
      final map = await repo.completionsMap(
        h,
        since: now.subtract(const Duration(days: 120)),
      );
      final streak = HabitLogic.currentStreak(h, map, now: now);
      if (streak > best) best = streak;
      consistencySum += await repo.consistencyFor(h);
      for (final e in map.entries) {
        if (!HabitLogic.isCompletedOn(h, e.key, e.value, now: now)) continue;
        total++;
        weekday[e.key.weekday - 1]++;
      }
      for (var i = 0; i < 90; i++) {
        final day = HabitLogic.dayOnly(now).subtract(Duration(days: 89 - i));
        if (HabitLogic.isCompletedOn(h, day, map[day], now: now)) {
          if (series[i] < streak.toDouble()) series[i] = streak.toDouble();
        }
      }
    }

    var perfect = 0;
    for (var i = 0; i < 30; i++) {
      final day = HabitLogic.dayOnly(now).subtract(Duration(days: i));
      var due = 0;
      var done = 0;
      for (final h in habits) {
        if (!HabitLogic.isScheduledOn(h, day) || HabitLogic.isPausedOn(h, day)) {
          continue;
        }
        due++;
        final map = await repo.completionsMap(h, since: day.subtract(const Duration(days: 1)));
        if (HabitLogic.isCompletedOn(h, day, map[day], now: now)) done++;
      }
      if (due > 0 && done == due) perfect++;
    }

    return AggregatedHabitStats(
      weekday: weekday,
      streakSeries: series,
      total: total,
      bestStreak: best,
      consistency: habits.isEmpty ? 0 : (consistencySum / habits.length).round(),
      perfectDays: perfect,
    );
  }
}
