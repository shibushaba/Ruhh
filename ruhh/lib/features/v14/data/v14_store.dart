import 'package:ruhh/features/v14/data/v14_models.dart';
import 'package:ruhh/features/v14/logic/xp_rules.dart';

abstract class V14Store {
  Future<V14ProfileData> loadProfile();
  Future<void> saveProfile(V14ProfileData profile);
  Future<PetWrite> choosePet({
    required String petId,
    required String petName,
    required String callName,
    required bool understandPermanent,
    required DateTime now,
  });
  Future<List<QuestData>> quests();
  Future<QuestData> addQuest(String title, {DateTime? now});
  Future<void> setQuestDone(String remoteId, bool done);
  Future<void> deleteQuest(String remoteId);
  Future<List<GoalData>> goals();
  Future<GoalData> addGoal(String title, {DateTime? now});
  Future<void> setGoalDone(String remoteId, bool done);
  Future<void> deleteGoal(String remoteId);
  Future<List<MilestoneData>> milestones(String goalRemoteId);
  Future<MilestoneData> addMilestone(String goalRemoteId, String title);
  Future<void> setMilestoneDone(String remoteId, bool done);
  Future<List<PlannerStopData>> stops(String dateKey);
  Future<PlannerStopData> addStop(
    String dateKey,
    String label,
    int minuteOfDay,
  );
  Future<void> moveStop(int id, int minuteOfDay);
  Future<void> deleteStop(int id);
  Future<int> lifetimeXp();
  Future<List<XpEventData>> xpEvents();
  Future<bool> award({
    required String source,
    required String sourceRef,
    int? amount,
    DateTime? now,
  });
  Future<bool> reverse(String sourceRef);
  Future<List<JourneyMarkData>> marks();
  Future<void> addMark(String title, String kind, {DateTime? now});
  Future<List<ChatTurnData>> chat();
  Future<void> addChat(
    String role,
    String text, {
    String proposalState = '',
    DateTime? now,
  });
}

class MemoryV14Store implements V14Store {
  V14ProfileData profile = const V14ProfileData();
  final quests_ = <QuestData>[];
  final goals_ = <GoalData>[];
  final milestones_ = <MilestoneData>[];
  final stops_ = <PlannerStopData>[];
  final xp_ = <XpEventData>[];
  final marks_ = <JourneyMarkData>[];
  final chat_ = <ChatTurnData>[];
  var _seq = 1;
  var _stopId = 1;

  String _id(String prefix) => '$prefix-${_seq++}';

  @override
  Future<V14ProfileData> loadProfile() async => profile;

  @override
  Future<void> saveProfile(V14ProfileData next) async {
    profile = next;
  }

  @override
  Future<PetWrite> choosePet({
    required String petId,
    required String petName,
    required String callName,
    required bool understandPermanent,
    required DateTime now,
  }) async {
    if (profile.petId != null) return PetWrite.alreadyChosen;
    if (!understandPermanent) return PetWrite.needsConfirm;
    profile = profile.copyWith(
      petId: petId,
      petName: petName,
      callName: callName,
      petChosenAt: now,
    );
    return PetWrite.saved;
  }

  @override
  Future<List<QuestData>> quests() async => quests_.where((q) => true).toList();

  @override
  Future<QuestData> addQuest(String title, {DateTime? now}) async {
    final row = QuestData(
      remoteId: _id('quest'),
      title: title,
      done: false,
      createdAt: now ?? DateTime.now(),
    );
    quests_.add(row);
    return row;
  }

  @override
  Future<void> setQuestDone(String remoteId, bool done) async {
    final i = quests_.indexWhere((q) => q.remoteId == remoteId);
    if (i < 0) return;
    final q = quests_[i];
    quests_[i] = QuestData(
      remoteId: q.remoteId,
      title: q.title,
      done: done,
      createdAt: q.createdAt,
    );
  }

  @override
  Future<void> deleteQuest(String remoteId) async {
    quests_.removeWhere((q) => q.remoteId == remoteId);
  }

  @override
  Future<List<GoalData>> goals() async {
    final copy = [...goals_]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return copy;
  }

  @override
  Future<GoalData> addGoal(String title, {DateTime? now}) async {
    final row = GoalData(
      remoteId: _id('goal'),
      title: title,
      done: false,
      sortOrder: goals_.length,
    );
    goals_.add(row);
    return row;
  }

