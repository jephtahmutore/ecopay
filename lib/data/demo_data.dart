import '../models/activity.dart';
import '../models/linked_account.dart';
import '../models/savings_club.dart';
import '../models/scheduled_send.dart';

/// Realistic sample data so the app never looks empty in a demo.
/// Starting balances here do not change the wallet balance.
class DemoData {
  DemoData._();

  /// Simulated name lookup, like the network check a mobile operator does.
  static const directory = {
    '+263771234567': 'Tendai Moyo',
    '+263772345678': 'Rudo Chikwanha',
    '+27821234567': 'Farai Ndlovu',
    '+263714455667': 'Nyasha Banda',
  };

  static const billers = {
    'School fees': ['Sunrise Academy', 'Greenfield Primary', 'Eastern Highlands College'],
    'Electricity': ['ZESA prepaid'],
    'Groceries': ['FreshMart vouchers', 'Village Market'],
    'Medical': ['City Clinic', 'Hope Pharmacy'],
  };

  static List<LinkedAccount> accounts() => [
        LinkedAccount(
          id: 'cbz',
          type: AccountType.bank,
          provider: 'CBZ Bank',
          number: '4500214821',
          balanceCents: 124000,
        ),
        LinkedAccount(
          id: 'ecocash',
          type: AccountType.mobile,
          provider: 'EcoCash',
          number: '0771234567',
          balanceCents: 8640,
        ),
        LinkedAccount(
          id: 'stanbic',
          type: AccountType.bank,
          provider: 'Stanbic Bank',
          number: '9140030937',
          balanceCents: 31075,
        ),
      ];

  static List<ScheduledSend> schedules() => const [
        ScheduledSend(
          id: 'demo-schedule',
          name: 'Rudo Chikwanha',
          phone: '+263772345678',
          amountCents: 8000,
          dayOfMonth: 25,
          note: 'Monthly groceries for Mum',
        ),
      ];

  static List<SavingsClub> clubs() {
    final now = DateTime.now();
    return [
      SavingsClub(
        id: 'demo-club',
        name: 'Family Mukando',
        contributionCents: 5000,
        round: 3,
        payoutDate: DateTime(now.year, now.month + 1, 1),
        members: [
          ClubMember(name: 'Chipo Moyo', paid: true),
          ClubMember(name: 'Tendai Moyo', paid: true),
          ClubMember(name: 'Rudo Chikwanha', paid: true),
          ClubMember(name: 'You', isYou: true),
          ClubMember(name: 'Farai Ndlovu'),
        ],
      ),
    ];
  }

  static List<Activity> activities() {
    final now = DateTime.now();
    DateTime ago(int days, [int hours = 0]) => now.subtract(Duration(days: days, hours: hours));

    return [
      Activity(
        id: 'EP1001',
        kind: ActivityKind.sendAbroad,
        title: 'Tendai Moyo',
        subtitle: 'Sent to +263771234567',
        amountCents: 10350,
        feeCents: 350,
        category: 'Family',
        createdAt: ago(1, 3),
        details: const {
          'Recipient': 'Tendai Moyo',
          'Phone': '+263771234567',
          'They receive': 'ZAR 1,825.00',
          'Fee': 'USD 3.50',
        },
      ),
      Activity(
        id: 'EP1002',
        kind: ActivityKind.bill,
        title: 'ZESA prepaid',
        subtitle: 'Electricity for Gogo',
        amountCents: 2500,
        category: 'Electricity',
        createdAt: ago(3),
        details: const {
          'Paid to': 'ZESA prepaid',
          'Reference': '37141234567',
          'For': 'Gogo',
          'Token': '4821 0937 5512 6604 2219',
          'Fee': 'Free',
        },
      ),
      Activity(
        id: 'EP1010',
        kind: ActivityKind.airtime,
        title: 'Econet airtime',
        subtitle: 'For 0772345678',
        amountCents: 500,
        category: 'Airtime',
        createdAt: ago(2, 5),
        details: const {
          'Network': 'Econet',
          'Phone': '0772345678',
          'Bought': 'Airtime',
          'Status': 'Recharged instantly',
          'Fee': 'Free',
        },
      ),
      Activity(
        id: 'EP1011',
        kind: ActivityKind.savings,
        title: 'Family Mukando',
        subtitle: 'Round 2 contribution',
        amountCents: 5000,
        category: 'Mukando',
        createdAt: ago(20),
        details: const {'Club': 'Family Mukando', 'Round': '2 of 5', 'Fee': 'Free'},
      ),
      Activity(
        id: 'EP1003',
        kind: ActivityKind.move,
        title: 'CBZ Bank to EcoPay wallet',
        subtitle: 'Between your accounts',
        amountCents: 30000,
        category: 'Own accounts',
        createdAt: ago(5),
        details: const {'From': 'CBZ Bank •••• 4821', 'To': 'EcoPay wallet', 'Fee': 'Free'},
      ),
      Activity(
        id: 'EP1004',
        kind: ActivityKind.bill,
        title: 'Sunrise Academy',
        subtitle: 'School fees for Tariro',
        amountCents: 15000,
        category: 'School fees',
        createdAt: ago(8),
        details: const {
          'Paid to': 'Sunrise Academy',
          'Reference': 'Student SA2291',
          'For': 'Tariro',
          'Fee': 'Free',
        },
      ),
      Activity(
        id: 'EP1005',
        kind: ActivityKind.bill,
        title: 'FreshMart vouchers',
        subtitle: 'Groceries for Mum',
        amountCents: 4000,
        category: 'Groceries',
        createdAt: ago(12),
        details: const {
          'Paid to': 'FreshMart vouchers',
          'Reference': '+263772345678',
          'For': 'Mum',
          'Fee': 'Free',
        },
      ),
      Activity(
        id: 'EP1006',
        kind: ActivityKind.sendAbroad,
        title: 'Farai Ndlovu',
        subtitle: 'Sent to +27821234567',
        amountCents: 5250,
        feeCents: 250,
        category: 'Family',
        createdAt: ago(16),
        details: const {
          'Recipient': 'Farai Ndlovu',
          'Phone': '+27821234567',
          'They receive': 'ZAR 912.50',
          'Fee': 'USD 2.50',
        },
      ),
      Activity(
        id: 'EP1007',
        kind: ActivityKind.scheduled,
        title: 'Rudo Chikwanha',
        subtitle: 'Monthly groceries for Mum',
        amountCents: 8310,
        feeCents: 310,
        category: 'Family',
        createdAt: ago(27),
        details: const {
          'Recipient': 'Rudo Chikwanha',
          'Phone': '+263772345678',
          'Schedule': 'Every month on day 25',
          'Fee': 'USD 3.10',
        },
      ),
    ];
  }
}
