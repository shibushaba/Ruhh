import 'package:ruhh/core/data/models/habit_local.dart';
import 'package:ruhh/features/habit/tracker/habit_calculations.dart';
import 'package:ruhh/features/habit/tracker/habit_scheduling.dart';
import 'package:ruhh/features/prayer/tracker/prayer_calculations.dart';
import 'package:ruhh/features/prayer/tracker/prayer_domain.dart';

class DailyConsistencyPoint {
  const DailyConsistencyPoint({
    required this.date,
    required this.label,
    required this.score,
    required this.isToday,
  });

  final DateTime date;
  final String label;
  final double score;
  final bool isToday;
}

/// Composite 0–100 score: average of enabled module scores for [dateKey].
double dailyConsistencyScore({
  required String dateKey,
  required String todayKey,
  required bool habitsEnabled,
  required bool prayerEnabled,
  required bool budgetEnabled,
  required List<HabitLocal> habits,
  required Map<String, Map<String, HabitLogView>> habitLogsByHabit,
  required Map<String, DailyPrayerLog> prayerLogsByDate,
  required bool budgetWithinLimitOnDay,
}) {
  final parts = <double>[];
  if (habitsEnabled) {
    final habitPct =
        dayScoreOn(habits, habitLogsByHabit, dateKey, todayKey) * 100;
    if (_hasDueHabits(habits, dateKey)) {
      parts.add(habitPct);
    }
  }
  if (prayerEnabled) {
    final log = resolveDayLog(dateKey, prayerLogsByDate, todayKey);
    parts.add(todayRatio(log) * 100);
  }
  if (budgetEnabled) {
    parts.add(budgetWithinLimitOnDay ? 100 : 0);
  }
  if (parts.isEmpty) return 0;
  return parts.reduce((a, b) => a + b) / parts.length;
}

bool _hasDueHabits(List<HabitLocal> habits, String dateKey) {
  for (final h in habits) {
    if (isDue(h, dateKey)) return true;
  }
  return false;
}

List<DailyConsistencyPoint> lastSevenDaysConsistency({
  required DateTime anchor,
  required String todayKey,
  required bool habitsEnabled,
  required bool prayerEnabled,
  required bool budgetEnabled,
  required List<HabitLocal> habits,
  required Map<String, Map<String, HabitLogView>> habitLogsByHabit,
  required Map<String, DailyPrayerLog> prayerLogsByDate,
  required bool Function(String dateKey) budgetWithinLimitForDay,
}) {
  final today = DateTime(anchor.year, anchor.month, anchor.day);
  final points = <DailyConsistencyPoint>[];
  for (var i = 6; i >= 0; i--) {
    final d = today.subtract(Duration(days: i));
    final key = dateKeyFromDate(d);
    final score = dailyConsistencyScore(
      dateKey: key,
      todayKey: todayKey,
      habitsEnabled: habitsEnabled,
      prayerEnabled: prayerEnabled,
      budgetEnabled: budgetEnabled,
      habits: habits,
      habitLogsByHabit: habitLogsByHabit,
      prayerLogsByDate: prayerLogsByDate,
      budgetWithinLimitOnDay: budgetWithinLimitForDay(key),
    );
    points.add(
      DailyConsistencyPoint(
        date: d,
        label: _weekdayShort(d),
        score: score,
        isToday: i == 0,
      ),
    );
  }
  return points;
}

String weekOverWeekTakeaway(List<DailyConsistencyPoint> last7) {
  if (last7.length < 7) {
    return 'Keep logging — your week will show a trend soon.';
  }
  final firstHalf = (last7[0].score + last7[1].score + last7[2].score) / 3;
  final secondHalf = (last7[4].score + last7[5].score + last7[6].score) / 3;
  final delta = secondHalf - firstHalf;
  if (delta.abs() < 3) {
    return 'Holding steady this week';
  }
  if (delta > 0) {
    return 'Trending up — ${delta.round()}% stronger later in the week';
  }
  return 'A bit quieter than earlier in the week';
}

String _weekdayShort(DateTime d) {
  const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return names[d.weekday - 1];
}

String dateKeyFromDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}
