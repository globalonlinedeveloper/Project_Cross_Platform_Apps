import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../data/models/subscription.dart';

/// On-device renewal reminders — the cross-platform reminder path (iOS, Android,
/// macOS, Linux, Windows). No server push, so it also covers the desktop targets
/// where FCM has no official support. Web falls back to a no-op (use the
/// service-worker Notification API there if needed).
///
/// NOTE: `flutter_local_notifications` is the most version-sensitive dependency
/// in this template. The calls below target the 17.x API. If `flutter pub get`
/// resolves a newer major, re-check `zonedSchedule` (androidScheduleMode /
/// uiLocalNotificationDateInterpretation) and the Windows init settings.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const String _channelId = 'renewals';
  static const String _channelName = 'Renewal reminders';

  Future<void> init() async {
    if (kIsWeb) return; // plugin has no web implementation
    tzdata.initializeTimeZones();
    // For exact local-time scheduling, add `flutter_timezone` and call
    // tz.setLocalLocation(tz.getLocation(await FlutterTimezone.getLocalTimezone()));
    // Defaults to UTC otherwise.

    const InitializationSettings settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
      linux: LinuxInitializationSettings(defaultActionName: 'Open'),
      // Windows: add WindowsInitializationSettings(appName, appUserModelId, guid)
      // once you have an AppUserModelID; omitted here to stay version-safe.
    );

    await _plugin.initialize(settings);
    await _requestPermissions();
    _ready = true;
  }

  Future<void> _requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Alerts a couple of days before a charge',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
        linux: LinuxNotificationDetails(),
      );

  /// Schedules a one-off reminder [daysBefore] the renewal, at 09:00 local.
  /// (Windows can't do *repeating* notifications, but one-off per-renewal
  /// reminders like this work everywhere.)
  Future<void> scheduleRenewalReminder(Subscription sub,
      {int daysBefore = 2}) async {
    if (!_ready) return;
    final DateTime target =
        sub.nextRenewal.subtract(Duration(days: daysBefore));
    final tz.TZDateTime when =
        tz.TZDateTime(tz.local, target.year, target.month, target.day, 9);
    if (when.isBefore(tz.TZDateTime.now(tz.local))) return; // don't fire in past

    await _plugin.zonedSchedule(
      _idFor(sub.id),
      'Renewal coming up',
      '${sub.name} renews on ${_pretty(sub.nextRenewal)}.',
      when,
      _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelForSubscription(String id) async {
    if (!_ready) return;
    await _plugin.cancel(_idFor(id));
  }

  Future<void> cancelAll() async {
    if (!_ready) return;
    await _plugin.cancelAll();
  }

  /// Rebuilds the full reminder set (call after edits, or on app resume).
  Future<void> syncAll(List<Subscription> subs, {int daysBefore = 2}) async {
    if (!_ready) return;
    await cancelAll();
    for (final Subscription s in subs) {
      await scheduleRenewalReminder(s, daysBefore: daysBefore);
    }
  }

  int _idFor(String id) => id.hashCode & 0x7fffffff;

  String _pretty(DateTime d) {
    const List<String> m = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${m[d.month - 1]} ${d.day}';
  }
}
