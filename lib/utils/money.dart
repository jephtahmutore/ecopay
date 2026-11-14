/// Money helpers. All amounts in the app are stored as whole cents (int)
/// so that we never lose precision with floating point arithmetic.
class Money {
  Money._();

  /// Converts a user entered string such as "120.5" into cents (12050).
  /// Returns null when the input is not a valid positive amount.
  static int? parseToCents(String input) {
    final cleaned = input.trim().replaceAll(',', '');
    if (cleaned.isEmpty) return null;
    final value = double.tryParse(cleaned);
    if (value == null || value <= 0) return null;
    return (value * 100).round();
  }

  /// Formats cents as a readable amount, for example 12050 becomes "120.50".
  static String format(int cents) {
    final negative = cents < 0;
    final abs = cents.abs();
    final whole = abs ~/ 100;
    final fraction = (abs % 100).toString().padLeft(2, '0');
    final withSeparators = _groupThousands(whole.toString());
    return '${negative ? '-' : ''}$withSeparators.$fraction';
  }

  static String formatWithCurrency(int cents, String currency) =>
      '$currency ${format(cents)}';

  static String _groupThousands(String digits) {
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final fromEnd = digits.length - i;
      buffer.write(digits[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buffer.write(',');
    }
    return buffer.toString();
  }
}
