import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Deterministic percentage-rollout flag evaluation (CFG G-14). A flag is "on"
/// for a device when the device lands in the rolled-out bucket — stable across
/// launches (same device + flag always lands in the same bucket), so a rollout
/// can ramp 0 → 100 with no client release. The server sends
/// `flags: {name: percent}` in the app config.
///
/// Bucketing: sha256("flag:stableId") → a 0..99 bucket; on when the bucket is
/// below [rolloutPercent]. So the on-set only ever GROWS as the percent rises
/// (monotonic — a device on at 30% is still on at 60%, never flipped off). A
/// percent ≤ 0 is off for everyone, ≥ 100 is on for everyone.
bool resolveFlag({
  required String flag,
  required int rolloutPercent,
  required String stableId,
}) {
  if (rolloutPercent <= 0) return false;
  if (rolloutPercent >= 100) return true;
  return flagBucket(flag: flag, stableId: stableId) < rolloutPercent;
}

/// The stable 0..99 rollout bucket for [flag] × [stableId]. Exposed for testing
/// and for callers that want the raw bucket (e.g. staged tiers).
int flagBucket({required String flag, required String stableId}) {
  final List<int> h = sha256.convert(utf8.encode('$flag:$stableId')).bytes;
  final int v = ((h[0] << 24) | (h[1] << 16) | (h[2] << 8) | h[3]) & 0x7fffffff;
  return v % 100;
}

/// Binds a per-app rollout map (`flag → percent`, e.g. `AppConfig.flags`) to a
/// stable device/install id, so callers ask `isOn('newHome')` without threading
/// the id and percentage through every call site.
class FeatureFlags {
  const FeatureFlags({required this.rollouts, required this.stableId});

  /// Flag → rollout percentage (0..100).
  final Map<String, int> rollouts;

  /// A stable per-device/install id — the same value across launches so a
  /// device's rollout decision never changes underfoot.
  final String stableId;

  /// Whether [flag] is rolled out to this device (an absent flag ⇒ off).
  bool isOn(String flag) => resolveFlag(
        flag: flag,
        rolloutPercent: rollouts[flag] ?? 0,
        stableId: stableId,
      );
}
