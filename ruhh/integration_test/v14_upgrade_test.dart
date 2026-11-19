import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:isar/isar.dart';
import 'package:ruhh/core/data/models/book_local.dart';
import 'package:ruhh/core/data/models/habit_local.dart';
import 'package:ruhh/core/data/models/movie_local.dart';
import 'package:ruhh/core/data/models/prayer_local.dart';
import 'package:ruhh/core/data/models/transaction_local.dart';
import 'package:ruhh/features/v14/widgets/v14_chrome.dart';
import 'package:ruhh/main.dart' as app;

/// Installed over a 1.0.34 database that already has one row per module.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('1.0.34 data is still there after the upgrade', (tester) async {
    await app.main();
    await _until(
      tester,
      find.byWidgetPredicate(
        (widget) =>
            widget.key == const Key('pet-card-dragon') ||
            widget.key == const Key('v14-orb') ||
            widget.key == const Key('pet-locked') ||
            (widget is Text && widget.data == 'Create account'),
      ),
    );
    expect(
      find.text('Create account'),
      findsNothing,
      reason: 'The 1.0.34 session should still be logged in',
    );
    // Home flashes an orb, then sends a profile with no pet to the picker.
    // Wait until one of those two stays.
    final end = DateTime.now().add(const Duration(seconds: 20));
    var entered = false;
    while (DateTime.now().isBefore(end) && !entered) {
      await tester.pump(const Duration(milliseconds: 250));
      if (find.byKey(const Key('pet-card-dragon')).evaluate().isNotEmpty ||
          find.byKey(const Key('pet-locked')).evaluate().isNotEmpty) {
        await _chooseDragon(tester);
        entered = true;
        break;
      }
      if (find.byKey(const Key('v14-orb')).evaluate().isNotEmpty &&
          find.text('Choose a companion').evaluate().isEmpty) {
        await tester.pump(const Duration(milliseconds: 800));
        if (find.byKey(const Key('pet-card-dragon')).evaluate().isNotEmpty) {
          continue;
        }
        entered = find.byKey(const Key('v14-orb')).evaluate().isNotEmpty;
      }
    }
    expect(entered, isTrue, reason: 'Home or the pet picker should stay open');
    await _until(tester, find.byKey(const Key('v14-orb')));
    expect(find.text('Choose a companion'), findsNothing);

    await _open(tester, 'habits', 'orbit');
    await _tapText(tester, 'Classic list');
    await _until(tester, find.byKey(const Key('habit-board-name-Upgrade walk')));
    await _back(tester);
    await _until(tester, find.byKey(const Key('v14-orb')));

    await _open(tester, 'money', 'money-month');
    await _until(tester, find.textContaining('125'));

    await _open(tester, 'prayer', 'prayer-sky');
    await _until(tester, find.byKey(const Key('prayer-no-xp')));
    final isar = Isar.getInstance('ruhh');
    expect(isar, isNotNull);
    final prayer = await isar!.dailyPrayerLogLocals.where().anyId().findFirst();
    expect(prayer, isNotNull);
    expect(prayer!.fajr, TrackerPrayerStatus.prayed);
    expect(
      await isar.habitLocals.where().anyId().findAll(),
      isNotEmpty,
    );
    expect(
      await isar.transactionLocals.where().anyId().findAll(),
      isNotEmpty,
    );
    expect(await isar.bookLocals.where().anyId().findAll(), isNotEmpty);
    expect(await isar.movieLocals.where().anyId().findAll(), isNotEmpty);

    await _open(tester, 'books', 'shelf');
    await _until(tester, find.textContaining('Upgrade Alchemist'));
    expect(find.textContaining('Upgrade Pather'), findsWidgets);
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 8)));
}

Future<void> _chooseDragon(WidgetTester tester) async {
  if (find.byKey(const Key('pet-locked')).evaluate().isNotEmpty) {
    final context = tester.element(find.byType(Scaffold).first);
    GoRouter.of(context).go('/home');
    await tester.pump(const Duration(milliseconds: 400));
    return;
  }
  await _tapKey(tester, const Key('pet-card-dragon'));
  await _tapText(tester, 'Choose');
  await _until(tester, find.byKey(const Key('pet-permanent')));
  final box = tester.widget<CheckboxListTile>(
    find.byKey(const Key('pet-permanent')),
  );
  box.onChanged?.call(true);
  await tester.pump(const Duration(milliseconds: 300));
  await _tapText(tester, 'Choose Dragon for good');
  await _until(tester, find.text('Skip'));
  for (var i = 0; i < 8; i++) {
    if (find.text('Skip').evaluate().isEmpty) break;
    await _tapText(tester, 'Skip');
    await tester.pump(const Duration(milliseconds: 300));
  }
  expect(find.text('Skip'), findsNothing);
}

Future<void> _open(WidgetTester tester, String group, String id) async {
  if (find.byKey(const Key('ring-hint')).evaluate().isEmpty) {
    await _pressOrb(tester);
    if (find.byKey(const Key('ring-hint')).evaluate().isEmpty) {
      await _pressOrb(tester);
    }
    await _until(tester, find.byKey(const Key('ring-hint')));
  }
  await _tapKey(tester, Key('ring-$group'));
  await _tapKey(tester, Key('ring-$id'));
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

Future<void> _pressOrb(WidgetTester tester) async {
  final finder = find.byKey(const Key('v14-orb'));
  await _until(tester, finder);
  tester.widget<GestureDetector>(finder).onTap?.call();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _tapKey(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  await _until(tester, finder);
  final widget = finder.evaluate().first.widget;
  if (widget is InkWell) {
    widget.onTap?.call();
  } else if (widget is GestureDetector) {
    widget.onTap?.call();
  }
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _tapText(WidgetTester tester, String label) async {
  final finder = find.text(label);
  await _until(tester, finder);
  var pressed = false;
  finder.evaluate().first.visitAncestorElements((ancestor) {
    final widget = ancestor.widget;
    if (widget is V14Button && widget.onPressed != null) {
      widget.onPressed!.call();
      pressed = true;
      return false;
    }
    if (widget is TextButton && widget.onPressed != null) {
      widget.onPressed!.call();
      pressed = true;
      return false;
    }
    return true;
  });
  if (!pressed) {
    await tester.tap(finder, warnIfMissed: false);
  }
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _until(WidgetTester tester, Finder finder) async {
  final end = DateTime.now().add(const Duration(seconds: 30));
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) return;
  }
  final visible = tester
      .widgetList<Text>(find.byType(Text))
      .map((text) => text.data)
      .whereType<String>()
      .take(24)
      .join(' | ');
  fail('Timed out waiting for $finder. Visible: $visible');
}
