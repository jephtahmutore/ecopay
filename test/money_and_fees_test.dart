import 'package:ecopay/utils/fee_calculator.dart';
import 'package:ecopay/utils/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Money', () {
    test('parses amounts to cents without float errors', () {
      expect(Money.parseToCents('120.5'), 12050);
      expect(Money.parseToCents('0.10'), 10);
      expect(Money.parseToCents('1,000'), 100000);
    });

    test('rejects empty, zero and negative amounts', () {
      expect(Money.parseToCents(''), isNull);
      expect(Money.parseToCents('0'), isNull);
      expect(Money.parseToCents('-5'), isNull);
      expect(Money.parseToCents('abc'), isNull);
    });

    test('formats cents with thousands separators', () {
      expect(Money.format(12050), '120.50');
      expect(Money.format(123456789), '1,234,567.89');
      expect(Money.formatWithCurrency(5, 'USD'), 'USD 0.05');
    });
  });

  group('FeeCalculator', () {
    const fees = FeeCalculator();

    test('charges flat fee plus 2 percent', () {
      // 100.00 USD: 1.50 + 2.00 = 3.50
      expect(fees.feeFor(10000), 350);
    });

    test('caps the fee at the maximum', () {
      // 5,000 USD would be 101.50 but is capped at 25.00
      expect(fees.feeFor(500000), 2500);
    });

    test('charges nothing for zero or negative amounts', () {
      expect(fees.feeFor(0), 0);
      expect(fees.feeFor(-100), 0);
    });
  });
}
