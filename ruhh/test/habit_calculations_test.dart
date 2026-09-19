import 'package:flutter_test/flutter_test.dart';
import 'package:ruhh/core/data/models/habit_local.dart';
import 'package:ruhh/features/habit/tracker/habit_calculations.dart';
import 'package:ruhh/features/habit/tracker/habit_scheduling.dart';

HabitLocal _gymHabit() {
  return HabitLocal()
    ..remoteId = 'gym'
    ..userId = 'u'
    ..name = 'Gym'
    ..colorValue = 0xFF22C55E
    ..icon = 'fitness'
    ..kind = HabitKind.positive
    ..interval = HabitInterval.weekdays
    ..scheduleWeekdays = [1, 3, 5]
    ..targetFrequency = 1
    ..scheduleEvery = 2
    ..scheduleUnit = ScheduleUnit.days
    ..targetPerDay = 1
    ..incrementAmount = 1
    ..unitLabel = ''
    ..description = ''
    ..frequency = 'weekdays'
    ..restDays = []
    ..vacationsJson = '[]'
    ..remindersJson = '[]'
    ..archived = false
    ..sortOrder = 0
    ..createdAt = DateTime(2024, 1, 1);
}

HabitLogView _log(String key, HabitLogStatus status) =>
    HabitLogView(dateKey: key, status: status);

void main() {
  test('weekly gym worked example streak and completion rate', () {
    const todayKey = '2024-01-12'; // Fri week 2
    final habit = _gymHabit();
    final logs = {
      '2024-01-01': _log('2024-01-01', HabitLogStatus.completed),
      '2024-01-03': _log('2024-01-03', HabitLogStatus.completed),
      '2024-01-05': _log('2024-01-05', HabitLogStatus.excused),
      '2024-01-08': _log('2024-01-08', HabitLogStatus.completed),
      '2024-01-10': _log('2024-01-10', HabitLogStatus.missed),
      '2024-01-12': _log('2024-01-12', HabitLogStatus.completed),
    };

    expect(
      currentStreakForHabit(habit, logs, todayKey),
      1,
    );
    expect(
      longestStreakForHabit(habit, logs, todayKey),
      3,
    );
    expect(
      completionRateForPeriod(
        habit,
        logs,
        '2024-01-01',
        '2024-01-12',
        todayKey,
      ),
      0.8,
    );
  });
}
