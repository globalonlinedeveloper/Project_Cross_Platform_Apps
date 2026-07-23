import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nikatru_core/nikatru_core.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'notification_capabilities.dart';

/// Native factory (Android/iOS/macOS/Linux/Windows) — selected by the conditional
/// import when `dart.library.io` is available.
NotificationService createPlatformNotificationService({
  LocalTimezoneResolver? localTimezone,
}) =>
    LocalNotificationService(localTimezone: localTimezone);

/// Returns a [tz.TZDateTime] a fixed clock — injected in tests for determinism.
typedef TZDateTimeNow = tz.TZDateTime Function();

/// Minimal port over the notification-plugin operations the service needs. A
/// seam so the service's platform-guard logic is unit-testable without platform
/// channels — the concrete adapter below is thin glue that `analyze` covers.
@visibleForTesting
abstract interface class NotificationPlugin {
  Future<void> initialize();
  Future<bool> requestPermission();
  Future<void> showNow(int id, String title, String body);
  Future<void> scheduleDaily(
    int id,
    String title,
    String body,
    tz.TZDateTime when,
  );
  Future<void> cancel(int id);
  Future<void> cancelAll();
}

/// A [NotificationService] backed by `flutter_local_notifications` + `timezone`.
///
/// All runtime plugin calls are guarded by [NotificationCapabilities] so an
/// unsupported platform degrades to a safe no-op instead of throwing (Windows
/// can't repeat-schedule; a web build uses the stub factory, never this class).
class LocalNotificationService implements NotificationService {
  LocalNotificationService({
    NotificationPlugin? plugin,
    TargetPlatform? platform,
    bool isWeb = false,
    LocalTimezoneResolver? localTimezone,
    TZDateTimeNow? now,
  })  : _plugin = plugin ?? _FlutterLocalNotificationsAdapter(),
        _caps = NotificationCapabilities.forPlatform(
          platform ?? defaultTargetPlatform,
          isWeb: isWeb,
        ),
        _resolveTimezone = localTimezone ?? _defaultTimezone,
        _now = now;

  final NotificationPlugin _plugin;
  final NotificationCapabilities _caps;
  final LocalTimezoneResolver _resolveTimezone;
  final TZDateTimeNow? _now;
  bool _initialized = false;

  /// Fixed id bucket for immediate notifications (kept clear of caller-chosen
  /// small reminder ids); each `showNow` replaces the previous immediate one.
  static const int _immediateId = 0x7f000000;

  static Future<String> _defaultTimezone() async => 'UTC';

  /// The resolved platform capabilities — lets the app decide whether to offer a
  /// scheduling toggle or fall back to an in-app nudge.
  NotificationCapabilities get capabilities => _caps;

  @override
  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(_locationOrUtc(await _safeTimezone()));
    if (_caps.canNotify) {
      await _plugin.initialize();
    }
    _initialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    if (!_caps.canNotify) return false;
    return _plugin.requestPermission();
  }

  @override
  Future<void> showNow({required String title, required String body}) async {
    if (!_caps.canNotify) return;
    await _plugin.showNow(_immediateId, title, body);
  }

  @override
  Future<void> scheduleDaily(DailyReminder reminder) async {
    if (!_caps.canSchedule) return;
    final tz.TZDateTime base = _now?.call() ?? tz.TZDateTime.now(tz.local);
    await _plugin.scheduleDaily(
      reminder.id,
      reminder.title,
      reminder.body,
      nextInstanceOfTime(reminder.hour, reminder.minute, base),
    );
  }

  @override
  Future<void> cancel(int id) async {
    if (!_caps.canNotify) return;
    await _plugin.cancel(id);
  }

  @override
  Future<void> cancelAll() async {
    if (!_caps.canNotify) return;
    await _plugin.cancelAll();
  }

  Future<String> _safeTimezone() async {
    try {
      return await _resolveTimezone();
    } catch (_) {
      return 'UTC';
    }
  }

  tz.Location _locationOrUtc(String name) {
    try {
      return tz.getLocation(name);
    } catch (_) {
      // tz.UTC is a built-in constant (no database lookup) so it never throws,
      // even if the tz database somehow isn't loaded.
      return tz.UTC;
    }
  }
}

/// The next [tz.TZDateTime] at [hour]:[minute] in [now]'s location, strictly
/// after [now] — today if the time is still ahead, otherwise tomorrow. Pure: the
/// daily-schedule anchor, kept side-effect-free so it can be tested exactly.
tz.TZDateTime nextInstanceOfTime(int hour, int minute, tz.TZDateTime now) {
  tz.TZDateTime scheduled = tz.TZDateTime(
    now.location,
    now.year,
    now.month,
    now.day,
    hour,
    minute,
  );
  if (!scheduled.isAfter(now)) {
    scheduled = scheduled.add(const Duration(days: 1));
  }
  return scheduled;
}

/// The default [NotificationPlugin] — thin glue onto `flutter_local_notifications`.
class _FlutterLocalNotificationsAdapter implements NotificationPlugin {
  final FlutterLocalNotificationsPlugin _fln =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    'nikatru_reminders',
    'Reminders',
    channelDescription: 'Daily streak and goal reminders',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  static const NotificationDetails _details = NotificationDetails(
    android: _androidDetails,
    iOS: DarwinNotificationDetails(),
    macOS: DarwinNotificationDetails(),
    linux: LinuxNotificationDetails(),
  );

  @override
  Future<void> initialize() async {
    const InitializationSettings settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
      linux: LinuxInitializationSettings(defaultActionName: 'Open'),
    );
    await _fln.initialize(settings);
  }

  @override
  Future<bool> requestPermission() async {
    final AndroidFlutterLocalNotificationsPlugin? android =
        _fln.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return (await android.requestNotificationsPermission()) ?? false;
    }
    final IOSFlutterLocalNotificationsPlugin? ios =
        _fln.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return (await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          )) ??
          false;
    }
    final MacOSFlutterLocalNotificationsPlugin? macos =
        _fln.resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>();
    if (macos != null) {
      return (await macos.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          )) ??
          false;
    }
    // Linux has no runtime permission prompt.
    return true;
  }

  @override
  Future<void> showNow(int id, String title, String body) =>
      _fln.show(id, title, body, _details);

  @override
  Future<void> scheduleDaily(
    int id,
    String title,
    String body,
    tz.TZDateTime when,
  ) =>
      _fln.zonedSchedule(
        id,
        title,
        body,
        when,
        _details,
        // inexact = no SCHEDULE_EXACT_ALARM permission needed (a daily nudge
        // tolerates OS batching); matchDateTimeComponents.time repeats it daily at
        // the same local time. uiLocalNotificationDateInterpretation is required by
        // the flutter_local_notifications 17.x API.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

  @override
  Future<void> cancel(int id) => _fln.cancel(id);

  @override
  Future<void> cancelAll() => _fln.cancelAll();
}
