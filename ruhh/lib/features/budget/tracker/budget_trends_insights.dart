import 'package:ruhh/core/data/models/budget_extras_local.dart';
import 'package:ruhh/features/budget/ledger/budget_calculations.dart'
    show BudgetCalculations, BudgetLedgerRow, BudgetMonthTotals;
import 'package:ruhh/features/budget/ledger/budget_month_key.dart';

class BudgetTrendsSnapshot {
  BudgetTrendsSnapshot({
    required this.monthKeys,
    required this.monthlyTotals,
    required this.totalIncome,
    required this.totalExpense,
    required this.netSaved,
    required this.savingsRate,
    required this.allTimeBalance,
    required this.topSpend,
    required this.highestExpenseMonthKey,
    required this.highestExpenseAmount,
    required this.currentMonthKey,
    required this.expenseChangeVsPriorMonth,
    required this.incomeChangeVsPriorMonth,
  });

  final List<String> monthKeys;
  final List<BudgetMonthTotals> monthlyTotals;
  final double totalIncome;
  final double totalExpense;
  final double netSaved;
  final double savingsRate;
  final double allTimeBalance;
  final List<TopSpendEntry> topSpend;
  final String? highestExpenseMonthKey;
  final double highestExpenseAmount;
  final String currentMonthKey;
  final double expenseChangeVsPriorMonth;
  final double incomeChangeVsPriorMonth;
}

class TopSpendEntry {
  const TopSpendEntry({
    required this.categoryId,
    required this.amount,
    required this.shareOfExpense,
  });

  final String categoryId;
  final double amount;
  final double shareOfExpense;
}

class BudgetTrendsInsights {
  static BudgetTrendsSnapshot build(
    List<BudgetLedgerRow> rows, {
    int monthCount = 6,
    List<CategoryLocal> expenseCategories = const [],
  }) {
    final now = DateTime.now();
    final monthKeys = List.generate(monthCount, (i) {
      final m = DateTime(now.year, now.month - (monthCount - 1 - i));
      return budgetMonthKey(m);
    });

    final monthlyTotals = [
      for (final k in monthKeys) BudgetCalculations.monthTotals(rows, k),
    ];

    var totalIncome = 0.0;
    var totalExpense = 0.0;
    String? peakMonth;
    var peakExpense = 0.0;

    for (var i = 0; i < monthKeys.length; i++) {
      final t = monthlyTotals[i];
      totalIncome += t.totalIncome;
      totalExpense += t.totalExpense;
      if (t.totalExpense > peakExpense) {
        peakExpense = t.totalExpense;
        peakMonth = monthKeys[i];
      }
    }

    final catTotals = <String, double>{};
    for (final c in expenseCategories) {
      catTotals[c.remoteId] = 0;
    }
    for (final k in monthKeys) {
      for (final e in BudgetCalculations.expenseByCategory(rows, k).entries) {
        catTotals[e.key] = (catTotals[e.key] ?? 0) + e.value;
      }
    }

    final topEntries = catTotals.entries.toList()
      ..sort((a, b) {
        final byAmount = b.value.compareTo(a.value);
        if (byAmount != 0) return byAmount;
        return categoryLabel(a.key, expenseCategories)
            .compareTo(categoryLabel(b.key, expenseCategories));
      });

    final topSpend = <TopSpendEntry>[];
    for (final e in topEntries) {
      topSpend.add(
        TopSpendEntry(
          categoryId: e.key,
          amount: e.value,
          shareOfExpense:
              totalExpense > 0 ? e.value / totalExpense : 0,
        ),
      );
    }

    final currentKey = monthKeys.last;
    final priorKey =
        monthKeys.length > 1 ? monthKeys[monthKeys.length - 2] : null;
    final current = monthlyTotals.last;
    final prior =
        priorKey != null ? monthlyTotals[monthKeys.length - 2] : null;

    return BudgetTrendsSnapshot(
      monthKeys: monthKeys,
      monthlyTotals: monthlyTotals,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netSaved: totalIncome - totalExpense,
      savingsRate:
          totalIncome > 0 ? (totalIncome - totalExpense) / totalIncome : 0,
      allTimeBalance: BudgetCalculations.allTimeBalance(rows),
      topSpend: topSpend,
      highestExpenseMonthKey: peakMonth,
      highestExpenseAmount: peakExpense,
      currentMonthKey: currentKey,
      expenseChangeVsPriorMonth: prior != null
          ? current.totalExpense - prior.totalExpense
          : 0,
      incomeChangeVsPriorMonth:
          prior != null ? current.totalIncome - prior.totalIncome : 0,
    );
  }

  static String categoryLabel(
    String categoryId,
    List<CategoryLocal> categories,
  ) {
    for (final c in categories) {
      if (c.remoteId == categoryId) return c.name;
    }
    return categoryId;
  }
}
