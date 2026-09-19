import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:ruhh/core/data/models/habit_local.dart';
import 'package:ruhh/features/habit/habit_logic.dart';
import 'package:ruhh/features/habit/habit_repository.dart';

class HomeWidgetService {
  static Timer? _pending;
  static const _androidProviders = ['RuhhTodayWidgetProvider'];

  static bool get supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static void syncSoon(Future<HabitRepository> repoFuture) {
    if (!supported) return;
    _pending?.cancel();
    _pending = Timer(const Duration(milliseconds: 700), () async {
      final repo = await repoFuture;
      await sync(repo);
    });
  }

  static Future<void> sync(HabitRepository repo) async {
    if (!supported) return;
    try {
      await HomeWidget.setAppGroupId('group.com.ruhh.ruhh');
      final habits = await repo.activeHabits();
      final now = DateTime.now();
      final today = HabitLogic.dayOnly(now);
      var best = 0;
      var done = 0;
      var total = 0;
      final habitRows = <Map<String, dynamic>>[];

      for (final h in habits) {
        final map = await repo.completionsMap(h, since: today.subtract(const Duration(days: 14)));
        final streak = HabitLogic.currentStreak(h, map, now: now);
        if (streak > best) best = streak;
        if (HabitLogic.isScheduledOn(h, today) && !HabitLogic.isPausedOn(h, today)) {
          total++;
          if (HabitLogic.isCompletedOn(h, today, map[today], now: now)) done++;
        }
        habitRows.add({
          'id': h.remoteId,
          'name': h.name,
          'color': h.colorValue,
          'streak': streak,
          'doneToday': HabitLogic.isCompletedOn(h, today, map[today], now: now),
        });
      }

      await HomeWidget.saveWidgetData<String>(
        'summary',
        jsonEncode({
          'doneToday': done,
          'total': total,
          'bestStreak': best,
          'label': '$done/$total today',
        }),
      );
      await HomeWidget.saveWidgetData<String>(
        'habits_data',
        jsonEncode({'habits': habitRows, 'updated': now.toIso8601String()}),
      );
      for (final p in _androidProviders) {
        await HomeWidget.updateWidget(androidName: p);
      }
    } catch (e) {
      debugPrint('HomeWidget sync: $e');
    }
  }
}
