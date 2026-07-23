import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nikatru_core/nikatru_core.dart';

/// [SecureStore] backed by `flutter_secure_storage` — the OS-backed secret store
/// (Keychain/Keystore/DPAPI on iOS/Android/macOS/Windows, libsecret on Linux, a
/// WebCrypto store on web). For auth tokens and the entitlement cache.
///
/// ADR 005 fallback: on a platform/version where the OS keystore is unavailable
/// (a Linux box without libsecret, some web contexts) `flutter_secure_storage`
/// can throw. Callers that must degrade gracefully wrap this behind a fallback
/// `SecureStore` (e.g. an encrypted key-value store) via the same seam — the
/// entitlement cache already treats a read failure as "nothing cached", so a
/// missing keystore never crashes the app, it just drops offline persistence.
class FlutterSecureStore implements SecureStore {
  FlutterSecureStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<void> deleteAll() => _storage.deleteAll();
}
