import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/core/data/models/budget_extras_local.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_button.dart';
import 'package:ruhh/core/widgets/nb_card.dart';
import 'package:ruhh/features/budget/budget_repository.dart';
import 'package:ruhh/features/budget/budget_schedule.dart';

class BudgetObjectivesPage extends ConsumerWidget {
  const BudgetObjectivesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(budgetRefreshProvider);
    final repoAsync = ref.watch(budgetRepositoryProvider);
    return repoAsync.when(
      data: (repo) => FutureBuilder(
        future: repo.objectives(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final objectives = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Goals', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Track savings targets and debt payoff like Cashew objectives.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              if (objectives.isEmpty)
                const NBCard(
                  child: Text('No goals yet — add a savings or debt goal.'),
                ),
              ...objectives.map(
                (o) => FutureBuilder(
                  future: repo.objectiveContributed(o),
                  builder: (context, progSnap) {
                    final contributed = progSnap.data ?? 0;
                    final progress = o.targetAmount <= 0
                        ? 0.0
                        : (contributed / o.targetAmount).clamp(0.0, 1.0);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: NBCard(
                        color: Color(o.colorValue).withValues(alpha: 0.25),
                        onTap: () => _editObjective(context, ref, repo, o),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(o.name,
                                style: Theme.of(context).textTheme.titleLarge),
                            Text(objectiveKindLabel(
                              o.kind == 'debt'
                                  ? ObjectiveKind.debt
                                  : ObjectiveKind.savings,
                            )),
                            Text(
                              '\$${contributed.toStringAsFixed(0)} / \$${o.targetAmount.toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: progress,
                              minHeight: 10,
                              backgroundColor: Colors.white,
                              color: NBColors.budget,
                            ),
                            const SizedBox(height: 8),
                            NBButton(
                              label: 'Add contribution',
                              color: NBColors.budget,
                              onPressed: () => context.push(
                                '/budget/add?objective=${o.remoteId}',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              NBButton(
                label: 'Add goal',
                color: NBColors.budget,
                onPressed: () => _editObjective(context, ref, repo, null),
              ),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }

  Future<void> _editObjective(
    BuildContext context,
    WidgetRef ref,
    BudgetRepository repo,
    ObjectiveLocal? existing,
  ) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final target =
        TextEditingController(text: existing?.targetAmount.toStringAsFixed(0) ?? '1000');
    var kind = existing?.kind ?? 'savings';
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null ? 'New goal' : 'Edit goal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: target,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Target amount'),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'savings', label: Text('Savings')),
                  ButtonSegment(value: 'debt', label: Text('Debt')),
                ],
                selected: {kind},
                onSelectionChanged: (s) => setLocal(() => kind = s.first),
              ),
            ],
          ),
          actions: [
            if (existing != null)
              TextButton(
                onPressed: () async {
                  await repo.deleteObjective(existing.id);
                  bumpBudgetRefresh(ref);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                final t = double.tryParse(target.text) ?? 0;
                if (name.text.trim().isEmpty || t <= 0) return;
                await repo.upsertObjective(
                  id: existing?.id,
                  name: name.text.trim(),
                  targetAmount: t,
                  kind: kind,
                  walletName: existing?.walletName ?? 'Cash',
                  colorValue: existing?.colorValue,
                );
                bumpBudgetRefresh(ref);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
