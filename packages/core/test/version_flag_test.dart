import 'package:nikatru_core/nikatru_core.dart';
import 'package:test/test.dart';

void main() {
  group('meetsMinVersion (force-update kill-switch)', () {
    test('supported when at or above the floor', () {
      expect(meetsMinVersion('1.2.0', '1.0.0'), isTrue);
      expect(meetsMinVersion('1.2.0', '1.2.0'), isTrue); // equal meets
      expect(meetsMinVersion('2.0.0', '1.9.9'), isTrue);
    });

    test('unsupported below the floor → mustForceUpdate', () {
      expect(meetsMinVersion('1.0.0', '1.2.0'), isFalse);
      expect(mustForceUpdate('1.0.0', '1.2.0'), isTrue);
      expect(mustForceUpdate('1.2.0', '1.0.0'), isFalse);
    });

    test('compares numerically, not lexically', () {
      expect(meetsMinVersion('1.10.0', '1.9.0'), isTrue); // 10 > 9
      expect(meetsMinVersion('1.9.0', '1.10.0'), isFalse);
    });

    test('ignores build (+N) and pre-release (-tag) suffixes', () {
      expect(meetsMinVersion('1.2.0+7', '1.2.0'), isTrue);
      expect(meetsMinVersion('1.2.0-beta', '1.2.0'), isTrue); // equal core
    });

    test('short/non-numeric segments count as 0', () {
      expect(meetsMinVersion('1.2', '1.2.0'), isTrue); // 1.2 == 1.2.0
      expect(meetsMinVersion('1.2', '1.2.1'), isFalse);
      expect(meetsMinVersion('1.x.0', '1.0.0'), isTrue); // x → 0
    });

    test('blank floor fails open (never bricks a client)', () {
      expect(meetsMinVersion('0.1.0', ''), isTrue);
      expect(meetsMinVersion('0.1.0', '   '), isTrue);
    });

    test('unreadable client version fails open + strips a v prefix', () {
      expect(meetsMinVersion('', '1.0.0'), isTrue); // empty → don't brick
      expect(mustForceUpdate('   ', '1.0.0'), isFalse);
      expect(meetsMinVersion('v2.0.0', '1.0.0'), isTrue); // v prefix stripped
      expect(meetsMinVersion('v1.0.0', '1.2.0'), isFalse);
    });
  });

  group('resolveFlag (deterministic percentage rollout)', () {
    test('0% is off for everyone, ≥100% on for everyone', () {
      for (final String id in <String>['a', 'b', 'device-42']) {
        expect(
            resolveFlag(flag: 'f', rolloutPercent: 0, stableId: id), isFalse);
        expect(
            resolveFlag(flag: 'f', rolloutPercent: -5, stableId: id), isFalse);
        expect(
            resolveFlag(flag: 'f', rolloutPercent: 100, stableId: id), isTrue);
        expect(
            resolveFlag(flag: 'f', rolloutPercent: 150, stableId: id), isTrue);
      }
    });

    test('deterministic for the same device + flag', () {
      final bool a =
          resolveFlag(flag: 'dark', rolloutPercent: 37, stableId: 'dev-1');
      final bool b =
          resolveFlag(flag: 'dark', rolloutPercent: 37, stableId: 'dev-1');
      expect(a, b);
    });

    test('monotonic — raising the percent never flips a device off', () {
      const String id = 'dev-monotonic';
      final int bucket = flagBucket(flag: 'f', stableId: id); // 0..99
      expect(resolveFlag(flag: 'f', rolloutPercent: bucket, stableId: id),
          isFalse); // bucket not < bucket
      expect(resolveFlag(flag: 'f', rolloutPercent: bucket + 1, stableId: id),
          isTrue); // now included, and stays included as % rises
    });

    test('flagBucket stays within [0, 99]', () {
      for (int i = 0; i < 500; i++) {
        expect(flagBucket(flag: 'f$i', stableId: 'id-$i'),
            inInclusiveRange(0, 99));
      }
    });

    test('FeatureFlags binds a rollout map + stable id', () {
      const FeatureFlags off =
          FeatureFlags(rollouts: <String, int>{'f': 0}, stableId: 'd');
      const FeatureFlags on =
          FeatureFlags(rollouts: <String, int>{'f': 100}, stableId: 'd');
      expect(off.isOn('f'), isFalse);
      expect(on.isOn('f'), isTrue);
      expect(on.isOn('absent'), isFalse); // absent flag ⇒ off
    });

    test('~splits the population at the configured percent (deterministic)',
        () {
      int on = 0;
      for (int i = 0; i < 1000; i++) {
        if (resolveFlag(flag: 'exp', rolloutPercent: 50, stableId: 'user-$i')) {
          on++;
        }
      }
      expect(on, greaterThan(400));
      expect(on, lessThan(600));
    });
  });
}
