import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/linked_account.dart';
import '../state/auth_provider.dart';
import '../state/wallet_provider.dart';
import '../theme/app_theme.dart';
import '../utils/money.dart';
import '../widgets/ui.dart';
import 'dashboard_tab.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final wallet = context.watch<WalletProvider>();
    final name = firstNameFrom(auth.email);

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        const PageTitle('Profile'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: AppCard(
            gradient: AppGradients.hero,
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(gradient: AppGradients.brand, shape: BoxShape.circle),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.midnight,
                    child: Text(name[0],
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                      Text(auth.email ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.65))),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.mint.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_rounded, size: 14, color: AppColors.mint),
                            SizedBox(width: 4),
                            Text('Verified account',
                                style: TextStyle(color: AppColors.mint, fontSize: 12, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SectionHeader('Safety and network'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AppCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                SwitchListTile(
                  value: auth.appLockEnabled,
                  onChanged: auth.setAppLock,
                  secondary: const Icon(Icons.lock_outline_rounded),
                  title: const Text('App lock'),
                  subtitle: const Text('Ask for your PIN when you come back to the app'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.lock_clock_outlined),
                  title: const Text('Lock now'),
                  subtitle: const Text('Try the lock screen'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  enabled: auth.appLockEnabled,
                  onTap: auth.lock,
                ),
                const Divider(),
                SwitchListTile(
                  value: wallet.scamShield,
                  onChanged: wallet.setScamShield,
                  secondary: const Icon(Icons.shield_outlined),
                  title: const Text('Scam shield'),
                  subtitle: const Text('Check names and warn before risky payments'),
                ),
                const Divider(),
                SwitchListTile(
                  value: wallet.offline,
                  onChanged: (v) => wallet.setOffline(v),
                  secondary: const Icon(Icons.cloud_off_outlined),
                  title: const Text('Offline mode (demo)'),
                  subtitle: const Text('Queue payments and send them when the network returns'),
                ),
              ],
            ),
          ),
        ),
        SectionHeader('Linked accounts', action: 'Link new', onAction: () => _linkAccount(context)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AppCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (final a in wallet.linkedAccounts)
                  ListTile(
                    leading: AccountBadge(account: a, size: 42),
                    title: Text(a.provider, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(a.masked),
                    trailing: Text(Money.formatWithCurrency(a.balanceCents, 'USD'),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: OutlinedButton.icon(
            onPressed: () => context.read<AuthProvider>().signOut(),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
        ),
      ],
    );
  }

  void _linkAccount(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => const _LinkAccountSheet(),
    );
  }
}

class _LinkAccountSheet extends StatefulWidget {
  const _LinkAccountSheet();

  @override
  State<_LinkAccountSheet> createState() => _LinkAccountSheetState();
}

class _LinkAccountSheetState extends State<_LinkAccountSheet> {
  static const _providers = {
    AccountType.bank: ['CBZ Bank', 'Stanbic Bank', 'FBC Bank', 'Steward Bank'],
    AccountType.mobile: ['EcoCash', 'OneMoney', 'InnBucks'],
  };

  AccountType _type = AccountType.bank;
  String _provider = 'CBZ Bank';
  final _number = TextEditingController();

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  void _save() {
    final number = _number.text.replaceAll(' ', '');
    if (number.length < 6) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter the full account or phone number')));
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    context.read<WalletProvider>().linkAccount(type: _type, provider: _provider, number: number);
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text('$_provider linked')));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Link an account',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 16),
          SegmentedButton<AccountType>(
            segments: const [
              ButtonSegment(value: AccountType.bank, label: Text('Bank'), icon: Icon(Icons.account_balance)),
              ButtonSegment(value: AccountType.mobile, label: Text('Mobile money'), icon: Icon(Icons.phone_iphone)),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() {
              _type = s.first;
              _provider = _providers[_type]!.first;
            }),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in _providers[_type]!)
                ChoiceChip(
                  label: Text(p),
                  selected: p == _provider,
                  showCheckmark: false,
                                    onSelected: (_) => setState(() => _provider = p),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _number,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: _type == AccountType.bank ? 'Account number' : 'Phone number',
              prefixIcon: const Icon(Icons.numbers),
            ),
          ),
          const SizedBox(height: 20),
          GradientButton(onPressed: _save, child: const Text('Link account')),
        ],
      ),
    );
  }
}