  @override
  Future<void> setGoalDone(String remoteId, bool done) async {
    final i = goals_.indexWhere((g) => g.remoteId == remoteId);
    if (i < 0) return;
    final g = goals_[i];
    goals_[i] = GoalData(
      remoteId: g.remoteId,
      title: g.title,
      done: done,
      sortOrder: g.sortOrder,
    );
  }

  @override
  Future<void> deleteGoal(String remoteId) async {
    goals_.removeWhere((g) => g.remoteId == remoteId);
    milestones_.removeWhere((m) => m.goalRemoteId == remoteId);
  }

  @override
  Future<List<MilestoneData>> milestones(String goalRemoteId) async {
    final copy =
        milestones_.where((m) => m.goalRemoteId == goalRemoteId).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return copy;
  }

  @override
  Future<MilestoneData> addMilestone(String goalRemoteId, String title) async {
    final count = milestones_
        .where((m) => m.goalRemoteId == goalRemoteId)
        .length;
    final row = MilestoneData(
      remoteId: _id('mile'),
      goalRemoteId: goalRemoteId,
      title: title,
      done: false,
      sortOrder: count,
    );
    milestones_.add(row);
    return row;
  }

  @override
  Future<void> setMilestoneDone(String remoteId, bool done) async {
    final i = milestones_.indexWhere((m) => m.remoteId == remoteId);
    if (i < 0) return;
    final m = milestones_[i];
    milestones_[i] = MilestoneData(
      remoteId: m.remoteId,
      goalRemoteId: m.goalRemoteId,
      title: m.title,
      done: done,
      sortOrder: m.sortOrder,
    );
  }

  @override
  Future<List<PlannerStopData>> stops(String dateKey) async =>
      stops_.where((s) => s.dateKey == dateKey).toList();

  @override
  Future<PlannerStopData> addStop(
    String dateKey,
    String label,
    int minuteOfDay,
  ) async {
    final row = PlannerStopData(
      id: _stopId++,
      dateKey: dateKey,
      label: label,
      minuteOfDay: minuteOfDay.clamp(0, 1439),
      kind: 'note',
    );
    stops_.add(row);
    return row;
  }

  @override
  Future<void> moveStop(int id, int minuteOfDay) async {
    final i = stops_.indexWhere((s) => s.id == id);
    if (i < 0) return;
    final s = stops_[i];
    stops_[i] = PlannerStopData(
      id: s.id,
      dateKey: s.dateKey,
      label: s.label,
      minuteOfDay: minuteOfDay.clamp(0, 1439),
      kind: s.kind,
    );
  }

  @override
  Future<void> deleteStop(int id) async {
    stops_.removeWhere((s) => s.id == id);
  }

  @override
  Future<int> lifetimeXp() async =>
      xp_.where((e) => !e.reversed).fold<int>(0, (s, e) => s + e.amount);

  @override
  Future<List<XpEventData>> xpEvents() async => List.unmodifiable(xp_);

  @override
  Future<bool> award({
    required String source,
    required String sourceRef,
    int? amount,
    DateTime? now,
  }) async {
    if (!XpRules.allows(source)) {
      throw StateError('XP is not awarded for $source');
    }
    final open = xp_.any((e) => e.sourceRef == sourceRef && !e.reversed);
    if (open) return false;
    xp_.add(
      XpEventData(
        source: source,
        sourceRef: sourceRef,
        amount: amount ?? XpRules.amountFor(source),
        reversed: false,
      ),
    );
    return true;
  }

  @override
  Future<bool> reverse(String sourceRef) async {
    var changed = false;
    for (var i = 0; i < xp_.length; i++) {
      final e = xp_[i];
      if (e.sourceRef == sourceRef && !e.reversed) {
        xp_[i] = XpEventData(
          source: e.source,
          sourceRef: e.sourceRef,
          amount: e.amount,
          reversed: true,
        );
        changed = true;
      }
    }
    return changed;
  }

  @override
  Future<List<JourneyMarkData>> marks() async => List.unmodifiable(marks_);

  @override
  Future<void> addMark(String title, String kind, {DateTime? now}) async {
    marks_.add(
      JourneyMarkData(
        title: title,
        kind: kind,
        createdAt: now ?? DateTime.now(),
      ),
    );
  }

  @override
  Future<List<ChatTurnData>> chat() async => List.unmodifiable(chat_);

  @override
  Future<void> addChat(
    String role,
    String text, {
    String proposalState = '',
    DateTime? now,
  }) async {
    chat_.add(
      ChatTurnData(
        role: role,
        text: text,
        createdAt: now ?? DateTime.now(),
        proposalState: proposalState,
      ),
    );
  }
}
