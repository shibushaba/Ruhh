import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/features/v14/data/v14_models.dart';
import 'package:ruhh/features/v14/data/v14_store.dart';
import 'package:ruhh/features/v14/logic/chat_intent.dart';
import 'package:ruhh/features/v14/logic/xp_rules.dart';
import 'package:ruhh/features/v14/screens/module_pages.dart';
import 'package:ruhh/features/v14/screens/module_views.dart';
import 'package:ruhh/features/v14/shell/v14_shell.dart';
import 'package:ruhh/features/v14/theme/v14_colors.dart';
import 'package:ruhh/features/v14/theme/v14_theme.dart';

void main() {
  testWidgets('quest, goal, planner, and chat workflows stay on device', (
    tester,
  ) async {
    final store = MemoryV14Store();
    final sink = _RecordingSink(store);
    await tester.pumpWidget(_app(QuestsPage(store: store)));
    await tester.enterText(find.byKey(const Key('quest-title')), 'Bank today');
    await tester.tap(find.text('Add quest'));
    await tester.pump();
    expect(find.text('Bank today'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pump();
    expect(await store.lifetimeXp(), XpRules.quest);
    await tester.tap(find.text('Undo'));
    await tester.pump();
    expect(await store.lifetimeXp(), 0);

    await tester.pumpWidget(_app(GoalsPage(store: store)));
    await tester.enterText(find.byKey(const Key('goal-title')), '10 km');
    await tester.tap(find.text('Add goal'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, '8 km');
    await tester.tap(find.text('Add milestone'));
    await tester.pump();
    await tester.tap(find.text('8 km'));
    await tester.pump();
    expect(await store.lifetimeXp(), XpRules.milestone);

    await tester.pumpWidget(
      _app(PlannerPage(store: store, now: DateTime(2026, 11, 18, 15))),
    );
    await tester.enterText(find.byKey(const Key('stop-label')), 'Walk');
    await tester.tap(find.text('Add stop'));
    await tester.pump();
    expect(find.textContaining('Walk'), findsWidgets);
    await tester.tap(find.text('Undo'));
    await tester.pump();
    expect(await store.stops('2026-11-18'), isEmpty);

    await tester.pumpWidget(_app(CompanionChatPage(store: store, sink: sink)));
    await tester.enterText(find.byKey(const Key('chat-input')), 'prayer fajr');
    await tester.tap(find.text('Send'));
    await tester.pump();
    expect(find.byKey(const Key('chat-proposal')), findsOneWidget);
    await tester.tap(find.text('Confirm'));
    await tester.pump();
    expect(sink.prayers, ['fajr']);
    expect(await store.lifetimeXp(), XpRules.milestone);
    expect(find.textContaining('no XP'), findsWidgets);
  });

  testWidgets('money and prayer copy never offer XP', (tester) async {
    await tester.pumpWidget(
      _app(
        MoneyBlocksPage(
          spend: const {'Food': 120, 'Bills': 80},
          recent: const ['Food · ₹120'],
        ),
      ),
    );
    expect(find.textContaining('never earns XP'), findsOneWidget);
    expect(find.textContaining('₹'), findsWidgets);
    expect(find.textContaining('+8'), findsNothing);

    await tester.pumpWidget(
      _app(
        const PrayerSkyPage(
          marks: {
            'fajr': 'missed',
            'dhuhr': 'prayed',
            'asr': 'unmarked',
            'maghrib': 'unmarked',
            'isha': 'unmarked',
          },
        ),
      ),
    );
    expect(find.byKey(const Key('prayer-no-xp')), findsOneWidget);
    expect(find.textContaining('XP'), findsOneWidget);
    final missed = tester.widget<Container>(
      find
          .descendant(
            of: find.byKey(const Key('prayer-fajr')),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = missed.decoration! as BoxDecoration;
    expect(decoration.color, V14Colors.missed);
  });

  testWidgets('ring tap path, list mode, reduced motion, and first run', (
    tester,
  ) async {
    final opened = <String>[];
    Future<void> pump(
      V14ProfileData profile, {
      bool reduce = false,
      bool reader = false,
    }) {
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, _) => V14Shell(
              previewProfile: profile,
              onNavigate: opened.add,
              onProfile: (_) {},
              child: const SizedBox.expand(child: Text('scene')),
            ),
          ),
        ],
      );
      return tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            theme: V14Theme.dark(),
            routerConfig: router,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                disableAnimations: reduce,
                accessibleNavigation: reader,
              ),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ),
      );
    }

    await pump(
      const V14ProfileData(petId: 'dragon', petName: 'Ruu', firstRunDone: true),
    );
    await tester.tap(find.byKey(const Key('v14-orb')));
    await tester.pump();
    expect(find.byKey(const Key('ring-money')), findsOneWidget);
    await tester.tap(find.byKey(const Key('ring-money')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('ring-money-add')));
    await tester.pump();
    expect(opened, contains('/budget/add'));

    opened.clear();
    await pump(
      const V14ProfileData(petId: 'dragon', listMode: true, firstRunDone: true),
      reader: true,
    );
    expect(find.byKey(const Key('places-list')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('place-books')),
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.byKey(const Key('place-books')));
    await tester.pump();
    expect(opened, contains('/book'));

    await pump(
      const V14ProfileData(petId: 'dragon', firstRunDone: false),
      reduce: true,
    );
    expect(find.byKey(const Key('demo-step')), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pump();
  });

  testWidgets('layouts survive text scale, small screens, and long scripts', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 480));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(() {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      tester.binding.setSurfaceSize(null);
    });
    await tester.pumpWidget(
      _app(
        const NightNookPage(
          books: ['ഒരു നീണ്ട മലയാളം പുസ്തകത്തിന്റെ പേര്'],
          movies: ['فيلم طويل جدا بعنوان الظل'],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('nook-no-xp')), findsOneWidget);

    await tester.binding.setSurfaceSize(const Size(1000, 1400));
    await tester.pumpWidget(
      _app(
        HabitsOrbitView(
          habits: [
            for (var i = 0; i < 12; i++)
              OrbitHabit(id: '$i', name: 'Habit $i ' * 4, done: i.isEven),
          ],
          onToggle: (_) {},
          onAdd: () {},
          onOpenQuests: () {},
          onOpenClassic: () {},
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('New habit'));
    await tester.tap(find.text('New habit'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty states render', (tester) async {
    final store = MemoryV14Store();
    await tester.pumpWidget(_app(QuestsPage(store: store)));
    expect(find.byKey(const Key('quests-empty')), findsOneWidget);
    await tester.pumpWidget(_app(GoalsPage(store: store)));
    expect(find.byKey(const Key('goals-empty')), findsOneWidget);
    await tester.pumpWidget(_app(JourneyPage(store: store)));
    expect(find.byKey(const Key('relics-empty')), findsOneWidget);
    await tester.pumpWidget(_app(const MoneyBlocksPage(spend: {})));
    expect(find.byKey(const Key('money-empty')), findsOneWidget);
  });
}

Widget _app(Widget child) {
  return ProviderScope(
    child: MaterialApp(theme: V14Theme.dark(), home: child),
  );
}

class _RecordingSink implements ChatSink {
  _RecordingSink(this.store);
  final MemoryV14Store store;
  final prayers = <String>[];

  @override
  Future<void> addHabit(String name) async {}
  @override
  Future<void> completeHabit(String name) async {
    await store.award(
      source: 'habit',
      sourceRef: 'habit:$name',
      amount: XpRules.habit,
    );
  }

  @override
  Future<void> logPrayer(String name) async => prayers.add(name);
  @override
  Future<void> addSpend(double amount, String category) async {}
  @override
  Future<void> addQuest(String title) async => store.addQuest(title);
  @override
  Future<void> completeQuest(String title) async {}
  @override
  Future<void> addGoal(String title) async {}
}
