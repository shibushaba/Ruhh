import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruhh/core/widgets/nb_layout.dart';
import 'package:ruhh/features/budget/budget_repository.dart';
import 'package:ruhh/features/budget/widgets/budget_goals_section.dart';

/// Standalone goals view (legacy); primary UI is under Budgets tab.
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
          return NBPageBody(
            child: ListView(
              children: [
                NBSection(
                  title: 'Goals',
                  subtitle:
                      'Savings targets and debt payoff — link contributions from transactions.',
                  child: BudgetGoalsSection(
                    repo: repo,
                    objectives: snap.data!,
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
}
