import 'package:ruhh/core/data/models/prayer_local.dart';
import 'package:ruhh/features/prayer/tracker/prayer_domain.dart';

bool isFullyPrayed(DailyPrayerLog day) =>
    !day.isExcusedDay &&
    prayerOrder.every((p) => day.statuses[p] == TrackerPrayerStatus.prayed);

bool isStreakSafe(DailyPrayerLog day) =>
    day.isExcusedDay || isFullyPrayed(day);

bool isBroken(DailyPrayerLog day) =>
    !day.isExcusedDay &&
    day.statuses.values.any((s) => s == TrackerPrayerStatus.missed);

DailyPrayerLog finalizePastDay(DailyPrayerLog log, {required String todayKey}) {
  if (log.dateKey.compareTo(todayKey) >= 0) return log;
  final next = Map<PrayerName, TrackerPrayerStatus>.from(log.statuses);
  for (final p in prayerOrder) {
    if (next[p] == TrackerPrayerStatus.unmarked) {
      next[p] = TrackerPrayerStatus.missed;
    }
  }
  return log.copyWith(statuses: next);
}

double todayRatio(DailyPrayerLog log) {
  final prayed = log.statuses.values
      .where((s) => s == TrackerPrayerStatus.prayed)
      .length;
  return prayed / 5;
}

DailyPrayerLog resolveDayLog(
  String dateKey,
  Map<String, DailyPrayerLog> logsByDate,
  String todayKey,
) {
  final raw = logsByDate[dateKey];
  if (raw == null) {
    if (dateKey.compareTo(todayKey) < 0) {
      return syntheticMissedDay(dateKey);
    }
    return DailyPrayerLog(
      id: '',
      dateKey: dateKey,
      statuses: emptyStatuses(),
    );
  }
  return finalizePastDay(raw, todayKey: todayKey);
}

