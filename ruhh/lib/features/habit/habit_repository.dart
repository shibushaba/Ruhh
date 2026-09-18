import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:ruhh/core/data/models/habit_local.dart';
import 'package:ruhh/core/session/session_providers.dart';
import 'package:uuid/uuid.dart';

class HabitRepository {
  HabitRepository(this._isar, this._userId);

  final Isar _isar;
  final String _userId;

  Future<List<HabitLocal>> activeHabits() => _isar.habitLocals
      .filter()
      .userIdEqualTo(_userId)
      .archivedEqualTo(false)
      .findAll();

  Future<void> addHabit({
    required String name,
    required int colorValue,
    int targetPerDay = 1,
    int? reminderMinute,
  }) async {
    final habit = HabitLocal()
      ..remoteId = const Uuid().v4()
      ..userId = _userId
      ..name = name
      ..colorValue = colorValue
      ..frequency = 'daily'
      ..targetPerDay = targetPerDay
      ..reminderMinute = reminderMinute
      ..archived = false
      ..createdAt = DateTime.now();
    await _isar.writeTxn(() => _isar.habitLocals.put(habit));
  }

  Future<void> markDone(HabitLocal habit, {DateTime? day}) async {
    final d = _dayOnly(day ?? DateTime.now());
    final existing = await _isar.habitCompletionLocals
        .filter()
        .habitRemoteIdEqualTo(habit.remoteId)
        .dayEqualTo(d)
        .findFirst();
    if (existing != null) return;
    final completion = HabitCompletionLocal()
      ..remoteId = const Uuid().v4()
      ..habitRemoteId = habit.remoteId
      ..userId = _userId
      ..day = d
      ..value = 1;
    await _isar.writeTxn(() => _isar.habitCompletionLocals.put(completion));
  }

  Future<int> streakFor(HabitLocal habit) async {
    final completions = await _isar.habitCompletionLocals
        .filter()
        .habitRemoteIdEqualTo(habit.remoteId)
        .sortByDayDesc()
        .findAll();
    if (completions.isEmpty) return 0;
    var streak = 0;
    var cursor = _dayOnly(DateTime.now());
    for (final c in completions) {
      if (_dayOnly(c.day) == cursor) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else if (_dayOnly(c.day).isBefore(cursor)) {
        break;
      }
    }
    return streak;
  }

  Future<bool> isDoneToday(HabitLocal habit) async {
    final d = _dayOnly(DateTime.now());
    final hit = await _isar.habitCompletionLocals
        .filter()
        .habitRemoteIdEqualTo(habit.remoteId)
        .dayEqualTo(d)
        .findFirst();
    return hit != null;
  }

  Future<HabitLocal?> nextDueHabit() async {
    final habits = await activeHabits();
    for (final h in habits) {
      if (!await isDoneToday(h)) return h;
    }
    return habits.isEmpty ? null : habits.first;
  }

  static DateTime _dayOnly(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);
}

final habitRepositoryProvider = FutureProvider<HabitRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) throw StateError('No user');
  return HabitRepository(isar, user.supabaseId ?? user.id.toString());
});
