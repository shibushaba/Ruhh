enum PetWrite { saved, alreadyChosen, needsConfirm }

class V14ProfileData {
  const V14ProfileData({
    this.petId,
    this.petName = '',
    this.petChosenAt,
    this.callName = '',
    this.listMode = false,
    this.showLabels = false,
    this.leftHandOrb = false,
    this.firstRunDone = false,
    this.lastSeenLevel = 0,
    this.morningSeenKey = '',
    this.eveningSeenKey = '',
  });

  final String? petId;
  final String petName;
  final DateTime? petChosenAt;
  final String callName;
  final bool listMode;
  final bool showLabels;
  final bool leftHandOrb;
  final bool firstRunDone;
  final int lastSeenLevel;
  final String morningSeenKey;
  final String eveningSeenKey;

  String displayPetName(String fallback) =>
      petName.trim().isEmpty ? fallback : petName.trim();

  V14ProfileData copyWith({
    String? petId,
    String? petName,
    DateTime? petChosenAt,
    String? callName,
    bool? listMode,
    bool? showLabels,
    bool? leftHandOrb,
    bool? firstRunDone,
    int? lastSeenLevel,
    String? morningSeenKey,
    String? eveningSeenKey,
    bool clearPet = false,
  }) {
    return V14ProfileData(
      petId: clearPet ? null : (petId ?? this.petId),
      petName: petName ?? this.petName,
      petChosenAt: clearPet ? null : (petChosenAt ?? this.petChosenAt),
      callName: callName ?? this.callName,
      listMode: listMode ?? this.listMode,
      showLabels: showLabels ?? this.showLabels,
      leftHandOrb: leftHandOrb ?? this.leftHandOrb,
      firstRunDone: firstRunDone ?? this.firstRunDone,
      lastSeenLevel: lastSeenLevel ?? this.lastSeenLevel,
      morningSeenKey: morningSeenKey ?? this.morningSeenKey,
      eveningSeenKey: eveningSeenKey ?? this.eveningSeenKey,
    );
  }
}

class QuestData {
  const QuestData({
    required this.remoteId,
    required this.title,
    required this.done,
    required this.createdAt,
  });
  final String remoteId;
  final String title;
  final bool done;
  final DateTime createdAt;
}

class GoalData {
  const GoalData({
    required this.remoteId,
    required this.title,
    required this.done,
    required this.sortOrder,
  });
  final String remoteId;
  final String title;
  final bool done;
  final int sortOrder;
}

class MilestoneData {
  const MilestoneData({
    required this.remoteId,
    required this.goalRemoteId,
    required this.title,
    required this.done,
    required this.sortOrder,
  });
  final String remoteId;
  final String goalRemoteId;
  final String title;
  final bool done;
  final int sortOrder;
}

class PlannerStopData {
  const PlannerStopData({
    required this.id,
    required this.dateKey,
    required this.label,
    required this.minuteOfDay,
    required this.kind,
  });
  final int id;
  final String dateKey;
  final String label;
  final int minuteOfDay;
  final String kind;
}

class JourneyMarkData {
  const JourneyMarkData({
    required this.title,
    required this.kind,
    required this.createdAt,
  });
  final String title;
  final String kind;
  final DateTime createdAt;
}

class ChatTurnData {
  const ChatTurnData({
    required this.role,
    required this.text,
    required this.createdAt,
    this.proposalState = '',
  });
  final String role;
  final String text;
  final DateTime createdAt;
  final String proposalState;
}

class XpEventData {
  const XpEventData({
    required this.source,
    required this.sourceRef,
    required this.amount,
    required this.reversed,
  });
  final String source;
  final String sourceRef;
  final int amount;
  final bool reversed;
}
