import 'package:isar/isar.dart';
import 'package:ruhh/core/data/models/v14_local.dart';
import 'package:ruhh/features/v14/data/v14_models.dart';
import 'package:ruhh/features/v14/data/v14_store.dart';
import 'package:ruhh/features/v14/logic/xp_rules.dart';
import 'package:uuid/uuid.dart';

/// Device-only store. Nothing here is added to the cloud payload.
class IsarV14Store implements V14Store {
  IsarV14Store(this._isar, this.userId);

  final Isar _isar;
  final String userId;
  final _uuid = const Uuid();

  Future<V14ProfileLocal> _profileRow() async {
    final existing = await _isar.v14ProfileLocals
        .filter()
        .userIdEqualTo(userId)
        .findFirst();
    if (existing != null) return existing;
    final created = V14ProfileLocal()..userId = userId;
    await _isar.writeTxn(() => _isar.v14ProfileLocals.put(created));
    return created;
  }

  V14ProfileData _mapProfile(V14ProfileLocal row) {
    return V14ProfileData(
      petId: row.petId,
      petName: row.petName,
      petChosenAt: row.petChosenAt,
      callName: row.callName,
      listMode: row.listMode,
      showLabels: row.showLabels,
      leftHandOrb: row.leftHandOrb,
      firstRunDone: row.firstRunDone,
      lastSeenLevel: row.lastSeenLevel,
      morningSeenKey: row.morningSeenKey,
      eveningSeenKey: row.eveningSeenKey,
    );
  }

  @override
  Future<V14ProfileData> loadProfile() async =>
      _mapProfile(await _profileRow());

  @override
  Future<void> saveProfile(V14ProfileData profile) async {
    final row = await _profileRow();
    row
      ..petId = profile.petId
      ..petName = profile.petName
      ..petChosenAt = profile.petChosenAt
      ..callName = profile.callName
      ..listMode = profile.listMode
      ..showLabels = profile.showLabels
      ..leftHandOrb = profile.leftHandOrb
      ..firstRunDone = profile.firstRunDone
      ..lastSeenLevel = profile.lastSeenLevel
      ..morningSeenKey = profile.morningSeenKey
      ..eveningSeenKey = profile.eveningSeenKey;
    await _isar.writeTxn(() => _isar.v14ProfileLocals.put(row));
  }

  @override
  Future<PetWrite> choosePet({
    required String petId,
    required String petName,
    required String callName,
    required bool understandPermanent,
    required DateTime now,
  }) async {
    final row = await _profileRow();
    if (row.petId != null && row.petId!.isNotEmpty) {
      return PetWrite.alreadyChosen;
    }
    if (!understandPermanent) return PetWrite.needsConfirm;
    row
      ..petId = petId
      ..petName = petName
      ..callName = callName
      ..petChosenAt = now;
    await _isar.writeTxn(() => _isar.v14ProfileLocals.put(row));
    return PetWrite.saved;
  }

  @override
  Future<List<QuestData>> quests() async {
    final rows = await _isar.questLocals
        .filter()
        .userIdEqualTo(userId)
        .findAll();
    return rows
        .where((q) => !q.archived)
        .map(
          (q) => QuestData(
            remoteId: q.remoteId,
            title: q.title,
            done: q.done,
            createdAt: q.createdAt,
          ),
        )
        .toList();
  }

  @override
  Future<QuestData> addQuest(String title, {DateTime? now}) async {
    final row = QuestLocal()
      ..remoteId = _uuid.v4()
      ..userId = userId
      ..title = title
      ..createdAt = now ?? DateTime.now();
    await _isar.writeTxn(() => _isar.questLocals.put(row));
    return QuestData(
      remoteId: row.remoteId,
      title: row.title,
      done: false,
      createdAt: row.createdAt,
    );
  }

  @override
  Future<void> setQuestDone(String remoteId, bool done) async {
    final row = await _isar.questLocals
        .filter()
        .remoteIdEqualTo(remoteId)
        .findFirst();
    if (row == null || row.userId != userId) return;
    row.done = done;
    await _isar.writeTxn(() => _isar.questLocals.put(row));
  }

