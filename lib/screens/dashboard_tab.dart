import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_provider.dart';
import '../state/wallet_provider.dart';
import '../theme/app_theme.dart';
import '../utils/money.dart';
import '../widgets/ui.dart';
import 'airtime_screen.dart';
import 'move_money_screen.dart';
import 'mukando_screen.dart';
import 'pay_bills_screen.dart';
import 'scheduled_screen.dart';
import 'send_money_screen.dart';

void openPage(BuildContext context, Widget page) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

/// Turns jay.mutore@mail.com into Jay.
String firstNameFrom(String? email) {
  if (email == null || email.isEmpty) return 'there';
  final word = email.split('@').first.split(RegExp(r'[._\-+0-9]')).firstWhere(
        (w) => w.isNotEmpty,
        orElse: () => 'there',
      );
  return word[0].toUpperCase() + word.substring(1);
}

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key, required this.onSeeAll});

  final VoidCallback onSeeAll;

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  bool _hideBalance = false;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final name = firstNameFrom(context.watch<AuthProvider>().email);
    final recent = wallet.activities.take(5).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        // Dark hero with greeting and the balance card
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: const BoxDecoration(
            gradient: AppGradients.hero,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: const BoxDecoration(gradient: AppGradients.brand, shape: BoxShape.circle),
                    child: CircleAvatar(
                      radius: 21,
                      backgroundColor: AppColors.midnight,
                      child: Text(name[0],
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_greeting(),
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
                        Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white)),
                      ],
                    ),
                  ),
                  _GlassIcon(
                    tooltip: wallet.offline ? 'Go online' : 'Simulate offline',
                    icon: wallet.offline ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
                    color: wallet.offline ? AppColors.warning : AppColors.mint,
                    onTap: () => wallet.setOffline(!wallet.offline),
                  ),
                  const SizedBox(width: 8),
                  _GlassIcon(
                    tooltip: 'Notifications',
                    icon: Icons.notifications_none_rounded,
                    color: Colors.white,
                    onTap: () => ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('You are all caught up'))),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              FadeSlideIn(
                child: _BalanceCard(
                  balanceCents: wallet.balanceCents,
                  offline: wallet.offline,
                  hidden: _hideBalance,
                  onToggle: () => setState(() => _hideBalance = !_hideBalance),
                ),
              ),
            ],
          ),
        ),

        if (wallet.offline)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: OfflineBanner(queued: wallet.queuedCount, onGoOnline: () => wallet.setOffline(false)),
          ),

        // Quick actions
        FadeSlideIn(
          order: 1,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: AppShadows.soft,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _QuickAction(
                        key: const Key('sendMoney'),
                        label: 'Send',
                        icon: Icons.public_rounded,
                        color: AppColors.blue,
                        onTap: () => openPage(context, const SendMoneyScreen()),
                      ),
                    ),
                    Expanded(
                      child: _QuickAction(
                        label: 'Move',
                        icon: Icons.swap_horiz_rounded,
                        color: AppColors.primary,
                        onTap: () => openPage(context, const MoveMoneyScreen()),
                      ),
                    ),
                    Expanded(
                      child: _QuickAction(
                        label: 'Pay bills',
                        icon: Icons.receipt_long_rounded,
                        color: AppColors.orange,
                        onTap: () => openPage(context, const PayBillsScreen()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _QuickAction(
                        label: 'Airtime',
                        icon: Icons.cell_tower_rounded,
                        color: AppColors.pink,
                        onTap: () => openPage(context, const AirtimeScreen()),
                      ),
                    ),
                    Expanded(
                      child: _QuickAction(
                        label: 'Mukando',
                        icon: Icons.groups_rounded,
                        color: AppColors.teal,
                        onTap: () => openPage(context, const MukandoScreen()),
                      ),
                    ),
                    Expanded(
                      child: _QuickAction(
                        label: 'Schedule',
                        icon: Icons.event_repeat_rounded,
                        color: AppColors.purple,
                        onTap: () => openPage(context, const ScheduledScreen()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SectionHeader('Your accounts'),
        FadeSlideIn(
          order: 2,
          child: SizedBox(
            height: 168,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              itemCount: wallet.linkedAccounts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, i) => AccountCard(account: wallet.linkedAccounts[i]),
            ),
          ),
        ),

        SectionHeader('Recent activity', action: 'See all', onAction: widget.onSeeAll),
        if (recent.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No activity yet. Tap Send to start.',
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
          )
        else
          FadeSlideIn(order: 3, child: ActivityList(items: recent)),
      ],
    );
  }
}

class _GlassIcon extends StatelessWidget {
  const _GlassIcon({required this.tooltip, required this.icon, required this.color, required this.onTap});

  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.white.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: SizedBox(width: 44, height: 44, child: Icon(icon, color: color, size: 22)),
          ),
        ),
      );
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.balanceCents,
    required this.offline,
    required this.hidden,
    required this.onToggle,
  });

  final int balanceCents;
  final bool offline;
  final bool hidden;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: AppGradients.brand,
        boxShadow: AppShadows.glow(AppColors.cyan),
      ),
      child: Stack(
        children: [
          Positioned(right: -60, top: -70, child: _Circle(size: 200, color: Colors.white.withValues(alpha: 0.12))),
          Positioned(left: -40, bottom: -90, child: _Circle(size: 180, color: Colors.white.withValues(alpha: 0.08))),
          Positioned(
            right: 20,
            bottom: 86,
            child: Icon(Icons.contactless_rounded, size: 30, color: Colors.white.withValues(alpha: 0.35)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 12, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Total balance',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: hidden ? 'Show balance' : 'Hide balance',
                      visualDensity: VisualDensity.compact,
                      onPressed: onToggle,
                      icon: Icon(
                        hidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: Colors.white.withValues(alpha: 0.85),
                        size: 20,
                      ),
                    ),
                    const Spacer(),
                    _LivePill(offline: offline),
                    const SizedBox(width: 10),
                  ],
                ),
                Text(
                  hidden ? 'USD ••••••' : Money.formatWithCurrency(balanceCents, WalletProvider.sendCurrency),
                  key: const Key('balance'),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text('EcoPay wallet · Available to send',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13)),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: _CardButton(
                          icon: Icons.add_rounded,
                          label: 'Add money',
                          onTap: () => openPage(context, const MoveMoneyScreen(toId: WalletProvider.walletId)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _CardButton(
                          icon: Icons.north_east_rounded,
                          label: 'Send',
                          solid: true,
                          onTap: () => openPage(context, const SendMoneyScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class _LivePill extends StatelessWidget {
  const _LivePill({required this.offline});

  final bool offline;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: offline ? AppColors.warning : AppColors.mint,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(offline ? 'Offline' : 'Live',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

class _CardButton extends StatelessWidget {
  const _CardButton({required this.icon, required this.label, required this.onTap, this.solid = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final fg = solid ? AppColors.midnight : Colors.white;
    return Material(
      color: solid ? Colors.white : Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fg, size: 19),
              const SizedBox(width: 6),
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppGradients.of(color),
                  borderRadius: BorderRadius.circular(19),
                  boxShadow: AppShadows.glow(color),
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(height: 10),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
            ],
          ),
        ),
      );
}
