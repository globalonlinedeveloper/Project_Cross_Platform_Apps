# nikatru_notifications

Concrete, plugin-backed implementation of the `packages/core`
`NotificationService` seam (local streak / daily-goal reminders) — the
engagement chassis (CFG **G-25**). Keeps `packages/core` pure Dart by living
behind the seam, mirroring `nikatru_platform_storage` (ADR 005).

## Usage

Inject the platform-appropriate service in the app/brick layer:

```dart
import 'package:nikatru_notifications/nikatru_notifications.dart';

final NotificationService notifications = createLocalNotificationService(
  // Optional: a real device-timezone resolver (e.g. flutter_timezone) for
  // timezone-correct scheduling. Defaults to UTC.
  localTimezone: () async => 'Asia/Kolkata',
);

await notifications.init();
await notifications.requestPermission();
await notifications.scheduleDaily(
  const DailyReminder(id: 1, title: 'Keep your streak', body: 'Today\'s lesson', hour: 9, minute: 0),
);
```

## Platform support (pinned `flutter_local_notifications` 17.x)

| Platform | `showNow` | `scheduleDaily` |
|----------|:---------:|:---------------:|
| Android / iOS / macOS | ✅ | ✅ |
| Linux | ✅ | ⬜ (no `zonedSchedule` on Linux → no-op) |
| Windows | ⬜ | ⬜ (no Windows plugin until 18.x → no-op) |
| Web | ⬜ | ⬜ (no plugin → `NoOpNotificationService`) |

The matrix is tied to the pinned major (shared with `apps/subly`, which uses the
17.x API). Windows support arrived in `flutter_local_notifications` 18.x and Linux
has never implemented `zonedSchedule`; both would need re-review on a version bump.

`createLocalNotificationService` returns a `NoOpNotificationService` on web (via a
conditional import, so the package stays web-compilable). Query
`LocalNotificationService.capabilities` (or `NotificationCapabilities.forPlatform`)
to decide whether to offer a scheduling toggle or fall back to an in-app nudge.
