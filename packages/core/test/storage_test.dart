import 'package:nikatru_core/nikatru_core.dart';
import 'package:test/test.dart';

void main() {
  group('InMemoryKeyValueStore', () {
    test('write then read round-trips, containsKey + remove behave', () async {
      final KeyValueStore kv = InMemoryKeyValueStore();
      expect(await kv.read('k'), isNull);
      expect(await kv.containsKey('k'), isFalse);

      await kv.write('k', 'v');
      expect(await kv.read('k'), 'v');
      expect(await kv.containsKey('k'), isTrue);

      await kv.write('k', 'v2'); // overwrite
      expect(await kv.read('k'), 'v2');

      await kv.remove('k');
      expect(await kv.read('k'), isNull);
      expect(await kv.containsKey('k'), isFalse);
      // remove of an absent key is a no-op.
      await kv.remove('k');
    });

    test('seed pre-populates the store', () async {
      final KeyValueStore kv =
          InMemoryKeyValueStore(<String, String>{'a': '1'});
      expect(await kv.read('a'), '1');
    });
  });

  group('InMemorySecureStore', () {
    test('write/read/delete round-trip and deleteAll clears everything',
        () async {
      final SecureStore s = InMemorySecureStore();
      await s.write('token', 'abc');
      await s.write('refresh', 'xyz');
      expect(await s.read('token'), 'abc');

      await s.delete('token');
      expect(await s.read('token'), isNull);
      expect(await s.read('refresh'), 'xyz');

      await s.deleteAll();
      expect(await s.read('refresh'), isNull);
    });
  });

  group('Entitlement(s) JSON round-trip (entitlement-cache persistence)', () {
    test('Entitlement round-trips with and without expires_at', () {
      final Entitlement lifetime = Entitlement.fromJson(<String, dynamic>{
        'entitlement': 'pro',
        'product_id': 'subly_pro',
        'store': 'paddle',
        'is_active': true,
      });
      final Entitlement back = Entitlement.fromJson(lifetime.toJson());
      expect(back.entitlement, 'pro');
      expect(back.productId, 'subly_pro');
      expect(back.store, 'paddle');
      expect(back.isActive, isTrue);
      expect(back.expiresAt, isNull);

      final DateTime exp = DateTime.utc(2027, 1, 2, 3, 4, 5);
      final Entitlement sub = Entitlement(
        entitlement: 'pro',
        productId: 'p',
        store: 'paddle',
        isActive: true,
        expiresAt: exp,
      );
      expect(Entitlement.fromJson(sub.toJson()).expiresAt, exp);
    });

    test('Entitlements round-trips its items', () {
      final Entitlements e = Entitlements(
        appId: 'subly',
        isPro: true,
        items: <Entitlement>[
          const Entitlement(
            entitlement: 'pro',
            productId: 'subly_pro',
            store: 'paddle',
            isActive: true,
          ),
        ],
      );
      final Entitlements back = Entitlements.fromJson(e.toJson());
      expect(back.appId, 'subly');
      expect(back.isPro, isTrue);
      expect(back.items, hasLength(1));
      expect(back.items.first.productId, 'subly_pro');
    });
  });
}
