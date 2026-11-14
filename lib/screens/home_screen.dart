import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_provider.dart';
import '../state/wallet_provider.dart';
import '../utils/money.dart';
import '../widgets/transfer_tile.dart';
import 'send_money_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final auth = context.watch<AuthProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('EcoPay'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('sendMoney'),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const SendMoneyScreen()),
        ),
        icon: const Icon(Icons.send),
        label: const Text('Send money'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hello, ${auth.email ?? ''}', style: TextStyle(color: scheme.onPrimary)),
                const SizedBox(height: 12),
                Text('Wallet balance', style: TextStyle(color: scheme.onPrimary)),
                Text(
                  Money.formatWithCurrency(wallet.balanceCents, WalletProvider.sendCurrency),
                  key: const Key('balance'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: scheme.onPrimary),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Recent transfers', style: Theme.of(context).textTheme.titleMedium),
          ),
          if (wallet.transfers.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No transfers yet. Tap Send money to start.', textAlign: TextAlign.center),
            )
          else
            ...wallet.transfers.map((t) => TransferTile(transfer: t)),
        ],
      ),
    );
  }
}
