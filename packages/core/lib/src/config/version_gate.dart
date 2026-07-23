/// Force-update kill-switch (CFG G-14). Compares a running app version against
/// the config's `min_supported_version`, so the server can force clients below a
/// floor to update — a config-only change, zero store review.
library;

/// Whether [current] meets or exceeds [minSupported]. Both are dot-separated
/// version strings (e.g. "1.2.0"); a build suffix (`+N`) and pre-release tag
/// (`-beta`) are ignored, missing/short/non-numeric segments count as 0. A blank
/// [minSupported] means "no floor" → always supported (fail-open, so a missing
/// config value can never brick a client).
bool meetsMinVersion(String current, String minSupported) {
  if (minSupported.trim().isEmpty) return true;
  // Symmetric fail-open: an empty/unreadable client version must not brick the
  // client behind the update wall (same posture as a blank floor).
  if (current.trim().isEmpty) return true;
  final List<int> a = _parse(current);
  final List<int> b = _parse(minSupported);
  final int n = a.length > b.length ? a.length : b.length;
  for (int i = 0; i < n; i++) {
    final int x = i < a.length ? a[i] : 0;
    final int y = i < b.length ? b[i] : 0;
    if (x != y) return x > y;
  }
  return true; // equal versions meet the floor
}

/// The complement of [meetsMinVersion] — true when the client MUST update.
bool mustForceUpdate(String current, String minSupported) =>
    !meetsMinVersion(current, minSupported);

List<int> _parse(String v) {
  String core = v.split('+').first.split('-').first.trim();
  if (core.startsWith('v') || core.startsWith('V')) core = core.substring(1);
  if (core.isEmpty) return const <int>[0];
  return core
      .split('.')
      .map((String s) => int.tryParse(s.trim()) ?? 0)
      .toList();
}
