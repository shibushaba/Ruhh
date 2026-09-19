import 'package:ruhh/core/data/models/habit_local.dart';
import 'package:ruhh/features/habit/tracker/habit_scheduling.dart';

class HabitLogView {
  const HabitLogView({
    required this.dateKey,
    required this.status,
    this.currentValue,
  });

  final String dateKey;
  final HabitLogStatus status;
  final double? currentValue;
}

HabitLogView finalizeLog(HabitLogView log, {required String todayKey}) {
  if (log.dateKey.compareTo(todayKey) >= 0) return log;
  if (log.status == HabitLogStatus.pending) {
    return HabitLogView(
      dateKey: log.dateKey,
      status: HabitLogStatus.missed,
      currentValue: log.currentValue,
    );
  }
  return log;
}

HabitLogView resolveLog(
  String dateKey,
  Map<String, HabitLogView> logs,
  String todayKey,
) {
  final raw = logs[dateKey];
  if (raw == null) {
    return HabitLogView(dateKey: dateKey, status: HabitLogStatus.missed);
  }
  return finalizeLog(raw, todayKey: todayKey);
}

bool isStreakSafe(HabitLogView log) =>
    log.status == HabitLogStatus.completed ||
    log.status == HabitLogStatus.excused;

bool isBroken(HabitLogView log) => log.status == HabitLogStatus.missed;

int currentStreakForHabit(
  HabitLocal habit,
  Map<String, HabitLogView> logs,
  String todayKey,
) {
  if (!isDue(habit, todayKey) && logs.isEmpty) return 0;

  final dueKeys = dueDateKeysInRange(
    habit,
    habitCreatedKey(habit),
    todayKey,
  ).toList();
  if (dueKeys.isEmpty) return 0;

  var startIdx = dueKeys.length - 1;
  final todayLog = logs[todayKey];
  if (isDue(habit, todayKey) &&
      todayLog != null &&
      finalizeLog(todayLog, todayKey: todayKey).status ==
          HabitLogStatus.completed) {
    startIdx = dueKeys.length - 1;
  } else {
    startIdx = dueKeys.length - 2;
  }
  if (startIdx < 0) return 0;

  var streak = 0;
  for (var i = startIdx; i >= 0; i--) {
    final key = dueKeys[i];
    final log = resolveLog(key, logs, todayKey);
    if (isBroken(log)) break;
    if (log.status == HabitLogStatus.completed) streak++;
    if (!isStreakSafe(log)) break;
  }
  return streak;
}

int longestStreakForHabit(
  HabitLocal habit,
  Map<String, HabitLogView> logs,
  String todayKey,
) {
  final dueKeys = dueDateKeysInRange(
    habit,
    habitCreatedKey(habit),
    todayKey,
  ).toList();
  var running = 0;
  var max = 0;
  for (final key in dueKeys) {
    final log = resolveLog(key, logs, todayKey);
    if (isBroken(log)) {
      running = 0;
    } else if (log.status == HabitLogStatus.completed) {
      running++;
      if (running > max) max = running;
    } else if (log.status == HabitLogStatus.excused) {
      // safe gap
    } else {
      running = 0;
    }
  }
  return max;
}

double completionRateForPeriod(
  HabitLocal habit,
  Map<String, HabitLogView> logs,
  String periodStartKey,
  String periodEndKey,
  String todayKey,
) {
  var completed = 0;
  var denom = 0;
  for (final key
      in dueDateKeysInRange(habit, periodStartKey, periodEndKey)) {
    final log = resolveLog(key, logs, todayKey);
    if (log.status == HabitLogStatus.excused) continue;
    denom++;
    if (log.status == HabitLogStatus.completed) completed++;
  }
  if (denom == 0) return 0;
  return completed / denom;
}

({int done, int total, double ratio}) todayScore(
  List<HabitLocal> habits,
  Map<String, Map<String, HabitLogView>> logsByHabit,
  String todayKey,
) {
  var done = 0;
  var total = 0;
  for (final h in habits) {
    if (!isDue(h, todayKey)) continue;
    total++;
    final log = resolveLog(
      todayKey,
      logsByHabit[h.remoteId] ?? {},
      todayKey,
    );
    if (log.status == HabitLogStatus.completed) done++;
  }
  return (
    done: done,
    total: total,
    ratio: total == 0 ? 0.0 : done / total,
  );
}

double dayScoreOn(
  List<HabitLocal> habits,
  Map<String, Map<String, HabitLogView>> logsByHabit,
  String dateKey,
  String todayKey,
) {
  var done = 0;
  var total = 0;
  for (final h in habits) {
    if (!isDue(h, dateKey)) continue;
    total++;
    final log = resolveLog(dateKey, logsByHabit[h.remoteId] ?? {}, todayKey);
    if (log.status == HabitLogStatus.completed) done++;
  }
  if (total == 0) return 0;
  return done / total;
}

int? streakMilestone(int streak) {
  for (final m in [7, 30, 100, 365]) {
    if (streak == m) return m;
  }
  return null;
}
