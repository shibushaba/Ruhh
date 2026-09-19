import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:ruhh/core/data/models/habit_local.dart';
import 'package:ruhh/core/data/models/habit_reminder.dart';
import 'package:ruhh/core/data/models/vacation_period.dart';
import 'package:ruhh/core/services/home_widget_service.dart';
import 'package:ruhh/core/session/session_providers.dart';
import 'package:ruhh/features/habit/habit_extensions.dart';
import 'package:ruhh/features/habit/habit_logic.dart';
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
      ..createdAt = DateTime.now();
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

  static List<int> presetColors() => [
        0xFFF97316,
        0xFF22C55E,
        0xFF14B8A6,
        0xFFA855F7,
        0xFF3B82F6,
        0xFFEC4899,
        0xFFEAB308,
        0xFFEF4444,
      ];

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
}

final habitRepositoryProvider = FutureProvider<HabitRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) throw StateError('No user');
  return HabitRepository(isar, user.supabaseId ?? user.id.toString());
});

final habitRefreshProvider = StateProvider<int>((ref) => 0);

void bumpHabitRefresh(WidgetRef ref) {
  ref.read(habitRefreshProvider.notifier).state++;
}
