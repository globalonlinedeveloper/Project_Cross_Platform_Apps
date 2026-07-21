import 'package:nikatru_core/nikatru_core.dart';
import 'package:test/test.dart';

void main() {
  test('yearly subscription normalizes to a monthly price', () {
    final Subscription s = Subscription(
      id: '1',
      name: 'Test',
      category: 'Other',
      price: 120,
      cycle: BillingCycle.yearly,
      nextRenewal: DateTime(2026, 1, 1),
    );
    expect(s.monthlyPrice, 10);
  });

  test('Result.ok folds to its value', () {
    const Result<int> r = Result<int>.ok(5);
    expect(r.fold((int v) => v, (Failure f) => -1), 5);
    expect(r.isOk, isTrue);
  });

  test('content-pack loader stub returns the empty pack', () async {
    final Result<ContentPack> r = await const ContentPackLoader().load('en');
    expect(r.fold((ContentPack p) => p.locale, (Failure f) => 'err'), 'en');
  });
}
