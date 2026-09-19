import 'package:intl/intl.dart';
import 'package:ruhh/core/data/models/todo_local.dart';

abstract final class TodoLogic {
  static String dayKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  static DateTime? parseDay(String key) {
    if (key.isEmpty) return null;
    return DateTime.tryParse(key);
  }

  static String sectionFor(TodoLocal todo) {
    if (todo.done) return 'done';
    final due = parseDay(todo.dateKey);
    if (due == null) return 'someday';
    final today = DateTime.now();
    final t = DateTime(today.year, today.month, today.day);
    final d = DateTime(due.year, due.month, due.day);
    if (d.isBefore(t)) return 'overdue';
    if (d == t) return 'today';
    if (d == t.add(const Duration(days: 1))) return 'tomorrow';
    return 'upcoming';
  }
}
