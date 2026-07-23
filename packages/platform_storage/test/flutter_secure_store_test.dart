import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nikatru_core/nikatru_core.dart';
import 'package:nikatru_platform_storage/nikatru_platform_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues(<String, String>{}));

  test('write / read / delete round-trip + deleteAll', () async {
    final SecureStore s = FlutterSecureStore();
    await s.write('token', 'abc');
    await s.write('refresh', 'xyz');
    expect(await s.read('token'), 'abc');

    await s.delete('token');
    expect(await s.read('token'), isNull);
    expect(await s.read('refresh'), 'xyz');

    await s.deleteAll();
    expect(await s.read('refresh'), isNull);
  });

  test('backs an EntitlementCache (save → readValid → clear)', () async {
    // Proves the adapter satisfies the core EntitlementCache contract.
    final EntitlementCache cache =
        EntitlementCache(store: FlutterSecureStore());
    await cache.save(const Entitlements(
      appId: 'subly',
      isPro: true,
      items: <Entitlement>[
        Entitlement(
          entitlement: 'pro',
          productId: 'subly_pro',
          store: 'paddle',
          isActive: true,
        ),
      ],
    ));
    final Entitlements v = await cache.readValid(now: DateTime.utc(2099));
    expect(v.isPro, isTrue);

    await cache.clear();
    expect(await cache.readRaw(), isNull);
  });
}
