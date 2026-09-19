import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/core/data/models/budget_extras_local.dart';
import 'package:ruhh/core/data/models/transaction_local.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_card.dart';
import 'package:ruhh/features/budget/budget_repository.dart';
import 'package:ruhh/features/budget/widgets/budget_pie_chart.dart';
import 'package:ruhh/features/budget/widgets/budget_period_card.dart';
import 'package:ruhh/features/budget/widgets/budget_transaction_list.dart';

class BudgetHomePage extends ConsumerWidget {
  const BudgetHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(budgetRefreshProvider);
    final repoAsync = ref.watch(budgetRepositoryProvider);
    return repoAsync.when(
      data: (repo) => FutureBuilder(
        future: Future.wait([
          repo.allWalletBalances(),
          repo.spentThisMonth(),
          repo.incomeInRange(
            monthRange(DateTime.now()).start,
            monthRange(DateTime.now()).end,
          ),
          repo.spendByCategoryThisMonth(),
          repo.budgets(),
          repo.recent(limit: 8),
        ]),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final wallets = snap.data![0] as List<WalletBalance>;
          final spent = snap.data![1] as double;
          final income = snap.data![2] as double;
          final byCat = snap.data![3] as Map<String, double>;
          final budgets = snap.data![4] as List<BudgetPeriodLocal>;
          final recent = snap.data![5] as List<TransactionLocal>;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Overview', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              NBCard(
                color: NBColors.budget.withValues(alpha: 0.2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Net (all wallets)',
                        style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      '\$${wallets.fold<double>(0, (s, w) => s + w.balance).toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Text(
                      'This month: +\$${income.toStringAsFixed(0)} / -\$${spent.toStringAsFixed(0)}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...wallets.map(
                (w) => NBCard(
                  child: ListTile(
                    title: Text(w.wallet.name),
                    subtitle: Text(w.wallet.currency),
                    trailing: Text(
                      '\$${w.balance.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Spending', style: Theme.of(context).textTheme.titleLarge),
              BudgetPieChart(byCategory: byCat),
              const SizedBox(height: 16),
              if (budgets.isNotEmpty)
                BudgetPeriodCard(
                  budget: budgets.first,
                  spent: spent,
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent', style: Theme.of(context).textTheme.titleLarge),
                  TextButton(
                    onPressed: () => context.go('/budget?tab=1'),
                    child: const Text('All transactions'),
                  ),
                ],
              ),
              BudgetTransactionList(
                transactions: recent,
                groupByDay: false,
                onTap: (t) => context.push('/budget/edit/${t.id}'),
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
}
