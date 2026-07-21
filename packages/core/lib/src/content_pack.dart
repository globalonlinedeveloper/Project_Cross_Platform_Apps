import 'result.dart';

/// A bundle of localized copy/config values for an app.
class ContentPack {
  const ContentPack(this.locale, this.values);

  final String locale;
  final Map<String, String> values;

  /// A safe empty default pack.
  static const ContentPack empty = ContentPack('en', <String, String>{});

  /// The value for [key], or the key itself when absent.
  String value(String key) => values[key] ?? key;
}

/// Loads [ContentPack]s for an app.
///
/// P0.3 stub: always resolves to [ContentPack.empty]. Real asset/remote
/// loading arrives with the content pipeline.
class ContentPackLoader {
  const ContentPackLoader();

  Future<Result<ContentPack>> load(String locale) async =>
      const Result<ContentPack>.ok(ContentPack.empty);
}
