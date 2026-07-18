// Fast unit tests (no browser) for the pure logic the UI relies on. Run by
// `flutter test` in CI; the browser E2E lives under integration_test/.
import 'package:flutter_test/flutter_test.dart';

import 'package:subly/core/format/currency.dart';
import 'package:subly/data/models/subscription.dart';

void main() {
  group('Currency', () {
    test(r'USD formats with the $ symbol and two decimals', () {
      expect(const Currency(r'$').fmt(10), r'$10.00');
      expect(const Currency(r'$').fmt0(1234), r'$1,234');
    });
    test('other symbols apply the demo FX conversion', () {
      expect(const Currency('€').fmt(10), '€9.20'); // 10 * 0.92
      expect(const Currency('₹').fmt(1), '₹83.00'); // 1 * 83
    });
  });

  group('Subscription', () {
    Subscription make(double price, BillingCycle cycle) => Subscription(
          id: '1',
          name: 'X',
          category: 'Other',
          price: price,
          cycle: cycle,
          nextRenewal: DateTime(2026, 1, 1),
        );

    test('yearly price normalises to a monthly figure', () {
      expect(make(120, BillingCycle.yearly).monthlyPrice, 10);
    });
    test('monthly price passes through unchanged', () {
      expect(make(9.99, BillingCycle.monthly).monthlyPrice, 9.99);
    });
    test('json round-trips name, price and cycle', () {
      final Subscription back =
          Subscription.fromJson(make(15.49, BillingCycle.yearly).toJson());
      expect(back.cycle, BillingCycle.yearly);
      expect(back.price, 15.49);
      expect(back.name, 'X');
    });
  });
}
