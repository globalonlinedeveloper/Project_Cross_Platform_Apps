/// Simple string key–value persistence seam (prefs, feature flags, the last-good
/// [AppConfig]). Concrete impls live in the app layer — e.g. a
/// `shared_preferences` adapter — so `core` stays pure Dart (ADR 005). Method
/// names mirror `shared_preferences` (`read`/`write`/`remove`) so the app-layer
/// adapter is a thin passthrough.
abstract interface class KeyValueStore {
  /// The stored value for [key], or null when absent.
  Future<String?> read(String key);

  /// Store [value] under [key], replacing any existing value.
  Future<void> write(String key, String value);

  /// Remove [key] if present (a no-op when absent).
  Future<void> remove(String key);

  /// Whether a value is stored under [key].
  Future<bool> containsKey(String key);
}

/// Volatile, dependency-free [KeyValueStore] backed by a plain map.
///
/// Intended for tests and as a safe last-resort fallback on a platform where no
/// real store is wired yet — values DO NOT survive a restart, so never use it as
/// the production store for data that must persist.
class InMemoryKeyValueStore implements KeyValueStore {
  InMemoryKeyValueStore([Map<String, String>? seed])
      : _store = <String, String>{...?seed};

  final Map<String, String> _store;

  @override
  Future<String?> read(String key) async => _store[key];

  @override
  Future<void> write(String key, String value) async => _store[key] = value;

  @override
  Future<void> remove(String key) async => _store.remove(key);

  @override
  Future<bool> containsKey(String key) async => _store.containsKey(key);
}
