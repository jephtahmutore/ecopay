import 'package:flutter/foundation.dart';

import '../models/quote.dart';
import '../models/transfer.dart';
import '../services/exchange_rate_service.dart';
import '../services/transfer_repository.dart';

class WalletProvider extends ChangeNotifier {
  WalletProvider({
    required ExchangeRateService rates,
    required TransferRepository repository,
  })  : _rates = rates,
        _repository = repository;

  final ExchangeRateService _rates;
  final TransferRepository _repository;

  /// Currencies recipients can receive.
  static const receiveCurrencies = ['ZAR', 'ZMW', 'BWP', 'MWK', 'GBP'];
  static const sendCurrency = 'USD';

  Quote? quote;
  String? error;
  bool loading = false;

  int get balanceCents => _repository.balanceCents;
  List<Transfer> get transfers => _repository.transfers;

  Future<void> getQuote({required int sendCents, required String receiveCurrency}) async {
    loading = true;
    error = null;
    quote = null;
    notifyListeners();
    try {
      final rate = await _rates.usdTo(receiveCurrency);
      quote = Quote.create(
        sendCurrency: sendCurrency,
        receiveCurrency: receiveCurrency,
        sendCents: sendCents,
        rate: rate,
      );
    } on ExchangeRateException catch (e) {
      error = e.message;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Returns the completed transfer, or null if it failed (see [error]).
  Future<Transfer?> confirm({required String recipientName, required String recipientPhone}) async {
    final current = quote;
    if (current == null) return null;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final transfer = await _repository.send(
        quote: current,
        recipientName: recipientName,
        recipientPhone: recipientPhone,
      );
      quote = null;
      return transfer;
    } on InsufficientFundsException catch (e) {
      error = e.toString();
    } on QuoteExpiredException catch (e) {
      error = e.toString();
      quote = null;
    } finally {
      loading = false;
      notifyListeners();
    }
    return null;
  }

  void clearQuote() {
    quote = null;
    error = null;
    notifyListeners();
  }
}
