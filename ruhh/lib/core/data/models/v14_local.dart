import 'package:isar/isar.dart';

part 'v14_local.g.dart';

@collection
class V14ProfileLocal {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String userId;

  String? petId;
  String petName = '';
  DateTime? petChosenAt;
  String callName = '';
  bool listMode = false;
  bool showLabels = false;
  bool leftHandOrb = false;
  bool firstRunDone = false;
  int lastSeenLevel = 0;
  String morningSeenKey = '';
  String eveningSeenKey = '';
}

@collection
class QuestLocal {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String remoteId;

  @Index()
  late String userId;

  late String title;
  bool done = false;
  bool archived = false;
  late DateTime createdAt;
}

@collection
class GoalLocal {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String remoteId;

  @Index()
  late String userId;

  late String title;
  bool done = false;
  int sortOrder = 0;
  late DateTime createdAt;
}

@collection
class MilestoneLocal {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String remoteId;

  @Index()
  late String goalRemoteId;

  @Index()
  late String userId;

  late String title;
  bool done = false;
  int sortOrder = 0;
}

@collection
class PlannerStopLocal {
  Id id = Isar.autoIncrement;

  @Index()
  late String userId;

  late String dateKey;
  late String label;
  int minuteOfDay = 8 * 60;
  String kind = 'note';
}

@collection
class LocalXpEventLocal {
  Id id = Isar.autoIncrement;

  @Index()
  late String userId;

  late String source;

  @Index()
  late String sourceRef;

  int amount = 0;
  bool reversed = false;
  late DateTime createdAt;
}

@collection
class ChatTurnLocal {
  Id id = Isar.autoIncrement;

  @Index()
  late String userId;

  late String role;
  late String text;
  String proposalJson = '';
  String proposalState = '';
  late DateTime createdAt;
}

@collection
class JourneyMarkLocal {
  Id id = Isar.autoIncrement;

  @Index()
  late String userId;

  late String title;
  late String kind;
  late DateTime createdAt;
}
