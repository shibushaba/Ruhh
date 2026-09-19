import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:ruhh/core/data/models/todo_local.dart';
import 'package:ruhh/core/services/notification_service.dart';
import 'package:ruhh/core/services/reminder_schedule.dart';
import 'package:ruhh/core/services/todos_widget_service.dart';
import 'package:ruhh/core/session/session_providers.dart';
import 'package:ruhh/features/todo/todo_logic.dart';
import 'package:uuid/uuid.dart';

class TodoRepository {
  TodoRepository(this._isar, this._userId, this._notifications);

  final Isar _isar;
  final String _userId;
  final NotificationService? _notifications;

  Stream<List<TodoLocal>> watchAll() async* {
    yield await allTodos();
    await for (final _ in _isar.todoLocals.watchLazy(fireImmediately: false)) {
      yield await allTodos();
    }
  }

  Future<List<TodoLocal>> allTodos() => _isar.todoLocals
      .filter()
      .userIdEqualTo(_userId)
      .findAll();

  Future<List<TodoLocal>> pendingTodos({int limit = 100}) async {
    final list = await _isar.todoLocals
        .filter()
        .userIdEqualTo(_userId)
        .doneEqualTo(false)
        .findAll();
    list.sort((a, b) => a.dateKey.compareTo(b.dateKey));
    return list.take(limit).toList();
  }

  Future<void> add({
    required String text,
    String dateKey = '',
    int? minutesOfDay,
  }) async {
    final t = TodoLocal()
      ..remoteId = const Uuid().v4()
      ..userId = _userId
      ..text = text
      ..done = false
      ..dateKey = dateKey
      ..minutesOfDay = minutesOfDay
      ..priority = TodoPriority.none
      ..createdAt = DateTime.now();
    await _isar.writeTxn(() => _isar.todoLocals.put(t));
    await _scheduleTodo(t);
    await TodosWidgetService.sync(this);
  }

  Future<void> toggle(TodoLocal todo) async {
    todo.done = !todo.done;
    todo.doneAt = todo.done ? DateTime.now() : null;
    await _isar.writeTxn(() => _isar.todoLocals.put(todo));
    await _scheduleTodo(todo);
    await TodosWidgetService.sync(this);
  }

  Future<void> delete(TodoLocal todo) async {
    await _notifications?.cancel(ReminderSchedule.todoReminderId(todo.remoteId));
    await _isar.writeTxn(() => _isar.todoLocals.delete(todo.id));
    await TodosWidgetService.sync(this);
  }

  Future<int> completedCount() => _isar.todoLocals
      .filter()
      .userIdEqualTo(_userId)
      .doneEqualTo(true)
      .count();

  Future<void> _scheduleTodo(TodoLocal todo) async {
    final n = _notifications;
    if (n == null) return;
    final id = ReminderSchedule.todoReminderId(todo.remoteId);
    await n.cancel(id);
    if (todo.done) return;
    final day = TodoLogic.parseDay(todo.dateKey);
    if (day == null || todo.minutesOfDay == null) return;
    final when = DateTime(
      day.year,
      day.month,
      day.day,
      todo.minutesOfDay! ~/ 60,
      todo.minutesOfDay! % 60,
    );
    await n.scheduleTodoAt(
      id: id,
      title: 'Todo due',
      body: todo.text.split('\n').first,
      when: when,
      payload: '/habit?tab=1',
    );
  }
}

final todoRepositoryProvider = FutureProvider<TodoRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  final user = await ref.watch(currentUserProvider.future);
  final n = await ref.watch(notificationServiceProvider.future);
  if (user == null) throw StateError('No user');
  return TodoRepository(isar, user.supabaseId ?? user.id.toString(), n);
});

final todoRefreshProvider = StateProvider<int>((ref) => 0);

void bumpTodoRefresh(WidgetRef ref) {
  ref.read(todoRefreshProvider.notifier).state++;
}
