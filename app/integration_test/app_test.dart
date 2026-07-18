// Subly — live end-to-end suite (runs against real Supabase auth + the live
// Cloudflare Worker + D1). Drives the REAL widget tree in a browser, so it works
// regardless of the Flutter web renderer (the UI is a canvas — no DOM to query,
// which is why Playwright can't do this and integration_test can).
//
// The app is flipped to LIVE mode purely by the SUPABASE_URL / SUPABASE_ANON_KEY
// / API_BASE_URL dart-defines (see AppConfig.isBackendLive) — no code change.
// Credentials for a throwaway, pre-confirmed user arrive via E2E_EMAIL /
// E2E_PASSWORD (the CI workflow provisions the user before this runs and purges
// it after).
//
// Run (see .github/workflows/e2e.yml):
//   chromedriver --port=4444 &
//   flutter drive \
//     --driver=test_driver/integration_test.dart \
//     --target=integration_test/app_test.dart \
//     -d web-server --browser-name=chrome \
//     --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... \
//     --dart-define=API_BASE_URL=... \
//     --dart-define=E2E_EMAIL=... --dart-define=E2E_PASSWORD=...

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:subly/core/e2e_keys.dart';
import 'package:subly/features/budget/budget_screen.dart';
import 'package:subly/features/calendar/calendar_screen.dart';
import 'package:subly/features/home/home_screen.dart';
import 'package:subly/features/insights/insights_screen.dart';
import 'package:subly/features/settings/settings_screen.dart';
import 'package:subly/features/shell/app_shell.dart';
import 'package:subly/main.dart' as app;

