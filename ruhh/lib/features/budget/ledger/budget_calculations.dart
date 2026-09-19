import 'package:ruhh/core/data/models/transaction_local.dart';
import 'package:ruhh/features/budget/ledger/budget_category_ids.dart';
import 'package:ruhh/features/budget/ledger/budget_month_key.dart';

/// Pure ledger row for Section 6 math.
class BudgetLedgerRow {
  const BudgetLedgerRow({
    required this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.monthKey,
  });

  final String id;
  final BudgetLedgerType type;
  final double amount;
  final String categoryId;
  final String monthKey;
}

class BudgetRuleRow {
  const BudgetRuleRow({
    required this.categoryId,
    required this.monthKey,
    required this.limitAmount,
    required this.rolloverEnabled,
  });

  final String categoryId;
  final String monthKey;
  final double limitAmount;
  final bool rolloverEnabled;
}

class BudgetMonthTotals {
  const BudgetMonthTotals({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.salaryAmount,
    required this.creditTotal,
  });

  final double totalIncome;
  final double totalExpense;
  final double balance;
  final double salaryAmount;
  final double creditTotal;
}

/// Section 6 — core formulas (pure, testable).
abstract final class BudgetCalculations {
  static double sanitize(double v) => v.isFinite && v > 0 ? v : 0;

  static List<BudgetLedgerRow> forMonth(
    List<BudgetLedgerRow> all,
    String monthKey,
  ) =>
      all.where((t) => t.monthKey == monthKey).toList();

  static BudgetMonthTotals monthTotals(
    List<BudgetLedgerRow> all,
    String monthKey,
  ) {
    final month = forMonth(all, monthKey);
    var salary = 0.0;
    var credits = 0.0;
    var expense = 0.0;
    for (final t in month) {
      final a = sanitize(t.amount);
      switch (t.type) {
        case BudgetLedgerType.salary:
          salary += a;
        case BudgetLedgerType.credit:
          credits += a;
        case BudgetLedgerType.expense:
          expense += a;
      }
    }
    final income = salary + credits;
    return BudgetMonthTotals(
      totalIncome: income,
      totalExpense: expense,
      balance: income - expense,
      salaryAmount: salary,
      creditTotal: credits,
    );
  }

  static double categorySpend(
    List<BudgetLedgerRow> all,
    String monthKey,
    String categoryId,
  ) {
    return forMonth(all, monthKey)
        .where((t) =>
            t.type == BudgetLedgerType.expense && t.categoryId == categoryId)
        .fold<double>(0, (s, t) => s + sanitize(t.amount));
  }

  static double? budgetLimitFor(
    List<BudgetLedgerRow> all,
    List<BudgetRuleRow> rules,
    String monthKey,
    String categoryId,
  ) {
    final oneOff = rules.where(
      (r) => r.categoryId == categoryId && r.monthKey == monthKey,
    );
    if (oneOff.isNotEmpty) {
      return sanitize(oneOff.first.limitAmount);
    }

    final recurring = rules.where(
      (r) =>
          r.categoryId == categoryId &&
          r.monthKey == BudgetLedgerKeys.recurringBudgetMonth,
    );
    if (recurring.isEmpty) return null;

    final rule = recurring.first;
    var limit = sanitize(rule.limitAmount);
    if (rule.rolloverEnabled) {
      final prevKey = budgetPreviousMonthKey(monthKey);
      if (prevKey != null) {
        final prevLimit = budgetLimitFor(all, rules, prevKey, categoryId);
        if (prevLimit != null && prevLimit > 0) {
          final prevSpend = categorySpend(all, prevKey, categoryId);
          limit += (prevLimit - prevSpend).clamp(0.0, double.infinity);
        }
      }
    }
    return limit;
  }

  static double? budgetUsageRatio(
    List<BudgetLedgerRow> all,
    List<BudgetRuleRow> rules,
    String monthKey,
    String categoryId,
  ) {
    final limit = budgetLimitFor(all, rules, monthKey, categoryId);
    if (limit == null || limit <= 0) return null;
    final spend = categorySpend(all, monthKey, categoryId);
    return spend / limit;
  }

  static double? categoryPercentOfTotalExpense(
    List<BudgetLedgerRow> all,
    String monthKey,
    String categoryId,
  ) {
    final totals = monthTotals(all, monthKey);
    if (totals.totalExpense <= 0) return null;
    final spend = categorySpend(all, monthKey, categoryId);
    return spend / totals.totalExpense;
  }

  static double allTimeBalance(List<BudgetLedgerRow> all) {
    final keys = all.map((t) => t.monthKey).toSet();
    var balance = 0.0;
    for (final key in keys) {
      balance += monthTotals(all, key).balance;
    }
    return balance;
  }

  static Map<String, double> expenseByCategory(
    List<BudgetLedgerRow> all,
    String monthKey,
  ) {
    final map = <String, double>{};
    for (final t in forMonth(all, monthKey)) {
      if (t.type != BudgetLedgerType.expense) continue;
      map[t.categoryId] = (map[t.categoryId] ?? 0) + sanitize(t.amount);
    }
    return map;
  }
}
