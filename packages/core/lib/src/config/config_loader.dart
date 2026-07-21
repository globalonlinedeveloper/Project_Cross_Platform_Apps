import '../result.dart';
import 'app_config.dart';
import 'default_configs.dart';

/// Seam for fetching raw config JSON for an app. Implementations live in the
/// app layer (e.g. a dio-based transport in Subly) so `core` stays pure Dart.
abstract interface class ConfigTransport {
  /// Fetch the raw config document for [appId]. Returns [Ok] with the decoded
  /// JSON map on a 2xx response, or [Err] on any network / HTTP / parse failure
  /// (an unknown app 404s ⇒ [Err], and the loader then falls back to defaults).
  Future<Result<Map<String, Object?>>> fetch(String appId);
}

/// In-memory best-known config per app, seeded from the compiled-in defaults.
/// A successful fetch updates the entry; reads fall back to the bundled default.
class ConfigCache {
  ConfigCache({Map<String, AppConfig>? seed})
      : _store = <String, AppConfig>{...?seed};

  final Map<String, AppConfig> _store;

  /// Best-known config for [appId]: last successful fetch, else the compiled-in
  /// default, else null for an unregistered app.
  AppConfig? get(String appId) => _store[appId] ?? defaultConfigFor(appId);

  /// Record a freshly fetched config as the new last-good value.
  void put(AppConfig config) => _store[config.appId] = config;
}

/// Loads runtime config for an app: network first, then the last-good cache,
/// then the compiled-in bundled default — so a known app is ALWAYS offline-safe.
class ConfigLoader {
  ConfigLoader({required ConfigTransport transport, ConfigCache? cache})
      : _transport = transport,
        _cache = cache ?? ConfigCache();

  final ConfigTransport _transport;
  final ConfigCache _cache;

  /// Best-known config WITHOUT a network call (last-good or bundled default).
  AppConfig? peek(String appId) => _cache.get(appId);

  /// Resolve config for [appId]. Never fails for a known app: a network or
  /// parse failure falls back to the last-good cache, then the bundled default.
  /// Returns [Err] only for an unknown app with no default and no cached value.
  Future<Result<AppConfig>> load(String appId) async {
    final Result<Map<String, Object?>> fetched = await _transport.fetch(appId);
    return fetched.fold(
      (Map<String, Object?> json) {
        try {
          final AppConfig config = AppConfig.fromJson(json);
          _cache.put(config);
          return Result<AppConfig>.ok(config);
        } on FormatException catch (e) {
          return _fallback(
              appId, Failure('malformed config for "$appId"', cause: e));
        }
      },
      (Failure failure) => _fallback(appId, failure),
    );
  }

  Result<AppConfig> _fallback(String appId, Failure failure) {
    final AppConfig? best = _cache.get(appId);
    if (best != null) return Result<AppConfig>.ok(best);
    return Result<AppConfig>.err(failure);
  }
}
