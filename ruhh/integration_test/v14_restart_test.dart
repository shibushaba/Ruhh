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
      await tester.tap(find.byType(V14Orb));
      await tester.pump(const Duration(milliseconds: 400));
      if (find.byKey(const Key('ring-hint')).evaluate().isEmpty) {
        await tester.tap(find.byType(V14Orb));
        await tester.pump(const Duration(milliseconds: 400));
      }
      await tester.tap(find.byKey(const Key('ring-habits')));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const Key('ring-orbit')));
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.textContaining('Read'), findsWidgets);
      expect(find.textContaining('Alchemist'), findsNothing);
      await tester.tap(find.byType(V14Orb));
      await tester.pump(const Duration(milliseconds: 400));
      if (find.byKey(const Key('ring-hint')).evaluate().isEmpty) {
        await tester.tap(find.byType(V14Orb));
        await tester.pump(const Duration(milliseconds: 400));
      }
      await tester.tap(find.byKey(const Key('ring-books')));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const Key('ring-shelf')));
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.textContaining('Alchemist'), findsWidgets);
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
