import 'package:ruhh/core/data/models/transaction_local.dart';

enum ObjectiveKind {
  savings,
  debt,
}

/// Whether this transaction affects spent/income totals and wallet balance.
bool transactionCountsInLedger(TransactionLocal t) {
  if (t.scheduleType == BudgetScheduleType.normal) return true;
  return t.paid;
}

DateTime addRecurrence(DateTime from, String recurrence, int periodLength) {
  switch (recurrence) {
    case 'daily':
      return from.add(Duration(days: periodLength));
    case 'weekly':
      return from.add(Duration(days: 7 * periodLength));
    case 'yearly':
      return DateTime(from.year + periodLength, from.month, from.day);
    case 'monthly':
    default:
      return DateTime(from.year, from.month + periodLength, from.day);
  }
}

bool isTransactionOverdue(TransactionLocal t) {
  if (t.paid) return false;
  if (t.scheduleType == BudgetScheduleType.normal) return false;
  return t.occurredAt.isBefore(DateTime.now());
}

String scheduleTypeLabel(BudgetScheduleType type) => switch (type) {
      BudgetScheduleType.normal => 'Regular',
      BudgetScheduleType.upcoming => 'Upcoming',
      BudgetScheduleType.subscription => 'Subscription',
      BudgetScheduleType.repetitive => 'Repeating',
    };

String objectiveKindLabel(ObjectiveKind kind) => switch (kind) {
      ObjectiveKind.savings => 'Savings goal',
      ObjectiveKind.debt => 'Debt payoff',
    };
