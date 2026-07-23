/// Local-notification seam (CFG G-25 / engagement chassis). Streak and
/// daily-goal reminders are the retention engine for content apps. The concrete
/// impl (`flutter_local_notifications` + timezone) lives in the app/adapter
/// layer so `core` stays pure Dart — mirroring the storage seams (ADR 005).
library;

/// A recurring daily reminder to schedule (a streak/goal nudge at [hour]:[minute]
/// local time). [id] is stable so the same reminder can be updated or cancelled.
class DailyReminder {
  const DailyReminder({
    required this.id,
    required this.title,
    required this.body,
    required this.hour,
    required this.minute,
  });

  final int id;
  final String title;
  final String body;

  /// 0–23 local hour.
  final int hour;

  /// 0–59 minute.
  final int minute;
}

/// Seam for local notifications. Impls schedule via the OS, and **not every
/// platform supports every operation** — the concrete impl reports its own
/// capability matrix and no-ops what it can't do so a caller never crashes (e.g.
/// the `flutter_local_notifications` adapter can't schedule on Web/Windows/Linux,
/// nor even show on Web/Windows). Callers fall back to an in-app catch-up nudge
/// where an operation no-ops; the [NoOpNotificationService] covers the rest.
abstract interface class NotificationService {
  /// One-time setup (timezone db, platform channels). Safe to call more than once.
  Future<void> init();

  /// Ask the user for notification permission; returns whether it was granted.
  Future<bool> requestPermission();

  /// Show a notification immediately (works on all platforms).
  Future<void> showNow({required String title, required String body});

  /// Schedule [reminder] to fire daily at its local time. No-op where the impl's
  /// backend can't schedule (e.g. Web/Windows/Linux with flutter_local_notifications).
  Future<void> scheduleDaily(DailyReminder reminder);

  /// Cancel a scheduled notification by id.
  Future<void> cancel(int id);

  /// Cancel every scheduled notification.
  Future<void> cancelAll();
}

/// A do-nothing [NotificationService] — the safe default before a real impl is
/// injected, and the fallback on platforms without local-notification support.
/// Never throws.
class NoOpNotificationService implements NotificationService {
  const NoOpNotificationService();

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> showNow({required String title, required String body}) async {}

  @override
  Future<void> scheduleDaily(DailyReminder reminder) async {}

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> cancelAll() async {}
}
