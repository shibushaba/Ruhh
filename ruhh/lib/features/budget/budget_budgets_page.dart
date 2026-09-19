import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruhh/core/data/models/budget_extras_local.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_button.dart';
import 'package:ruhh/core/widgets/nb_dialog.dart';
import 'package:ruhh/core/widgets/nb_form_fields.dart';
import 'package:ruhh/core/widgets/nb_glass.dart';
import 'package:ruhh/core/widgets/nb_layout.dart';
import 'package:ruhh/core/widgets/nb_text_field.dart';
import 'package:ruhh/features/budget/budget_format.dart';
import 'package:ruhh/features/budget/budget_repository.dart';
import 'package:ruhh/features/budget/widgets/budget_goals_section.dart';
import 'package:ruhh/features/budget/widgets/budget_period_card.dart';
import 'package:ruhh/features/budget/widgets/budget_ui.dart';

class BudgetBudgetsPage extends ConsumerWidget {
  const BudgetBudgetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(budgetRefreshProvider);
    final repoAsync = ref.watch(budgetRepositoryProvider);
    return repoAsync.when(
      data: (repo) => FutureBuilder(
        future: Future.wait([
          repo.budgets(),
          repo.spentThisMonth(),
          repo.objectives(),
        ]),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final budgets = snap.data![0] as List<BudgetPeriodLocal>;
          final spent = BudgetFormat.sanitize(snap.data![1] as double);
          final objectives = snap.data![2] as List<ObjectiveLocal>;
          return NBPageBody(
            child: ListView(
              children: [
                NBSection(
                  title: 'Budget periods',
                  subtitle: 'Monthly caps and category limits.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (budgets.isEmpty)
                        const BudgetEmptyCard(
                          message: 'No budgets yet — add a monthly cap below.',
                        ),
                      ...budgets.map(
                        (b) => Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      NBButton(
                        label: 'Add budget',
                        color: NBColors.budget,
                        onPressed: () => _editBudget(context, ref, repo, null),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: NBLayout.sectionGap),
                NBSection(
                  title: 'Goals',
                  subtitle:
                      'Savings and debt targets — contribute from transactions.',
                  child: BudgetGoalsSection(
                    repo: repo,
                    objectives: objectives,
                  ),
                ),
                const SizedBox(height: 72),
              ],
            ),
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
      text: existing != null
          ? BudgetFormat.sanitize(existing.limitAmount).toStringAsFixed(0)
          : '2000',
    );
    await showNBFormDialog(
      context: context,
      title: existing == null ? 'Add budget' : 'Edit budget',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NBTextField(controller: nameCtrl, label: 'Name'),
          const SizedBox(height: 12),
          NBTextField(
            controller: limitCtrl,
            label: 'Monthly limit',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ),
      actions: (dialogCtx) => [
        if (existing != null)
          NBDialogAction(
            label: 'Delete',
            destructive: true,
            onPressed: () async {
              await repo.deleteBudgetPeriod(existing.id);
              bumpBudgetRefresh(ref);
              if (dialogCtx.mounted) popNBDialog(dialogCtx);
            },
          ),
        NBDialogAction(
          label: 'Cancel',
          onPressed: () => popNBDialog(dialogCtx),
        ),
        NBDialogAction(
          label: 'Save',
          primary: true,
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
            if (dialogCtx.mounted) popNBDialog(dialogCtx);
          },
        ),
      ],
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
          padding: const EdgeInsets.only(bottom: 8),
          child: NBGlassPanel(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BudgetSectionHeader(
                  title: 'Category limits',
                  actionLabel: 'Add limit',
                  onAction: () => _addLimit(context, ref, repo, budget),
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
                      final catSpent =
                          BudgetFormat.sanitize(spentSnap.data ?? 0);
                      final lim = BudgetFormat.sanitize(l.limitAmount);
                      final p = lim <= 0 ? 0.0 : (catSpent / lim).clamp(0.0, 1.0);
                      return BudgetListRow(
                        title: l.categoryName,
                        subtitle:
                            '${BudgetFormat.money(catSpent, decimals: 0)} of ${BudgetFormat.money(lim, decimals: 0)}',
                        accent: catSpent > lim ? Colors.red : NBColors.budget,
                        trailing: SizedBox(
                          width: 48,
                          child: NBProgressBar(
                            progress: p,
                            color: catSpent > lim
                                ? Colors.red.shade700
                                : NBColors.budget,
                          ),
                        ),
                        onTap: () => _editLimit(context, ref, repo, budget, l),
                      );
                    },
                  ),
                ),
              ],
            ),
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
    await showNBStatefulFormDialog(
      context: context,
      title: 'Category limit',
      content: (_, setLocal) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          NBDropdownField<String>(
            label: 'Category',
            value: category,
            items: cats
                .map(
                  (c) => DropdownMenuItem(
                    value: c.name,
                    child: Text(c.name),
                  ),
                )
                .toList(),
            onChanged: (v) => setLocal(() => category = v ?? category),
          ),
          const SizedBox(height: 12),
          NBTextField(
            controller: limitCtrl,
            label: 'Monthly limit',
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ),
      actions: (dialogCtx, __) => [
        NBDialogAction(
          label: 'Cancel',
          onPressed: () => popNBDialog(dialogCtx),
        ),
        NBDialogAction(
          label: 'Save',
          primary: true,
          onPressed: () async {
            final lim = double.tryParse(limitCtrl.text) ?? 0;
            if (lim <= 0) return;
            await repo.upsertCategoryLimit(
              budgetRemoteId: budget.remoteId,
              categoryName: category,
              limitAmount: lim,
            );
            bumpBudgetRefresh(ref);
            if (dialogCtx.mounted) popNBDialog(dialogCtx);
          },
        ),
      ],
    );
  }

  Future<void> _editLimit(
    BuildContext context,
    WidgetRef ref,
    BudgetRepository repo,
    BudgetPeriodLocal budget,
    CategoryBudgetLimitLocal limit,
  ) async {
    final limitCtrl = TextEditingController(
      text: BudgetFormat.sanitize(limit.limitAmount).toStringAsFixed(0),
    );
    await showNBFormDialog(
      context: context,
      title: 'Limit · ${limit.categoryName}',
      content: NBTextField(
        controller: limitCtrl,
        label: 'Monthly limit',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
      actions: (dialogCtx) => [
        NBDialogAction(
          label: 'Delete',
          destructive: true,
          onPressed: () async {
            await repo.deleteCategoryLimit(limit.id);
            bumpBudgetRefresh(ref);
            if (dialogCtx.mounted) popNBDialog(dialogCtx);
          },
        ),
        NBDialogAction(
          label: 'Cancel',
          onPressed: () => popNBDialog(dialogCtx),
        ),
        NBDialogAction(
          label: 'Save',
          primary: true,
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
            if (dialogCtx.mounted) popNBDialog(dialogCtx);
          },
        ),
      ],
    );
  }
}
