import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:ruhh/core/data/models/habit_local.dart';
import 'package:ruhh/core/data/models/habit_reminder.dart';
import 'package:ruhh/core/data/models/vacation_period.dart';
import 'package:ruhh/core/services/cloud_sync.dart';
import 'package:ruhh/core/services/home_widget_service.dart';
import 'package:ruhh/core/services/local_data_sync.dart';
import 'package:ruhh/core/services/overlay_runtime.dart';
import 'package:ruhh/core/services/reschedule_all_notifications.dart';
import 'package:ruhh/core/session/session_providers.dart';
import 'package:ruhh/features/habit/habit_extensions.dart';
import 'package:ruhh/features/habit/habit_logic.dart';
import 'package:ruhh/features/habit/tracker/habit_calculations.dart';
import 'package:ruhh/features/habit/tracker/habit_scheduling.dart';
import 'package:ruhh/features/habit/tracker/habit_appearance.dart';
import 'package:uuid/uuid.dart';

class HabitRepository {
  HabitRepository(this._isar, this._userId);

  final Isar _isar;
  final String _userId;

  Stream<List<HabitLocal>> watchActiveHabits() async* {
    yield await activeHabits();
    await for (final _ in _isar.habitLocals.watchLazy(fireImmediately: false)) {
      yield await activeHabits();
    }
  }

