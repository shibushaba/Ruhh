import 'package:flutter_test/flutter_test.dart';
import 'package:ruhh/core/data/models/habit_local.dart';
import 'package:ruhh/core/data/models/prayer_local.dart';
import 'package:ruhh/features/habit/tracker/habit_calculations.dart';
import 'package:ruhh/features/habit/tracker/habit_scheduling.dart';
import 'package:ruhh/features/home/logic/home_weekly_consistency.dart';
import 'package:ruhh/features/prayer/tracker/prayer_domain.dart';

void main() {
  test('dailyConsistencyScore averages habit and prayer', () {
    final habit = HabitLocal()
      ..remoteId = 'h1'
      ..createdAt = DateTime(2026, 1, 1)
      ..interval = HabitInterval.daily
      ..archived = false;
    final logs = {
      'h1': {
        '2026-09-24': const HabitLogView(
          dateKey: '2026-09-24',
          status: HabitLogStatus.completed,
        ),
      },
    };
    final prayerLogs = {
      '2026-09-24': DailyPrayerLog(
        id: '1',
        dateKey: '2026-09-24',
        statuses: {
          for (final p in prayerOrder) p: TrackerPrayerStatus.prayed,
        },
      ),
    };
    final score = dailyConsistencyScore(
      dateKey: '2026-09-24',
      todayKey: '2026-09-24',
      habitsEnabled: true,
      prayerEnabled: true,
      budgetEnabled: false,
      habits: [habit],
      habitLogsByHabit: logs,
      prayerLogsByDate: prayerLogs,
      budgetWithinLimitOnDay: true,
    );
    expect(score, 100);
  });
}
