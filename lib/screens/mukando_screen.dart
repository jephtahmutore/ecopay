import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/savings_club.dart';
import '../state/wallet_provider.dart';
import '../theme/app_theme.dart';
import '../utils/dates.dart';
import '../utils/money.dart';
import '../widgets/ui.dart';

const _clubGradient = LinearGradient(
  colors: [Color(0xFF0F766E), Color(0xFF14B8A6), Color(0xFF6366F1)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

/// Mukando: a rotating savings club. Everyone pays each round and one
/// member, in turn, receives the whole pot.
class MukandoScreen extends StatelessWidget {
  const MukandoScreen({super.key});

  void _newClub(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.sheet,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => const _NewClubSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();

    return GlassScaffold(
      appBar: AppBar(title: const Text('Mukando')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newClub(context),
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.group_add_rounded),
        label: const Text('New club'),
      ),
      body: PageWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
          children: [
            const Text(
              'Save together with family and friends. Everyone pays each round, '
              'and the pot goes to one member in turn. Every payment is recorded, so nobody is forgotten.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            for (final club in wallet.clubs) ...[
              FadeSlideIn(child: _ClubCard(club: club)),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }
}

class _ClubCard extends StatelessWidget {
  const _ClubCard({required this.club});

  final SavingsClub club;

  Future<void> _pay(BuildContext context) async {
    final wallet = context.read<WalletProvider>();
    final activity = await wallet.contributeToClub(club.id);
    if (!context.mounted) return;
    if (activity == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(wallet.error ?? 'Could not pay')));
      return;
    }
    await showReceipt(context, activity);
  }

  void _remind(BuildContext context) {
    final count = context.read<WalletProvider>().remindUnpaid(club.id);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(count == 0
          ? 'Everyone else has paid'
          : 'Friendly reminder sent to $count member${count == 1 ? '' : 's'}'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final you = club.you;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Summary card
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: _clubGradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: AppShadows.glow(AppColors.teal),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -40,
                top: -40,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.groups_rounded, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(club.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('Round ${club.round} of ${club.totalRounds}',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text('This round\'s pot', style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
                    Text(Money.formatWithCurrency(club.potCents, 'USD'),
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: club.collectedCents / club.potCents,
                        minHeight: 10,
                        color: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${Money.formatWithCurrency(club.collectedCents, 'USD')} collected · '
                      '${club.paidCount} of ${club.members.length} paid',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.emoji_events_rounded, color: Color(0xFFFDE68A)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${club.receiver.isYou ? 'You receive' : '${club.receiver.name} receives'} '
                              'the pot on ${Dates.short(club.payoutDate)}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
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
        ),
        const SizedBox(height: 14),

        // Members
        Glass(
          child: Material(
            type: MaterialType.transparency,
            child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              for (var i = 0; i < club.members.length; i++) ...[
                if (i > 0) const Divider(indent: 72, endIndent: 16),
                _MemberRow(
                  member: club.members[i],
                  order: i + 1,
                  isReceiver: club.members[i] == club.receiver,
                ),
              ],
            ],
          ),
        ),
          ),
          ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _remind(context),
                icon: const Icon(Icons.notifications_active_outlined, size: 18),
                label: const Text('Remind'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: GradientButton(
                gradient: _clubGradient,
                onPressed: you.paid || wallet.loading ? null : () => _pay(context),
                child: Text(you.paid
                    ? 'You have paid'
                    : 'Pay ${Money.formatWithCurrency(club.contributionCents, 'USD')}'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.order, required this.isReceiver});

  final ClubMember member;
  final int order;
  final bool isReceiver;

  @override
  Widget build(BuildContext context) {
    final initials = member.name.split(' ').where((w) => w.isNotEmpty).take(2).map((w) => w[0]).join();
    final statusColor = member.paid ? AppColors.primary : AppColors.warning;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: member.isYou ? AppColors.teal : AppColors.teal.withValues(alpha: 0.14),
                child: Text(initials,
                    style: TextStyle(
                      color: member.isYou ? Colors.white : AppColors.teal,
                      fontWeight: FontWeight.w800,
                    )),
              ),
              if (isReceiver)
                const Positioned(
                  right: -4,
                  top: -6,
                  child: Icon(Icons.emoji_events_rounded, size: 18, color: AppColors.warning),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                Text(isReceiver ? 'Receives this round' : 'Payout turn $order',
                    style: const TextStyle(color: AppColors.muted, fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(member.paid ? Icons.check_circle_rounded : Icons.schedule_rounded, size: 14, color: statusColor),
                const SizedBox(width: 4),
                Text(member.paid ? 'Paid' : 'Pending',
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NewClubSheet extends StatefulWidget {
  const _NewClubSheet();

  @override
  State<_NewClubSheet> createState() => _NewClubSheetState();
}

class _NewClubSheetState extends State<_NewClubSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _members = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _members.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.read<WalletProvider>().createClub(
          name: _name.text,
          cents: Money.parseToCents(_amount.text)!,
          memberNames: _members.text.split(','),
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Start a Mukando',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Club name', prefixIcon: Icon(Icons.groups_rounded)),
                validator: (v) => (v == null || v.trim().length < 2) ? 'Enter a name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Each person pays per round', prefixText: 'USD '),
                validator: (v) => Money.parseToCents(v ?? '') == null ? 'Enter an amount above zero' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _members,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Members, separated by commas',
                  hintText: 'Chipo, Tendai, Rudo',
                  prefixIcon: Icon(Icons.person_add_alt_rounded),
                ),
                validator: (v) =>
                    (v ?? '').split(',').where((n) => n.trim().isNotEmpty).isEmpty ? 'Add at least one member' : null,
              ),
              const SizedBox(height: 20),
              GradientButton(gradient: _clubGradient, onPressed: _save, child: const Text('Create club')),
            ],
          ),
        ),
      ),
    );
  }
}
