enum AccountType { wallet, bank, mobile }

/// A bank account or mobile money wallet linked to EcoPay.
///
/// Balances are simulated in this demo. In production they would come from
/// the bank or EcoCash API.
class LinkedAccount {
  LinkedAccount({
    required this.id,
    required this.type,
    required this.provider,
    required this.number,
    required this.balanceCents,
  });

  final String id;
  final AccountType type;
  final String provider;
  final String number;
  int balanceCents;

  String get masked {
    if (type == AccountType.wallet) return 'Main balance';
    final last4 = number.length > 4 ? number.substring(number.length - 4) : number;
    return '•••• $last4';
  }
}
