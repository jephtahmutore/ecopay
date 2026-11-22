import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/wallet_provider.dart';
import '../theme/app_theme.dart';
import '../utils/money.dart';
import '../widgets/ui.dart';

/// Buy airtime or data for yourself or family, on any Zimbabwe network.
class AirtimeScreen extends StatefulWidget {
  const AirtimeScreen({super.key});

  @override
  State<AirtimeScreen> createState() => _AirtimeScreenState();
}

class _AirtimeScreenState extends State<AirtimeScreen> {
  static const _amounts = [100, 200, 500, 1000, 2000];
  static const _bundles = [
    (name: 'Daily 250 MB', validity: '24 hours', cents: 50, icon: Icons.today_rounded),
    (name: 'Weekly 1 GB', validity: '7 days', cents: 200, icon: Icons.date_range_rounded),
    (name: 'Monthly 5 GB', validity: '30 days', cents: 800, icon: Icons.calendar_month_rounded),
    (name: 'WhatsApp monthly', validity: '30 days', cents: 150, icon: Icons.chat_rounded),
    (name: 'Social 2 GB', validity: '30 days', cents: 300, icon: Icons.groups_2_rounded),
  ];

  final _phone = TextEditingController();
  bool _data = false;
  int _amount = 500;
  int _bundle = 1;

  @override
  void initState() {
    super.initState();
    _phone.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<WalletProvider>().clearError();
    });
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _buy() async {
    final digits = _phone.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid phone number')));
      return;
    }
    final bundle = _bundles[_bundle];
    final activity = await context.read<WalletProvider>().buyAirtime(
          phone: _phone.text,
          item: _data ? '${bundle.name} (${bundle.validity})' : 'Airtime',
          cents: _data ? bundle.cents : _amount,
          isData: _data,
        );
    if (!mounted || activity == null) return;
    await showReceipt(context, activity);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final network = _phone.text.trim().isEmpty ? null : WalletProvider.networkFor(_phone.text);
    final myNumber = wallet.linkedAccounts
        .where((a) => a.provider == 'EcoCash')
        .map((a) => a.number)
        .firstOrNull;
    final price = _data ? _bundles[_bundle].cents : _amount;

    return GlassScaffold(
      appBar: AppBar(title: const Text('Airtime and data')),
      body: PageWidth(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Hero
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)]),
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppShadows.glow(AppColors.pink),
              ),
              child: const Row(
                children: [
                  Icon(Icons.cell_tower_rounded, color: Colors.white, size: 36),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Top up anyone, instantly',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
                        Text('Econet, NetOne and Telecel. Send airtime home from anywhere.',
                            style: TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Airtime'), icon: Icon(Icons.phone_in_talk_rounded)),
                ButtonSegment(value: true, label: Text('Data'), icon: Icon(Icons.wifi_rounded)),
              ],
              selected: {_data},
              onSelectionChanged: (s) => setState(() => _data = s.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone number',
                prefixIcon: const Icon(Icons.phone_iphone_rounded),
                suffixIcon: network == null
                    ? null
                    : Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: _NetworkPill(network: network),
                      ),
                suffixIconConstraints: const BoxConstraints(minHeight: 32),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (myNumber != null)
                  ActionChip(
                    avatar: const Icon(Icons.person_rounded, size: 18),
                    label: const Text('My number'),
                    onPressed: () => _phone.text = myNumber,
                  ),
                for (final r in wallet.recentRecipients.where((r) => !r.phone.startsWith('+27')).take(3))
                  ActionChip(
                    label: Text(r.name.split(' ').first),
                    onPressed: () => _phone.text = r.phone,
                  ),
              ],
            ),
            const SizedBox(height: 20),
            if (!_data) ...[
              const Text('Amount', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final a in _amounts)
                    ChoiceChip(
                      label: Text(Money.formatWithCurrency(a, 'USD')),
                      selected: a == _amount,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _amount = a),
                    ),
                ],
              ),
            ] else ...[
              const Text('Choose a bundle', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
              const SizedBox(height: 10),
              for (var i = 0; i < _bundles.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _BundleTile(
                    name: _bundles[i].name,
                    validity: _bundles[i].validity,
                    cents: _bundles[i].cents,
                    icon: _bundles[i].icon,
                    selected: i == _bundle,
                    onTap: () => setState(() => _bundle = i),
                  ),
                ),
            ],
            if (wallet.error != null) ErrorText(wallet.error!),
            const SizedBox(height: 20),
            GradientButton(
              onPressed: wallet.loading ? null : _buy,
              child: wallet.loading
                  ? const ButtonSpinner()
                  : Text('${wallet.offline ? 'Queue' : 'Buy'} ${Money.formatWithCurrency(price, 'USD')}'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NetworkPill extends StatelessWidget {
  const _NetworkPill({required this.network});

  final String network;

  @override
  Widget build(BuildContext context) {
    final color = switch (network) {
      'Econet' => AppColors.blue,
      'NetOne' => AppColors.orange,
      'Telecel' => AppColors.danger,
      _ => AppColors.muted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(network, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}

class _BundleTile extends StatelessWidget {
  const _BundleTile({
    required this.name,
    required this.validity,
    required this.cents,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final String validity;
  final int cents;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.pink.withValues(alpha: 0.16) : AppColors.glass,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.pink : AppColors.border, width: selected ? 2 : 1),
          boxShadow: selected ? AppShadows.glow(AppColors.pink) : null,
        ),
        child: Row(
          children: [
            IconBadge(look: (icon: icon, color: AppColors.pink), size: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
                  Text('Valid for $validity', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                ],
              ),
            ),
            Text(Money.formatWithCurrency(cents, 'USD'),
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(width: 8),
            Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                color: selected ? AppColors.pink : AppColors.muted),
          ],
        ),
      ),
    );
  }
}
