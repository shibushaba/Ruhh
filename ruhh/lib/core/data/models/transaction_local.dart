import 'package:isar/isar.dart';

part 'transaction_local.g.dart';

@collection
class TransactionLocal {
  Id id = Isar.autoIncrement;

  late String remoteId;
  late String userId;

  late double amount;
  late bool isIncome;
  late String category;
  late String account;
  late String note;
  late DateTime occurredAt;
}
