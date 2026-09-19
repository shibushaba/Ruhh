import 'package:ruhh/core/data/models/habit_local.dart';
import 'package:ruhh/core/data/models/todo_local.dart';
import 'package:ruhh/core/data/models/focus_session_local.dart';
import 'package:ruhh/features/habit/habit_logic.dart';
import 'package:ruhh/features/habit/habit_repository.dart';

class IslandLedger {
  const IslandLedger({
    required this.checks,
    required this.focusMinutes,
    required this.perfectDays,
    required this.todos,
    required this.milestones,
  });

  static const perCheck = 10;
  static const perFocusMinute = 1;
  static const focusCapPerDay = 60;
  static const perPerfectDay = 25;
  static const perTodo = 4;

  static const steps = [(7, 30), (30, 150), (100, 600), (365, 2500)];

  final int checks;
  final int focusMinutes;
  final int perfectDays;
  final int todos;
  final int milestones;

  int get earned =>
      checks * perCheck +
      focusMinutes * perFocusMinute +
      perfectDays * perPerfectDay +
      todos * perTodo +
      milestones;

  static Future<IslandLedger> compute({
    required HabitRepository habitRepo,
    required List<FocusSessionLocal> sessions,
    required int completedTodos,
  }) async {
    final habits = await habitRepo.activeHabits();
    final today = HabitLogic.dayOnly(DateTime.now());
    var checks = 0;
    var milestones = 0;
    final perfectDayKeys = <String>{};

    for (final h in habits) {
      final map = await habitRepo.completionsMap(h);
      final streak = HabitLogic.currentStreak(h, map, now: DateTime.now());
      for (final step in steps) {
        if (streak >= step.$1) milestones += step.$2;
      }
      for (final entry in map.entries) {
        if (entry.key.isAfter(today)) continue;
        if (!HabitLogic.isCompletedOn(h, entry.key, entry.value, now: DateTime.now())) {
          continue;
        }
        checks++;
        perfectDayKeys.add(HabitLogic.dayOnly(entry.key).toIso8601String());
      }
    }

    var perfect = 0;
    for (final key in perfectDayKeys) {
      final date = DateTime.parse(key);
      var all = true;
      var any = false;
      for (final h in habits) {
        if (!HabitLogic.isScheduledOn(h, date)) continue;
        any = true;
        final map = await habitRepo.completionsMap(h);
        if (!HabitLogic.isCompletedOn(h, date, map[date], now: DateTime.now())) {
          all = false;
          break;
        }
      }
      if (any && all) perfect++;
    }

    final perDay = <String, int>{};
    for (final s in sessions) {
      final k = HabitLogic.dayOnly(s.startedAt).toIso8601String();
      perDay[k] = (perDay[k] ?? 0) + (s.seconds ~/ 60);
    }
    var minutes = 0;
    for (final v in perDay.values) {
      minutes += v > focusCapPerDay ? focusCapPerDay : v;
    }

    return IslandLedger(
      checks: checks,
      focusMinutes: minutes,
      perfectDays: perfect,
      todos: completedTodos,
      milestones: milestones,
    );
  }
}

class IslandPiece {
  const IslandPiece(this.id, this.name, this.price, this.emoji);
  final String id;
  final String name;
  final int price;
  final String emoji;
}

abstract final class IslandCatalog {
  static const pieces = [
    IslandPiece('palm', 'Palm tree', 80, '🌴'),
    IslandPiece('hut', 'Beach hut', 120, '🛖'),
    IslandPiece('boat', 'Boat', 200, '⛵'),
    IslandPiece('lighthouse', 'Lighthouse', 350, '🗼'),
    IslandPiece('volcano', 'Volcano', 500, '🌋'),
  ];
}
