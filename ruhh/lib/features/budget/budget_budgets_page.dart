import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruhh/core/data/models/budget_extras_local.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_button.dart';
import 'package:ruhh/features/budget/budget_repository.dart';
import 'package:ruhh/features/budget/widgets/budget_period_card.dart';

class BudgetBudgetsPage extends ConsumerWidget {
  const BudgetBudgetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(budgetRefreshProvider);
    final repoAsync = ref.watch(budgetRepositoryProvider);
    return repoAsync.when(
      data: (repo) => FutureBuilder(
        future: Future.wait([repo.budgets(), repo.spentThisMonth()]),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final budgets = snap.data![0] as List<BudgetPeriodLocal>;
          final spent = snap.data![1] as double;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Budgets', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              if (budgets.isEmpty)
                const Text('No budgets yet — add one below.'),
              ...budgets.map(
                (b) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BudgetPeriodCard(
                      budget: b,
                      spent: spent,
                      onTap: () => _editBudget(context, ref, repo, b),
                    ),
                    _CategoryLimitsSection(
                      budget: b,
                      repo: repo,
                      ref: ref,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              NBButton(
                label: 'Add budget',
                color: NBColors.budget,
                onPressed: () => _editBudget(context, ref, repo, null),
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

  Future<void> _editBudget(
    BuildContext context,
    WidgetRef ref,
    BudgetRepository repo,
    BudgetPeriodLocal? existing,
  ) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final limitCtrl = TextEditingController(
      text: existing?.limitAmount.toStringAsFixed(0) ?? '2000',
    );
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add budget' : 'Edit budget'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            TextField(
              controller: limitCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Limit'),
            ),
          ],
        ),
        actions: [
          if (existing != null)
            TextButton(
              onPressed: () async {
                await repo.deleteBudgetPeriod(existing.id);
                bumpBudgetRefresh(ref);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final limit = double.tryParse(limitCtrl.text) ?? 0;
              if (nameCtrl.text.trim().isEmpty || limit <= 0) return;
              await repo.upsertBudgetPeriod(
                id: existing?.id,
                name: nameCtrl.text.trim(),
                limitAmount: limit,
                colorValue: existing?.colorValue ?? NBColors.budget.toARGB32(),
              );
              bumpBudgetRefresh(ref);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _CategoryLimitsSection extends StatelessWidget {
  const _CategoryLimitsSection({
    required this.budget,
    required this.repo,
    required this.ref,
  });

  final BudgetPeriodLocal budget;
  final BudgetRepository repo;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final range = monthRange(DateTime.now());
    return FutureBuilder(
      future: repo.categoryLimitsForBudget(budget.remoteId),
      builder: (context, snap) {
        final limits = snap.data ?? [];
        return Padding(
          padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Category limits',
                      style: Theme.of(context).textTheme.titleMedium),
                  TextButton(
                    onPressed: () => _addLimit(context, ref, repo, budget),
                    child: const Text('Add limit'),
                  ),
                ],
              ),
              if (limits.isEmpty)
                Text(
                  'Set per-category caps for this budget period.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ...limits.map(
                (l) => FutureBuilder(
                  future: repo.categorySpentInRange(
                    l.categoryName,
                    range.start,
                    range.end,
                  ),
                  builder: (context, spentSnap) {
                    final catSpent = spentSnap.data ?? 0;
                    final p = l.limitAmount <= 0
                        ? 0.0
                        : (catSpent / l.limitAmount).clamp(0.0, 1.0);
                    return ListTile(
                      dense: true,
                      title: Text(l.categoryName),
                      subtitle: LinearProgressIndicator(
                        value: p,
                        minHeight: 6,
                        color: catSpent > l.limitAmount
                            ? Colors.red
                            : NBColors.budget,
                      ),
                      trailing: Text(
                        '\$${catSpent.toStringAsFixed(0)}/\$${l.limitAmount.toStringAsFixed(0)}',
                      ),
                      onTap: () => _editLimit(context, ref, repo, budget, l),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addLimit(
    BuildContext context,
    WidgetRef ref,
    BudgetRepository repo,
    BudgetPeriodLocal budget,
  ) async {
    final cats = await repo.categories(income: false);
    if (cats.isEmpty || !context.mounted) return;
    var category = cats.first.name;
    final limitCtrl = TextEditingController(text: '200');
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Category limit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: category,
                items: cats
                    .map((c) => DropdownMenuItem(
                          value: c.name,
                          child: Text(c.name),
                        ))
                    .toList(),
                onChanged: (v) => setLocal(() => category = v ?? category),
              ),
              TextField(
                controller: limitCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Monthly limit'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                final lim = double.tryParse(limitCtrl.text) ?? 0;
                if (lim <= 0) return;
                await repo.upsertCategoryLimit(
                  budgetRemoteId: budget.remoteId,
                  categoryName: category,
                  limitAmount: lim,
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

  Future<void> _editLimit(
    BuildContext context,
    WidgetRef ref,
    BudgetRepository repo,
    BudgetPeriodLocal budget,
    CategoryBudgetLimitLocal limit,
  ) async {
    final limitCtrl =
        TextEditingController(text: limit.limitAmount.toStringAsFixed(0));
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Limit · ${limit.categoryName}'),
        content: TextField(
          controller: limitCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Monthly limit'),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await repo.deleteCategoryLimit(limit.id);
              bumpBudgetRefresh(ref);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final lim = double.tryParse(limitCtrl.text) ?? 0;
              if (lim <= 0) return;
              await repo.upsertCategoryLimit(
                id: limit.id,
                budgetRemoteId: budget.remoteId,
                categoryName: limit.categoryName,
                limitAmount: lim,
              );
              bumpBudgetRefresh(ref);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
