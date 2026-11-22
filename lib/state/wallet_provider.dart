import 'package:flutter/foundation.dart';

import '../models/corridor.dart';
import '../models/insights.dart';
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

  /// Currencies recipients can receive, one per country we send to.
  static final receiveCurrencies = Corridor.all.map((c) => c.currency).toList();
  static const sendCurrency = 'USD';

  Quote? quote;
  String? error;
  bool loading = false;

  int get balanceCents => _repository.balanceCents;
  List<Transfer> get transfers => _repository.transfers;

  /// People the user sent to before, newest first.
  List<SavedRecipient> get savedRecipients => SavedRecipient.fromHistory(transfers);

  /// Spending summary for the current month.
  SpendingInsights get insights => SpendingInsights.forMonth(transfers, DateTime.now());

  Future<void> getQuote({required int sendCents, required String receiveCurrency}) async {
    loading = true;
    error = null;
    quote = null;
    notifyListeners();
    try {
      // Sending USD to be paid out in USD (for example EcoCash in Zimbabwe)
      // needs no conversion, so we skip the rate service.
      final rate = receiveCurrency == sendCurrency ? 1.0 : await _rates.usdTo(receiveCurrency);
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
  Future<Transfer?> confirm({
    required String recipientName,
    required String recipientPhone,
    String country = 'Other',
    DeliveryMethod deliveryMethod = DeliveryMethod.mobileWallet,
  }) async {
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
        country: country,
        deliveryMethod: deliveryMethod,
      );
      quote = null;
      return transfer;
    } on InsufficientFundsException catch (e) {
      error = e.toString();
    } on InvalidRecipientException catch (e) {
      error = e.message;
    } on QuoteExpiredException catch (e) {
      error = e.toString();
      quote = null;
    } finally {
      loading = false;
      notifyListeners();
    }
    return null;
  }

  /// Buys Econet airtime from the wallet. Returns null if it failed (see [error]).
  Future<Transfer?> buyAirtime({required String phone, required int amountCents}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      return await _repository.buyAirtime(phone: phone, amountCents: amountCents);
    } on InsufficientFundsException catch (e) {
      error = e.toString();
    } on InvalidRecipientException catch (e) {
      error = e.message;
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
