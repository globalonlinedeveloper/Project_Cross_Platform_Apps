import 'app_config.dart';

/// Compiled-in fallback configs, one per known app, so an app works offline if
/// the config host is unreachable.
///
/// MIRRORS the server's authoritative defaults in
/// `services/platform/src/config.ts` `DEFAULT_CONFIGS` — keep the two in
/// lockstep. The CFG-1 contract test pins the `subly` values so drift fails CI.
const Map<String, AppConfig> kDefaultConfigs = <String, AppConfig>{
  'subly': AppConfig(
    appId: 'subly',
    apiBaseUrl: 'https://api.nikatru.com/v1',
    features: <String, bool>{
      'renewals': true,
      'budgets': true,
      'exports': true,
    },
    paywall: PaywallConfig(enabled: false),
    contentPack: null,
    copy: <String, String>{},
    minSupportedVersion: '1.0.0',
  ),
};

/// The compiled-in fallback for [appId], or null if the app is unregistered.
AppConfig? defaultConfigFor(String appId) => kDefaultConfigs[appId];