void main() {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const String email = String.fromEnvironment('E2E_EMAIL');
  const String password = String.fromEnvironment('E2E_PASSWORD');

  // The app animates forever in places (scan progress ring/timer, loaders), so
  // pumpAndSettle() would hang. Advance a fixed wall-clock slice instead — this
  // still lets real network futures resolve on the live binding.
  Future<void> pumpFor(WidgetTester tester, Duration total) async {
    final DateTime end = DateTime.now().add(total);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> shot(String name) => binding.takeScreenshot(name);

  testWidgets('login rejects empty + invalid credentials with clear messages',
      (WidgetTester tester) async {
    await app.main();
    await pumpFor(tester, const Duration(seconds: 3));

    await tester.tap(find.text('Skip'));
    await pumpFor(tester, const Duration(seconds: 2));
    expect(find.text('Welcome back'), findsOneWidget);

    // Fields must start EMPTY — no demo credentials shipped to users.
    expect(find.text('alex@example.com'), findsNothing);
    await shot('00a-login-empty');

    // Empty submit → inline validation, no network round-trip.
    await tester.tap(find.byKey(E2EKeys.loginSubmit));
    await pumpFor(tester, const Duration(seconds: 1));
    expect(find.textContaining('Enter your email'), findsWidgets);
    await shot('00b-empty-validation');

    // Wrong credentials → friendly message, stays on the login screen.
    final int ts = DateTime.now().millisecondsSinceEpoch;
    await tester.enterText(
        find.byKey(E2EKeys.loginEmail), 'nobody-$ts@nikatru.com');
    await tester.enterText(
        find.byKey(E2EKeys.loginPassword), 'wrong-password-123');
    await pumpFor(tester, const Duration(milliseconds: 300));
    await tester.tap(find.byKey(E2EKeys.loginSubmit));
    await pumpFor(tester, const Duration(seconds: 8));
    expect(find.textContaining('Incorrect email or password'), findsWidgets);
    expect(find.text('Welcome back'), findsOneWidget);
    await shot('00c-invalid-credentials');
  });

  testWidgets('visits every page, creates a subscription, reads it back',
      (WidgetTester tester) async {
    expect(email, isNotEmpty,
        reason: 'E2E_EMAIL dart-define missing — CI must provision a user');
    expect(password, isNotEmpty, reason: 'E2E_PASSWORD dart-define missing');

    int shellIndex() => tester
        .widget<AppShell>(find.byType(AppShell))
        .navigationShell
        .currentIndex;

    // ── Boot ───────────────────────────────────────────────────────────────
    await app.main();
    await pumpFor(tester, const Duration(seconds: 3));

    // ── 01 Onboarding ────────────────────────────────────────────────────────
    expect(find.text('Skip'), findsOneWidget,
        reason: 'App did not land on the onboarding screen');
    await shot('01-onboarding');
    await tester.tap(find.text('Skip'));
    await pumpFor(tester, const Duration(seconds: 2));

    // ── 02 Login ─────────────────────────────────────────────────────────────
    expect(find.text('Welcome back'), findsOneWidget);
    await shot('02-login');
    await tester.enterText(find.byKey(E2EKeys.loginEmail), email);
    await tester.enterText(find.byKey(E2EKeys.loginPassword), password);
    await pumpFor(tester, const Duration(milliseconds: 500));
    await tester.tap(find.byKey(E2EKeys.loginSubmit));
    // GoTrue sign-in + navigation to /scan.
    await pumpFor(tester, const Duration(seconds: 10));

    // ── 03 Scan ──────────────────────────────────────────────────────────────
    await shot('03-scan');
    expect(find.text('Go to dashboard'), findsOneWidget,
        reason: 'Scan never finished — sign-in likely failed (bad/unconfirmed '
            'credentials or backend down)');
    await tester.tap(find.text('Go to dashboard'));
    await pumpFor(tester, const Duration(seconds: 4));

    // ── 04 Home ──────────────────────────────────────────────────────────────
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(HomeScreen), findsWidgets);
    expect(shellIndex(), 0);
    await shot('04-home');

    // ── 05 Calendar ──────────────────────────────────────────────────────────
    await tester.tap(find.text('Calendar'));
    await pumpFor(tester, const Duration(seconds: 2));
    expect(shellIndex(), 1);
    expect(find.byType(CalendarScreen), findsWidgets);
    await shot('05-calendar');

    // ── 06 Insights ──────────────────────────────────────────────────────────
    await tester.tap(find.text('Insights'));
    await pumpFor(tester, const Duration(seconds: 2));
    expect(shellIndex(), 2);
    expect(find.byType(InsightsScreen), findsWidgets);
    await shot('06-insights');

    // ── 07 Budget (loads over the network first) ─────────────────────────────
    await tester.tap(find.text('Budget'));
    await pumpFor(tester, const Duration(seconds: 4));
    expect(shellIndex(), 3);
    expect(find.byType(BudgetScreen), findsWidgets);
    await shot('07-budget');

    // ── 08 Settings (the 5th tab is labelled "More") ─────────────────────────
    await tester.tap(find.text('More'));
    await pumpFor(tester, const Duration(seconds: 2));
    expect(shellIndex(), 4);
    expect(find.byType(SettingsScreen), findsWidgets);
    expect(find.text('Log out'), findsWidgets);
    await shot('08-settings');

    // Back to Home for notifications + create.
    await tester.tap(find.text('Home'));
    await pumpFor(tester, const Duration(seconds: 2));
    expect(shellIndex(), 0);

    // ── 09 Notifications (bell on Home) ──────────────────────────────────────
    await tester.tap(find.byIcon(Icons.notifications_none_rounded));
    await pumpFor(tester, const Duration(seconds: 2));
    expect(find.text('Notifications'), findsWidgets);
    await shot('09-notifications');
    await tester.tap(find.byIcon(Icons.close));
    await pumpFor(tester, const Duration(seconds: 2));
    expect(shellIndex(), 0);

    // ── 10 Add-subscription sheet ────────────────────────────────────────────
    final String subName =
        'E2E Probe ${DateTime.now().millisecondsSinceEpoch}';
    await tester.tap(find.byKey(E2EKeys.fabAdd));
    await pumpFor(tester, const Duration(seconds: 2));
    expect(find.text('Add subscription'), findsWidgets);
    await tester.enterText(find.byKey(E2EKeys.addName), subName);
    await tester.enterText(find.byKey(E2EKeys.addPrice), '12.34');
    await pumpFor(tester, const Duration(milliseconds: 500));
    await shot('10-add-sheet');
    await tester.tap(find.byKey(E2EKeys.addSubmit));
    // POST /v1/subscriptions → Worker → D1, then the sheet closes.
    await pumpFor(tester, const Duration(seconds: 8));

    // ── 11 Read-back on Home (proves the row round-tripped through D1) ────────
    // Home is a lazy ListView — scroll the new row into view before asserting.
    final Finder subFinder = find.text(subName);
    await tester.scrollUntilVisible(
      subFinder.first,
      160,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 40,
    );
    expect(subFinder, findsWidgets,
        reason: 'The created subscription did not appear on Home — the POST or '
            'read-back failed');
    await shot('11-home-after-create');

    // ── 12 Detail (subscription A) ───────────────────────────────────────────
    await tester.tap(subFinder.first);
    await pumpFor(tester, const Duration(seconds: 3));
    expect(find.text('Payment history'), findsWidgets);
    await shot('12-detail');

    // ── 13 Cancel/delete A (exercises DELETE /v1/subscriptions/:id) ───────────
    await tester.tap(find.text('Cancel plan'));
    await pumpFor(tester, const Duration(seconds: 2));
    expect(find.text('Confirm cancel'), findsOneWidget);
    await tester.tap(find.text('Confirm cancel'));
    await pumpFor(tester, const Duration(seconds: 8)); // DELETE round-trip
    expect(find.text('Cancelled'), findsWidgets,
        reason: 'Cancel confirmation never appeared — DELETE likely failed');
    await tester.tap(find.text('Done'));
    await pumpFor(tester, const Duration(seconds: 4)); // sheet + detail pop → home
    expect(shellIndex(), 0);
    expect(find.text(subName), findsNothing,
        reason: 'Cancelled subscription still shows on Home — delete failed');
    await shot('13-after-cancel');

    // ── 14 Create a SECOND subscription (left in D1 for the CI verify+purge) ──
    final String subNameB =
        'E2E Probe B ${DateTime.now().millisecondsSinceEpoch}';
    await tester.tap(find.byKey(E2EKeys.fabAdd));
    await pumpFor(tester, const Duration(seconds: 2));
    await tester.enterText(find.byKey(E2EKeys.addName), subNameB);
    await tester.enterText(find.byKey(E2EKeys.addPrice), '7.77');
    await pumpFor(tester, const Duration(milliseconds: 500));
    await tester.tap(find.byKey(E2EKeys.addSubmit));
    await pumpFor(tester, const Duration(seconds: 8));
    final Finder subFinderB = find.text(subNameB);
    await tester.scrollUntilVisible(
      subFinderB.first,
      160,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 40,
    );
    expect(subFinderB, findsWidgets,
        reason: 'Second subscription did not round-trip to Home');
    await shot('14-second-sub');

    // ── 15 Settings: switch currency (client-state propagation) ──────────────
    await tester.tap(find.text('More'));
    await pumpFor(tester, const Duration(seconds: 2));
    expect(shellIndex(), 4);
    await tester.tap(find.text('€'));
    await pumpFor(tester, const Duration(seconds: 1));
    await shot('15-settings-currency');

    // ── 16 Home reflects the new currency ────────────────────────────────────
    await tester.tap(find.text('Home'));
    await pumpFor(tester, const Duration(seconds: 2));
    expect(shellIndex(), 0);
    expect(find.textContaining('€'), findsWidgets,
        reason: 'Currency change did not propagate to Home');
    await shot('16-home-currency');

    // ── 17 Sign out → back to onboarding ─────────────────────────────────────
    await tester.tap(find.text('More'));
    await pumpFor(tester, const Duration(seconds: 2));
    await tester.tap(find.text('Log out'));
    await pumpFor(tester, const Duration(seconds: 4));
    expect(find.text('Skip'), findsOneWidget,
        reason: 'Sign-out did not return to the onboarding flow');
    await shot('17-signed-out');
  });
}
