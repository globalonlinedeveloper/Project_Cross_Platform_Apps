import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nikatru_design_system/nikatru_design_system.dart';

void main() {
  const List<AppDestination> destinations = <AppDestination>[
    AppDestination(icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home'),
    AppDestination(icon: Icons.pie_chart_outline, selectedIcon: Icons.pie_chart, label: 'Budget'),
    AppDestination(icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: 'Settings'),
  ];

  Widget harness({int index = 0, ValueChanged<int>? onSelected}) {
    return MaterialApp(
      home: AppScaffold(
        destinations: destinations,
        selectedIndex: index,
        onDestinationSelected: onSelected ?? (_) {},
        body: const Center(child: Text('BODY')),
      ),
    );
  }

  Future<void> pumpAt(WidgetTester tester, Size size, Widget w) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(w);
  }

  testWidgets('compact width → NavigationBar only', (WidgetTester tester) async {
    await pumpAt(tester, const Size(400, 800), harness());
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(NavigationDrawer), findsNothing);
    expect(find.text('BODY'), findsOneWidget);
  });

  testWidgets('medium width → NavigationRail only', (WidgetTester tester) async {
    await pumpAt(tester, const Size(800, 800), harness(index: 1));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(NavigationDrawer), findsNothing);
  });

  testWidgets('expanded width → NavigationDrawer only', (WidgetTester tester) async {
    await pumpAt(tester, const Size(1300, 900), harness(index: 2));
    expect(find.byType(NavigationDrawer), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('tapping a destination reports its index', (WidgetTester tester) async {
    int? tapped;
    await pumpAt(tester, const Size(400, 800), harness(onSelected: (int i) => tapped = i));
    await tester.tap(find.text('Settings'));
    await tester.pump();
    expect(tapped, 2);
  });

  testWidgets('renders an app bar title when provided', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: AppScaffold(
          destinations: destinations,
          selectedIndex: 0,
          onDestinationSelected: (_) {},
          title: const Text('Subly'),
          body: const SizedBox.shrink(),
        ),
      ),
    );
    expect(find.widgetWithText(AppBar, 'Subly'), findsOneWidget);
  });
}