  @override
  Future<void> deleteQuest(String remoteId) async {
    final row = await _isar.questLocals
        .filter()
        .remoteIdEqualTo(remoteId)
        .findFirst();
    if (row == null || row.userId != userId) return;
    row.archived = true;
    await _isar.writeTxn(() => _isar.questLocals.put(row));
  }

  @override
  Future<List<GoalData>> goals() async {
    final rows = await _isar.goalLocals
        .filter()
        .userIdEqualTo(userId)
        .findAll();
    rows.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return rows
        .map(
          (g) => GoalData(
            remoteId: g.remoteId,
            title: g.title,
            done: g.done,
            sortOrder: g.sortOrder,
          ),
        )
        .toList();
  }

  @override
  Future<GoalData> addGoal(String title, {DateTime? now}) async {
    final existing = await goals();
    final row = GoalLocal()
      ..remoteId = _uuid.v4()
      ..userId = userId
      ..title = title
      ..sortOrder = existing.length
      ..createdAt = now ?? DateTime.now();
    await _isar.writeTxn(() => _isar.goalLocals.put(row));
    return GoalData(
      remoteId: row.remoteId,
      title: row.title,
      done: false,
      sortOrder: row.sortOrder,
    );
  }

  @override
  Future<void> setGoalDone(String remoteId, bool done) async {
    final row = await _isar.goalLocals
        .filter()
        .remoteIdEqualTo(remoteId)
        .findFirst();
    if (row == null || row.userId != userId) return;
    row.done = done;
    await _isar.writeTxn(() => _isar.goalLocals.put(row));
  }

  @override
  Future<void> deleteGoal(String remoteId) async {
    final row = await _isar.goalLocals
        .filter()
        .remoteIdEqualTo(remoteId)
        .findFirst();
    if (row == null || row.userId != userId) return;
    final miles = await _isar.milestoneLocals
        .filter()
        .goalRemoteIdEqualTo(remoteId)
        .findAll();
    await _isar.writeTxn(() async {
      await _isar.goalLocals.delete(row.id);
      for (final mile in miles) {
        if (mile.userId == userId) await _isar.milestoneLocals.delete(mile.id);
      }
    });
  }

  @override
  Future<List<MilestoneData>> milestones(String goalRemoteId) async {
    final rows = await _isar.milestoneLocals
        .filter()
        .goalRemoteIdEqualTo(goalRemoteId)
        .findAll();
    rows.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return rows
        .where((m) => m.userId == userId)
        .map(
          (m) => MilestoneData(
            remoteId: m.remoteId,
            goalRemoteId: m.goalRemoteId,
            title: m.title,
            done: m.done,
            sortOrder: m.sortOrder,
          ),
        )
        .toList();
  }

  @override
  Future<MilestoneData> addMilestone(String goalRemoteId, String title) async {
    final existing = await milestones(goalRemoteId);
    final row = MilestoneLocal()
      ..remoteId = _uuid.v4()
      ..goalRemoteId = goalRemoteId
      ..userId = userId
      ..title = title
      ..sortOrder = existing.length;
    await _isar.writeTxn(() => _isar.milestoneLocals.put(row));
    return MilestoneData(
      remoteId: row.remoteId,
      goalRemoteId: goalRemoteId,
      title: title,
      done: false,
      sortOrder: row.sortOrder,
    );
  }

  @override
  Future<void> setMilestoneDone(String remoteId, bool done) async {
    final row = await _isar.milestoneLocals
        .filter()
        .remoteIdEqualTo(remoteId)
        .findFirst();
    if (row == null || row.userId != userId) return;
    row.done = done;
    await _isar.writeTxn(() => _isar.milestoneLocals.put(row));
  }

  @override
  Future<List<PlannerStopData>> stops(String dateKey) async {
    final rows = await _isar.plannerStopLocals
        .filter()
        .userIdEqualTo(userId)
        .findAll();
    return rows
        .where((s) => s.dateKey == dateKey)
        .map(
          (s) => PlannerStopData(
            id: s.id,
            dateKey: s.dateKey,
            label: s.label,
            minuteOfDay: s.minuteOfDay,
            kind: s.kind,
          ),
        )
        .toList();
  }

