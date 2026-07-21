import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../data/api/api_client.dart';
import '../data/api/dio_api_client.dart';
import '../data/api/seed_api_client.dart';
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

/// API: real Worker via Dio when configured, else the seed client (demo mode).
final Provider<ApiClient> apiClientProvider = Provider<ApiClient>((ref) =>
    AppConfig.isApiConfigured
        ? DioApiClient(
            baseUrl: '${AppConfig.apiBaseUrl}/v1',
            tokenProvider: ref.watch(authRepositoryProvider).currentAccessToken,
          )
        : SeedApiClient());

final Provider<SubscriptionRepository> subscriptionRepositoryProvider =
    Provider<SubscriptionRepository>(
        (ref) => SubscriptionRepository(ref.watch(apiClientProvider)));

final Provider<NotificationService> notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService.instance);

final Provider<PurchasesService> purchasesServiceProvider =
    Provider<PurchasesService>((ref) => PurchasesService.create());
