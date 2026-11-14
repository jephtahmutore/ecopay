/// Calculates the transfer fee charged to the sender.
///
/// Fee = flat fee + percentage of the amount, capped at a maximum.
/// Everything is in cents.
class FeeCalculator {
  const FeeCalculator({
    this.flatFeeCents = 150,
    this.percentBasisPoints = 200,
    this.maxFeeCents = 2500,
  });

  /// Flat fee per transfer, in cents (default USD 1.50).
  final int flatFeeCents;

  /// Percentage fee in basis points (200 = 2%).
  final int percentBasisPoints;

  /// Maximum fee for a single transfer, in cents (default USD 25.00).
  final int maxFeeCents;

  int feeFor(int amountCents) {
    if (amountCents <= 0) return 0;
    final percentFee = (amountCents * percentBasisPoints / 10000).round();
    final fee = flatFeeCents + percentFee;
    return fee > maxFeeCents ? maxFeeCents : fee;
  }
}
