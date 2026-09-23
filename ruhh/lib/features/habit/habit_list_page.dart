import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/core/data/models/habit_local.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_layout.dart';
import 'package:ruhh/core/widgets/ruhh_scroll_insets.dart';
import 'package:ruhh/features/habit/habit_repository.dart';
import 'package:ruhh/features/habit/tracker/habit_scheduling.dart';
import 'package:ruhh/features/habit/tracker/habit_appearance.dart';

class HabitListPage extends ConsumerWidget {
  const HabitListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repoAsync = ref.watch(habitRepositoryProvider);

    return repoAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (repo) => StreamBuilder(
        stream: repo.watchActiveHabits(),
        builder: (context, activeSnap) {
          final active = activeSnap.data ?? [];
          return FutureBuilder(
            future: repo.archivedHabits(),
            builder: (context, archSnap) {
              final archived = archSnap.data ?? [];
              return NBPageBody(
                child: ListView(
                  children: [
                    Row(
                      children: [
                        Text('Active habits',
                            style: Theme.of(context).textTheme.titleLarge),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => context.push('/habit/new'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (active.isEmpty)
                      const NBEmptyState(message: 'No active habits yet.')
                    else
                      ...active.map((h) => _HabitRow(repo: repo, habit: h)),
                    if (archived.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      ExpansionTile(
                        title: const Text('Archived'),
                        children: archived
                            .map(
                              (h) => ListTile(
                                title: Text(h.name),
                                trailing: TextButton(
                                  onPressed: () async {
                                    await repo.restoreHabit(h);
                                    bumpHabitRefresh(ref);
                                  },
                                  child: const Text('Restore'),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const RuhhNavClearance(extra: 12),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _HabitRow extends ConsumerWidget {
  const _HabitRow({required this.repo, required this.habit});

  final HabitRepository repo;
  final HabitLocal habit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<int>(
      future: repo.trackerStreak(habit),
      builder: (context, snap) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            border: Border.all(color: NBColors.black, width: NBMetrics.borderWidth),
            color: NBColors.surfaceFill(Theme.of(context).brightness),
            boxShadow: const [
              BoxShadow(color: NBColors.shadow, offset: Offset(3, 3), blurRadius: 0),
            ],
          ),
          child: ListTile(
            leading: habitIconChip(habit.icon, Color(habit.colorValue), size: 36),
            title: Text(habit.name),
            subtitle: Text(
              '${scheduleSummary(habit)} · 🔥 ${snap.data ?? 0}',
            ),
            onTap: () => context.push('/habit/detail/${habit.remoteId}'),
            trailing: PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'archive') {
                  await repo.archiveHabit(habit);
                  bumpHabitRefresh(ref);
                } else if (v == 'edit') {
                  context.push('/habit/edit/${habit.remoteId}');
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'archive', child: Text('Archive')),
              ],
            ),
          ),
        );
      },
    );
  }
}
