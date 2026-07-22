import 'package:nikatru_core/nikatru_core.dart';
import 'package:test/test.dart';

void main() {
  test('Result.ok folds to its value', () {
    const Result<int> r = Result<int>.ok(5);
    expect(r.fold((int v) => v, (Failure f) => -1), 5);
    expect(r.isOk, isTrue);
  });

  test('Result.err folds to the failure branch', () {
    const Result<int> r = Result<int>.err(Failure('boom'));
    expect(r.fold((int v) => v, (Failure f) => -1), -1);
    expect(r.isOk, isFalse);
  });
}
