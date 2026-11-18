import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ruhh/core/data/models/user_local.dart';
import 'package:ruhh/core/services/supabase_sync_service.dart';
import 'package:ruhh/features/prayer/tracker/prayer_domain.dart';
import 'package:ruhh/features/v14/data/v14_models.dart';
import 'package:ruhh/features/v14/data/v14_store.dart';
import 'package:ruhh/features/v14/logic/chat_intent.dart';
import 'package:ruhh/features/v14/logic/level_curve.dart';
import 'package:ruhh/features/v14/logic/pet_catalog.dart';
import 'package:ruhh/features/v14/logic/ring_layout.dart';
import 'package:ruhh/features/v14/logic/treemap_layout.dart';
import 'package:ruhh/features/v14/logic/undo_ticket.dart';
import 'package:ruhh/features/v14/logic/world_map.dart';
import 'package:ruhh/features/v14/logic/xp_rules.dart';
import 'package:ruhh/features/v14/theme/v14_colors.dart';

void main() {
  test('phase 1 curve stays pluggable and has no daily cap', () {
    const curve = Phase1LevelCurve();
    expect(curve.threshold(1), 0);
    expect(curve.threshold(2), (50 * 1).floor());
    expect(curve.levelFor(0), 1);
    expect(curve.levelFor(curve.threshold(8)), 8);
    expect(curve.levelFor(curve.threshold(8) - 1), 7);
    const swapped = WorldMap(curve: LinearLevelCurve(100));
    expect(swapped.progress(0).world, 1);
    expect(swapped.progress(2400).level, 25);
    expect(swapped.progress(2400).world, 2);
    expect(const WorldMap().progress(curve.threshold(8)).world, 1);
  });

  test('world map uses four sub-stages inside each band', () {
    const map = WorldMap(curve: LinearLevelCurve(1));
    expect(map.progress(0).subStage, 0);
    expect(map.progress(23).subStage, 3);
    expect(map.progress(24).world, 2);
    expect(map.progress(99).world, 5);
    expect(map.progress(500).world, 5);
    expect(petPackFor('dragon').formName(1, 0), 'Ember Egg');
    expect(petPackFor('dragon').formName(1, 3), 'Hearthling');
    expect(petPackFor('panda').artMissing(3), isTrue);
    expect(petPackFor('dragon').artMissing(3), isFalse);
  });

  test('excluded modules never receive XP', () async {
    final store = MemoryV14Store();
    for (final source in ['prayer', 'movie', 'book', 'budget', 'money']) {
      expect(XpRules.allows(source), isFalse);
      expect(
        () => store.award(source: source, sourceRef: source),
        throwsStateError,
      );
    }
    expect(
      await store.award(source: 'habit', sourceRef: 'habit:1:2026-11-18'),
      isTrue,
    );
    expect(
      await store.award(source: 'habit', sourceRef: 'habit:1:2026-11-18'),
      isFalse,
    );
    expect(await store.lifetimeXp(), XpRules.habit);
    expect(await store.reverse('habit:1:2026-11-18'), isTrue);
    expect(await store.lifetimeXp(), 0);
    expect(
      await store.award(source: 'habit', sourceRef: 'habit:1:2026-11-18'),
      isTrue,
    );
  });

  test('pet choice is write-once and rename stays local', () async {
    final store = MemoryV14Store();
    expect(
      await store.choosePet(
        petId: 'panda',
        petName: 'Sumi',
        callName: 'നിങ്ങൾ',
        understandPermanent: false,
        now: DateTime.utc(2026, 11, 18),
      ),
      PetWrite.needsConfirm,
    );
    expect((await store.loadProfile()).petId, isNull);
    expect(
      await store.choosePet(
        petId: 'panda',
        petName: 'Sumi',
        callName: 'صلاة',
        understandPermanent: true,
        now: DateTime.utc(2026, 11, 18),
      ),
      PetWrite.saved,
    );
    expect(
      await store.choosePet(
        petId: 'cat',
        petName: 'Kage',
        callName: 'x',
        understandPermanent: true,
        now: DateTime.utc(2026, 11, 18),
      ),
      PetWrite.alreadyChosen,
    );
    final profile = await store.loadProfile();
    expect(profile.petId, 'panda');
    await store.saveProfile(profile.copyWith(petName: 'Ink', callName: 'രൂ'));
    expect((await store.loadProfile()).petId, 'panda');
    expect((await store.loadProfile()).petName, 'Ink');
  });

  test('chat understands included and excluded intents', () async {
    final prayer = parseCompanionUtterance('prayer fajr');
    expect(prayer.effect, ChatEffect.logPrayer);
    expect(prayer.grantsXp, isFalse);
    final spend = parseCompanionUtterance('spent 120 on food');
    expect(spend.effect, ChatEffect.addSpend);
    expect(spend.grantsXp, isFalse);
    expect(spend.amount, 120);
    final habit = parseCompanionUtterance('add habit നടത്തം');
    expect(habit.title, 'നടത്തം');
    expect(habit.grantsXp, isFalse);
    final done = parseCompanionUtterance('complete quest صلاة');
    expect(done.grantsXp, isTrue);
    expect(done.title, 'صلاة');
    final sink = _Sink();
    await applyChatProposal(prayer, sink);
    await applyChatProposal(spend, sink);
    await applyChatProposal(habit, sink);
    expect(sink.prayers, ['fajr']);
    expect(sink.spends, [('food', 120.0)]);
    expect(sink.habits, ['നടത്തം']);
    expect(sink.xp, isEmpty);
  });

  test('treemap covers the bounds and survives empty or huge input', () {
    expect(layoutTreemap(const Rect.fromLTWH(0, 0, 200, 100), {}), isEmpty);
    final tiles = layoutTreemap(const Rect.fromLTWH(0, 0, 300, 200), {
      'Food': 6200,
      'Bills': 7900,
      'Travel': 2100,
      'Other': 2250,
    });
    expect(tiles, hasLength(4));
    final area = tiles.fold<double>(
      0,
      (s, t) => s + t.rect.width * t.rect.height,
    );
    expect(area, closeTo(300 * 200, 1));
    final huge = {for (var i = 0; i < 80; i++) 'c$i': (i + 1).toDouble()};
    final many = layoutTreemap(const Rect.fromLTWH(0, 0, 400, 400), huge);
    expect(many, hasLength(80));
  });

  test('ring hit targets sit on the upper half and mirror', () {
    const right = RingLayout(
      origin: Offset(200, 700),
      radius: 160,
      leftHand: false,
    );
    final nodes = right.nodes([
      'home',
      'prayer',
      'money',
      'habits',
      'books',
      'movies',
    ]);
    expect(nodes.first.center.dx, lessThan(200));
    expect(nodes.last.center.dx, greaterThan(200));
    expect(nodes[2].center.dy, lessThan(660));
    expect(nodes.every((n) => n.center.dy <= 700), isTrue);
    expect(right.hit(nodes[2].center, nodes), 'money');
    const left = RingLayout(
      origin: Offset(48, 700),
      radius: 120,
      leftHand: true,
    );
    final mirrored = left.nodes([
      'home',
      'prayer',
      'money',
      'habits',
      'books',
      'movies',
    ]);
    expect(mirrored.first.center.dx, greaterThan(48));
  });

  test('undo expires after five seconds', () async {
    final buffer = UndoBuffer();
    var reverted = false;
    final now = DateTime(2026, 11, 18, 9);
    final ticket = buffer.push(
      label: 'Lit walk',
      now: now,
      revert: () async => reverted = true,
    );
    expect(
      await buffer.undo(ticket.id, now.add(const Duration(seconds: 5))),
      isFalse,
    );
    expect(reverted, isFalse);
    final again = buffer.push(
      label: 'Lit walk',
      now: now,
      revert: () async => reverted = true,
    );
    expect(
      await buffer.undo(again.id, now.add(const Duration(seconds: 4))),
      isTrue,
    );
    expect(reverted, isTrue);
  });

  test('missed colour is not red and rupee formatting stays INR', () {
    expect(V14Colors.missed.r, lessThan(0.7));
    expect(V14Colors.missed, isNot(const Color(0xFFE11D48)));
    expect(V14Colors.missed.toARGB32(), 0xFF7F9A96);
  });

  test('existing user schema and cloud keys are unchanged', () {
    expect(UserLocalSchema.name, 'UserLocal');
    expect(UserLocalSchema.id, 5846211031786981232);
    expect(
      UserLocalSchema.properties.keys,
      containsAll(['username', 'pinHash', 'pinSalt', 'onboardingComplete']),
    );
    expect(UserLocalSchema.properties.keys, isNot(contains('petId')));
    const forbidden = [
      'quests',
      'goals',
      'pet',
      'xp',
      'planner',
      'chat',
      'v14',
    ];
    for (final key in SupabaseSyncService.cloudSyncListKeys) {
      expect(forbidden.contains(key), isFalse, reason: key);
    }
  });

  test('date keys stay on the local calendar across DST edges', () {
    expect(dateKeyFrom(DateTime(2026, 3, 8, 1, 30)), '2026-03-08');
    expect(dateKeyFrom(DateTime(2026, 11, 1, 1, 30)), '2026-11-01');
    expect(dateKeyFrom(DateTime(2026, 11, 18, 23, 59)), '2026-11-18');
  });
}

class _Sink implements ChatSink {
  final habits = <String>[];
  final prayers = <String>[];
  final spends = <(String, double)>[];
  final xp = <String>[];

  @override
  Future<void> addHabit(String name) async => habits.add(name);
  @override
  Future<void> completeHabit(String name) async => xp.add(name);
  @override
  Future<void> logPrayer(String name) async => prayers.add(name);
  @override
  Future<void> addSpend(double amount, String category) async =>
      spends.add((category, amount));
  @override
  Future<void> addQuest(String title) async {}
  @override
  Future<void> completeQuest(String title) async => xp.add(title);
  @override
  Future<void> addGoal(String title) async {}
}
