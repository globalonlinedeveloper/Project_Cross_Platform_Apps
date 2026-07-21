// Pure-Dart unit tests for the PII scrubber. Deliberately imports ONLY the
// scrubber (no Flutter widgets, no Sentry) so it runs fast anywhere.
import 'package:flutter_test/flutter_test.dart';
import 'package:nikatru_telemetry/src/pii_scrubber.dart';

void main() {
  const scrubber = PiiScrubber();

  group('PiiScrubber.scrubText', () {
    test('redacts PAN numbers', () {
      final out = scrubber.scrubText('PAN BNQPR6389M submitted');
      expect(out, contains(redactedToken));
      expect(out, isNot(contains('BNQPR6389M')));
    });

    test('redacts Aadhaar numbers with spaces', () {
      final out = scrubber.scrubText('Aadhaar: 1234 5678 9012');
      expect(out, contains(redactedToken));
      expect(out, isNot(contains('1234 5678 9012')));
    });

    test('redacts Aadhaar numbers without spaces', () {
      final out = scrubber.scrubText('Aadhaar 123456789012 rejected');
      expect(out, contains(redactedToken));
      expect(out, isNot(contains('123456789012')));
    });

    test('redacts email addresses', () {
      final out = scrubber.scrubText('contact a@b.com for help');
      expect(out, contains(redactedToken));
      expect(out, isNot(contains('a@b.com')));
    });

    test('redacts +91 prefixed phone numbers', () {
      final out = scrubber.scrubText('call +91 9876543210 now');
      expect(out, contains(redactedToken));
      expect(out, isNot(contains('9876543210')));
    });

    test('redacts bare 10-digit phone numbers', () {
      final out = scrubber.scrubText('call 9876543210 now');
      expect(out, contains(redactedToken));
      expect(out, isNot(contains('9876543210')));
    });

    test('leaves text without PII byte-identical', () {
      const control = 'User tapped checkout, cart total 499 INR';
      final out = scrubber.scrubText(control);
      expect(out, control);
      expect(out, isNot(contains(redactedToken)));
    });
  });

  group('PiiScrubber.scrubMap', () {
    test('scrubs nested string values and preserves structure', () {
      final out = scrubber.scrubMap(<String, dynamic>{
        'note': 'mail a@b.com',
        'count': 3,
        'nested': <String, dynamic>{'phone': '+91 9876543210'},
        'list': <dynamic>['9876543210', 42],
      });

      expect(out['note'], contains(redactedToken));
      expect(out['count'], 3);

      final nested = out['nested'] as Map<String, dynamic>;
      expect(nested['phone'], contains(redactedToken));

      final list = out['list'] as List<Object?>;
      expect(list.first, contains(redactedToken));
      expect(list.last, 42);
    });
  });
}
