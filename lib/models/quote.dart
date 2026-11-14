import '../utils/fee_calculator.dart';

/// A price quote shown to the user before they confirm a transfer.
class Quote {
  const Quote({
    required this.sendCurrency,
    required this.receiveCurrency,
    required this.sendCents,
    required this.feeCents,
    required this.rate,
    required this.receiveCents,
    required this.createdAt,
  });

  final String sendCurrency;
  final String receiveCurrency;
  final int sendCents;
  final int feeCents;
  final double rate;
  final int receiveCents;
  final DateTime createdAt;

  /// Total debited from the sender's wallet.
  int get totalCents => sendCents + feeCents;

  /// Quotes expire so that users never send at a stale exchange rate.
  bool isExpired({Duration validFor = const Duration(minutes: 5)}) =>
      DateTime.now().difference(createdAt) > validFor;

  factory Quote.create({
    required String sendCurrency,
    required String receiveCurrency,
    required int sendCents,
    required double rate,
    FeeCalculator fees = const FeeCalculator(),
    DateTime? now,
  }) {
    if (sendCents <= 0) {
      throw ArgumentError.value(sendCents, 'sendCents', 'must be positive');
    }
    if (rate <= 0) {
      throw ArgumentError.value(rate, 'rate', 'must be positive');
    }
    return Quote(
      sendCurrency: sendCurrency,
      receiveCurrency: receiveCurrency,
      sendCents: sendCents,
      feeCents: fees.feeFor(sendCents),
      rate: rate,
      receiveCents: (sendCents * rate).round(),
      createdAt: now ?? DateTime.now(),
    );
  }
}
