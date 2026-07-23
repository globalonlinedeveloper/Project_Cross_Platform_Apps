import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nikatru_design_system/nikatru_design_system.dart';

void main() {
  testWidgets('shows the child when no update is required',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: ForceUpdateGate(mustUpdate: false, child: Text('app content')),
    ));
    expect(find.text('app content'), findsOneWidget);
    expect(find.text('Update required'), findsNothing);
  });

  testWidgets('blocks with the update screen when an update is required',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: ForceUpdateGate(mustUpdate: true, child: Text('app content')),
    ));
    expect(find.text('app content'), findsNothing);
    expect(find.text('Update required'), findsOneWidget);
  });

  testWidgets('fires onUpdate when the button is tapped',
      (WidgetTester tester) async {
    int taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: ForceUpdateGate(
        mustUpdate: true,
        onUpdate: () => taps++,
        child: const Text('app content'),
      ),
    ));
    expect(find.text('Update now'), findsOneWidget);
    await tester.tap(find.text('Update now'));
    expect(taps, 1);
  });

  testWidgets('hides the button when onUpdate is null but still blocks',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: ForceUpdateGate(mustUpdate: true, child: Text('app content')),
    ));
    expect(find.text('Update now'), findsNothing);
    expect(find.text('Update required'), findsOneWidget);
  });
}
