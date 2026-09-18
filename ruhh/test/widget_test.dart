import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruhh/main.dart';

void main() {
  testWidgets('RUHH app smoke', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: RuhhApp()));
    expect(find.text('RUHH'), findsOneWidget);
  });
}