  Future<List<HabitLocal>> activeHabits() async {
    final list = await _isar.habitLocals
        .filter()
        .userIdEqualTo(_userId)
        .archivedEqualTo(false)
        .findAll();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  Future<List<HabitLocal>> archivedHabits() async {
    final list = await _isar.habitLocals
        .filter()
        .userIdEqualTo(_userId)
        .archivedEqualTo(true)
        .findAll();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<HabitLocal?> byRemoteId(String remoteId) => _isar.habitLocals
      .filter()
      .remoteIdEqualTo(remoteId)
      .userIdEqualTo(_userId)
      .findFirst();

  Future<void> addHabit({
    required String name,
    required int colorValue,
    String icon = 'target',
    HabitKind kind = HabitKind.positive,
    HabitInterval interval = HabitInterval.daily,
    int targetFrequency = 1,
    List<int> scheduleWeekdays = const [],
    int scheduleEvery = 2,
    ScheduleUnit scheduleUnit = ScheduleUnit.days,
    int targetPerDay = 1,
    double incrementAmount = 1,
    String unitLabel = '',
    String description = '',
    int? reminderMinute,
  }) async {
    final active = await activeHabits();
    final habit = HabitLocal()
      ..remoteId = const Uuid().v4()
      ..userId = _userId
      ..name = name
      ..colorValue = colorValue
      ..icon = icon
      ..kind = kind
      ..interval = interval
      ..targetFrequency = targetFrequency
      ..scheduleWeekdays = List.from(scheduleWeekdays)
      ..scheduleEvery = scheduleEvery
      ..scheduleUnit = scheduleUnit
      ..targetPerDay = targetPerDay
      ..incrementAmount = incrementAmount
      ..unitLabel = unitLabel
      ..description = description
      ..frequency = interval.name
      ..reminderMinute = reminderMinute
      ..restDays = []
      ..vacationsJson = '[]'
      ..remindersJson = '[]'
      ..archived = false
      ..sortOrder = active.length
      ..createdAt = DateTime.now()
      ..scheduleStartDateKey = habitDateKey(DateTime.now())
      ..scheduleMonthDays =
          interval == HabitInterval.monthly ? [1] : const [];
    await _isar.writeTxn(() => _isar.habitLocals.put(habit));
    await _afterWrite();
  }

  Future<void> updateHabit(HabitLocal habit) async {
    habit.frequency = habit.interval.name;
    await _isar.writeTxn(() => _isar.habitLocals.put(habit));
    await _afterWrite();
  }

  Future<void> setReminders(HabitLocal habit, List<HabitReminder> list) async {
    habit.reminders = list;
    await updateHabit(habit);
  }

  Future<void> setVacation(HabitLocal habit, bool enabled) async {
    final periods = [...habit.vacations];
    if (enabled) {
      if (!periods.any((p) => p.isOngoing)) {
        periods.add(VacationPeriod(start: DateTime.now()));
      }
    } else {
      for (var i = 0; i < periods.length; i++) {
        if (periods[i].isOngoing) {
          periods[i] = periods[i].copyWith(
            end: DateTime.now().subtract(const Duration(days: 1)),
          );
        }
      }
    }
    habit.vacations = periods;
    await updateHabit(habit);
  }

  Future<void> setRestDays(HabitLocal habit, List<int> weekdays) async {
    habit.restDays = weekdays;
    await updateHabit(habit);
  }

  Future<void> _afterWrite() async {
    notifyLocalDataChanged();
    HomeWidgetService.syncSoon(Future.value(this));
  }

  Future<void> archiveHabit(HabitLocal habit) async {
    habit.archived = true;
    await updateHabit(habit);
  }

  Future<void> restoreHabit(HabitLocal habit) async {
    habit.archived = false;
    final active = await activeHabits();
    habit.sortOrder = active.length;
    await updateHabit(habit);
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final habits = await activeHabits();
    if (oldIndex < 0 ||
        newIndex < 0 ||
        oldIndex >= habits.length ||
        newIndex >= habits.length) {
      return;
    }
    if (newIndex > oldIndex) newIndex--;
    final item = habits.removeAt(oldIndex);
    habits.insert(newIndex, item);
    await _isar.writeTxn(() async {
      for (var i = 0; i < habits.length; i++) {
        habits[i].sortOrder = i;
        await _isar.habitLocals.put(habits[i]);
      }
    });
  }

  Future<Map<DateTime, double>> completionsMap(
    HabitLocal habit, {
    DateTime? since,
  }) async {
    final rows = since == null
        ? await _isar.habitCompletionLocals
            .filter()
            .habitRemoteIdEqualTo(habit.remoteId)
            .userIdEqualTo(_userId)
            .findAll()
        : await _isar.habitCompletionLocals
            .filter()
            .habitRemoteIdEqualTo(habit.remoteId)
            .userIdEqualTo(_userId)
            .dayGreaterThan(
              HabitLogic.dayOnly(since).subtract(const Duration(days: 1)),
            )
            .findAll();
    final map = <DateTime, double>{};
    for (final c in rows) {
      final d = HabitLogic.dayOnly(c.day);
      map[d] = c.value;
    }
    return map;
  }

  Future<double?> valueOn(HabitLocal habit, DateTime day) async {
    final d = HabitLogic.dayOnly(day);
    final hit = await _isar.habitCompletionLocals
        .filter()
        .habitRemoteIdEqualTo(habit.remoteId)
        .userIdEqualTo(_userId)
        .dayEqualTo(d)
        .findFirst();
    return hit?.value;
  }

  Future<void> _setValue(HabitLocal habit, DateTime day, double? value) async {
    final d = HabitLogic.dayOnly(day);
    final existing = await _isar.habitCompletionLocals
        .filter()
        .habitRemoteIdEqualTo(habit.remoteId)
        .dayEqualTo(d)
        .findFirst();
    if (value == null) {
      if (existing != null) {
        await _isar.writeTxn(() => _isar.habitCompletionLocals.delete(existing.id));
      }
      await _afterWrite();
      return;
    }
    final row = existing ??
        (HabitCompletionLocal()
          ..remoteId = const Uuid().v4()
          ..habitRemoteId = habit.remoteId
          ..userId = _userId
          ..day = d);
    row.value = value;
    await _isar.writeTxn(() => _isar.habitCompletionLocals.put(row));
    await _afterWrite();
  }

  Future<void> toggleToday(HabitLocal habit, {DateTime? day}) async {
    final d = HabitLogic.dayOnly(day ?? DateTime.now());
    if (d.isAfter(HabitLogic.dayOnly(DateTime.now()))) return;

    if (habit.kind == HabitKind.negative) {
      final v = await valueOn(habit, d);
      if (v != null) {
        await _setValue(habit, d, null);
      } else {
        await _setValue(habit, d, 1);
      }
      return;
    }

    final v = await valueOn(habit, d);
    final done = HabitLogic.isCompletedOn(habit, d, v, now: DateTime.now());
    if (done) {
      await _setValue(habit, d, null);
    } else if (habit.kind == HabitKind.quantitative) {
      final target = habit.targetPerDay <= 0 ? 1.0 : habit.targetPerDay.toDouble();
      await _setValue(habit, d, target);
    } else {
      await _setValue(habit, d, 1);
    }
  }

  Future<void> addProgress(HabitLocal habit, double delta, {DateTime? day}) async {
    final d = HabitLogic.dayOnly(day ?? DateTime.now());
    if (d.isAfter(HabitLogic.dayOnly(DateTime.now()))) return;
    final prev = await valueOn(habit, d) ?? 0;
    final next = prev + delta;
    if (next <= 0) {
      await _setValue(habit, d, null);
    } else {
      await _setValue(habit, d, next);
    }
  }

  Future<void> markDone(HabitLocal habit, {DateTime? day}) async {
    await toggleToday(habit, day: day);
  }

  Future<int> streakFor(HabitLocal habit) async {
    final map = await completionsMap(habit);
    return HabitLogic.currentStreak(habit, map, now: DateTime.now());
  }

  Future<bool> isDoneToday(HabitLocal habit) async {
    final today = HabitLogic.dayOnly(DateTime.now());
    if (!HabitLogic.isScheduledOn(habit, today)) return true;
    final v = await valueOn(habit, today);
    return HabitLogic.isCompletedOn(habit, today, v, now: DateTime.now());
  }

  Future<({int done, int total, double ratio})> todayProgress() async {
    final habits = await activeHabits();
    final maps = <String, Map<DateTime, double>>{};
    for (final h in habits) {
      maps[h.remoteId] = await completionsMap(
        h,
        since: DateTime.now().subtract(const Duration(days: 400)),
      );
    }
    return HabitLogic.todayProgress(habits, maps, now: DateTime.now());
  }

  Future<int> consistencyFor(HabitLocal habit) async {
    final map = await completionsMap(
      habit,
      since: DateTime.now().subtract(const Duration(days: 60)),
    );
    return HabitLogic.consistencyPercent(habit, map, now: DateTime.now());
  }

  Future<HabitLocal?> nextDueHabit() async {
    final habits = await activeHabits();
    final today = HabitLogic.dayOnly(DateTime.now());
    for (final h in habits) {
      if (!HabitLogic.isScheduledOn(h, today)) continue;
      if (!await isDoneToday(h)) return h;
    }
    return habits.isEmpty ? null : habits.first;
  }

  Future<int> bestStreakAmongActive() async {
    final habits = await activeHabits();
    var best = 0;
    for (final h in habits) {
      final s = await streakFor(h);
      if (s > best) best = s;
    }
    return best;
  }

  static List<int> presetColors() => habitPresetColorValues();

  static String kindLabel(HabitKind k) => switch (k) {
        HabitKind.positive => 'Build',
        HabitKind.negative => 'Break',
        HabitKind.quantitative => 'Amount',
      };

  static String intervalLabel(HabitInterval i) => switch (i) {
        HabitInterval.daily => 'Daily',
        HabitInterval.weekly => 'Weekly',
        HabitInterval.monthly => 'Monthly',
        HabitInterval.weekdays => 'Specific days',
        HabitInterval.everyXDays => 'Every X days',
      };

  String get todayKey => habitDateKey(DateTime.now());

  Stream<void> watchHabitLogs() {
    return _isar.habitLogLocals
        .watchLazy(fireImmediately: false)
        .map((_) {});
  }

  Future<void> ensureTodayLogs() async {
    final habits = await activeHabits();
    final key = todayKey;
    for (final h in habits) {
      if (!isDue(h, key)) continue;
      await _ensureLog(h, key);
    }
  }

  Future<Map<String, Map<String, HabitLogView>>> allLogViews() async {
    final rows = await _isar.habitLogLocals
        .filter()
        .userIdEqualTo(_userId)
        .findAll();
    final map = <String, Map<String, HabitLogView>>{};
    for (final row in rows) {
      map.putIfAbsent(row.habitRemoteId, () => {});
      map[row.habitRemoteId]![row.dateKey] = _viewFromLocal(row);
    }
    return map;
  }

  Future<Map<String, HabitLogView>> logsForHabit(HabitLocal habit) async {
    final rows = await _isar.habitLogLocals
        .filter()
        .userIdEqualTo(_userId)
        .habitRemoteIdEqualTo(habit.remoteId)
        .findAll();
    return {
      for (final r in rows) r.dateKey: finalizeLog(_viewFromLocal(r), todayKey: todayKey),
    };
  }

  HabitLogView _viewFromLocal(HabitLogLocal row) => HabitLogView(
        dateKey: row.dateKey,
        status: row.status,
        currentValue: row.currentValue,
      );

  Future<HabitLogLocal> _ensureLog(HabitLocal habit, String dateKey) async {
    if (!isDue(habit, dateKey)) {
      throw StateError('Not due');
    }
    final existing = await _logLocal(habit.remoteId, dateKey);
    if (existing != null) return existing;
    return _isar.writeTxn(() async {
      final again = await _logLocal(habit.remoteId, dateKey);
      if (again != null) return again;
      await _migrateCompletionToLog(habit, dateKey);
      final migrated = await _logLocal(habit.remoteId, dateKey);
      if (migrated != null) return migrated;
      final row = HabitLogLocal()
        ..remoteId = const Uuid().v4()
        ..userId = _userId
        ..habitRemoteId = habit.remoteId
        ..dateKey = dateKey
        ..status = HabitLogStatus.pending
        ..currentValue = isHabitGoal(habit) ? 0 : null;
      await _isar.habitLogLocals.put(row);
      return row;
    });
  }

  Future<HabitLogLocal?> _logLocal(String habitId, String dateKey) =>
      _isar.habitLogLocals
          .filter()
          .userIdEqualTo(_userId)
          .habitRemoteIdEqualTo(habitId)
          .dateKeyEqualTo(dateKey)
          .findFirst();

  Future<void> _migrateCompletionToLog(
    HabitLocal habit,
    String dateKey,
  ) async {
    final day = parseHabitDateKey(dateKey);
    final c = await _isar.habitCompletionLocals
        .filter()
        .habitRemoteIdEqualTo(habit.remoteId)
        .userIdEqualTo(_userId)
        .dayEqualTo(HabitLogic.dayOnly(day))
        .findFirst();
    if (c == null) return;
    final target = habitGoalTarget(habit);
    final completed = isHabitGoal(habit)
        ? c.value >= target
        : c.value >= 1;
    final row = HabitLogLocal()
      ..remoteId = const Uuid().v4()
      ..userId = _userId
      ..habitRemoteId = habit.remoteId
      ..dateKey = dateKey
      ..currentValue = isHabitGoal(habit) ? c.value : null
      ..status = completed ? HabitLogStatus.completed : HabitLogStatus.pending;
    await _isar.habitLogLocals.put(row);
  }

  Future<void> _persistLog(HabitLocal habit, HabitLogLocal row) async {
    await _isar.writeTxn(() => _isar.habitLogLocals.put(row));
    await _syncCompletion(habit, row);
    await _afterWrite();
  }

  Future<void> _syncCompletion(HabitLocal habit, HabitLogLocal row) async {
    final day = parseHabitDateKey(row.dateKey);
    if (row.status == HabitLogStatus.completed) {
      final v = isHabitGoal(habit)
          ? (row.currentValue ?? habitGoalTarget(habit))
          : 1.0;
      await _setValue(habit, day, v);
    } else if (row.status == HabitLogStatus.pending &&
        isHabitGoal(habit) &&
        (row.currentValue ?? 0) > 0) {
      await _setValue(habit, day, row.currentValue!);
    } else if (row.status == HabitLogStatus.excused ||
        row.status == HabitLogStatus.missed ||
        (row.status == HabitLogStatus.pending &&
            (row.currentValue ?? 0) == 0)) {
      await _setValue(habit, day, null);
    }
  }

  Future<HabitLogView> toggleSimple(HabitLocal habit, String dateKey) async {
    final row = await _ensureLog(habit, dateKey);
    final isToday = dateKey == todayKey;
    if (isToday) {
      row.status = row.status == HabitLogStatus.completed
          ? HabitLogStatus.pending
          : HabitLogStatus.completed;
    } else {
      row.status = row.status == HabitLogStatus.completed
          ? HabitLogStatus.missed
          : HabitLogStatus.completed;
    }
    if (row.status == HabitLogStatus.completed && isHabitGoal(habit)) {
      row.currentValue = habitGoalTarget(habit);
    }
    await _persistLog(habit, row);
    return finalizeLog(_viewFromLocal(row), todayKey: todayKey);
  }

  Future<HabitLogView> stepGoal(
    HabitLocal habit,
    String dateKey,
    double delta,
  ) async {
    final row = await _ensureLog(habit, dateKey);
    final next = (row.currentValue ?? 0) + delta;
    row.currentValue = next < 0 ? 0 : next;
    if (row.currentValue! >= habitGoalTarget(habit)) {
      row.status = HabitLogStatus.completed;
      row.currentValue = row.currentValue!.clamp(0, habitGoalTarget(habit));
    } else {
      row.status = HabitLogStatus.pending;
    }
    await _persistLog(habit, row);
    return finalizeLog(_viewFromLocal(row), todayKey: todayKey);
  }

  Future<HabitLogView> setExcused(
    HabitLocal habit,
    String dateKey,
    bool excused,
  ) async {
    final row = await _ensureLog(habit, dateKey);
    row.status = excused ? HabitLogStatus.excused : HabitLogStatus.pending;
    await _persistLog(habit, row);
    return finalizeLog(_viewFromLocal(row), todayKey: todayKey);
  }

  Future<({int done, int total, double ratio})> trackerTodayScore() async {
    final habits = await activeHabits();
    final logs = await allLogViews();
    return todayScore(habits, logs, todayKey);
  }

  Future<int> trackerStreak(HabitLocal habit) async {
    final logs = await logsForHabit(habit);
    return currentStreakForHabit(habit, logs, todayKey);
  }

  Future<int> trackerLongestStreak(HabitLocal habit) async {
    final logs = await logsForHabit(habit);
    return longestStreakForHabit(habit, logs, todayKey);
  }
}

final habitRepositoryProvider = FutureProvider<HabitRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) throw StateError('No user');
  final repo = HabitRepository(isar, user.supabaseId ?? user.id.toString());
  await repo.ensureTodayLogs();
  return repo;
});

final habitLogViewsProvider =
    StreamProvider<Map<String, Map<String, HabitLogView>>>((ref) async* {
  ref.watch(habitRefreshProvider);
  final repo = await ref.watch(habitRepositoryProvider.future);
  yield await repo.allLogViews();
  await for (final _ in repo.watchHabitLogs()) {
    yield await repo.allLogViews();
  }
});

final habitRefreshProvider = StateProvider<int>((ref) => 0);

void bumpHabitRefresh(WidgetRef ref, {bool scheduleCloudSync = true}) {
  ref.read(habitRefreshProvider.notifier).state++;
  if (scheduleCloudSync && !ruhhOverlayIsolate) {
    scheduleCloudSyncFromWidget(ref);
  }
  if (!ruhhOverlayIsolate) {
    unawaited(refreshStreakProtectionAlarm(ref));
  }
}
