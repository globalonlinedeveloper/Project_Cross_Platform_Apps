/// Typed runtime configuration for an app (CFG-1).
///
/// Mirrors the server contract served by `services/platform`
/// `GET /config/<app>` (see `services/platform/src/types.ts` `AppConfig` and
/// `src/config.ts` `DEFAULT_CONFIGS`). DATA/flags only — never UI. JSON is
/// snake_case to match the Worker response and the committed `defaults.json`.
library;

/// Paywall sub-config. [enabled] is the known flag; [extra] preserves any other
/// paywall keys the server sends so the client stays forward-compatible.
class PaywallConfig {
  const PaywallConfig({
    required this.enabled,
    this.extra = const <String, Object?>{},
  });

  final bool enabled;
  final Map<String, Object?> extra;

  factory PaywallConfig.fromJson(Map<String, Object?> json) {
    final Map<String, Object?> rest = <String, Object?>{...json}
      ..remove('enabled');
    return PaywallConfig(enabled: json['enabled'] == true, extra: rest);
  }

  Map<String, Object?> toJson() =>
      <String, Object?>{'enabled': enabled, ...extra};
}

/// Resolved runtime config for an app.
class AppConfig {
  const AppConfig({
    required this.appId,
    required this.apiBaseUrl,
    required this.features,
    required this.paywall,
    required this.contentPack,
    required this.copy,
    required this.minSupportedVersion,
    this.theme,
  });

  final String appId;
  final String apiBaseUrl;
  final Map<String, bool> features;
  final PaywallConfig paywall;
  final String? contentPack;
  final Map<String, String> copy;
  final String minSupportedVersion;
  final Map<String, Object?>? theme;

  /// Whether feature [key] is enabled ([orElse] when the key is absent).
  bool feature(String key, {bool orElse = false}) => features[key] ?? orElse;

  /// Override copy for [key], or [key] itself when absent.
  String text(String key) => copy[key] ?? key;

  /// Parse the Worker / `defaults.json` JSON shape.
  ///
  /// Throws [FormatException] when a required key (`app_id`, `api_base_url`,
  /// `min_supported_version`) is missing or the wrong type — callers fall back
  /// to bundled defaults, mirroring the server's "malformed ⇒ defaults" rule.
  factory AppConfig.fromJson(Map<String, Object?> json) {
    final Object? appId = json['app_id'];
    final Object? apiBaseUrl = json['api_base_url'];
    final Object? minVer = json['min_supported_version'];
    if (appId is! String || appId.isEmpty) {
      throw const FormatException('AppConfig: missing or invalid app_id');
    }
    if (apiBaseUrl is! String || apiBaseUrl.isEmpty) {
      throw const FormatException('AppConfig: missing or invalid api_base_url');
    }
    if (minVer is! String || minVer.isEmpty) {
      throw const FormatException(
          'AppConfig: missing or invalid min_supported_version');
    }
    return AppConfig(
      appId: appId,
      apiBaseUrl: apiBaseUrl,
      features: _boolMap(json['features']),
      paywall: PaywallConfig.fromJson(_asMap(json['paywall'])),
      // Non-required: coerce a wrong-typed value to null rather than throwing a
      // TypeError (only the three keys above are strict). Keeps a corrupt cached
      // or drifted server body from crashing load()/hydrate().
      contentPack: json['content_pack'] is String
          ? json['content_pack'] as String
          : null,
      copy: _stringMap(json['copy']),
      minSupportedVersion: minVer,
      theme: json['theme'] == null ? null : _asMap(json['theme']),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'app_id': appId,
        'api_base_url': apiBaseUrl,
        'features': features,
        'paywall': paywall.toJson(),
        'content_pack': contentPack,
        'copy': copy,
        'min_supported_version': minSupportedVersion,
        if (theme != null) 'theme': theme,
      };

  AppConfig copyWith({
    String? appId,
    String? apiBaseUrl,
    Map<String, bool>? features,
    PaywallConfig? paywall,
    String? contentPack,
    Map<String, String>? copy,
    String? minSupportedVersion,
    Map<String, Object?>? theme,
  }) =>
      AppConfig(
        appId: appId ?? this.appId,
        apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
        features: features ?? this.features,
        paywall: paywall ?? this.paywall,
        contentPack: contentPack ?? this.contentPack,
        copy: copy ?? this.copy,
        minSupportedVersion: minSupportedVersion ?? this.minSupportedVersion,
        theme: theme ?? this.theme,
      );

  @override
  String toString() => 'AppConfig($appId, api=$apiBaseUrl)';
}

Map<String, bool> _boolMap(Object? v) {
  if (v is! Map) return <String, bool>{};
  final Map<String, bool> out = <String, bool>{};
  v.forEach((Object? k, Object? val) {
    if (val is bool) out['$k'] = val;
  });
  return out;
}

Map<String, String> _stringMap(Object? v) {
  if (v is! Map) return <String, String>{};
  final Map<String, String> out = <String, String>{};
  v.forEach((Object? k, Object? val) {
    out['$k'] = '${val ?? ''}';
  });
  return out;
}

Map<String, Object?> _asMap(Object? v) => v is Map
    ? v.map((Object? k, Object? val) => MapEntry<String, Object?>('$k', val))
    : <String, Object?>{};
