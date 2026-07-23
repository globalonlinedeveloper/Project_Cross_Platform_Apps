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

  /// Snake_case JSON that round-trips through [Entitlement.fromJson] — used to
  /// persist the entitlement cache (so a paid user stays unlocked offline).
  Map<String, dynamic> toJson() => <String, dynamic>{
        'entitlement': entitlement,
        'product_id': productId,
        'store': store,
        'is_active': isActive,
        // Normalize to UTC so a local DateTime round-trips to the same instant
        // regardless of any device-timezone change between write and read.
        'expires_at': expiresAt?.toUtc().toIso8601String(),
      };

  /// Whether this entitlement should still be honoured offline at [now], given a
  /// [grace] window after expiry. A lifetime entitlement (no [expiresAt]) never
  /// expires; a subscription is honoured until expiry + [grace], after which the
  /// server must reconcile on reconnect (ADR 005).
  bool isValidAt(DateTime now, {Duration grace = Duration.zero}) {
    if (!isActive) return false;
    final DateTime? exp = expiresAt;
    return exp == null || now.isBefore(exp.add(grace));
  }
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

  /// Snake_case JSON that round-trips through [Entitlements.fromJson] — the
  /// serialized shape the entitlement cache persists to a [SecureStore].
  Map<String, dynamic> toJson() => <String, dynamic>{
        'app_id': appId,
        'is_pro': isPro,
        'entitlements': items.map((Entitlement e) => e.toJson()).toList(),
      };

  /// Whether the user should be treated as Pro at [now] offline: the server said
  /// Pro AND either there are no dated line items (a lifetime grant) or at least
  /// one item is still valid within [grace]. Lifetime grants stay Pro forever
  /// offline; expired subscriptions drop to not-Pro past the grace window (ADR 005).
  bool isProAt(DateTime now, {Duration grace = Duration.zero}) =>
      isPro &&
      (items.isEmpty ||
          items.any((Entitlement e) => e.isValidAt(now, grace: grace)));

  static const Entitlements none =
      Entitlements(appId: '', isPro: false, items: <Entitlement>[]);
}
