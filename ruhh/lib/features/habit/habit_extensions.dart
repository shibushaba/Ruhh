import 'dart:convert';

import 'package:ruhh/core/data/models/habit_local.dart';
import 'package:ruhh/core/data/models/habit_reminder.dart';
import 'package:ruhh/core/data/models/vacation_period.dart';

extension HabitLocalExtras on HabitLocal {
  List<VacationPeriod> get vacations {
    try {
      final list = jsonDecode(vacationsJson) as List;
      return list
          .map((e) => VacationPeriod.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  set vacations(List<VacationPeriod> periods) {
    vacationsJson = jsonEncode(periods.map((e) => e.toJson()).toList());
  }

  List<HabitReminder> get reminders {
    try {
      final list = jsonDecode(remindersJson) as List;
      return list
          .map((e) => HabitReminder.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  set reminders(List<HabitReminder> list) {
    remindersJson = jsonEncode(list.map((e) => e.toJson()).toList());
  }

  bool get isOnVacation => vacations.any((v) => v.isOngoing);
}
