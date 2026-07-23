import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:flutter_test/flutter_test.dart';
import 'package:nikatru_core/nikatru_core.dart';
// The plugin-backed service + its test seam live in the io library (the barrel
// deliberately does NOT export it, so web stays compilable). Tests run natively,
// where `dart.library.io` is available.
import 'package:nikatru_notifications/src/local_notification_service_io.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Records which plugin operations the service decided to invoke, so the
/// platform-guard logic can be asserted without real platform channels.
class _FakePlugin implements NotificationPlugin {
  final List<String> calls = <String>[];
  final List<tz.TZDateTime> scheduledFor = <tz.TZDateTime>[];
  bool permission = true;

  @override
  Future<void> initialize() async => calls.add('initialize');

  @override
  Future<bool> requestPermission() async {
    calls.add('requestPermission');
    return permission;
  }

  @override
  Future<void> showNow(int id, String title, String body) async =>
      calls.add('showNow:$id');

  @override
  Future<void> scheduleDaily(
    int id,
    String title,
    String body,
    tz.TZDateTime when,
  ) async {
    calls.add('scheduleDaily:$id');
    scheduledFor.add(when);
  }

  @override
  Future<void> cancel(int id) async => calls.add('cancel:$id');

  @override
  Future<void> cancelAll() async => calls.add('cancelAll');
}

void main() {
  setUpAll(tz_data.initializeTimeZones);

  LocalNotificationService build(
    _FakePlugin plugin,
    TargetPlatform platform, {
    bool isWeb = false,
    TZDateTimeNow? now,
  }) =>
      LocalNotificationService(
        plugin: plugin,
        platform: platform,
        isWeb: isWeb,
        localTimezone: () async => 'UTC',
        now: now,
      );

  const DailyReminder reminder = DailyReminder(
    id: 7,
    title: 'Keep your streak',
    body: 'Do today\'s lesson',
    hour: 9,
    minute: 15,
  );

  group('supported platform (android)', () {
    test('init sets up the plugin', () async {
      final _FakePlugin p = _FakePlugin();
      await build(p, TargetPlatform.android).init();
      expect(p.calls, contains('initialize'));
    });

    test('init is idempotent (initializes the plugin once)', () async {
      final _FakePlugin p = _FakePlugin();
      final LocalNotificationService s = build(p, TargetPlatform.android);
      await s.init();
      await s.init();
      expect(p.calls.where((String c) => c == 'initialize').length, 1);
    });

    test('requestPermission delegates and returns the plugin result', () async {
      final _FakePlugin p = _FakePlugin()..permission = true;
      expect(
        await build(p, TargetPlatform.android).requestPermission(),
        isTrue,
      );
      expect(p.calls, contains('requestPermission'));
    });

    test('showNow shows an immediate notification', () async {
      final _FakePlugin p = _FakePlugin();
      await build(p, TargetPlatform.android).showNow(title: 'a', body: 'b');
      expect(p.calls.any((String c) => c.startsWith('showNow')), isTrue);
    });

    test('scheduleDaily schedules by reminder id', () async {
      final _FakePlugin p = _FakePlugin();
      await build(p, TargetPlatform.android).scheduleDaily(reminder);
      expect(p.calls, contains('scheduleDaily:7'));
    });

    test('cancel / cancelAll delegate', () async {
      final _FakePlugin p = _FakePlugin();
      final LocalNotificationService s = build(p, TargetPlatform.android);
      await s.cancel(3);
      await s.cancelAll();
      expect(p.calls, containsAll(<String>['cancel:3', 'cancelAll']));
    });

    test('exposes canNotify + canSchedule capabilities', () {
      final LocalNotificationService s = build(
        _FakePlugin(),
        TargetPlatform.android,
      );
      expect(s.capabilities.canNotify, isTrue);
      expect(s.capabilities.canSchedule, isTrue);
    });
  });

  group('linux (show yes, repeat-schedule no)', () {
    test('scheduleDaily is a no-op (no zonedSchedule on Linux)', () async {
      final _FakePlugin p = _FakePlugin();
      await build(p, TargetPlatform.linux).scheduleDaily(reminder);
      expect(p.calls, isNot(contains('scheduleDaily:7')));
    });

    test('showNow still works', () async {
      final _FakePlugin p = _FakePlugin();
      await build(p, TargetPlatform.linux).showNow(title: 'a', body: 'b');
      expect(p.calls.any((String c) => c.startsWith('showNow')), isTrue);
    });

    test('cancel still delegates (Linux can dismiss a shown notification)',
        () async {
      final _FakePlugin p = _FakePlugin();
      await build(p, TargetPlatform.linux).cancel(9);
      expect(p.calls, contains('cancel:9'));
    });
  });

  // On the pinned flutter_local_notifications 17.x both Web (no plugin) and
  // Windows (no Windows plugin until 18.x) are fully unsupported: every op must
  // degrade to a no-op rather than throw.
  group('fully unsupported (web + windows on 17.x)', () {
    Future<void> expectAllNoOp(
        LocalNotificationService s, _FakePlugin p) async {
      await s.init();
      expect(await s.requestPermission(), isFalse);
      await s.showNow(title: 'a', body: 'b');
      await s.scheduleDaily(reminder);
      await s.cancel(1);
      await s.cancelAll();
      expect(p.calls, isEmpty);
    }

    test('web never touches the plugin', () async {
      final _FakePlugin p = _FakePlugin();
      await expectAllNoOp(build(p, TargetPlatform.android, isWeb: true), p);
    });

    test('windows never touches the plugin', () async {
      final _FakePlugin p = _FakePlugin();
      await expectAllNoOp(build(p, TargetPlatform.windows), p);
    });
  });

  group('nextInstanceOfTime', () {
    test('returns today when the time is still ahead', () {
      final tz.TZDateTime now = tz.TZDateTime(tz.UTC, 2026, 1, 1, 6, 0);
      expect(
        nextInstanceOfTime(9, 0, now),
        tz.TZDateTime(tz.UTC, 2026, 1, 1, 9, 0),
      );
    });

    test('rolls to tomorrow when the time already passed today', () {
      final tz.TZDateTime now = tz.TZDateTime(tz.UTC, 2026, 1, 1, 10, 0);
      expect(
        nextInstanceOfTime(9, 0, now),
        tz.TZDateTime(tz.UTC, 2026, 1, 2, 9, 0),
      );
    });

    test('rolls to tomorrow when the time equals now (strictly after)', () {
      final tz.TZDateTime now = tz.TZDateTime(tz.UTC, 2026, 1, 1, 9, 0);
      expect(
        nextInstanceOfTime(9, 0, now),
        tz.TZDateTime(tz.UTC, 2026, 1, 2, 9, 0),
      );
    });
  });

  test(
    'scheduleDaily anchors at the next local instance of the reminder time',
    () async {
      final _FakePlugin p = _FakePlugin();
      final tz.TZDateTime now = tz.TZDateTime(tz.UTC, 2026, 1, 1, 6, 0);
      await build(
        p,
        TargetPlatform.android,
        now: () => now,
      ).scheduleDaily(reminder);
      expect(p.scheduledFor.single, tz.TZDateTime(tz.UTC, 2026, 1, 1, 9, 15));
    },
  );
}
