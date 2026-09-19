/// Stable category ids for seeded defaults (Section 4).
abstract final class BudgetCategoryIds {
  static const salary = 'income-salary';
  static const bonus = 'income-bonus';
  static const refund = 'income-refund';
  static const giftIncome = 'income-gift';
  static const otherIncome = 'income-other';

  static const food = 'exp-food';
  static const medical = 'exp-medical';
  static const transport = 'exp-transport';
  static const rent = 'exp-rent';
  static const utilities = 'exp-utilities';
  static const shopping = 'exp-shopping';
  static const entertainment = 'exp-entertainment';
  static const otherExpense = 'exp-other';
}

abstract final class BudgetLedgerKeys {
  static const recurringBudgetMonth = 'recurring';
}
