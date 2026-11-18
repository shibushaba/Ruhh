import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/features/v14/data/v14_models.dart';
import 'package:ruhh/features/v14/home/living_home_view.dart';
import 'package:ruhh/features/v14/screens/module_views.dart';
import 'package:ruhh/features/v14/shell/v14_shell.dart';
import 'package:ruhh/features/v14/theme/v14_theme.dart';

Future<void> _loadFonts() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  );
  for (final family in manifest as List) {
    final loader = FontLoader(family['family'] as String);
    for (final font in family['fonts'] as List) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture every v14 screen', (tester) async {
    Directory('../docs/design/v14/build-screens').createSync(recursive: true);
    await _loadFonts();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    Future<void> shot(
      String name,
      Widget child, {
      Future<void> Function()? settle,
    }) async {
      final router = GoRouter(
        initialLocation: '/home',
        routes: [GoRoute(path: '/home', builder: (_, _) => child)],
      );
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: V14Theme.dark(),
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      if (settle != null) await settle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../../../docs/design/v14/build-screens/$name.png'),
      );
    }

    const profile = V14ProfileData(
      petId: 'dragon',
      petName: 'Ruu',
      callName: 'friend',
      firstRunDone: true,
    );
    await shot(
      'home-dragon-w1',
      LivingHomeView(
        petId: 'dragon',
        world: 1,
        level: 8,
        subStage: 1,
        callName: 'friend',
        hero: 'Walk',
        showLabels: true,
        habitCount: 3,
        questCount: 1,
        prayerChip: '3 of 5',
        onOpen: (_) {},
        onToggleLabels: () {},
      ),
    );
    await shot(
      'home-dragon-w5',
      LivingHomeView(
        petId: 'dragon',
        world: 5,
        level: 90,
        subStage: 3,
        callName: 'friend',
        hero: 'Walk',
        showLabels: false,
        habitCount: 2,
        questCount: 0,
        prayerChip: '1 of 5',
        onOpen: (_) {},
        onToggleLabels: () {},
      ),
    );
    await shot(
      'home-panda-missing',
      LivingHomeView(
        petId: 'panda',
        world: 3,
        level: 50,
        subStage: 0,
        callName: 'friend',
        hero: 'Walk',
        showLabels: true,
        habitCount: 1,
        questCount: 1,
        prayerChip: '0 of 5',
        onOpen: (_) {},
        onToggleLabels: () {},
      ),
    );
    await shot(
      'habits-orbit',
      HabitsOrbitView(
        habits: const [
          OrbitHabit(id: 'a', name: 'Walk', done: false),
          OrbitHabit(id: 'b', name: 'Read', done: true),
        ],
        onToggle: (_) {},
        onAdd: () {},
        onOpenQuests: () {},
        onOpenClassic: () {},
      ),
    );
    await shot(
      'quests',
      QuestsBoardView(
        quests: [
          QuestData(
            remoteId: 'q',
            title: 'Bank today',
            done: false,
            createdAt: DateTime(2026, 11, 18),
          ),
        ],
        onAdd: (_) {},
        onDone: (_) {},
        onDelete: (_) {},
      ),
    );
    await shot(
      'goal-climb',
      GoalClimbView(
        goals: const [
          GoalData(remoteId: 'g', title: '10 km', done: false, sortOrder: 0),
        ],
        milestones: const {
          'g': [
            MilestoneData(
              remoteId: 'm',
              goalRemoteId: 'g',
              title: '8 km',
              done: true,
              sortOrder: 0,
            ),
          ],
        },
        onAddGoal: (_) {},
        onAddMilestone: (_, __) {},
        onToggleMilestone: (_) {},
        onToggleGoal: (_) {},
      ),
    );
    await shot(
      'money-blocks',
      MoneyBlocksView(
        spend: const {'Bills': 7900, 'Food': 6200, 'Other': 2250},
        spent: 16350,
        recent: const ['Food'],
        onAdd: () {},
        onLedger: () {},
        onDelete: (_) {},
      ),
    );
    await shot(
      'planner',
      PlannerDialView(
        dateKey: '2026-11-18',
        stops: const [
          PlannerStopData(
            id: 1,
            dateKey: '2026-11-18',
            label: 'Walk',
            minuteOfDay: 540,
            kind: 'note',
          ),
        ],
        onMove: (_, __) {},
        onAdd: (_, __) {},
      ),
    );
    await shot(
      'prayer-sky',
      PrayerSkyView(
        marks: const {
          'fajr': 'prayed',
          'dhuhr': 'missed',
          'asr': 'unmarked',
          'maghrib': 'unmarked',
          'isha': 'unmarked',
        },
        onToggle: (_) {},
        onOpenFull: () {},
      ),
    );
    await shot(
      'night-nook',
      NightNookView(
        books: const ['The left hand of darkness'],
        movies: const ['A quiet film'],
        onAddBook: () {},
        onAddMovie: () {},
        onOpenBooks: () {},
        onOpenMovies: () {},
      ),
    );
    await shot(
      'journey',
      JourneyView(
        worldName: 'Moss Ledge',
        formName: 'Ledgewalker',
        level: 33,
        marks: const [],
        onAddRelic: (_) {},
      ),
    );
    await shot(
      'chat',
      CompanionChatView(
        companionName: 'Ruu',
        lines: const ['Add a spend?'],
        proposal: null,
        onSubmit: (_) {},
        onConfirm: () {},
        onEdit: (_) {},
        onCancel: () {},
      ),
    );
    await shot(
      'settings',
      SettingsTilesView(
        listMode: false,
        leftHand: false,
        petLabel: 'Dragon · Ruu',
        onListMode: (_) {},
        onLeftHand: (_) {},
        onNotifications: () {},
        onOverlay: () {},
        onAnalytics: () {},
        onCallName: (_) {},
      ),
    );
    await shot(
      'pet-picker',
      PetPickerView(
        selected: 'panda',
        onSelect: (_) {},
        onTry: () {},
        onChoose: () {},
        locked: false,
      ),
    );
    await shot(
      'pet-confirm',
      PetConfirmView(
        petId: 'panda',
        checked: true,
        onChecked: (_) {},
        onBack: () {},
        onConfirm: () {},
        onNames: (_, __) {},
      ),
    );
    await shot(
      'list-mode',
      V14Shell(
        previewProfile: profile.copyWith(listMode: true),
        onNavigate: (_) {},
        child: const SizedBox.shrink(),
      ),
    );
    await shot(
      'ring',
      V14Shell(
        previewProfile: profile,
        onNavigate: (_) {},
        child: const ColoredBox(color: Color(0xFF0E0F10)),
      ),
      settle: () async {
        tester
            .state<V14ShellState>(find.byType(V14Shell))
            .openRing(tapMode: true);
        await tester.pump();
      },
    );
  });
}
