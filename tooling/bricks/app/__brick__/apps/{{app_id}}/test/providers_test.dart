import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nikatru_core/nikatru_core.dart' as core;
import 'package:{{app_id.snakeCase()}}/state/providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer harness() => ProviderContainer(
    overrides: <Override>[
      // Swap the real shared_preferences store for an in-memory one so the
      // wiring is testable without platform channels.
      keyValueStoreProvider.overrideWith(
        (Ref ref) async => core.InMemoryKeyValueStore(),
      ),
    ],
  );

  test('install id is generated, non-empty and stable across reads', () async {
    final ProviderContainer c = harness();
    addTearDown(c.dispose);
    final String id1 = await c.read(installIdProvider.future);
    final String id2 = await c.read(installIdProvider.future);
    expect(id1, isNotEmpty);
    expect(id1, id2); // persisted → stable across launches
  });

  test('featureFlags resolves; an unconfigured flag is off', () async {
    final ProviderContainer c = harness();
    addTearDown(c.dispose);
    final core.FeatureFlags flags = await c.read(featureFlagsProvider.future);
    expect(flags.isOn('not_configured'), isFalse);
  });

  test('entitlementCache is available', () {
    final ProviderContainer c = harness();
    addTearDown(c.dispose);
    expect(c.read(entitlementCacheProvider), isA<core.EntitlementCache>());
  });
}