  @override
  Future<PlannerStopData> addStop(
    String dateKey,
    String label,
    int minuteOfDay,
  ) async {
    final row = PlannerStopLocal()
      ..userId = userId
      ..dateKey = dateKey
      ..label = label
      ..minuteOfDay = minuteOfDay.clamp(0, 1439);
    await _isar.writeTxn(() => _isar.plannerStopLocals.put(row));
    return PlannerStopData(
      id: row.id,
      dateKey: dateKey,
      label: label,
      minuteOfDay: row.minuteOfDay,
      kind: row.kind,
    );
  }

  @override
  Future<void> moveStop(int id, int minuteOfDay) async {
    final row = await _isar.plannerStopLocals.get(id);
    if (row == null || row.userId != userId) return;
    row.minuteOfDay = minuteOfDay.clamp(0, 1439);
    await _isar.writeTxn(() => _isar.plannerStopLocals.put(row));
  }

  @override
  Future<void> deleteStop(int id) async {
    final row = await _isar.plannerStopLocals.get(id);
    if (row == null || row.userId != userId) return;
    await _isar.writeTxn(() => _isar.plannerStopLocals.delete(id));
  }

  @override
  Future<List<XpEventData>> xpEvents() async {
    final rows = await _isar.localXpEventLocals
        .filter()
        .userIdEqualTo(userId)
        .findAll();
    return rows
        .map(
          (e) => XpEventData(
            source: e.source,
            sourceRef: e.sourceRef,
            amount: e.amount,
            reversed: e.reversed,
          ),
        )
        .toList();
  }

  @override
  Future<int> lifetimeXp() async {
    final rows = await xpEvents();
    return rows.where((e) => !e.reversed).fold<int>(0, (s, e) => s + e.amount);
  }

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
    final rows = await _isar.localXpEventLocals
        .filter()
        .userIdEqualTo(userId)
        .findAll();
    if (rows.any((e) => e.sourceRef == sourceRef && !e.reversed)) return false;
    final row = LocalXpEventLocal()
      ..userId = userId
      ..source = source
      ..sourceRef = sourceRef
      ..amount = amount ?? XpRules.amountFor(source)
      ..createdAt = now ?? DateTime.now();
    await _isar.writeTxn(() => _isar.localXpEventLocals.put(row));
    return true;
  }

  @override
  Future<bool> reverse(String sourceRef) async {
    final rows = await _isar.localXpEventLocals
        .filter()
        .userIdEqualTo(userId)
        .findAll();
    final open = rows
        .where((e) => e.sourceRef == sourceRef && !e.reversed)
        .toList();
    if (open.isEmpty) return false;
    await _isar.writeTxn(() async {
      for (final row in open) {
        row.reversed = true;
        await _isar.localXpEventLocals.put(row);
      }
    });
    return true;
  }

  @override
  Future<List<JourneyMarkData>> marks() async {
    final rows = await _isar.journeyMarkLocals
        .filter()
        .userIdEqualTo(userId)
        .findAll();
    return rows
        .map(
          (m) => JourneyMarkData(
            title: m.title,
            kind: m.kind,
            createdAt: m.createdAt,
          ),
        )
        .toList();
  }

  @override
  Future<void> addMark(String title, String kind, {DateTime? now}) async {
    final row = JourneyMarkLocal()
      ..userId = userId
      ..title = title
      ..kind = kind
      ..createdAt = now ?? DateTime.now();
    await _isar.writeTxn(() => _isar.journeyMarkLocals.put(row));
  }

  @override
  Future<List<ChatTurnData>> chat() async {
    final rows = await _isar.chatTurnLocals
        .filter()
        .userIdEqualTo(userId)
        .findAll();
    rows.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return rows
        .map(
          (c) => ChatTurnData(
            role: c.role,
            text: c.text,
            createdAt: c.createdAt,
            proposalState: c.proposalState,
          ),
        )
        .toList();
  }

  @override
  Future<void> addChat(
    String role,
    String text, {
    String proposalState = '',
    DateTime? now,
  }) async {
    final row = ChatTurnLocal()
      ..userId = userId
      ..role = role
      ..text = text
      ..proposalState = proposalState
      ..createdAt = now ?? DateTime.now();
    await _isar.writeTxn(() => _isar.chatTurnLocals.put(row));
  }
}
