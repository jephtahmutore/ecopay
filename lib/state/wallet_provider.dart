import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/demo_data.dart';
import '../models/activity.dart';
import '../models/linked_account.dart';
import '../models/quote.dart';
import '../models/savings_club.dart';
import '../models/scheduled_send.dart';
import '../models/transfer.dart';
import '../services/exchange_rate_service.dart';
import '../services/transfer_repository.dart';
import '../utils/fee_calculator.dart';
import '../utils/money.dart';

/// Result of the scam shield check before sending money.
class ScamCheck {
  const ScamCheck({required this.registeredName, required this.warnings});

  /// Name the number is registered to, or null if it is not verified.
  final String? registeredName;
  final List<String> warnings;

  bool get isSafe => warnings.isEmpty;
}

class WalletProvider extends ChangeNotifier {
  WalletProvider({
    required ExchangeRateService rates,
    required TransferRepository repository,
    bool withDemoData = true,
  })  : _rates = rates,
        _repository = repository {
    if (withDemoData) {
      _accounts.addAll(DemoData.accounts());
      _activities.addAll(DemoData.activities());
      _schedules.addAll(DemoData.schedules());
      _clubs.addAll(DemoData.clubs());
    }
  }

  /// Currencies recipients can receive. USD goes straight into an EcoCash
  /// wallet in Zimbabwe.
  static const receiveCurrencies = ['USD', 'ZAR', 'ZMW', 'BWP', 'MWK', 'GBP'];

  /// True when this currency is paid out to an EcoCash wallet in Zimbabwe.
  static bool isEcoCashPayout(String currency) => currency == sendCurrency;

  /// Econet lines start with 077 or 078 (+263 77 or +263 78).
  /// EcoCash wallets use these numbers.
  static bool isEconetNumber(String phone) =>
      RegExp(r'^(\+?263|0)7[78]\d{7}$').hasMatch(phone.replaceAll(RegExp(r'[\s\-()]'), ''));
  static const sendCurrency = 'USD';
  static const walletId = 'wallet';
  static const billCategories = ['School fees', 'Electricity', 'Groceries', 'Medical'];

  /// Amounts at or above this get an extra scam shield warning (USD 200).
  static const largeAmountCents = 20000;

  final ExchangeRateService _rates;
  final TransferRepository _repository;
  final FeeCalculator _fees = const FeeCalculator();
  final Random _random = Random();

  final List<LinkedAccount> _accounts = [];
  final List<Activity> _activities = [];
  final List<ScheduledSend> _schedules = [];
  final List<SavingsClub> _clubs = [];

  /// Payments made while offline, waiting to be sent. Keyed by activity id.
  final Map<String, void Function()> _queue = {};

  Quote? quote;
  String? error;
  bool loading = false;
  bool offline = false;
  bool scamShield = true;

  // ---------------------------------------------------------------- getters

  int get balanceCents => _repository.balanceCents;
  List<Transfer> get transfers => _repository.transfers;
  List<LinkedAccount> get linkedAccounts => List.unmodifiable(_accounts);
  List<ScheduledSend> get schedules => List.unmodifiable(_schedules);
  List<SavingsClub> get clubs => List.unmodifiable(_clubs);
  int get queuedCount => _queue.length;

  /// Newest first.
  List<Activity> get activities =>
      [..._activities]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// The EcoPay wallet followed by every linked account.
  List<LinkedAccount> get allAccounts => [
        LinkedAccount(
          id: walletId,
          type: AccountType.wallet,
          provider: 'EcoPay wallet',
          number: '',
          balanceCents: balanceCents,
        ),
        ..._accounts,
      ];

  LinkedAccount accountById(String id) => allAccounts.firstWhere((a) => a.id == id);

