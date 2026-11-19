import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ruhh/features/v14/widgets/v14_chrome.dart';
import 'package:ruhh/main.dart' as app;

/// Run after [v14_device_test] without uninstalling.
/// The process is started fresh, so this checks kill/restart persistence.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets(
    'habits and books survive a process restart',
    (tester) async {
      await app.main();
      final end = DateTime.now().add(const Duration(seconds: 40));
      while (DateTime.now().isBefore(end)) {
        await tester.pump(const Duration(milliseconds: 300));
        if (find.byType(V14Orb).evaluate().isNotEmpty) break;
        if (find.text('Sign in').evaluate().isNotEmpty ||
            find.text('Welcome back').evaluate().isNotEmpty) {
          break;
        }
      }
      if (find.byType(V14Orb).evaluate().isEmpty) {
        final pin = find.text('1');
        if (pin.evaluate().isNotEmpty) {
          for (final digit in '135790'.split('')) {
            await tester.tap(find.text(digit).last);
            await tester.pump(const Duration(milliseconds: 150));
          }
        }
      }
      final ready = DateTime.now().add(const Duration(seconds: 30));
      while (DateTime.now().isBefore(ready)) {
        await tester.pump(const Duration(milliseconds: 300));
        if (find.byType(V14Orb).evaluate().isNotEmpty) break;
      }
      expect(find.byType(V14Orb), findsWidgets);
      await _pressOrb(tester);
      if (find.byKey(const Key('ring-hint')).evaluate().isEmpty) {
        await _pressOrb(tester);
      }
      await _tapKey(tester, const Key('ring-habits'));
      await _tapKey(tester, const Key('ring-orbit'));
      await _until(tester, find.textContaining('Read'));
      expect(find.textContaining('Alchemist'), findsNothing);
      await _pressOrb(tester);
      if (find.byKey(const Key('ring-hint')).evaluate().isEmpty) {
        await _pressOrb(tester);
      }
      await _tapKey(tester, const Key('ring-books'));
      await _tapKey(tester, const Key('ring-shelf'));
      await _until(tester, find.textContaining('Alchemist'));
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
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
  } else {
    await tester.tap(finder, warnIfMissed: false);
  }
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _until(WidgetTester tester, Finder finder) async {
  final end = DateTime.now().add(const Duration(seconds: 20));
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timed out waiting for $finder');
}
