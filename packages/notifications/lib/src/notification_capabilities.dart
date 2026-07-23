import 'package:flutter/foundation.dart' show TargetPlatform, immutable;

/// Resolves the device's IANA timezone name (e.g. `Asia/Kolkata`) for
/// timezone-correct daily scheduling.
///
/// The app/brick layer injects a real resolver (e.g. backed by `flutter_timezone`);
/// the package default returns `UTC` so scheduling stays portable and dependency
/// -light, but daily reminders fire at the injected zone's local time only once a
/// real resolver is supplied — mirroring the "concrete plugin lives at the edge"
/// seam philosophy (ConfigTransport / PackVerifier).
typedef LocalTimezoneResolver = Future<String> Function();

/// What a platform can do with local notifications — the portability seam that
/// drives every runtime guard in the notification adapter.
///
/// The matrix is tied to the **pinned `flutter_local_notifications` 17.x** (shared
/// with apps/subly); re-review it on any version bump:
/// - **Android / iOS / macOS** — immediate display + repeating daily schedule.
/// - **Linux** — shows immediately, but `zonedSchedule` is unimplemented (the
///   Linux backend can't schedule, in 17.x–19.x alike) → show yes, schedule no.
/// - **Windows** — 17.x has **no Windows plugin** (support landed in 18.x), so it
///   can neither show nor schedule → both no-op. Revisit if the workspace moves
///   to 18.x+ and wires `WindowsInitializationSettings`.
/// - **Web / Fuchsia** — neither.
///
/// Unsupported operations no-op and callers fall back to an in-app catch-up nudge.
@immutable
class NotificationCapabilities {
  const NotificationCapabilities({
    required this.canNotify,
    required this.canSchedule,
  });

  /// Whether immediate notifications (`showNow`) work on this platform.
  final bool canNotify;

  /// Whether repeating daily schedules (`scheduleDaily`) work on this platform.
  final bool canSchedule;

  /// The capabilities for [platform] (with [isWeb] taking precedence — a web
  /// build reports its host [TargetPlatform] but has no notification plugin).
  static NotificationCapabilities forPlatform(
    TargetPlatform platform, {
    required bool isWeb,
  }) {
    if (isWeb) {
      return const NotificationCapabilities(
        canNotify: false,
        canSchedule: false,
      );
    }
    switch (platform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        // Full support: immediate display + repeating daily zonedSchedule.
        return const NotificationCapabilities(
          canNotify: true,
          canSchedule: true,
        );
      case TargetPlatform.linux:
        // flutter_local_notifications shows immediately on Linux but has NO
        // zonedSchedule implementation (throws UnimplementedError) — true in
        // 17.x through 19.x. Show yes, repeat-schedule no.
        return const NotificationCapabilities(
          canNotify: true,
          canSchedule: false,
        );
      case TargetPlatform.windows:
        // The pinned flutter_local_notifications 17.x has NO Windows plugin
        // (Windows support arrived in 18.x); calling show/cancel there throws.
        // Treat Windows as fully unsupported until the workspace bumps to 18.x+.
        return const NotificationCapabilities(
          canNotify: false,
          canSchedule: false,
        );
      case TargetPlatform.fuchsia:
        return const NotificationCapabilities(
          canNotify: false,
          canSchedule: false,
        );
    }
  }

  @override
  String toString() =>
      'NotificationCapabilities(canNotify: $canNotify, canSchedule: $canSchedule)';
}
