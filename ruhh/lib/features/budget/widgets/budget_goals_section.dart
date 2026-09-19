import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/core/data/models/budget_extras_local.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_dialog.dart';
import 'package:ruhh/core/widgets/nb_glass.dart';
import 'package:ruhh/core/widgets/nb_button.dart';
import 'package:ruhh/core/widgets/nb_text_field.dart';
import 'package:ruhh/features/budget/budget_format.dart';
import 'package:ruhh/features/budget/budget_repository.dart';
import 'package:ruhh/features/budget/budget_schedule.dart';
import 'package:ruhh/features/budget/widgets/budget_ui.dart';

/// Goals list + add/edit — embedded in Budgets tab.
class BudgetGoalsSection extends ConsumerWidget {
  const BudgetGoalsSection({
    super.key,
    required this.repo,
    required this.objectives,
  });

  final BudgetRepository repo;
  final List<ObjectiveLocal> objectives;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (objectives.isEmpty)
          const BudgetEmptyCard(
            message: 'No goals yet — add a savings or debt goal.',
          ),
        ...objectives.map(
          (o) => FutureBuilder(
            future: repo.objectiveContributed(o),
            builder: (context, progSnap) {
              final contributed = BudgetFormat.sanitize(progSnap.data ?? 0);
              final target = BudgetFormat.sanitize(o.targetAmount);
              final progress =
                  target <= 0 ? 0.0 : (contributed / target).clamp(0.0, 1.0);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: NBGlassSurface(
                  accent: Color(o.colorValue),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        o.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        objectiveKindLabel(
                          o.kind == 'debt'
                              ? ObjectiveKind.debt
                              : ObjectiveKind.savings,
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${BudgetFormat.money(contributed, decimals: 0)} / ${BudgetFormat.money(target, decimals: 0)}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      NBProgressBar(
                        progress: progress,
                        color: NBColors.budget,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: NBButton(
                              label: 'Contribute',
                              color: NBColors.budget,
                              onPressed: () => context.push(
                                '/budget/add?objective=${o.remoteId}',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => editBudgetObjective(
                              context,
                              ref,
                              repo,
                              o,
                            ),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        NBButton(
          label: 'Add goal',
          color: NBColors.budget,
          onPressed: () => editBudgetObjective(context, ref, repo, null),
        ),
      ],
    );
  }
}

Future<void> editBudgetObjective(
  BuildContext context,
  WidgetRef ref,
  BudgetRepository repo,
  ObjectiveLocal? existing,
) async {
  final name = TextEditingController(text: existing?.name ?? '');
  final target = TextEditingController(
    text: existing != null
        ? BudgetFormat.sanitize(existing.targetAmount).toStringAsFixed(0)
        : '1000',
  );
  var kind = existing?.kind ?? 'savings';
  await showNBStatefulFormDialog(
    context: context,
    title: existing == null ? 'New goal' : 'Edit goal',
    content: (_, setLocal) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        NBTextField(controller: name, label: 'Name'),
        const SizedBox(height: 12),
        NBTextField(
          controller: target,
          label: 'Target amount',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 12),
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
    actions: (_, __) => [
      if (existing != null)
        NBDialogAction(
          label: 'Delete',
          destructive: true,
          onPressed: () async {
            await repo.deleteObjective(existing.id);
            bumpBudgetRefresh(ref);
            if (context.mounted) Navigator.pop(context);
          },
        ),
      NBDialogAction(
        label: 'Cancel',
        onPressed: () => Navigator.pop(context),
      ),
      NBDialogAction(
        label: 'Save',
        primary: true,
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
          if (context.mounted) Navigator.pop(context);
        },
      ),
    ],
  );
}
