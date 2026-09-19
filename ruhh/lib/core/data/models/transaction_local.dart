import 'package:isar/isar.dart';

part 'transaction_local.g.dart';

enum BudgetScheduleType {
  normal,
  upcoming,
  subscription,
  repetitive,
}

@collection
class TransactionLocal {
  Id id = Isar.autoIncrement;

  late String remoteId;
  late String userId;

  late double amount;
  late bool isIncome;
  late String title;
  late String category;
  late String account;
  late String note;
  late DateTime occurredAt;

  @Enumerated(EnumType.name)
  BudgetScheduleType scheduleType = BudgetScheduleType.normal;

  /// Upcoming/subscription/repeating: counts toward totals only when true.
  bool paid = true;

  /// none, daily, weekly, monthly, yearly
  String recurrence = 'none';

  int periodLength = 1;

  DateTime? recurrenceEnd;

  String? objectiveRemoteId;
}