  Activity? activityById(String id) {
    for (final a in _activities) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// People the user has sent to before, for the quick pick row.
  List<({String name, String phone})> get recentRecipients {
    final seen = <String>{};
    final result = <({String name, String phone})>[];
    for (final a in activities) {
      final phone = a.details['Phone'];
      final name = a.details['Recipient'];
      if (phone == null || name == null) continue;
      if (seen.add(_normalize(phone))) result.add((name: name, phone: phone));
    }
    return result;
  }

  // ------------------------------------------------------------ simple setters

  void clearError() {
    error = null;
    notifyListeners();
  }

  void clearQuote() {
    quote = null;
    error = null;
    notifyListeners();
  }

  void setScamShield(bool value) {
    scamShield = value;
    notifyListeners();
  }

  // ------------------------------------------------------------ offline mode

  /// Turning offline off sends everything in the queue, oldest first.
  Future<void> setOffline(bool value) async {
    offline = value;
    notifyListeners();
    if (!value) await _flushQueue();
  }

  Future<void> _flushQueue() async {
    if (_queue.isEmpty) return;
    final pending = Map.of(_queue);
    _queue.clear();
    for (final entry in pending.entries) {
      final index = _activities.indexWhere((a) => a.id == entry.key);
      if (index == -1) continue;
      try {
        entry.value();
        _activities[index] = _activities[index].copyWith(status: ActivityStatus.completed);
      } catch (_) {
        _activities[index] = _activities[index].copyWith(status: ActivityStatus.failed);
      }
    }
    notifyListeners();
  }

  /// Runs a payment now, or queues it when offline.
  Future<Activity?> _run(Activity activity, void Function() action) async {
    error = null;
    if (offline) {
      final queued = activity.copyWith(status: ActivityStatus.queued);
      _queue[activity.id] = action;
      _activities.add(queued);
      notifyListeners();
      return queued;
    }
    loading = true;
    notifyListeners();
    try {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      action();
      _activities.add(activity);
      return activity;
    } on InsufficientFundsException {
      error = 'Not enough money for this payment';
      return null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------- send money abroad

  Future<void> getQuote({required int sendCents, required String receiveCurrency}) async {
    if (offline) {
      error = 'You are offline. Sending abroad needs a live exchange rate. '
          'Bills and moves still work and will be queued.';
      notifyListeners();
      return;
    }
    loading = true;
    error = null;
    quote = null;
    notifyListeners();
    try {
      // USD to an EcoCash wallet needs no conversion, so skip the rate service.
      final rate = isEcoCashPayout(receiveCurrency) ? 1.0 : await _rates.usdTo(receiveCurrency);
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
    if (offline) {
      error = 'You are offline. Go online to send abroad.';
      notifyListeners();
      return null;
    }
    loading = true;
    error = null;
    notifyListeners();
    final ecoCash = isEcoCashPayout(current.receiveCurrency);
    if (ecoCash && !isEconetNumber(recipientPhone)) {
      error = 'EcoCash needs an Econet number starting with 077 or 078';
      loading = false;
      notifyListeners();
      return null;
    }
    try {
      final transfer = await _repository.send(
        quote: current,
        recipientName: recipientName,
        recipientPhone: recipientPhone,
      );
      _activities.add(Activity(
        id: transfer.id,
        kind: ActivityKind.sendAbroad,
        title: transfer.recipientName,
        subtitle: ecoCash ? 'To EcoCash ${transfer.recipientPhone}' : 'Sent to ${transfer.recipientPhone}',
        amountCents: current.totalCents,
        feeCents: current.feeCents,
        category: 'Family',
        createdAt: transfer.createdAt,
        details: {
          'Recipient': transfer.recipientName,
          'Phone': transfer.recipientPhone,
          'They receive': Money.formatWithCurrency(current.receiveCents, current.receiveCurrency),
          'Paid out to': ecoCash ? 'EcoCash wallet, Zimbabwe' : 'Mobile wallet',
          'Exchange rate':
              '1 ${current.sendCurrency} = ${current.rate.toStringAsFixed(2)} ${current.receiveCurrency}',
          'Fee': Money.formatWithCurrency(current.feeCents, current.sendCurrency),
        },
      ));
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

  // ------------------------------------------------------------ scam shield

  ScamCheck checkRecipient({required String name, required String phone, required int cents}) {
    final normalized = _normalize(phone);
    final registered = DemoData.directory[normalized];
    final known = recentRecipients.any((r) => _normalize(r.phone) == normalized) ||
        _schedules.any((s) => _normalize(s.phone) == normalized);

    final warnings = <String>[];
    if (registered == null) {
      warnings.add('This number is not registered to a verified name.');
    } else if (!_namesMatch(registered, name)) {
      warnings.add('This number is registered to $registered, not ${name.trim()}.');
    }
    if (!known) warnings.add('You have never sent money to this number before.');
    if (cents >= largeAmountCents) {
      warnings.add('This is a large amount. Scammers often push for urgent, large payments.');
    }
    return ScamCheck(registeredName: registered, warnings: warnings);
  }

  // ---------------------------------------------- move money between accounts

  Future<Activity?> moveMoney({required String fromId, required String toId, required int cents}) async {
    if (fromId == toId) {
      error = 'Choose two different accounts';
      notifyListeners();
      return null;
    }
    final from = accountById(fromId);
    final to = accountById(toId);
    if (!offline && cents > from.balanceCents) {
      error = 'Not enough money in ${from.provider}';
      notifyListeners();
      return null;
    }
    final activity = Activity(
      id: newId(),
      kind: ActivityKind.move,
      title: '${from.provider} to ${to.provider}',
      subtitle: 'Between your accounts',
      amountCents: cents,
      category: 'Own accounts',
      createdAt: DateTime.now(),
      details: {
        'From': '${from.provider} ${from.masked}',
        'To': '${to.provider} ${to.masked}',
        'Fee': 'Free',
      },
    );
    return _run(activity, () {
      _debitAccount(fromId, cents);
      _creditAccount(toId, cents);
    });
  }

  void _debitAccount(String id, int cents) {
    if (id == walletId) {
      _repository.debit(cents);
      return;
    }
    final account = _accounts.firstWhere((a) => a.id == id);
    if (cents > account.balanceCents) throw InsufficientFundsException();
    account.balanceCents -= cents;
  }

  void _creditAccount(String id, int cents) {
    if (id == walletId) {
      _repository.credit(cents);
      return;
    }
    _accounts.firstWhere((a) => a.id == id).balanceCents += cents;
  }

  void linkAccount({required AccountType type, required String provider, required String number}) {
    _accounts.add(LinkedAccount(
      id: newId(),
      type: type,
      provider: provider,
      number: number,
      // Demo balance so the new account can be used straight away.
      balanceCents: 25000,
    ));
    notifyListeners();
  }

  // ---------------------------------------------------- pay for home (bills)

  Future<Activity?> payBill({
    required String category,
    required String biller,
    required String reference,
    required String beneficiary,
    required int cents,
  }) async {
    if (!offline && cents > balanceCents) {
      error = 'Your wallet balance is too low for this payment';
      notifyListeners();
      return null;
    }
    final details = {
      'Paid to': biller,
      'Reference': reference.trim(),
      'For': beneficiary.trim(),
      'Fee': 'Free',
    };
    if (category == 'Electricity') {
      details['Token'] = offline ? 'Issued when you are back online' : _token();
    }
    final activity = Activity(
      id: newId(),
      kind: ActivityKind.bill,
      title: biller,
      subtitle: '$category for ${beneficiary.trim()}',
      amountCents: cents,
      category: category,
      createdAt: DateTime.now(),
      details: details,
    );
    return _run(activity, () => _repository.debit(cents));
  }

  String _token() => List.generate(5, (_) => (_random.nextInt(9000) + 1000).toString()).join(' ');

  // ------------------------------------------------------- airtime and data

  /// Works out the mobile network from a Zimbabwe number.
  static String networkFor(String phone) {
    var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('263')) digits = '0${digits.substring(3)}';
    if (digits.startsWith('077') || digits.startsWith('078')) return 'Econet';
    if (digits.startsWith('071')) return 'NetOne';
    if (digits.startsWith('073')) return 'Telecel';
    return 'Unknown network';
  }

  Future<Activity?> buyAirtime({
    required String phone,
    required String item,
    required int cents,
    bool isData = false,
  }) async {
    if (!offline && cents > balanceCents) {
      error = 'Your wallet balance is too low for this purchase';
      notifyListeners();
      return null;
    }
    final network = networkFor(phone);
    final activity = Activity(
      id: newId(),
      kind: ActivityKind.airtime,
      title: isData ? '$network $item' : '$network airtime',
      subtitle: 'For ${phone.trim()}',
      amountCents: cents,
      category: 'Airtime',
      createdAt: DateTime.now(),
      details: {
        'Network': network,
        'Phone': phone.trim(),
        'Bought': item,
        'Status': offline ? 'Recharges when you are back online' : 'Recharged instantly',
        'Fee': 'Free',
      },
    );
    return _run(activity, () => _repository.debit(cents));
  }

  // ------------------------------------------------------ Mukando savings club

  Future<Activity?> contributeToClub(String clubId) async {
    final club = _clubs.firstWhere((c) => c.id == clubId);
    final you = club.you;
    if (you.paid) {
      error = 'You have already paid for this round';
      notifyListeners();
      return null;
    }
    if (!offline && club.contributionCents > balanceCents) {
      error = 'Your wallet balance is too low for this contribution';
      notifyListeners();
      return null;
    }
    final activity = Activity(
      id: newId(),
      kind: ActivityKind.savings,
      title: club.name,
      subtitle: 'Round ${club.round} contribution',
      amountCents: club.contributionCents,
      category: 'Mukando',
      createdAt: DateTime.now(),
      details: {
        'Club': club.name,
        'Round': '${club.round} of ${club.totalRounds}',
        'This round goes to': club.receiver.name,
        'Fee': 'Free',
      },
    );
    return _run(activity, () {
      _repository.debit(club.contributionCents);
      you.paid = true;
    });
  }

  /// Sends a reminder to everyone who has not paid. Returns how many.
  int remindUnpaid(String clubId) {
    final club = _clubs.firstWhere((c) => c.id == clubId);
    return club.members.where((m) => !m.paid && !m.isYou).length;
  }

  void createClub({required String name, required int cents, required List<String> memberNames}) {
    final now = DateTime.now();
    _clubs.add(SavingsClub(
      id: newId(),
      name: name.trim(),
      contributionCents: cents,
      payoutDate: DateTime(now.year, now.month + 1, 1),
      members: [
        ClubMember(name: 'You', isYou: true),
        for (final n in memberNames)
          if (n.trim().isNotEmpty) ClubMember(name: n.trim()),
      ],
    ));
    notifyListeners();
  }

  // ---------------------------------------------------------- scheduled sends

  void addSchedule({
    required String name,
    required String phone,
    required int cents,
    required int dayOfMonth,
    String note = '',
  }) {
    _schedules.add(ScheduledSend(
      id: newId(),
      name: name.trim(),
      phone: phone.trim(),
      amountCents: cents,
      dayOfMonth: dayOfMonth,
      note: note.trim(),
    ));
    notifyListeners();
  }

  void removeSchedule(String id) {
    _schedules.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  Future<Activity?> runSchedule(String id) async {
    final s = _schedules.firstWhere((s) => s.id == id);
    final fee = _fees.feeFor(s.amountCents);
    final total = s.amountCents + fee;
    if (!offline && total > balanceCents) {
      error = 'Your wallet balance is too low for this send';
      notifyListeners();
      return null;
    }
    final activity = Activity(
      id: newId(),
      kind: ActivityKind.scheduled,
      title: s.name,
      subtitle: s.note.isEmpty ? 'Scheduled send' : s.note,
      amountCents: total,
      feeCents: fee,
      category: 'Family',
      createdAt: DateTime.now(),
      details: {
        'Recipient': s.name,
        'Phone': s.phone,
        'Schedule': 'Every month on day ${s.dayOfMonth}',
        'Fee': Money.formatWithCurrency(fee, sendCurrency),
      },
    );
    return _run(activity, () => _repository.debit(total));
  }

  // ------------------------------------------------------------- insights

  Iterable<Activity> _spending(int days) {
    final since = DateTime.now().subtract(Duration(days: days));
    return _activities.where((a) =>
        a.status == ActivityStatus.completed &&
        a.kind != ActivityKind.move &&
        a.createdAt.isAfter(since));
  }

  /// Total spent per category in the last [days] days, biggest first.
  Map<String, int> spendingByCategory({int days = 30}) {
    final totals = <String, int>{};
    for (final a in _spending(days)) {
      totals[a.category] = (totals[a.category] ?? 0) + a.amountCents;
    }
    final sorted = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted);
  }

  int feesPaid({int days = 30}) => _spending(days).fold(0, (sum, a) => sum + a.feeCents);

  /// Money sent to family (without fees) in the last [days] days.
  int familySentCents({int days = 30}) => _spending(days)
      .where((a) => a.category == 'Family')
      .fold(0, (sum, a) => sum + a.amountCents - a.feeCents);

  // ---------------------------------------------------------------- helpers

  String newId() => 'EP${DateTime.now().millisecondsSinceEpoch}${_random.nextInt(900) + 100}';

  static String _normalize(String phone) => phone.replaceAll(RegExp(r'[^0-9+]'), '');

  static bool _namesMatch(String registered, String entered) {
    final words = registered.toLowerCase().split(' ');
    final typed = entered.trim().toLowerCase().split(RegExp(r'\s+'));
    return typed.isNotEmpty && typed.every(words.contains);
  }
}
