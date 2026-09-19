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
  double openingBalance = 0;
}

@collection
class CategoryLocal {
  Id id = Isar.autoIncrement;
  late String remoteId;
  late String userId;
  late String name;
  late bool isIncome;
  late int colorValue;
  late int sortOrder;
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
  late int colorValue;
  bool archived = false;
}

@collection
class ObjectiveLocal {
  Id id = Isar.autoIncrement;
  late String remoteId;
  late String userId;
  late String name;
  late double targetAmount;
  late String kind; // savings | debt
  late String walletName;
  late int colorValue;
  bool pinned = true;
  bool archived = false;
  DateTime? endDate;
  late int sortOrder;
}

@collection
class CategoryBudgetLimitLocal {
  Id id = Isar.autoIncrement;
  late String remoteId;
  late String userId;
  late String budgetRemoteId;
  late String categoryName;
  late double limitAmount;
}
