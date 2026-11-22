import 'dart:math';

import '../models/quote.dart';
import '../models/transfer.dart';

class InsufficientFundsException implements Exception {
  @override
  String toString() => 'Your wallet balance is too low for this transfer';
}

class QuoteExpiredException implements Exception {
  @override
  String toString() => 'This quote has expired. Please get a new quote';
}

/// Stores the wallet balance and transfer history.
///
/// This version keeps data in memory to simulate a backend. Swapping it for
/// a real REST API only means replacing this class, because the rest of the
/// app depends on its methods, not on how they are implemented.
class TransferRepository {
  TransferRepository({int startingBalanceCents = 50000})
      : _balanceCents = startingBalanceCents;

  int _balanceCents;
  final List<Transfer> _transfers = [];
  final Random _random = Random();

  int get balanceCents => _balanceCents;

  /// Newest first.
  List<Transfer> get transfers => List.unmodifiable(_transfers.reversed);

  Future<Transfer> send({
    required Quote quote,
    required String recipientName,
    required String recipientPhone,
  }) async {
    if (quote.isExpired()) throw QuoteExpiredException();
    if (quote.totalCents > _balanceCents) throw InsufficientFundsException();

    await Future<void>.delayed(const Duration(milliseconds: 600));

    _balanceCents -= quote.totalCents;
    final transfer = Transfer(
      id: _newId(),
      recipientName: recipientName.trim(),
      recipientPhone: recipientPhone.trim(),
      quote: quote,
      status: TransferStatus.completed,
      createdAt: DateTime.now(),
    );
    _transfers.add(transfer);
    return transfer;
  }

  /// Takes money out of the wallet, for bills, moves and scheduled sends.
  void debit(int cents) {
    if (cents <= 0) throw ArgumentError.value(cents, 'cents', 'must be positive');
    if (cents > _balanceCents) throw InsufficientFundsException();
    _balanceCents -= cents;
  }

  /// Adds money to the wallet, for example a top up from a bank.
  void credit(int cents) {
    if (cents <= 0) throw ArgumentError.value(cents, 'cents', 'must be positive');
    _balanceCents += cents;
  }

  String _newId() =>
      'EP${DateTime.now().millisecondsSinceEpoch}${_random.nextInt(900) + 100}';
}
