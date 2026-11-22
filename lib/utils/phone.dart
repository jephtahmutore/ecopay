/// Phone number helpers.
class PhoneNumbers {
  PhoneNumbers._();

  /// Removes spaces, dashes and brackets that people type for readability.
  static String clean(String input) => input.replaceAll(RegExp(r'[\s\-()]'), '');

  /// Any international number: optional +, then 9 to 15 digits.
  static bool isValidInternational(String input) =>
      RegExp(r'^\+?\d{9,15}$').hasMatch(clean(input));

  /// Econet Wireless lines in Zimbabwe start with 077 or 078
  /// (+263 77 or +263 78). EcoCash wallets and Econet airtime use these numbers.
  static bool isEconetNumber(String input) =>
      RegExp(r'^(\+?263|0)7[78]\d{7}$').hasMatch(clean(input));

  /// Converts a Zimbabwe number to the +263 format, for example
  /// 0772 123 456 becomes +263772123456.
  static String toZimbabweInternational(String input) {
    final c = clean(input);
    if (c.startsWith('+263')) return c;
    if (c.startsWith('263')) return '+$c';
    if (c.startsWith('0')) return '+263${c.substring(1)}';
    return c;
  }
}
