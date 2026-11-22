import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/insights.dart';
import '../state/auth_provider.dart';
import '../state/wallet_provider.dart';
import '../theme/app_theme.dart';
import '../utils/money.dart';
import '../widgets/glass.dart';
import '../widgets/transfer_tile.dart';
import 'airtime_screen.dart';
import 'receipt_screen.dart';
import 'send_money_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static String greetingFor(DateTime now) {
    if (now.hour < 12) return 'Good morning';
    if (now.hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _openSend(BuildContext context, [SavedRecipient? recipient]) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => SendMoneyScreen(recipient: recipient)),
    );
  }

  void _openAirtime(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AirtimeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final auth = context.watch<AuthProvider>();
    final text = Theme.of(context).textTheme;
    final recipients = wallet.savedRecipients;

    return GlassScaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [AppColors.cyan, AppColors.violet]),
                  ),
                  child: Text(
                    (auth.email ?? '').isEmpty ? '?' : auth.email!.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(greetingFor(DateTime.now()), style: const TextStyle(color: AppColors.muted)),
                      Text(
                        auth.email ?? '',
                        overflow: TextOverflow.ellipsis,
                        style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Sign out',
                  icon: const Icon(Icons.logout),
                  onPressed: () => context.read<AuthProvider>().signOut(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Balance
            GlassCard(
              tint: AppColors.cyan,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.account_balance_wallet_outlined, size: 18, color: AppColors.muted),
                      SizedBox(width: 6),
                      Text('Wallet balance', style: TextStyle(color: AppColors.muted)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    Money.formatWithCurrency(wallet.balanceCents, WalletProvider.sendCurrency),
                    key: const Key('balance'),
                    style: text.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          key: const Key('sendMoney'),
                          icon: Icons.send_rounded,
                          label: 'Send money',
                          color: AppColors.cyan,
                          onTap: () => _openSend(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickAction(
                          key: const Key('buyAirtime'),
                          icon: Icons.phone_android_rounded,
                          label: 'Econet airtime',
                          color: AppColors.mint,
                          onTap: () => _openAirtime(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _InsightsCard(insights: wallet.insights),

            if (recipients.isNotEmpty) ...[
              const SizedBox(height: 24),
              const _SectionTitle('Send again'),
              const SizedBox(height: 12),
              SizedBox(
                height: 92,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: recipients.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, i) => _RecipientChip(
                    recipient: recipients[i],
                    onTap: () => _openSend(context, recipients[i]),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),
            const _SectionTitle('Recent activity'),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: wallet.transfers.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 40, color: AppColors.faint),
                          SizedBox(height: 8),
                          Text(
                            'No transfers yet. Tap Send money to start.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.muted),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        for (final t in wallet.transfers)
                          TransferTile(
                            transfer: t,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(builder: (_) => ReceiptScreen(transfer: t)),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      onTap: onTap,
      child: Row(
        children: [
          GlassIconBadge(icon: icon, color: color, size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Feature: monthly spending insights.
class _InsightsCard extends StatelessWidget {
  const _InsightsCard({required this.insights});

  final SpendingInsights insights;

  @override
  Widget build(BuildContext context) {
    Widget stat(String label, int cents, Color color) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '\$${Money.format(cents)}',
                  style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ],
          ),
        );

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const GlassIconBadge(icon: Icons.insights_rounded, color: AppColors.violet, size: 36),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('This month', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              Text(
                '${insights.transferCount} transfer${insights.transferCount == 1 ? '' : 's'}',
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              stat('Sent', insights.sentCents, AppColors.cyan),
              stat('Fees', insights.feesCents, AppColors.amber),
              stat('Airtime', insights.airtimeCents, AppColors.mint),
            ],
          ),
          if (insights.topCountry != null) ...[
            const SizedBox(height: 12),
            Text(
              'You send most to ${insights.topCountry}',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

/// Feature: saved recipients for one tap repeat transfers.
class _RecipientChip extends StatelessWidget {
  const _RecipientChip({required this.recipient, required this.onTap});

  final SavedRecipient recipient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final firstName = recipient.name.split(' ').first;
    return SizedBox(
      width: 76,
      child: GlassCard(
        radius: 20,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.cyan.withValues(alpha: 0.2),
              child: Text(
                recipient.initials,
                style: const TextStyle(color: AppColors.cyan, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              firstName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
