import 'package:ruhh/core/data/models/habit_local.dart';
import 'package:ruhh/features/habit/habit_logic.dart';

String habitDateKey(DateTime dt) {
  final d = HabitLogic.dayOnly(dt);
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

DateTime parseHabitDateKey(String key) {
  final p = key.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

String habitCreatedKey(HabitLocal habit) => habitDateKey(habit.createdAt);

String habitStartKey(HabitLocal habit) {
  if (habit.scheduleStartDateKey.isNotEmpty) {
    return habit.scheduleStartDateKey;
  }
  return habitCreatedKey(habit);
}

bool isHabitGoal(HabitLocal habit) => habit.kind == HabitKind.quantitative;

double habitGoalTarget(HabitLocal habit) =>
    habit.targetPerDay <= 0 ? 1.0 : habit.targetPerDay.toDouble();

/// Section 5 — is a habit due on date D?
bool isDue(HabitLocal habit, String dateKey) {
  if (habit.archived) return false;
  if (dateKey.compareTo(habitCreatedKey(habit)) < 0) return false;

  final date = parseHabitDateKey(dateKey);
  switch (habit.interval) {
    case HabitInterval.daily:
      return true;
    case HabitInterval.weekdays:
      final days = habit.scheduleWeekdays;
      if (days.isEmpty) return false;
      return days.contains(date.weekday);
    case HabitInterval.monthly:
      final dom = habit.scheduleMonthDays;
      final list = dom.isEmpty ? [1] : dom;
      return list.contains(date.day);
    case HabitInterval.everyXDays:
      final n = habit.scheduleEvery <= 0 ? 1 : habit.scheduleEvery;
      final start = parseHabitDateKey(habitStartKey(habit));
      final diff = HabitLogic.epochDay(date) - HabitLogic.epochDay(start);
      if (diff < 0) return false;
      return diff % n == 0;
    case HabitInterval.weekly:
      return true;
  }
}

Iterable<String> dueDateKeysInRange(
  HabitLocal habit,
  String startKey,
  String endKey,
) sync* {
  var cursor = parseHabitDateKey(startKey);
  final end = parseHabitDateKey(endKey);
  while (!cursor.isAfter(end)) {
    final key = habitDateKey(cursor);
    if (isDue(habit, key)) yield key;
    cursor = cursor.add(const Duration(days: 1));
  }
}

String scheduleSummary(HabitLocal habit) => switch (habit.interval) {
      HabitInterval.daily => 'Daily',
      HabitInterval.weekdays =>
        'Weekly · ${_weekdayNames(habit.scheduleWeekdays)}',
      HabitInterval.monthly =>
        'Monthly · ${habit.scheduleMonthDays.isEmpty ? '1' : habit.scheduleMonthDays.join(', ')}',
      HabitInterval.everyXDays =>
        'Every ${habit.scheduleEvery} day${habit.scheduleEvery == 1 ? '' : 's'}',
      HabitInterval.weekly => 'Weekly target',
    };

String _weekdayNames(List<int> days) {
  const names = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return days.map((d) => names[d.clamp(1, 7)]).join(', ');
}
