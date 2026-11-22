/// How the recipient collects the money.
enum DeliveryMethod {
  ecocash('EcoCash wallet'),
  mobileWallet('Mobile wallet'),
  bank('Bank account'),
  cashPickup('Cash pickup');

  const DeliveryMethod(this.label);
  final String label;
}

/// A country EcoPay sends to, its payout currency and how money can be paid out.
class Corridor {
  const Corridor({
    required this.country,
    required this.flag,
    required this.currency,
    required this.methods,
  });

  final String country;
  final String flag;
  final String currency;
  final List<DeliveryMethod> methods;

  /// Zimbabwe comes first: USD straight into an EcoCash wallet.
  static const all = [
    Corridor(
      country: 'Zimbabwe',
      flag: '🇿🇼',
      currency: 'USD',
      methods: [DeliveryMethod.ecocash, DeliveryMethod.bank, DeliveryMethod.cashPickup],
    ),
    Corridor(
      country: 'South Africa',
      flag: '🇿🇦',
      currency: 'ZAR',
      methods: [DeliveryMethod.mobileWallet, DeliveryMethod.bank, DeliveryMethod.cashPickup],
    ),
    Corridor(
      country: 'Zambia',
      flag: '🇿🇲',
      currency: 'ZMW',
      methods: [DeliveryMethod.mobileWallet, DeliveryMethod.bank, DeliveryMethod.cashPickup],
    ),
    Corridor(
      country: 'Botswana',
      flag: '🇧🇼',
      currency: 'BWP',
      methods: [DeliveryMethod.mobileWallet, DeliveryMethod.bank],
    ),
    Corridor(
      country: 'Malawi',
      flag: '🇲🇼',
      currency: 'MWK',
      methods: [DeliveryMethod.mobileWallet, DeliveryMethod.bank, DeliveryMethod.cashPickup],
    ),
    Corridor(
      country: 'United Kingdom',
      flag: '🇬🇧',
      currency: 'GBP',
      methods: [DeliveryMethod.bank],
    ),
  ];

  static Corridor byCountry(String country) =>
      all.firstWhere((c) => c.country == country, orElse: () => all.first);
}
