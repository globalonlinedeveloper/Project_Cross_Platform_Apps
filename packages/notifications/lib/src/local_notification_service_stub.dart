import 'package:nikatru_core/nikatru_core.dart'
    show NoOpNotificationService, NotificationService;

import 'notification_capabilities.dart';

/// Web fallback: no local-notification plugin exists for web, so callers get a
/// [NoOpNotificationService] and show an in-app catch-up nudge instead. Selected
/// by the conditional import in `local_notification_service.dart` when
/// `dart.library.io` is unavailable (i.e. web).
NotificationService createPlatformNotificationService({
  LocalTimezoneResolver? localTimezone,
}) => const NoOpNotificationService();
