class Entitlement {
  const Entitlement({
    required this.entitlement,
    required this.productId,
    required this.store,
    required this.isActive,
    this.expiresAt,
  });

  final String entitlement;
  final String productId;
  final String store;
  final bool isActive;
  final DateTime? expiresAt;

  factory Entitlement.fromJson(Map<String, dynamic> j) => Entitlement(
        entitlement: (j['entitlement'] ?? '') as String,
        productId: (j['product_id'] ?? '') as String,
        store: (j['store'] ?? '') as String,
        isActive: j['is_active'] == true || j['is_active'] == 1,
        expiresAt: j['expires_at'] == null
            ? null
            : DateTime.tryParse(j['expires_at'] as String),
      );
}

/// The current user's entitlements for THIS app (from the shared platform DB).
class Entitlements {
  const Entitlements({
    required this.appId,
    required this.isPro,
    required this.items,
  });

  final String appId;
  final bool isPro;
  final List<Entitlement> items;

  factory Entitlements.fromJson(Map<String, dynamic> j) => Entitlements(
        appId: (j['app_id'] ?? '') as String,
        isPro: j['is_pro'] == true || j['is_pro'] == 1,
        items: ((j['entitlements'] as List<dynamic>?) ?? <dynamic>[])
            .map((dynamic e) => Entitlement.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  static const Entitlements none =
      Entitlements(appId: '', isPro: false, items: <Entitlement>[]);
}
