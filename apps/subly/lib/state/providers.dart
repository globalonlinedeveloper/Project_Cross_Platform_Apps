import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nikatru_core/nikatru_core.dart' as core;

import '../core/config/app_config.dart';
import '../data/api/api_client.dart';
import '../data/api/dio_api_client.dart';
import '../data/api/seed_api_client.dart';
import '../data/config/dio_config_transport.dart';
import '../data/auth/auth_models.dart';
import '../data/auth/auth_repository.dart';
import '../data/auth/mock_auth_repository.dart';
import '../data/auth/supabase_auth_repository.dart';
import '../data/subscriptions/subscription_repository.dart';
import '../services/notifications/notification_service.dart';
import '../services/purchases/purchases_service.dart';

/// Auth: real Supabase when configured, else the in-memory mock (demo mode).
final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>((ref) => AppConfig.isSupabaseConfigured
        ? SupabaseAuthRepository()
        : MockAuthRepository());

/// Reactive auth stream (drives sign-in UI; router uses its own refresh bridge).
final StreamProvider<AuthUser?> authStateProvider =
    StreamProvider<AuthUser?>((ref) =>
        ref.watch(authRepositoryProvider).authStateChanges());

/// CFG-1 transport: dio `GET {configBaseUrl}/config/<app>`.
final Provider<core.ConfigTransport> configTransportProvider =
    Provider<core.ConfigTransport>(
        (ref) => DioConfigTransport(configBaseUrl: AppConfig.configBaseUrl));

/// CFG-1 loader: network -> last-good cache -> compiled-in bundled default.
final Provider<core.ConfigLoader> configLoaderProvider =
    Provider<core.ConfigLoader>((ref) =>
        core.ConfigLoader(transport: ref.watch(configTransportProvider)));

/// Runtime config for this app, resolved at launch. Offline-safe: the loader
/// falls back to the compiled-in default, so this resolves even with no network.
/// Demo/test builds (no backend configured) skip the network entirely and use
/// the bundled default, keeping widget tests hermetic.
final FutureProvider<core.AppConfig> appConfigProvider =
    FutureProvider<core.AppConfig>((ref) async {
  final core.ConfigLoader loader = ref.watch(configLoaderProvider);
  if (!AppConfig.isApiConfigured) {
    return loader.peek(AppConfig.appId) ??
        (throw StateError('no config for ${AppConfig.appId}'));
  }
  final core.Result<core.AppConfig> r = await loader.load(AppConfig.appId);
  return r.fold(
    (core.AppConfig c) => c,
    (core.Failure f) =>
        loader.peek(AppConfig.appId) ??
        (throw StateError('no config for ${AppConfig.appId}')),
  );
});

/// API: real Worker via Dio when configured, else the seed client (demo mode).
/// The Dio base URL comes from the CFG-1 `api_base_url` (runtime, swappable with
/// no store release), falling back to the compile-time define until it resolves.
final Provider<ApiClient> apiClientProvider = Provider<ApiClient>((ref) {
  if (!AppConfig.isApiConfigured) return SeedApiClient();
  final core.AppConfig? cfg = ref.watch(appConfigProvider).valueOrNull;
  final String baseUrl = cfg?.apiBaseUrl ?? '${AppConfig.apiBaseUrl}/v1';
  return DioApiClient(
    baseUrl: baseUrl,
    tokenProvider: ref.watch(authRepositoryProvider).currentAccessToken,
  );
});

final Provider<SubscriptionRepository> subscriptionRepositoryProvider =
    Provider<SubscriptionRepository>(
        (ref) => SubscriptionRepository(ref.watch(apiClientProvider)));

final Provider<NotificationService> notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService.instance);

final Provider<PurchasesService> purchasesServiceProvider =
    Provider<PurchasesService>((ref) => PurchasesService.create());
