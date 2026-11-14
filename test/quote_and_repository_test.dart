import 'package:ecopay/models/quote.dart';
import 'package:ecopay/services/transfer_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Quote', () {
    test('calculates fee, total and amount received', () {
      final quote = Quote.create(
        sendCurrency: 'USD',
        receiveCurrency: 'ZAR',
        sendCents: 10000,
        rate: 18.5,
      );
      expect(quote.feeCents, 350);
      expect(quote.totalCents, 10350);
      expect(quote.receiveCents, 185000);
    });

    test('expires after five minutes', () {
      final old = Quote.create(
        sendCurrency: 'USD',
        receiveCurrency: 'ZAR',
        sendCents: 1000,
        rate: 18.5,
        now: DateTime.now().subtract(const Duration(minutes: 6)),
      );
      expect(old.isExpired(), isTrue);
    });

    test('rejects invalid amounts and rates', () {
      expect(
        () => Quote.create(sendCurrency: 'USD', receiveCurrency: 'ZAR', sendCents: 0, rate: 18.5),
        throwsArgumentError,
      );
      expect(
        () => Quote.create(sendCurrency: 'USD', receiveCurrency: 'ZAR', sendCents: 100, rate: 0),
        throwsArgumentError,
      );
    });
  });

  group('TransferRepository', () {
    Quote quoteFor(int cents) =>
        Quote.create(sendCurrency: 'USD', receiveCurrency: 'ZMW', sendCents: cents, rate: 26.0);

    test('debits the wallet and records the transfer', () async {
      final repo = TransferRepository(startingBalanceCents: 50000);
      final transfer = await repo.send(
        quote: quoteFor(10000),
        recipientName: 'Tendai Moyo',
        recipientPhone: '+260971234567',
      );
      expect(repo.balanceCents, 50000 - 10350);
      expect(repo.transfers.first.id, transfer.id);
    });

    test('blocks transfers above the balance', () async {
      final repo = TransferRepository(startingBalanceCents: 1000);
      expect(
        () => repo.send(quote: quoteFor(10000), recipientName: 'A B', recipientPhone: '+263771234567'),
        throwsA(isA<InsufficientFundsException>()),
      );
      expect(repo.balanceCents, 1000);
    });
  });
}
