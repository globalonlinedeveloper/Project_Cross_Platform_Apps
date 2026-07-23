import 'dart:convert';

import 'models/entitlement.dart';
import 'storage/secure_store.dart';

/// Persists the user's last-known [Entitlements] to a [SecureStore] so a paid
/// user stays unlocked across restarts and offline.
///
/// A lifetime entitlement (no `expires_at`) is always honoured offline; a
/// subscription is honoured until `expires_at` + [grace], after which the client
/// falls back to not-Pro until the server reconciles on reconnect (ADR 005). The
/// server is always the source of truth; this cache is the offline stand-in.
class EntitlementCache {
  EntitlementCache({
    required SecureStore store,
    String key = 'nikatru.entitlements',
    Duration grace = const Duration(days: 3),
  })  : _store = store,
        _key = key,
        _grace = grace;

  final SecureStore _store;
  final String _key;
  final Duration _grace;

  /// The offline grace window applied after a subscription's `expires_at`.
  Duration get grace => _grace;

  /// Persist [entitlements] as the new last-known value (call after a successful
  /// server fetch).
  Future<void> save(Entitlements entitlements) =>
      _store.write(_key, jsonEncode(entitlements.toJson()));

  /// Drop the cached entitlements (e.g. on sign-out).
  Future<void> clear() => _store.delete(_key);

  /// The raw cached entitlements exactly as last saved, or null when nothing is
  /// cached or the cached value is unreadable/corrupt (a corrupt cache can never
  /// take the app down — it is treated as absent).
  Future<Entitlements?> readRaw() async {
    final String? raw = await _store.read(_key);
    if (raw == null) return null;
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is Map) {
        return Entitlements.fromJson(decoded.cast<String, dynamic>());
      }
    } catch (_) {
      // Malformed/tampered cache — fall through and report nothing cached.
    }
    return null;
  }

  /// The offline entitlement decision at [now] (defaults to the current time):
  /// the cached entitlements when still Pro-valid within [grace], otherwise the
  /// same appId downgraded to not-Pro. Returns [Entitlements.none] when nothing
  /// is cached. The gate should still refresh from the server when online.
  Future<Entitlements> readValid({DateTime? now}) async {
    final Entitlements? cached = await readRaw();
    if (cached == null) return Entitlements.none;
    final DateTime at = now ?? DateTime.now();
    if (cached.isProAt(at, grace: _grace)) return cached;
    return Entitlements(
      appId: cached.appId,
      isPro: false,
      items: const <Entitlement>[],
    );
  }
}
