import 'package:isar/isar.dart';

part 'budget_extras_local.g.dart';

@collection
class WalletLocal {
  Id id = Isar.autoIncrement;
  late String remoteId;
  late String userId;
  late String name;
  late String currency;
  late int colorValue;
  late int sortOrder;
}

@collection
class CategoryLocal {
  Id id = Isar.autoIncrement;
  late String remoteId;
  late String userId;
  late String name;
  late bool isIncome;
  late int colorValue;
}

@collection
class BudgetPeriodLocal {
  Id id = Isar.autoIncrement;
  late String remoteId;
  late String userId;
  late String name;
  late double limitAmount;
  late String period; // monthly, weekly
  late DateTime startsAt;
}
