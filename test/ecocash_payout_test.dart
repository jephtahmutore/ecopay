import 'package:ecopay/models/activity.dart';
import 'package:ecopay/services/exchange_rate_service.dart';
import 'package:ecopay/services/transfer_repository.dart';
import 'package:ecopay/state/wallet_provider.dart';
import 'package:ecopay/widgets/ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// A wallet whose rate service is down, to prove EcoCash payouts never need it.
WalletProvider offlineRatesWallet({int balance = 50000}) => WalletProvider(
      rates: ExchangeRateService(client: MockClient((_) async => http.Response('down', 500))),
      repository: TransferRepository(startingBalanceCents: balance),
      withDemoData: false,
    );

void main() {
  group('Econet numbers', () {
    test('accepts 077 and 078 lines in any format', () {
      expect(WalletProvider.isEconetNumber('0772 123 456'), isTrue);
      expect(WalletProvider.isEconetNumber('+263 78 330 9763'), isTrue);
      expect(WalletProvider.isEconetNumber('263771234567'), isTrue);
    });

    test('rejects other networks and countries', () {
      expect(WalletProvider.isEconetNumber('0712345678'), isFalse); // NetOne
      expect(WalletProvider.isEconetNumber('0732345678'), isFalse); // Telecel
      expect(WalletProvider.isEconetNumber('+260971234567'), isFalse); // Zambia
    });
  });

  group('EcoCash payouts', () {
    test('USD to EcoCash needs no exchange rate', () async {
      final wallet = offlineRatesWallet();
      await wallet.getQuote(sendCents: 2000, receiveCurrency: 'USD');
      expect(wallet.error, isNull);
      expect(wallet.quote!.rate, 1.0);
      expect(wallet.quote!.receiveCents, 2000);
    });

    test('sends to an Econet number and shows EcoCash on the receipt', () async {
      final wallet = offlineRatesWallet();
      await wallet.getQuote(sendCents: 2000, receiveCurrency: 'USD');
      final transfer = await wallet.confirm(recipientName: 'Rudo Chikore', recipientPhone: '0772123456');

      expect(transfer, isNotNull);
      final activity = wallet.activityById(transfer!.id)!;
      expect(activity.details['Paid out to'], 'EcoCash wallet, Zimbabwe');
      expect(trackingSteps(activity).last, 'Paid into their EcoCash wallet');
      expect(wallet.balanceCents, 50000 - wallet.transfers.first.quote.totalCents);
    });

    test('blocks a non Econet number and keeps the money', () async {
      final wallet = offlineRatesWallet();
      await wallet.getQuote(sendCents: 2000, receiveCurrency: 'USD');
      final transfer = await wallet.confirm(recipientName: 'Rudo Chikore', recipientPhone: '0712345678');

      expect(transfer, isNull);
      expect(wallet.error, contains('Econet'));
      expect(wallet.balanceCents, 50000);
    });
  });

  group('Receipt tracking', () {
    Activity activity(ActivityKind kind, ActivityStatus status) => Activity(
          id: 'EP1',
          kind: kind,
          title: 'ZESA',
          subtitle: '',
          amountCents: 1000,
          createdAt: DateTime(2026, 11, 23),
          category: 'Electricity',
          status: status,
        );

    test('has steps for every kind of payment', () {
      for (final kind in ActivityKind.values) {
        expect(trackingSteps(activity(kind, ActivityStatus.completed)), isNotEmpty);
      }
    });

    test('bill payments end with the biller receiving it', () {
      expect(trackingSteps(activity(ActivityKind.bill, ActivityStatus.completed)).last, 'Payment received');
    });
  });
}
