import 'package:isar/isar.dart';

part 'focus_session_local.g.dart';

@collection
class FocusSessionLocal {
  Id id = Isar.autoIncrement;

  late String remoteId;
  late String userId;
  late String habitRemoteId;
  late int targetMinutes;
  late int seconds;
  late bool completed;
  late DateTime startedAt;
}
