import 'package:nikatru_core/nikatru_core.dart' show NotificationService;

import 'notification_capabilities.dart';
// The real impl imports `flutter_local_notifications`, which has no web support
// (it pulls `dart:ui`/`dart:io`). Conditional import keeps `nikatru_notifications`
// web-compilable: native builds get the plugin-backed service; web gets a stub
// that returns `NoOpNotificationService`.
import 'local_notification_service_stub.dart'
    if (dart.library.io) 'local_notification_service_io.dart';

/// Creates the platform-appropriate [NotificationService] (pinned
/// `flutter_local_notifications` 17.x — see [NotificationCapabilities]).
///
/// - Android / iOS / macOS → immediate display + daily `zonedSchedule`.
/// - Linux → shows immediately; `scheduleDaily` no-ops (no Linux zonedSchedule).
/// - Windows → both no-op on 17.x (no Windows plugin until 18.x).
/// - Web → a `NoOpNotificationService` (no plugin; show an in-app nudge instead).
///
/// Unsupported operations degrade to a safe no-op. Inject [localTimezone] (e.g.
/// via `flutter_timezone`) for timezone-correct scheduling; it defaults to `UTC`.
NotificationService createLocalNotificationService({
  LocalTimezoneResolver? localTimezone,
}) =>
    createPlatformNotificationService(localTimezone: localTimezone);