int currentStreak(
  Map<String, DailyPrayerLog> logsByDate,
  String todayKey,
) {
  final today = resolveDayLog(todayKey, logsByDate, todayKey);
  var cursor = parseDateKey(todayKey);
  if (!isFullyPrayed(today)) {
    cursor = cursor.subtract(const Duration(days: 1));
  }

  var streak = 0;
  while (true) {
    final key = dateKeyFrom(cursor);
    if (key.compareTo('2020-01-01') < 0) break;
    final day = resolveDayLog(key, logsByDate, todayKey);
    if (isBroken(day)) break;
    if (isFullyPrayed(day)) streak++;
    if (!isStreakSafe(day)) break;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

int longestStreak(
  Map<String, DailyPrayerLog> logsByDate,
  String todayKey,
) {
  if (logsByDate.isEmpty) return 0;
  final keys = logsByDate.keys.toList()..sort();
  final first = parseDateKey(keys.first);
  final last = parseDateKey(todayKey);
  var running = 0;
  var max = 0;
  var cursor = first;
  while (!cursor.isAfter(last)) {
    final key = dateKeyFrom(cursor);
    final day = resolveDayLog(key, logsByDate, todayKey);
    if (isBroken(day)) {
      running = 0;
    } else if (isFullyPrayed(day)) {
      running++;
      if (running > max) max = running;
    } else if (day.isExcusedDay) {
      // safe gap
    } else {
      running = 0;
    }
    cursor = cursor.add(const Duration(days: 1));
  }
  return max;
}

class MonthlyPrayerStats {
  const MonthlyPrayerStats({
    required this.fullyPrayedDays,
    required this.excusedDays,
    required this.partialDays,
    required this.missedDays,
    required this.completionPercent,
    required this.perPrayerCompletion,
  });

  final int fullyPrayedDays;
  final int excusedDays;
  final int partialDays;
  final int missedDays;
  final double completionPercent;
  final Map<PrayerName, double> perPrayerCompletion;
}

MonthlyPrayerStats monthlyStats({
  required int year,
  required int month,
  required Map<String, DailyPrayerLog> logsByDate,
  required String todayKey,
}) {
  final daysInMonth = DateTime(year, month + 1, 0).day;
  final isCurrentMonth =
      year == parseDateKey(todayKey).year &&
      month == parseDateKey(todayKey).month;
  final lastDay = isCurrentMonth ? parseDateKey(todayKey).day : daysInMonth;

  var fully = 0;
  var excused = 0;
  var partial = 0;
  var missed = 0;
  final prayedCounts = {for (final p in prayerOrder) p: 0};

  for (var d = 1; d <= lastDay; d++) {
    final key =
        '$year-${month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
    final day = resolveDayLog(key, logsByDate, todayKey);
    if (isFullyPrayed(day)) fully++;
    if (day.isExcusedDay) excused++;
    final allMissed = !day.isExcusedDay &&
        prayerOrder.every((p) => day.statuses[p] == TrackerPrayerStatus.missed);
    if (allMissed) missed++;
    final prayed = day.statuses.values
        .where((s) => s == TrackerPrayerStatus.prayed)
        .length;
    if (!day.isExcusedDay && prayed > 0 && prayed < 5) partial++;
    for (final p in prayerOrder) {
      if (day.statuses[p] == TrackerPrayerStatus.prayed) {
        prayedCounts[p] = prayedCounts[p]! + 1;
      }
    }
  }

  final denom = lastDay;
  return MonthlyPrayerStats(
    fullyPrayedDays: fully,
    excusedDays: excused,
    partialDays: partial,
    missedDays: missed,
    completionPercent: denom == 0 ? 0 : fully / denom,
    perPrayerCompletion: {
      for (final p in prayerOrder)
        p: denom == 0 ? 0 : prayedCounts[p]! / denom,
    },
  );
}

enum DayVisualKind {
  future,
  today,
  fullStar,
  excused,
  partial,
  allMissed,
  empty,
}

DayVisualKind dayVisualKind(
  DailyPrayerLog day,
  String todayKey,
) {
  if (day.dateKey.compareTo(todayKey) > 0) return DayVisualKind.future;
  if (day.dateKey == todayKey) {
    if (isFullyPrayed(day)) return DayVisualKind.fullStar;
    if (day.isExcusedDay) return DayVisualKind.excused;
    final prayed = prayedCount(day);
    if (prayed == 0) return DayVisualKind.today;
    if (prayed < 5) return DayVisualKind.partial;
    return DayVisualKind.today;
  }
  if (isFullyPrayed(day)) return DayVisualKind.fullStar;
  if (day.isExcusedDay) return DayVisualKind.excused;
  if (prayerOrder.every((p) => day.statuses[p] == TrackerPrayerStatus.missed)) {
    return DayVisualKind.allMissed;
  }
  if (prayedCount(day) > 0) return DayVisualKind.partial;
  return DayVisualKind.empty;
}

int prayedCount(DailyPrayerLog day) =>
    day.statuses.values.where((s) => s == TrackerPrayerStatus.prayed).length;

int? _minutesFromMidnight(String? hhmm) {
  if (hhmm == null || hhmm.length < 4) return null;
  final parts = hhmm.split(':');
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  return h * 60 + m;
}

/// When Isha is after midnight (e.g. 00:35), it belongs to the evening of [day],
/// not the early-morning slot on the same calendar date.
DateTime? prayerOccurrenceAt(
  DateTime day,
  PrayerName prayer,
  Map<PrayerName, String> times,
) {
  final mins = _minutesFromMidnight(times[prayer]);
  if (mins == null) return null;
  final d = DateTime(day.year, day.month, day.day);
  var at = d.add(Duration(minutes: mins));
  if (prayer == PrayerName.isha) {
    final fajrMins = _minutesFromMidnight(times[PrayerName.fajr]);
    if (fajrMins != null && mins <= fajrMins) {
      at = at.add(const Duration(days: 1));
    }
  }
  return at;
}

/// Next salāh for home / highlights: earliest upcoming unlogged, else latest overdue.
PrayerName? nextUnloggedPrayer({
  required DailyPrayerLog log,
  required Map<PrayerName, String> times,
  required DateTime now,
}) {
  final day = DateTime(now.year, now.month, now.day);
  PrayerName? latestPassedUnmarked;
  PrayerName? firstFutureUnmarked;

  for (final p in prayerOrder) {
    if (log.statuses[p] == TrackerPrayerStatus.prayed) continue;
    final at = prayerOccurrenceAt(day, p, times);
    if (at == null) continue;
    if (!at.isAfter(now)) {
      latestPassedUnmarked = p;
    } else if (firstFutureUnmarked == null) {
      firstFutureUnmarked = p;
    }
  }

  return firstFutureUnmarked ?? latestPassedUnmarked;
}
