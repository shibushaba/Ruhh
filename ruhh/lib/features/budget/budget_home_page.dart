import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ruhh/core/data/models/budget_extras_local.dart';
import 'package:ruhh/core/widgets/nb_layout.dart';
import 'package:ruhh/core/widgets/ruhh_components.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';
import 'package:ruhh/features/budget/budget_repository.dart';
import 'package:ruhh/features/budget/ledger/budget_calculations.dart';
import 'package:ruhh/features/budget/ledger/budget_inr.dart';
import 'package:ruhh/features/budget/ledger/budget_month_key.dart';
import 'package:ruhh/features/budget/widgets/budget_caps_section.dart';
import 'package:ruhh/features/budget/widgets/budget_pie_chart.dart';
import 'package:ruhh/features/budget/widgets/category_display.dart';

class BudgetHomePage extends ConsumerStatefulWidget {
  const BudgetHomePage({super.key});

  @override
  ConsumerState<BudgetHomePage> createState() => _BudgetHomePageState();
}

class _BudgetHomePageState extends ConsumerState<BudgetHomePage> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  String? _pieCategoryFilter;

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _pieCategoryFilter = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(budgetRefreshProvider);
    final repoAsync = ref.watch(budgetRepositoryProvider);
    return repoAsync.when(
      data: (repo) => FutureBuilder(
        future: Future.wait([
          repo.monthTotals(_month),
          repo.expenseByCategory(_month),
          repo.budgetRules(),
          repo.activeCategories(income: false),
          repo.ledgerRows(),
          repo.standingSalary(),
        ]),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final totals = snap.data![0] as BudgetMonthTotals;
          final byCat = snap.data![1] as Map<String, double>;
          final rules = snap.data![2] as List<BudgetRuleRow>;
          final expenseCats = snap.data![3] as List<CategoryLocal>;
          final rows = snap.data![4] as List<BudgetLedgerRow>;
          final standing = snap.data![5] as StandingSalaryLocal?;
          final monthKey = budgetMonthKey(_month);

          final catName = {for (final c in expenseCats) c.remoteId: c.name};
          final budgetedIds = rules
              .where((r) =>
                  r.monthKey == 'recurring' ||
                  r.monthKey == monthKey)
              .map((r) => r.categoryId)
              .toSet();

          final pieSlices = <BudgetPieSlice>[];
          var colorIndex = 0;
          for (final c in expenseCats) {
            final amount = byCat[c.remoteId] ?? 0;
            if (amount <= 0) continue;
            pieSlices.add(
              BudgetPieSlice(
                categoryId: c.remoteId,
                label: categoryChipLabel(c),
                amount: amount,
                color: categoryAccentColorOrFallback(c, colorIndex),
              ),
            );
            colorIndex++;
          }
          for (final e in byCat.entries) {
            if (e.value <= 0) continue;
            if (expenseCats.any((c) => c.remoteId == e.key)) continue;
            pieSlices.add(
              BudgetPieSlice(
                categoryId: e.key,
                label: catName[e.key] ?? e.key,
                amount: e.value,
                color: categoryAccentColorOrFallback(null, colorIndex),
              ),
            );
            colorIndex++;
          }
          pieSlices.sort((a, b) => b.amount.compareTo(a.amount));

          return NBPageBody(
            child: ListView(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _shiftMonth(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Text(
                        DateFormat.yMMMM().format(_month),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      onPressed: _month.year == DateTime.now().year &&
                              _month.month == DateTime.now().month
                          ? null
                          : () => _shiftMonth(1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                if (standing == null || standing.amount <= 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Set monthly salary in Manage → Salary to auto-credit each month.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                const SizedBox(height: 8),
                RuhhStatProgressCard(
                  label: 'Balance',
                  value: BudgetInr.format(totals.balance),
                  targetLabel: DateFormat.yMMMM().format(_month),
                  progress: totals.totalIncome <= 0
                      ? 0
                      : (totals.balance / totals.totalIncome).clamp(0, 1),
                ),
                const SizedBox(height: 16),
                RuhhTwinMetricRow(
                  left: RuhhStatProgressCard(
                    compact: true,
                    label: 'Income',
                    value: BudgetInr.format(totals.totalIncome),
                    progress: 1,
                    accent: context.ruhh.accentMint,
                  ),
                  right: RuhhStatProgressCard(
                    compact: true,
                    label: 'Expense',
                    value: BudgetInr.format(totals.totalExpense),
                    progress: totals.totalIncome <= 0
                        ? 0
                        : (totals.totalExpense / totals.totalIncome)
                            .clamp(0, 1),
                    accent: context.ruhh.textPrimary,
                  ),
                ),
                const SizedBox(height: NBLayout.sectionGap),
                NBSection(
                  title: 'Expense breakdown',
                  subtitle: _pieCategoryFilter == null
                      ? 'Tap the chart or a row for details · tap again to filter caps'
                      : 'Filtering budgets: ${catName[_pieCategoryFilter] ?? _pieCategoryFilter}',
                  child: BudgetPieChart(
                    slices: pieSlices,
                    selectedCategoryId: _pieCategoryFilter,
                    onSelectedCategoryIdChanged: (id) {
                      setState(() => _pieCategoryFilter = id);
                    },
                  ),
                ),
                const SizedBox(height: NBLayout.sectionGap),
                BudgetCapsSection(
                  expenseCats: expenseCats,
                  budgetedIds: budgetedIds,
                  rules: rules,
                  rows: rows,
                  byCat: byCat,
                  monthKey: monthKey,
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
