import 'package:ecopay/models/activity.dart';
import 'package:ecopay/models/scheduled_send.dart';
import 'package:ecopay/services/auth_service.dart';
import 'package:ecopay/services/exchange_rate_service.dart';
import 'package:ecopay/services/transfer_repository.dart';
import 'package:ecopay/state/auth_provider.dart';
import 'package:ecopay/state/wallet_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// Auth service that keeps everything in memory, no secure storage needed.
class MemoryAuthService extends AuthService {
  String? _pin;

  @override
  Future<String?> restoreSession() async => null;

  @override
  Future<void> signIn({required String email, required String pin}) async {
    _pin = pin;
  }

  @override
  Future<bool> verifyPin(String pin) async => pin == _pin;

  @override
  Future<void> signOut() async {
    _pin = null;
  }
}

WalletProvider makeWallet({int balance = 50000}) => WalletProvider(
      rates: ExchangeRateService(),
      repository: TransferRepository(startingBalanceCents: balance),
    );

void main() {
  group('Move money', () {
    test('moves from a bank into the wallet', () async {
      final wallet = makeWallet();
      final bankBefore = wallet.accountById('cbz').balanceCents;

      final activity = await wallet.moveMoney(fromId: 'cbz', toId: WalletProvider.walletId, cents: 10000);

      expect(activity, isNotNull);
      expect(wallet.balanceCents, 60000);
      expect(wallet.accountById('cbz').balanceCents, bankBefore - 10000);
    });

    test('moves from EcoCash straight to a bank', () async {
      final wallet = makeWallet();
      final ecocashBefore = wallet.accountById('ecocash').balanceCents;
      final bankBefore = wallet.accountById('stanbic').balanceCents;

      await wallet.moveMoney(fromId: 'ecocash', toId: 'stanbic', cents: 1000);

      expect(wallet.accountById('ecocash').balanceCents, ecocashBefore - 1000);
      expect(wallet.accountById('stanbic').balanceCents, bankBefore + 1000);
    });

    test('refuses to move more than the account holds', () async {
      final wallet = makeWallet();
      final activity = await wallet.moveMoney(fromId: 'ecocash', toId: 'cbz', cents: 99999999);
      expect(activity, isNull);
      expect(wallet.error, isNotNull);
    });
  });

  group('Pay for home', () {
    test('pays a bill from the wallet and issues a ZESA token', () async {
      final wallet = makeWallet();
      final activity = await wallet.payBill(
        category: 'Electricity',
        biller: 'ZESA prepaid',
        reference: '37141234567',
        beneficiary: 'Gogo',
        cents: 2000,
      );
      expect(wallet.balanceCents, 48000);
      expect(activity!.details['Token'], isNotNull);
    });
  });

  group('Offline mode', () {
    test('queues payments and sends them when back online', () async {
      final wallet = makeWallet();
      await wallet.setOffline(true);

      final queued = await wallet.payBill(
        category: 'Groceries',
        biller: 'FreshMart vouchers',
        reference: '+263772345678',
        beneficiary: 'Mum',
        cents: 3000,
      );
      expect(queued!.status, ActivityStatus.queued);
      expect(wallet.queuedCount, 1);
      expect(wallet.balanceCents, 50000);

      await wallet.setOffline(false);
      expect(wallet.queuedCount, 0);
      expect(wallet.balanceCents, 47000);
      expect(wallet.activityById(queued.id)!.status, ActivityStatus.completed);
    });
  });

  group('Scam shield', () {
    test('warns about an unknown number', () {
      final check = makeWallet().checkRecipient(name: 'John Doe', phone: '+263799999999', cents: 1000);
      expect(check.isSafe, isFalse);
      expect(check.registeredName, isNull);
    });

    test('warns when the name does not match the registered name', () {
      final check = makeWallet().checkRecipient(name: 'Peter Smith', phone: '+263771234567', cents: 1000);
      expect(check.registeredName, 'Tendai Moyo');
      expect(check.warnings.any((w) => w.contains('registered to Tendai Moyo')), isTrue);
    });

    test('passes a known, verified recipient with a normal amount', () {
      final check = makeWallet().checkRecipient(name: 'Tendai Moyo', phone: '+263 77 123 4567', cents: 5000);
      expect(check.isSafe, isTrue);
    });
  });

  group('Scheduled sends', () {
    test('next date rolls over to next month', () {
      const s = ScheduledSend(id: 'x', name: 'A', phone: '+263771234567', amountCents: 100, dayOfMonth: 5);
      expect(s.nextDate(DateTime(2026, 11, 22)), DateTime(2026, 12, 5));
      expect(s.nextDate(DateTime(2026, 11, 2)), DateTime(2026, 11, 5));
    });

    test('send now debits amount plus fee', () async {
      final wallet = makeWallet();
      final activity = await wallet.runSchedule(wallet.schedules.first.id);
      // USD 80.00 plus fee 1.50 + 2% (1.60) = 83.10
      expect(activity!.amountCents, 8310);
      expect(wallet.balanceCents, 50000 - 8310);
    });
  });

  group('Airtime and data', () {
    test('detects the network from the number', () {
      expect(WalletProvider.networkFor('0772345678'), 'Econet');
      expect(WalletProvider.networkFor('+263 78 330 9763'), 'Econet');
      expect(WalletProvider.networkFor('0712345678'), 'NetOne');
      expect(WalletProvider.networkFor('0732345678'), 'Telecel');
    });

    test('buys a data bundle from the wallet', () async {
      final wallet = makeWallet();
      final activity = await wallet.buyAirtime(phone: '0772345678', item: 'Weekly 1 GB', cents: 200, isData: true);
      expect(activity!.title, 'Econet Weekly 1 GB');
      expect(wallet.balanceCents, 49800);
    });
  });

  group('Mukando', () {
    test('pays my contribution once per round', () async {
      final wallet = makeWallet();
      final club = wallet.clubs.first;
      final paidBefore = club.paidCount;

      expect(await wallet.contributeToClub(club.id), isNotNull);
      expect(club.paidCount, paidBefore + 1);
      expect(wallet.balanceCents, 50000 - club.contributionCents);

      expect(await wallet.contributeToClub(club.id), isNull);
      expect(wallet.balanceCents, 50000 - club.contributionCents);
    });

    test('creates a club with me first in the list', () {
      final wallet = makeWallet();
      wallet.createClub(name: 'Work club', cents: 2000, memberNames: ['Ann', ' ', 'Bo']);
      final club = wallet.clubs.last;
      expect(club.members.length, 3);
      expect(club.members.first.isYou, isTrue);
      expect(club.potCents, 6000);
    });
  });

  group('App lock', () {
    test('locks and only unlocks with the right PIN', () async {
      final auth = AuthProvider(MemoryAuthService());
      await auth.signIn('jay@example.com', '1234');

      auth.lock();
      expect(auth.locked, isTrue);

      expect(await auth.unlock('9999'), isFalse);
      expect(auth.locked, isTrue);
      expect(auth.lockError, isNotNull);

      expect(await auth.unlock('1234'), isTrue);
      expect(auth.locked, isFalse);
    });
  });
}
