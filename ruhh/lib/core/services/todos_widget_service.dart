import 'dart:convert';

import 'package:home_widget/home_widget.dart';
import 'package:ruhh/core/data/models/todo_local.dart';
import 'package:ruhh/features/todo/todo_repository.dart';

class TodosWidgetService {
  static Future<void> sync(TodoRepository repo) async {
    try {
      final pending = await repo.pendingTodos(limit: 40);
      await HomeWidget.saveWidgetData<String>(
        'todos_data',
        jsonEncode({
          'pending': pending
              .map((t) => {'id': t.remoteId, 'title': t.text.split('\n').first})
              .toList(),
        }),
      );
      await HomeWidget.updateWidget(androidName: 'RuhhTodayWidgetProvider');
    } catch (_) {}
  }
}
