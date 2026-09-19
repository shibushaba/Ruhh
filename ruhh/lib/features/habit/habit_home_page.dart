import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_button.dart';
import 'package:ruhh/features/habit/habit_repository.dart';
import 'package:ruhh/features/habit/widgets/habit_card.dart';
import 'package:ruhh/features/habit/widgets/vacation_sheet.dart';
import 'package:ruhh/features/habit/widgets/habit_today_progress.dart';

class HabitHomePage extends ConsumerStatefulWidget {
  const HabitHomePage({super.key});

  @override
  ConsumerState<HabitHomePage> createState() => _HabitHomePageState();
}

class _HabitHomePageState extends ConsumerState<HabitHomePage> {
  var _reorder = false;

  @override
  Widget build(BuildContext context) {
    ref.watch(habitRefreshProvider);
    final repoAsync = ref.watch(habitRepositoryProvider);

    return repoAsync.when(
      data: (repo) => StreamBuilder(
        stream: repo.watchActiveHabits(),
        builder: (context, habitSnap) {
          final habits = habitSnap.data ?? [];
          return FutureBuilder(
            future: repo.todayProgress(),
            builder: (context, progSnap) {
              final prog = progSnap.data;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (prog != null)
                          HabitTodayProgress(
                            done: prog.done,
                            total: prog.total,
                            ratio: prog.ratio,
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text('Today',
                                style:
                                    Theme.of(context).textTheme.titleLarge),
                            const Spacer(),
                            if (habits.isNotEmpty)
                              TextButton(
                                onPressed: () =>
                                    setState(() => _reorder = !_reorder),
                                child: Text(_reorder ? 'Done' : 'Reorder'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (habits.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            'No habits yet. Tap + to add your first one.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 12),
                          NBButton(
                            label: 'Create habit',
                            color: NBColors.habit,
                            onPressed: () => context.push('/habit/new'),
                          ),
                        ],
                      ),
                    )
                  else
                    Expanded(
                      child: _reorder
                          ? ReorderableListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                              itemCount: habits.length,
                              onReorder: (o, n) async {
                                await repo.reorder(o, n);
                                bumpHabitRefresh(ref);
                              },
                              itemBuilder: (context, i) => _habitTile(
                                context,
                                repo,
                                habits[i],
                                key: ValueKey(habits[i].remoteId),
                                dragHandle: ReorderableDragStartListener(
                                  index: i,
                                  child: const Icon(Icons.drag_handle),
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                              itemCount: habits.length,
                              itemBuilder: (context, i) => _habitTile(
                                context,
                                repo,
                                habits[i],
                              ),
                            ),
                    ),
                ],
              );
            },
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }

  Widget _habitTile(
    BuildContext context,
    HabitRepository repo,
    habit, {
    Key? key,
    Widget? dragHandle,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 10),
      child: FutureBuilder(
        future: Future.wait([
          repo.completionsMap(
            habit,
            since: DateTime.now().subtract(const Duration(days: 30)),
          ),
          repo.streakFor(habit),
        ]),
        builder: (context, snap) {
          final map = snap.data?[0] as Map<DateTime, double>? ?? {};
          final streak = snap.data?[1] as int? ?? 0;
          return Row(
            children: [
              if (dragHandle != null) ...[
                dragHandle,
                const SizedBox(width: 4),
              ],
              Expanded(
                child: HabitCard(
                  habit: habit,
                  byDay: map,
                  streak: streak,
                  onToggle: () async {
                    await repo.toggleToday(habit);
                    bumpHabitRefresh(ref);
                    setState(() {});
                  },
                  onAddProgress: (d) async {
                    await repo.addProgress(habit, d);
                    bumpHabitRefresh(ref);
                    setState(() {});
                  },
                  onLongPress: () => _actions(context, repo, habit),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _actions(BuildContext context, HabitRepository repo, habit) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.beach_access),
              title: const Text('Vacation & rest'),
              onTap: () {
                Navigator.pop(ctx);
                showVacationSheet(context, ref, habit);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit habit'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/habit/edit/${habit.remoteId}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: const Text('Archive'),
              onTap: () async {
                await repo.archiveHabit(habit);
                bumpHabitRefresh(ref);
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}
