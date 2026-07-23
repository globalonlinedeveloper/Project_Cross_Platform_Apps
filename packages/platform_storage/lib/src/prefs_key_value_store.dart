import 'package:nikatru_core/nikatru_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [KeyValueStore] backed by `shared_preferences` — non-secret persistence
/// (prefs, feature-flag install id, last-good [AppConfig]) on all six platforms.
///
/// For SECRETS/tokens use a `SecureStore` implementation instead — this store is
/// not encrypted.
class PrefsKeyValueStore implements KeyValueStore {
  PrefsKeyValueStore(this._prefs);

  /// Build from the platform's default `SharedPreferences` instance.
  static Future<PrefsKeyValueStore> create() async =>
      PrefsKeyValueStore(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  @override
  Future<String?> read(String key) async => _prefs.getString(key);

  @override
  Future<void> write(String key, String value) => _prefs.setString(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);

  @override
  Future<bool> containsKey(String key) async => _prefs.containsKey(key);
}
