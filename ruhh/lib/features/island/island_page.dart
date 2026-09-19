import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruhh/core/data/models/habit_local.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_button.dart';
import 'package:ruhh/core/widgets/nb_card.dart';
import 'package:ruhh/features/focus/focus_repository.dart';
import 'package:ruhh/features/habit/habit_repository.dart';
import 'package:ruhh/features/island/island_controller.dart';
import 'package:ruhh/features/island/island_ledger.dart';
import 'package:ruhh/features/todo/todo_repository.dart';

class IslandPage extends ConsumerWidget {
  const IslandPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final island = ref.watch(islandProvider);
    final habitRepo = ref.watch(habitRepositoryProvider);
    final focusRepo = ref.watch(focusRepositoryProvider);
    final todoRepo = ref.watch(todoRepositoryProvider);

    return habitRepo.when(
      data: (hRepo) => focusRepo.when(
        data: (fRepo) => todoRepo.when(
          data: (tRepo) => FutureBuilder<IslandLedger>(
            future: () async {
              final sessions = await fRepo.allSessions();
              final todos = await tRepo.completedCount();
              return IslandLedger.compute(
                habitRepo: hRepo,
                sessions: sessions,
                completedTodos: todos,
              );
            }(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final ledger = snap.data!;
              final balance =
                  ref.read(islandProvider.notifier).balance(ledger.earned);

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  NBCard(
                    color: const Color(0x88B2DFDB),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(island.name,
                            style: Theme.of(context).textTheme.headlineMedium),
                        Text('Balance: $balance coins'),
                        Text('Earned total: ${ledger.earned}'),
                        const SizedBox(height: 8),
                        Text(
                          'Checks ${ledger.checks} · Focus ${ledger.focusMinutes}m · '
                          'Perfect days ${ledger.perfectDays} · Todos ${ledger.todos}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Your island',
                      style: Theme.of(context).textTheme.titleLarge),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final id in island.owned)
                        Chip(
                          label: Text(_emojiFor(id)),
                        ),
                      if (island.owned.isEmpty)
                        const Text('Buy items below to build your island.'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Shop', style: Theme.of(context).textTheme.titleLarge),
                  ...IslandCatalog.pieces.map((p) {
                    final owned = island.owned.contains(p.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: NBCard(
                        child: Row(
                          children: [
                            Text(p.emoji, style: const TextStyle(fontSize: 28)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.name),
                                  Text('${p.price} coins'),
                                ],
                              ),
                            ),
                            NBButton(
                              expand: false,
                              label: owned ? 'Owned' : 'Buy',
                              color: owned ? Colors.grey : NBColors.habit,
                              onPressed: owned
                                  ? null
                                  : () async {
                                      await ref
                                          .read(islandProvider.notifier)
                                          .buy(p.id, p.price, balance);
                                    },
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 80),
                ],
              );
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }

  static String _emojiFor(String id) {
    for (final p in IslandCatalog.pieces) {
      if (p.id == id) return p.emoji;
    }
    return id;
  }
}
