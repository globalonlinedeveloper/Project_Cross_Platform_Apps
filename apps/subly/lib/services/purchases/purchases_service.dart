import 'package:flutter/foundation.dart';

/// A purchasable plan surfaced to the paywall.
class PurchaseOption {
  const PurchaseOption({
    required this.productId,
    required this.title,
    required this.priceString,
    required this.period,
  });
  final String productId;
  final String title;
  final String priceString;
  final String period;
}

class PurchaseResult {
  const PurchaseResult({required this.success, this.isPro = false, this.message});
  final bool success;
  final bool isPro;
  final String? message;
}

/// Payments seam. The real implementation wraps RevenueCat's `purchases_flutter`;
/// entitlement state is the source of truth on the SERVER — RevenueCat's webhook
/// writes the shared `(user_id, app_id)` entitlements table, and the app reads it
/// via `ApiClient.getEntitlements()`. The client never grants Pro on its own.
abstract class PurchasesService {
  /// Swap this redirect to `RevenueCatPurchasesService` once the SDK is wired.
  factory PurchasesService.create() = StubPurchasesService;

  Future<void> init({String? appUserId});
  Future<List<PurchaseOption>> offerings();
  Future<PurchaseResult> purchase(String productId);
  Future<bool> restore();
}

/// No-op stub so the app builds and the paywall renders with no native config.
class StubPurchasesService implements PurchasesService {
  @override
  Future<void> init({String? appUserId}) async {
    debugPrint('[purchases] stub init (RevenueCat not wired) user=$appUserId');
  }

  @override
  Future<List<PurchaseOption>> offerings() async => const <PurchaseOption>[
        PurchaseOption(
          productId: 'subly_pro_monthly',
          title: 'Subly Pro',
          priceString: r'$2.99',
          period: 'month',
        ),
        PurchaseOption(
          productId: 'subly_pro_yearly',
          title: 'Subly Pro',
          priceString: r'$24.99',
          period: 'year',
        ),
      ];

  @override
  Future<PurchaseResult> purchase(String productId) async {
    debugPrint('[purchases] stub purchase $productId — wire RevenueCat to enable');
    return const PurchaseResult(
      success: false,
      message: 'Purchases are not enabled in this build.',
    );
  }

  @override
  Future<bool> restore() async => false;
}

// ── To wire RevenueCat for real ──────────────────────────────────────────────
// 1. Add `purchases_flutter` to pubspec.
// 2. Implement RevenueCatPurchasesService with Purchases.configure(apiKey,
//    appUserID: <supabase user id>), Purchases.getOfferings(), purchasePackage(),
//    restorePurchases().
// 3. Point PurchasesService.create() at it.
// 4. Configure the RevenueCat → Worker webhook (POST /v1/webhooks/revenuecat)
//    so entitlements land in the shared platform DB, keyed by (user_id, app_id).
