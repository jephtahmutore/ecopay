import 'package:ecopay/models/corridor.dart';
import 'package:ecopay/models/insights.dart';
import 'package:ecopay/models/quote.dart';
import 'package:ecopay/models/transfer.dart';
import 'package:ecopay/screens/receipt_screen.dart';
import 'package:ecopay/services/exchange_rate_service.dart';
import 'package:ecopay/services/transfer_repository.dart';
import 'package:ecopay/state/wallet_provider.dart';
import 'package:ecopay/utils/phone.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Quote usdQuote(int cents) =>
    Quote.create(sendCurrency: 'USD', receiveCurrency: 'USD', sendCents: cents, rate: 1);

Transfer transferAt(
  DateTime when, {
  String name = 'Tendai Moyo',
  String phone = '+263772123456',
  int cents = 10000,
  String country = 'Zimbabwe',
  TransferKind kind = TransferKind.remittance,
}) =>
    Transfer(
      id: 'EP${when.microsecondsSinceEpoch}',
      recipientName: name,
      recipientPhone: phone,
      quote: usdQuote(cents),
      status: TransferStatus.completed,
      createdAt: when,
      kind: kind,
      country: country,
      deliveryMethod: DeliveryMethod.ecocash,
    );

void main() {
  group('PhoneNumbers', () {
    test('recognises Econet lines', () {
      expect(PhoneNumbers.isEconetNumber('0772 123 456'), isTrue);
      expect(PhoneNumbers.isEconetNumber('+263 78 123 4567'), isTrue);
      expect(PhoneNumbers.isEconetNumber('263771234567'), isTrue);
      expect(PhoneNumbers.isEconetNumber('0712345678'), isFalse); // NetOne
      expect(PhoneNumbers.isEconetNumber('+260971234567'), isFalse); // Zambia
    });

    test('converts Zimbabwe numbers to +263 format', () {
      expect(PhoneNumbers.toZimbabweInternational('0772 123 456'), '+263772123456');
      expect(PhoneNumbers.toZimbabweInternational('263772123456'), '+263772123456');
    });
  });

  group('EcoCash payouts', () {
    test('accepts an Econet number', () async {
      final repo = TransferRepository(startingBalanceCents: 50000);
      final t = await repo.send(
        quote: usdQuote(2000),
        recipientName: 'Rudo Chikore',
        recipientPhone: '0772123456',
        country: 'Zimbabwe',
        deliveryMethod: DeliveryMethod.ecocash,
      );
      expect(t.deliveryMethod, DeliveryMethod.ecocash);
      expect(repo.balanceCents, 50000 - usdQuote(2000).totalCents);
    });

    test('rejects a number that is not on Econet', () async {
      final repo = TransferRepository(startingBalanceCents: 50000);
      expect(
        () => repo.send(
          quote: usdQuote(2000),
          recipientName: 'Rudo Chikore',
          recipientPhone: '0712345678',
          deliveryMethod: DeliveryMethod.ecocash,
        ),
        throwsA(isA<InvalidRecipientException>()),
      );
    });

    test('USD to USD quotes need no exchange rate call', () async {
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        return http.Response('down', 500);
      });
      final wallet = WalletProvider(
        rates: ExchangeRateService(client: client),
        repository: TransferRepository(),
      );
      await wallet.getQuote(sendCents: 5000, receiveCurrency: 'USD');
      expect(wallet.error, isNull);
      expect(wallet.quote!.receiveCents, 5000);
      expect(calls, 0);
    });
  });

  group('Econet airtime', () {
    test('debits the wallet with no fee and records the top up', () async {
      final repo = TransferRepository(startingBalanceCents: 1000);
      final purchase = await repo.buyAirtime(phone: '0782 000 111', amountCents: 500);
      expect(purchase.isAirtime, isTrue);
      expect(purchase.quote.feeCents, 0);
      expect(purchase.recipientPhone, '+263782000111');
      expect(repo.balanceCents, 500);
      expect(repo.transfers.first.id, purchase.id);
    });

    test('rejects non Econet numbers and amounts above the balance', () async {
      final repo = TransferRepository(startingBalanceCents: 100);
      expect(
        () => repo.buyAirtime(phone: '0712345678', amountCents: 100),
        throwsA(isA<InvalidRecipientException>()),
      );
      expect(
        () => repo.buyAirtime(phone: '0772123456', amountCents: 500),
        throwsA(isA<InsufficientFundsException>()),
      );
      expect(repo.balanceCents, 100);
    });
  });

  group('Spending insights', () {
    test('adds up this month only and finds the top country', () {
      final now = DateTime(2026, 11, 20);
      final insights = SpendingInsights.forMonth([
        transferAt(DateTime(2026, 11, 2), cents: 10000, country: 'Zimbabwe'),
        transferAt(DateTime(2026, 11, 5), cents: 4000, country: 'Zambia'),
        transferAt(DateTime(2026, 11, 6), cents: 300, kind: TransferKind.airtime),
        transferAt(DateTime(2026, 10, 30), cents: 99900, country: 'Zambia'),
      ], now);

      expect(insights.sentCents, 14000);
      expect(insights.transferCount, 2);
      expect(insights.airtimeCents, usdQuote(300).totalCents);
      expect(insights.feesCents, usdQuote(10000).feeCents + usdQuote(4000).feeCents);
      expect(insights.topCountry, 'Zimbabwe');
    });
  });

  group('Saved recipients', () {
    test('one per phone number, newest first, no airtime', () {
      final recipients = SavedRecipient.fromHistory([
        transferAt(DateTime(2026, 11, 9), name: 'Rudo Chikore', phone: '+263772000001'),
        transferAt(DateTime(2026, 11, 8), name: 'Airtime', kind: TransferKind.airtime),
        transferAt(DateTime(2026, 11, 7), name: 'Rudo C', phone: '+263772000001'),
        transferAt(DateTime(2026, 11, 6), name: 'Tendai Moyo', phone: '+263772000002'),
      ]);
      expect(recipients.map((r) => r.name), ['Rudo Chikore', 'Tendai Moyo']);
      expect(recipients.first.initials, 'RC');
    });
  });

  group('Receipt tracking', () {
    test('shows the EcoCash payout as the last step', () {
      final steps = ReceiptScreen.stepsFor(transferAt(DateTime(2026, 11, 1)));
      expect(steps.last, 'Paid into the EcoCash wallet');
      expect(steps.length, 4);
    });

    test('formats dates without extra packages', () {
      expect(ReceiptScreen.formatDate(DateTime(2026, 11, 22, 9, 5)), '22 Nov 2026, 09:05');
    });
  });
}
