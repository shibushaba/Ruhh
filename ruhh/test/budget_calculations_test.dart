import 'package:flutter_test/flutter_test.dart';
import 'package:ruhh/core/data/models/transaction_local.dart';
import 'package:ruhh/features/budget/ledger/budget_calculations.dart';
import 'package:ruhh/features/budget/ledger/budget_category_ids.dart';

void main() {
  test('Section 6 worked example', () {
    const month = '2026-09';
    final rows = <BudgetLedgerRow>[
      const BudgetLedgerRow(
        id: '1',
        type: BudgetLedgerType.salary,
        amount: 25000,
        categoryId: BudgetCategoryIds.salary,
        monthKey: month,
      ),
      const BudgetLedgerRow(
        id: '2',
        type: BudgetLedgerType.credit,
        amount: 500,
        categoryId: BudgetCategoryIds.refund,
        monthKey: month,
      ),
      const BudgetLedgerRow(
        id: '3',
        type: BudgetLedgerType.expense,
        amount: 3000,
        categoryId: BudgetCategoryIds.food,
        monthKey: month,
      ),
      const BudgetLedgerRow(
        id: '4',
        type: BudgetLedgerType.expense,
        amount: 1200,
        categoryId: BudgetCategoryIds.medical,
        monthKey: month,
      ),
    ];

    const rules = [
      BudgetRuleRow(
        categoryId: BudgetCategoryIds.food,
        monthKey: 'recurring',
        limitAmount: 5000,
        rolloverEnabled: false,
      ),
    ];

    final totals = BudgetCalculations.monthTotals(rows, month);
    expect(totals.totalIncome, 25500);
    expect(totals.totalExpense, 4200);
    expect(totals.balance, closeTo(21300, 0.001));

    expect(
      BudgetCalculations.categorySpend(rows, month, BudgetCategoryIds.food),
      3000,
    );
    expect(
      BudgetCalculations.categorySpend(rows, month, BudgetCategoryIds.medical),
      1200,
    );

    expect(
      BudgetCalculations.categoryPercentOfTotalExpense(
        rows,
        month,
        BudgetCategoryIds.food,
      ),
      closeTo(3000 / 4200, 0.001),
    );

    final foodRatio = BudgetCalculations.budgetUsageRatio(
      rows,
      rules,
      month,
      BudgetCategoryIds.food,
    );
    expect(foodRatio, closeTo(0.6, 0.001));

    expect(
      BudgetCalculations.budgetUsageRatio(
        rows,
        rules,
        month,
        BudgetCategoryIds.medical,
      ),
      isNull,
    );

    // Credit must not reduce expense totals.
    final withExtraCredit = [
      ...rows,
      const BudgetLedgerRow(
        id: '5',
        type: BudgetLedgerType.credit,
        amount: 9999,
        categoryId: BudgetCategoryIds.refund,
        monthKey: month,
      ),
    ];
    expect(
      BudgetCalculations.monthTotals(withExtraCredit, month).totalExpense,
      4200,
    );
  });
}
