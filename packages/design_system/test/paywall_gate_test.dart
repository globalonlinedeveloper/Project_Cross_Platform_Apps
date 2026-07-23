import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nikatru_design_system/nikatru_design_system.dart';

void main() {
  testWidgets('shows the child when unlocked', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: PaywallGate(locked: false, child: Text('premium content')),
      ),
    ));
    expect(find.text('premium content'), findsOneWidget);
    expect(find.text('Unlock the full experience'), findsNothing);
  });

  testWidgets('shows the upsell when locked', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: PaywallGate(locked: true, child: Text('premium content')),
      ),
    ));
    expect(find.text('premium content'), findsNothing);
    expect(find.text('Unlock the full experience'), findsOneWidget);
  });

  testWidgets('fires onUpgrade when the button is tapped',
      (WidgetTester tester) async {
    int taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PaywallGate(
          locked: true,
          onUpgrade: () => taps++,
          child: const Text('premium content'),
        ),
      ),
    ));
    expect(find.text('Upgrade'), findsOneWidget);
    await tester.tap(find.text('Upgrade'));
    expect(taps, 1);
  });

  testWidgets('hides the button when onUpgrade is null but stays locked',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: PaywallGate(locked: true, child: Text('premium content')),
      ),
    ));
    expect(find.text('Upgrade'), findsNothing);
    expect(find.text('Unlock the full experience'), findsOneWidget);
  });
}
