import 'package:flutter_test/flutter_test.dart';
import 'package:ruhh/core/data/models/prayer_local.dart';
import 'package:ruhh/features/prayer/tracker/prayer_calculations.dart';
import 'package:ruhh/features/prayer/tracker/prayer_domain.dart';

DailyPrayerLog _day(
  String key, {
  bool excused = false,
  List<TrackerPrayerStatus>? statuses,
}) {
  final map = emptyStatuses();
  if (statuses != null) {
    for (var i = 0; i < prayerOrder.length; i++) {
      map[prayerOrder[i]] = statuses[i];
    }
  }
  return DailyPrayerLog(
    id: key,
    dateKey: key,
    isExcusedDay: excused,
    statuses: map,
  );
}

DailyPrayerLog _allPrayed(String key) => _day(
      key,
      statuses: List.filled(5, TrackerPrayerStatus.prayed),
    );

void main() {
  test('worked example streak and monthly counts', () {
    final logs = {
      '2024-01-01': _allPrayed('2024-01-01'),
      '2024-01-02': _allPrayed('2024-01-02'),
      '2024-01-03': _day('2024-01-03', excused: true),
      '2024-01-04': _allPrayed('2024-01-04'),
      '2024-01-05': finalizePastDay(
        _day(
          '2024-01-05',
          statuses: [
            TrackerPrayerStatus.prayed,
            TrackerPrayerStatus.prayed,
            TrackerPrayerStatus.prayed,
            TrackerPrayerStatus.prayed,
            TrackerPrayerStatus.unmarked,
          ],
        ),
        todayKey: '2024-01-06',
      ),
    };

    expect(currentStreak(logs, '2024-01-04'), 3);
    expect(currentStreak(logs, '2024-01-06'), 0);

    final stats = monthlyStats(
      year: 2024,
      month: 1,
      logsByDate: logs,
      todayKey: '2024-01-06',
    );
    expect(stats.fullyPrayedDays, 3);
    expect(stats.excusedDays, 1);
    expect(stats.missedDays, 0);
  });

  test('today only counts toward streak when fully prayed', () {
    final logs = {
      '2024-02-01': _allPrayed('2024-02-01'),
      '2024-02-02': _day(
        '2024-02-02',
        statuses: [
          TrackerPrayerStatus.prayed,
          TrackerPrayerStatus.prayed,
          TrackerPrayerStatus.unmarked,
          TrackerPrayerStatus.unmarked,
          TrackerPrayerStatus.unmarked,
        ],
      ),
    };
    expect(currentStreak(logs, '2024-02-02'), 1);
    logs['2024-02-02'] = _allPrayed('2024-02-02');
    expect(currentStreak(logs, '2024-02-02'), 2);
  });

  test('next unlogged prayer prefers upcoming over post-midnight isha', () {
    final log = _day(
      '2026-09-22',
      statuses: [
        TrackerPrayerStatus.prayed,
        TrackerPrayerStatus.unmarked,
        TrackerPrayerStatus.unmarked,
        TrackerPrayerStatus.unmarked,
        TrackerPrayerStatus.unmarked,
      ],
    );
    final times = {
      PrayerName.fajr: '05:12',
      PrayerName.dhuhr: '12:18',
      PrayerName.asr: '15:42',
      PrayerName.maghrib: '18:31',
      PrayerName.isha: '00:35',
    };
    final now = DateTime(2026, 9, 22, 11, 23);
    expect(
      nextUnloggedPrayer(log: log, times: times, now: now),
      PrayerName.dhuhr,
    );
  });

  test('post-midnight isha counts as tonight not early morning', () {
    final times = {
      PrayerName.fajr: '05:12',
      PrayerName.dhuhr: '12:18',
      PrayerName.asr: '15:42',
      PrayerName.maghrib: '18:31',
      PrayerName.isha: '00:35',
    };
    final day = DateTime(2026, 9, 22);
    final ishaAt = prayerOccurrenceAt(day, PrayerName.isha, times);
    expect(ishaAt, DateTime(2026, 9, 23, 0, 35));
  });
}
