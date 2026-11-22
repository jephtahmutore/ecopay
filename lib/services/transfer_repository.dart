import 'dart:math';

import '../models/corridor.dart';
import '../models/quote.dart';
import '../models/transfer.dart';
import '../utils/fee_calculator.dart';
import '../utils/phone.dart';

class InsufficientFundsException implements Exception {
  @override
  String toString() => 'Your wallet balance is too low for this transfer';
}

class QuoteExpiredException implements Exception {
  @override
  String toString() => 'This quote has expired. Please get a new quote';
}

class InvalidRecipientException implements Exception {
  InvalidRecipientException(this.message);
  final String message;

  @override
  String toString() => message;
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
    String country = 'Other',
    DeliveryMethod deliveryMethod = DeliveryMethod.mobileWallet,
  }) async {
    if (quote.isExpired()) throw QuoteExpiredException();
    if (quote.totalCents > _balanceCents) throw InsufficientFundsException();
    if (deliveryMethod == DeliveryMethod.ecocash && !PhoneNumbers.isEconetNumber(recipientPhone)) {
      throw InvalidRecipientException('EcoCash needs an Econet number starting with 077 or 078');
    }

    await Future<void>.delayed(const Duration(milliseconds: 600));

    _balanceCents -= quote.totalCents;
    final transfer = Transfer(
      id: _newId(),
      recipientName: recipientName.trim(),
      recipientPhone: recipientPhone.trim(),
      quote: quote,
      status: TransferStatus.completed,
      createdAt: DateTime.now(),
      country: country,
      deliveryMethod: deliveryMethod,
    );
    _transfers.add(transfer);
    return transfer;
  }

  /// Buys Econet airtime for a Zimbabwe number, paid from the wallet.
  /// Airtime has no fee and is charged in USD.
  Future<Transfer> buyAirtime({required String phone, required int amountCents}) async {
    if (!PhoneNumbers.isEconetNumber(phone)) {
      throw InvalidRecipientException('Enter an Econet number starting with 077 or 078');
    }
    if (amountCents < minAirtimeCents || amountCents > maxAirtimeCents) {
      throw InvalidRecipientException('Airtime must be between USD 0.50 and USD 50.00');
    }
    if (amountCents > _balanceCents) throw InsufficientFundsException();

    await Future<void>.delayed(const Duration(milliseconds: 400));

    final quote = Quote.create(
      sendCurrency: 'USD',
      receiveCurrency: 'USD',
      sendCents: amountCents,
      rate: 1,
      fees: const FeeCalculator(flatFeeCents: 0, percentBasisPoints: 0),
    );
    _balanceCents -= quote.totalCents;
    final purchase = Transfer(
      id: _newId(),
      recipientName: 'Econet airtime',
      recipientPhone: PhoneNumbers.toZimbabweInternational(phone),
      quote: quote,
      status: TransferStatus.completed,
      createdAt: DateTime.now(),
      kind: TransferKind.airtime,
      country: 'Zimbabwe',
      deliveryMethod: DeliveryMethod.ecocash,
    );
    _transfers.add(purchase);
    return purchase;
  }

  static const minAirtimeCents = 50;
  static const maxAirtimeCents = 5000;

  String _newId() =>
      'EP${DateTime.now().millisecondsSinceEpoch}${_random.nextInt(900) + 100}';
}
