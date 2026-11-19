import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:isar/isar.dart';
import 'package:ruhh/core/data/models/habit_local.dart';
import 'package:ruhh/core/data/models/v14_local.dart';
import 'package:ruhh/core/widgets/ruhh_components.dart';
import 'package:ruhh/features/v14/logic/level_curve.dart';
import 'package:ruhh/features/v14/logic/pet_catalog.dart';
import 'package:ruhh/features/v14/shell/v14_shell.dart';
import 'package:ruhh/features/v14/v14_providers.dart';
import 'package:ruhh/features/v14/widgets/v14_chrome.dart';
import 'package:ruhh/main.dart' as app;

const _user = 'ruhhdevice';
const _pin = '135790';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('v14 workflows on a device', (tester) async {
    await app.main();
    await _until(tester, find.text('Create account'));
    await _shot('01-welcome');

    await tester.tap(find.text('Create account'));
    await _until(tester, find.text('Sign up'));
    await tester.enterText(find.byType(TextField).first, _user);
    await _until(tester, find.textContaining('offline'));
    await _pinIn(tester, _pin);
    await _until(tester, find.text('Confirm PIN'));
    await _pinIn(tester, _pin);
    await _until(tester, find.text('Pick your trackers'));
    await tester.tap(find.text('Continue'));
    await _until(tester, find.text('Not now'));
    await tester.tap(find.text('Not now'));

    await _until(tester, find.byKey(const Key('pet-card-dragon')));
    await _shot('02-pet-picker');
    await tester.tap(find.byKey(const Key('pet-card-dragon')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Try'));
    await _until(tester, find.textContaining('Trying Dragon'));
    await _shot('03-home-dragon-try');
    await _until(tester, find.byKey(const Key('pet-card-panda')), seconds: 60);
    await tester.tap(find.byKey(const Key('pet-card-panda')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Try'));
    await _until(tester, find.textContaining('Trying Panda'));
    await _shot('04-home-panda-try');
    await _until(tester, find.byKey(const Key('pet-card-cat')), seconds: 60);
    await tester.tap(find.byKey(const Key('pet-card-cat')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Try'));
    await _until(tester, find.textContaining('Trying Cat'));
    await _shot('05-home-cat-try');
    await _until(tester, find.text('Choose'), seconds: 60);

    await tester.tap(find.byKey(const Key('pet-card-dragon')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Choose'));
    await _until(tester, find.byKey(const Key('pet-permanent')));
    await tester.tap(find.byKey(const Key('pet-permanent')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Choose Dragon for good'));
    await _until(tester, find.text('Skip'));
    await _shot('06-home-dragon');
    for (var i = 0; i < 8; i++) {
      if (find.text('Skip').evaluate().isEmpty) break;
      await tester.tap(find.text('Skip'));
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(find.text('Skip'), findsNothing);

    await _until(tester, find.byType(V14Orb));
    await tester.tap(find.byType(V14Orb));
    await _until(tester, find.byKey(const Key('ring-hint')));
    await _shot('07-ring');
    await tester.tap(find.byKey(const Key('ring-dismiss')));
    await tester.pump(const Duration(milliseconds: 400));

    await _open(tester, 'habits', 'quests');
    await _until(tester, find.byKey(const Key('quests-empty')));
    await _open(tester, 'habits', 'goals');
    await _until(tester, find.byKey(const Key('goals-empty')));

    await _open(tester, 'habits', 'orbit');
    await _until(tester, find.text('New habit'));
    await _shot('08-habits');
    await tester.tap(find.text('New habit'));
    await _until(tester, find.text('Name'));
    await tester.enterText(find.byType(TextField).first, 'Walk');
    await _tapText(tester, 'Create habit');
    await _until(tester, find.textContaining('Walk'));
    for (var i = 0; i < 6; i++) {
      final habit = find.textContaining('Walk');
      if (habit.evaluate().isEmpty) {
        await tester.pump(const Duration(milliseconds: 200));
        continue;
      }
      await tester.tap(habit.first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 120));
    }
    await _until(tester, find.text('Undo'));
    await tester.tap(find.text('Undo'));
    await _until(tester, find.textContaining('Walk'));
    await tester.tap(find.text('Classic list'));
    await _until(tester, find.byKey(const Key('habit-board-name-Walk')));
    await _tapKey(tester, const Key('habit-board-name-Walk'));
    await _until(tester, find.text('Edit habit'));
    await tester.enterText(find.byType(TextField).first, 'Walk evening');
    await _tapText(tester, 'Save changes');
    await _until(
      tester,
      find.byKey(const Key('habit-board-name-Walk evening')),
    );
    await _tapKey(tester, const Key('habit-board-name-Walk evening'));
    await _until(tester, find.text('Edit habit'));
    await _tapText(tester, 'Archive habit');
    await tester.pump(const Duration(seconds: 1));
    await _back(tester);
    await _until(tester, find.text('New habit'));

    await tester.tap(find.text('New habit'));
    await _until(tester, find.text('Name'));
    await tester.enterText(find.byType(TextField).first, 'Read');
    await _tapText(tester, 'Create habit');
    await _until(tester, find.textContaining('Light it · Read'));
    await tester.tap(find.textContaining('Light it · Read'));
    await _until(tester, find.textContaining('Read · lit'));

    await _open(tester, 'money', 'money-month');
    await _until(tester, find.byKey(const Key('money-total')));
    await _shot('09-money');
    await tester.tap(find.text('Add spend'));
    await _until(tester, find.text('Save'));
    await tester.enterText(find.byType(TextField).first, '250');
    await tester.tap(find.byTooltip('Food'));
    await tester.pump(const Duration(milliseconds: 300));
    await _tapText(tester, 'Save');
    await _until(tester, find.textContaining('₹250'));
    await tester.tap(find.text('Full ledger'));
    await _until(tester, find.textContaining('250'));
    await tester.tap(find.textContaining('250').first);
    await _until(tester, find.text('Save'));
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(1), 'tea');
    await _tapText(tester, 'Save');
    await tester.pump(const Duration(seconds: 1));
    await _back(tester);
    await _open(tester, 'money', 'money-month');
    await _until(tester, find.byKey(const Key('tx-delete-0')));
    await tester.tap(find.byKey(const Key('tx-delete-0')));
    await _until(tester, find.text('Undo'));
    await tester.tap(find.text('Undo'));
    await _until(tester, find.textContaining('Food'));

    await _open(tester, 'prayer', 'prayer-sky');
    await _until(tester, find.byKey(const Key('prayer-no-xp')));
    await tester.tap(find.byKey(const Key('prayer-fajr')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('prayer-no-xp')), findsOneWidget);
    final xpBeforeQuiet = await _lifetimeXp();
    await _open(tester, 'books', 'shelf');
    await _until(tester, find.byKey(const Key('nook-no-xp')));
    await tester.tap(find.text('Add book'));
    await _until(tester, find.text('Manual'));
    await tester.tap(find.text('Manual'));
    await _until(tester, find.text('Add to shelf'));
    await tester.enterText(find.byType(TextField).first, 'The Alchemist');
    await _tapText(tester, 'Add to shelf');
    await _until(tester, find.textContaining('Alchemist'));
    await _open(tester, 'movies', 'movie-add');
    await _until(tester, find.text('Title'));
    await tester.enterText(find.byType(TextField).first, 'Pather Panchali');
    await _tapText(tester, 'Save');
    await tester.pump(const Duration(seconds: 1));
    expect(await _lifetimeXp(), xpBeforeQuiet);

    await _open(tester, 'habits', 'quests');
    await _field(tester, 'quest-title', 'Add quest', 'Carry water');
    await _until(tester, find.text('Carry water'));
    await tester.tap(find.text('Done'));
    await _until(tester, find.text('Undo'));
    await tester.tap(find.text('Undo'));
    await _until(tester, find.text('Done'));

    await _open(tester, 'habits', 'goals');
    await _field(tester, 'goal-title', 'Add goal', 'Finish the climb');
    await _until(tester, find.text('Finish the climb'));
    await _shot('10-goal-climb');
    await tester.enterText(find.byType(TextField).first, 'First step');
    await tester.tap(find.text('Add milestone'));
    await _until(tester, find.text('First step'));
    await tester.tap(find.text('First step'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Mark goal done'));
    await tester.pump(const Duration(seconds: 1));

    await _open(tester, 'prayer', 'planner');
    await _field(tester, 'stop-label', 'Add stop', 'Tea');
    await _until(tester, find.text('Undo'));
    await tester.tap(find.text('Undo'));
    await _field(tester, 'stop-label', 'Add stop', 'Tea');
    await _until(tester, find.text('Move'));
    await tester.tap(find.text('Move'));
    await _until(tester, find.text('Undo'));

    await _open(tester, 'home', 'chat');
    await _until(tester, find.byKey(const Key('chat-input')));
    await tester.enterText(
      find.byKey(const Key('chat-input')),
      'add habit നടക്കുക',
    );
    await tester.tap(find.text('Send'));
    await _until(tester, find.text('Confirm'));
    await tester.enterText(find.byKey(const Key('chat-edit')), 'നടക്കുക');
    await tester.tap(find.text('Edit'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(
      find.byKey(const Key('chat-input')),
      'add habit مرحبا',
    );
    await tester.tap(find.text('Send'));
    await _until(tester, find.text('Cancel'));
    await tester.tap(find.text('Cancel'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(
      find.byKey(const Key('chat-input')),
      'add habit Chat walk',
    );
    await tester.tap(find.text('Send'));
    await _until(tester, find.text('Confirm'));
    await tester.tap(find.text('Confirm'));
    await tester.pump(const Duration(seconds: 1));
    await tester.enterText(find.byKey(const Key('chat-input')), 'prayer dhuhr');
    await tester.tap(find.text('Send'));
    await _until(tester, find.textContaining('no XP'));
    await tester.tap(find.text('Confirm'));
    await tester.pump(const Duration(seconds: 1));

    await _home(tester);
    await _until(tester, find.byKey(const Key('level-up')), seconds: 20);
    await _shot('11-level-up');
    await tester.tap(find.text('Stay'));
    await tester.pump(const Duration(milliseconds: 400));

    await _open(tester, 'home', 'settings');
    await _until(tester, find.byKey(const Key('list-mode')));
    await tester.tap(find.byKey(const Key('list-mode')));
    await tester.pump(const Duration(milliseconds: 400));
    await _home(tester);
    await _until(tester, find.text('Places'));
    await _shot('12-list-mode');
    await _open(tester, 'home', 'settings');
    await tester.tap(find.byKey(const Key('list-mode')));
    await tester.pump(const Duration(milliseconds: 400));

    tester.platformDispatcher.textScaleFactorTestValue = 2;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    await tester.pump(const Duration(milliseconds: 500));
    await _home(tester);
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    await _shot('13-home-scaled');
    tester.platformDispatcher.textScaleFactorTestValue = 1;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures();
    await tester.pump(const Duration(milliseconds: 300));

    await _open(tester, 'home', 'journey');
    await _until(tester, find.byKey(const Key('relics-empty')));
    await _field(tester, 'relic-title', 'Keep relic', 'നക്ഷത്ര · نجمة');
    await _until(tester, find.textContaining('നക്ഷത്ര'));
    await _until(tester, find.textContaining('نجمة'));

    for (var i = 0; i < 8; i++) {
      await tester.tap(find.byType(V14Orb), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 40));
    }
    expect(tester.takeException(), isNull);
    if (find.byKey(const Key('ring-hint')).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(const Key('ring-dismiss')));
      await tester.pump(const Duration(milliseconds: 300));
    }

    await _frame(tester, const Size(320, 640));
    await _shot('18-small');
    await _frame(tester, const Size(800, 1280));
    await _shot('19-large');
    await _frame(tester, const Size(800, 360));
    await _shot('20-rotated');
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);

    await _seedHugeHabits();
    await _open(tester, 'habits', 'orbit');
    await _until(tester, find.textContaining('Huge 3'));
    expect(tester.takeException(), isNull);
    await _clearHugeHabits();

    await _tour(tester, 'dragon', '21-home-dragon');
    await _tour(tester, 'panda', '22-home-panda');
    await _tour(tester, 'cat', '23-home-cat');
    expect(find.byKey(const Key('companion-sprite')), findsNothing);
    expect(find.textContaining('Could not open home'), findsNothing);
  }, timeout: const Timeout(Duration(minutes: 25)));
}

const _worldLevels = [8, 25, 45, 65, 90];

/// Test hook. Writes lifetime XP and the pet on the device store.
/// There is no shipped control for this.
Future<void> _seedWorld(WidgetTester tester, String petId, int level) async {
  final isar = Isar.getInstance();
  expect(isar, isNotNull);
  final found = await isar!.v14ProfileLocals.where().findFirst();
  expect(found, isNotNull);
  final profile = found!;
  final xp = const Phase1LevelCurve().threshold(level);
  profile
    ..petId = petId
    ..petName = petPackFor(petId).defaultName
    ..lastSeenLevel = level
    ..firstRunDone = true;
  final previous = await isar.localXpEventLocals
      .filter()
      .userIdEqualTo(profile.userId)
      .findAll();
  await isar.writeTxn(() async {
    await isar.localXpEventLocals.deleteAll([
      for (final row in previous) row.id,
    ]);
    await isar.v14ProfileLocals.put(profile);
    await isar.localXpEventLocals.put(
      LocalXpEventLocal()
        ..userId = profile.userId
        ..source = 'quest'
        ..sourceRef = 'device-world-$petId-$level'
        ..amount = xp
        ..createdAt = DateTime.now(),
    );
  });
  final context = tester.element(find.byType(V14Shell));
  ProviderScope.containerOf(context).invalidate(v14ProfileProvider);
  ProviderScope.containerOf(context).invalidate(v14StoreProvider);
}

Future<void> _tour(WidgetTester tester, String petId, String shot) async {
  final pack = petPackFor(petId);
  for (var i = 0; i < _worldLevels.length; i++) {
    final level = _worldLevels[i];
    await _seedWorld(tester, petId, level);
    await _open(tester, 'home', 'settings');
    await tester.pump(const Duration(milliseconds: 300));
    await _home(tester);
    await _until(tester, find.textContaining(pack.worldName(i + 1)));
    expect(find.byKey(const Key('companion-sprite')), findsNothing);
    if (find.text('Stay').evaluate().isNotEmpty) {
      await tester.tap(find.text('Stay'));
      await tester.pump(const Duration(milliseconds: 300));
    }
    if (i == 0 || i == _worldLevels.length - 1) {
      await _shot(i == 0 ? shot : '$shot-w5');
    }
  }
}

Future<int> _lifetimeXp() async {
  final isar = Isar.getInstance();
  expect(isar, isNotNull);
  final rows = await isar!.localXpEventLocals.where().findAll();
  return rows
      .where((row) => !row.reversed)
      .fold<int>(0, (sum, row) => sum + row.amount);
}

Future<void> _seedHugeHabits() async {
  final isar = Isar.getInstance();
  expect(isar, isNotNull);
  final profile = await isar!.v14ProfileLocals.where().findFirst();
  expect(profile, isNotNull);
  await isar.writeTxn(() async {
    for (var i = 0; i < 24; i++) {
      await isar.habitLocals.put(
        HabitLocal()
          ..remoteId = 'huge-$i'
          ..userId = profile!.userId
          ..name = 'Huge $i'
          ..colorValue = 0xFF3FC08A
          ..icon = 'walk'
          ..kind = HabitKind.positive
          ..interval = HabitInterval.daily
          ..targetFrequency = 1
          ..scheduleWeekdays = []
          ..scheduleEvery = 1
          ..scheduleUnit = ScheduleUnit.days
          ..targetPerDay = 1
          ..incrementAmount = 1
          ..unitLabel = ''
          ..description = ''
          ..frequency = 'daily'
          ..restDays = []
          ..vacationsJson = '[]'
          ..remindersJson = '[]'
          ..archived = false
          ..sortOrder = 100 + i
          ..createdAt = DateTime.now(),
      );
    }
  });
}

Future<void> _clearHugeHabits() async {
  final isar = Isar.getInstance();
  if (isar == null) return;
  final rows = await isar.habitLocals
      .filter()
      .remoteIdStartsWith('huge-')
      .findAll();
  await isar.writeTxn(() async {
    await isar.habitLocals.deleteAll([for (final row in rows) row.id]);
  });
}

Future<void> _frame(WidgetTester tester, Size logical) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = logical;
  await tester.pump(const Duration(milliseconds: 500));
  expect(tester.takeException(), isNull);
}

Future<void> _home(WidgetTester tester) async {
  if (find.byKey(const Key('ring-hint')).evaluate().isNotEmpty) {
    await tester.tap(find.byKey(const Key('ring-dismiss')));
    await tester.pump(const Duration(milliseconds: 300));
  }
  await _until(tester, find.byType(V14Orb));
  await tester.tap(find.byType(V14Orb));
  await tester.pump(const Duration(milliseconds: 400));
  if (find.byKey(const Key('ring-hint')).evaluate().isNotEmpty) {
    await tester.tap(find.byKey(const Key('ring-dismiss')));
    await tester.pump(const Duration(milliseconds: 300));
  }
}

Future<void> _open(WidgetTester tester, String group, String id) async {
  if (find.byKey(const Key('ring-hint')).evaluate().isEmpty) {
    await _until(tester, find.byType(V14Orb));
    await tester.tap(find.byType(V14Orb));
    await tester.pump(const Duration(milliseconds: 400));
    if (find.byKey(const Key('ring-hint')).evaluate().isEmpty) {
      await tester.tap(find.byType(V14Orb));
      await tester.pump(const Duration(milliseconds: 400));
    }
    await _until(tester, find.byKey(const Key('ring-hint')));
  }
  await tester.tap(find.byKey(Key('ring-$group')));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(find.byKey(Key('ring-$id')));
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> _field(
  WidgetTester tester,
  String key,
  String button,
  String value,
) async {
  final field = find.byKey(Key(key));
  await _until(tester, field);
  await tester.enterText(field, value);
  await tester.pump(const Duration(milliseconds: 200));
  await _tapText(tester, button);
}

Future<void> _pinIn(WidgetTester tester, String pin) async {
  for (final digit in pin.split('')) {
    await tester.tap(find.text(digit).last);
    await tester.pump(const Duration(milliseconds: 120));
  }
}

Future<void> _back(WidgetTester tester) async {
  final back = find.byType(BackButton);
  if (back.evaluate().isNotEmpty) {
    await tester.tap(back.first);
  } else {
    final close = find.byIcon(Icons.arrow_back);
    if (close.evaluate().isNotEmpty) {
      await tester.tap(close.first);
    } else {
      await tester.pageBack();
    }
  }
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _tapText(WidgetTester tester, String label) async {
  final finder = find.text(label);
  final vertical = find.byWidgetPredicate(
    (widget) =>
        widget is Scrollable &&
        (widget.axisDirection == AxisDirection.down ||
            widget.axisDirection == AxisDirection.up),
  );
  if (finder.evaluate().isEmpty && vertical.evaluate().isNotEmpty) {
    for (final state in tester.stateList<ScrollableState>(vertical)) {
      for (var i = 0; i < 8 && finder.evaluate().isEmpty; i++) {
        final position = state.position;
        position.jumpTo(
          (position.pixels + 420).clamp(
            position.minScrollExtent,
            position.maxScrollExtent,
          ),
        );
        await tester.pump(const Duration(milliseconds: 150));
      }
    }
  }
  await _until(tester, finder, seconds: 8);
  final element = finder.evaluate().first;
  var pressed = false;
  element.visitAncestorElements((ancestor) {
    final widget = ancestor.widget;
    if (widget is RuhhPrimaryButton) {
      widget.onPressed?.call();
      pressed = true;
      return false;
    }
    if (widget is V14Button) {
      widget.onPressed?.call();
      pressed = true;
      return false;
    }
    if (widget is TextButton) {
      widget.onPressed?.call();
      pressed = true;
      return false;
    }
    return true;
  });
  if (!pressed) {
    await tester.tap(finder, warnIfMissed: false);
  }
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _tapKey(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  await _until(tester, finder);
  final element = finder.evaluate().first;
  var pressed = false;
  element.visitAncestorElements((ancestor) {
    final widget = ancestor.widget;
    if (widget is ListTile) {
      widget.onTap?.call();
      pressed = true;
      return false;
    }
    if (widget is InkWell) {
      widget.onTap?.call();
      pressed = true;
      return false;
    }
    return true;
  });
  if (!pressed) {
    await tester.tap(finder, warnIfMissed: false);
  }
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _until(
  WidgetTester tester,
  Finder finder, {
  int seconds = 25,
}) async {
  final end = DateTime.now().add(Duration(seconds: seconds));
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) {
      try {
        await tester.ensureVisible(finder.first);
      } catch (_) {}
      return;
    }
  }
  final visible = tester
      .widgetList<Text>(find.byType(Text))
      .map((text) => text.data)
      .whereType<String>()
      .take(30)
      .join(' | ');
  fail('Timed out waiting for $finder. Visible: $visible');
}

Future<void> _shot(String name) async {
  // ignore: avoid_print
  print('RUHH_SHOT $name');
  await Future<void>.delayed(const Duration(milliseconds: 700));
}
