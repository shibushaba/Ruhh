import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruhh/core/data/models/todo_local.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_button.dart';
import 'package:ruhh/core/widgets/nb_card.dart';
import 'package:ruhh/core/widgets/nb_text_field.dart';
import 'package:ruhh/features/todo/todo_logic.dart';
import 'package:ruhh/features/todo/todo_repository.dart';

class TodosPage extends ConsumerStatefulWidget {
  const TodosPage({super.key});

  @override
  ConsumerState<TodosPage> createState() => _TodosPageState();
}

class _TodosPageState extends ConsumerState<TodosPage> {
  final _text = TextEditingController();

  @override
  Widget build(BuildContext context) {
    ref.watch(todoRefreshProvider);
    final repoAsync = ref.watch(todoRepositoryProvider);
    return repoAsync.when(
      data: (repo) => StreamBuilder(
        stream: repo.watchAll(),
        builder: (context, snap) {
          final todos = snap.data ?? [];
          final pending = todos.where((t) => !t.done).toList()
            ..sort((a, b) => a.dateKey.compareTo(b.dateKey));
          final done = todos.where((t) => t.done).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              NBCard(
                child: Column(
                  children: [
                    NBTextField(controller: _text, label: 'New todo'),
                    const SizedBox(height: 8),
                    NBButton(
                      label: 'Add for today',
                      color: NBColors.habit,
                      onPressed: () async {
                        if (_text.text.trim().isEmpty) return;
                        await repo.add(
                          text: _text.text.trim(),
                          dateKey: TodoLogic.dayKey(DateTime.now()),
                        );
                        _text.clear();
                        bumpTodoRefresh(ref);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Open', style: Theme.of(context).textTheme.titleLarge),
              ...pending.map((t) => _tile(repo, t)),
              if (done.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Done', style: Theme.of(context).textTheme.titleMedium),
                ...done.take(20).map((t) => _tile(repo, t)),
              ],
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }

  Widget _tile(TodoRepository repo, TodoLocal t) {
    return ListTile(
      title: Text(t.text.split('\n').first),
      subtitle: Text(t.dateKey.isEmpty ? 'Someday' : t.dateKey),
      leading: Checkbox(
        value: t.done,
        onChanged: (_) async {
          await repo.toggle(t);
          bumpTodoRefresh(ref);
        },
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () async {
          await repo.delete(t);
          bumpTodoRefresh(ref);
        },
      ),
    );
  }
}
