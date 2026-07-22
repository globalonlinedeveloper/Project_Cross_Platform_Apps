/// Secure secret / token persistence seam (auth tokens, the entitlement cache).
///
/// Concrete impls live in the app layer — e.g. a `flutter_secure_storage`
/// adapter backed by the OS Keychain/Keystore/DPAPI, with a documented encrypted
/// fallback on platforms/versions where the OS keystore is absent (Linux/some
/// web) — so `core` stays pure Dart (ADR 005). Method names mirror
/// `flutter_secure_storage` (`read`/`write`/`delete`/`deleteAll`) so the
/// app-layer adapter is a thin passthrough.
abstract interface class SecureStore {
  /// The stored value for [key], or null when absent.
  Future<String?> read(String key);

  /// Securely store [value] under [key], replacing any existing value.
  Future<void> write(String key, String value);

  /// Delete [key] if present (a no-op when absent).
  Future<void> delete(String key);

  /// Delete every value this store holds (e.g. on sign-out).
  Future<void> deleteAll();
}

/// Volatile, dependency-free [SecureStore] backed by a plain map.
///
/// Intended for tests and as a safe last-resort fallback BEFORE a real secure
/// store is wired. It provides NO encryption or OS-backed protection and values
/// do not survive a restart — never use it to persist real secrets in
/// production.
class InMemorySecureStore implements SecureStore {
  InMemorySecureStore([Map<String, String>? seed])
      : _store = <String, String>{...?seed};

  final Map<String, String> _store;

  @override
  Future<String?> read(String key) async => _store[key];

  @override
  Future<void> write(String key, String value) async => _store[key] = value;

  @override
  Future<void> delete(String key) async => _store.remove(key);

  @override
  Future<void> deleteAll() async => _store.clear();
}
