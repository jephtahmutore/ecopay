import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/linked_account.dart';
import '../state/wallet_provider.dart';
import '../theme/app_theme.dart';
import '../utils/money.dart';
import '../widgets/ui.dart';

/// Moves money between the EcoPay wallet, banks and mobile money,
/// in any direction.
class MoveMoneyScreen extends StatefulWidget {
  const MoveMoneyScreen({super.key, this.fromId, this.toId});

  final String? fromId;
  final String? toId;

  @override
  State<MoveMoneyScreen> createState() => _MoveMoneyScreenState();
}

class _MoveMoneyScreenState extends State<MoveMoneyScreen> {
  late String _from;
  late String _to;
  final _amount = TextEditingController();

  @override
  void initState() {
    super.initState();
    final wallet = context.read<WalletProvider>();
    final ids = wallet.allAccounts.map((a) => a.id).toList();
    _to = widget.toId ?? WalletProvider.walletId;
    _from = widget.fromId ?? ids.firstWhere((id) => id != _to, orElse: () => ids.first);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<WalletProvider>().clearError();
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pick({required bool isFrom}) async {
    final wallet = context.read<WalletProvider>();
    final current = isFrom ? _from : _to;
    final id = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(isFrom ? 'Move from' : 'Move to',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            for (final a in wallet.allAccounts)
              ListTile(
                leading: AccountBadge(account: a, size: 40),
                title: Text(a.provider, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${a.masked} · ${Money.formatWithCurrency(a.balanceCents, 'USD')}'),
                trailing: a.id == current ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                onTap: () => Navigator.of(ctx).pop(a.id),
              ),
          ],
        ),
      ),
    );
    if (id == null || !mounted) return;
    setState(() {
      if (isFrom) {
        if (id == _to) _to = _from;
        _from = id;
      } else {
        if (id == _from) _from = _to;
        _to = id;
      }
    });
  }

  Future<void> _submit() async {
    final cents = Money.parseToCents(_amount.text);
    if (cents == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter an amount above zero')));
      return;
    }
    final activity =
        await context.read<WalletProvider>().moveMoney(fromId: _from, toId: _to, cents: cents);
    if (!mounted || activity == null) return;
    await showReceipt(context, activity);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final from = wallet.accountById(_from);
    final to = wallet.accountById(_to);

    return Scaffold(
      appBar: AppBar(title: const Text('Move money')),
      body: PageWidth(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Bank, EcoCash and your EcoPay wallet, in any direction.',
                style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 16),
            _AccountPicker(label: 'From', account: from, onTap: () => _pick(isFrom: true)),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: IconButton.filledTonal(
                  tooltip: 'Swap',
                  icon: const Icon(Icons.swap_vert),
                  onPressed: () => setState(() {
                    final t = _from;
                    _from = _to;
                    _to = t;
                  }),
                ),
              ),
            ),
            _AccountPicker(label: 'To', account: to, onTap: () => _pick(isFrom: false)),
            const SizedBox(height: 20),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(labelText: 'Amount', prefixText: 'USD '),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                for (final v in [10, 20, 50, 100])
                  ActionChip(label: Text('USD $v'), onPressed: () => setState(() => _amount.text = '$v')),
              ],
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.bolt, size: 18, color: AppColors.primary),
                SizedBox(width: 6),
                Expanded(
                  child: Text('Free and instant between your own accounts',
                      style: TextStyle(color: AppColors.muted, fontSize: 13)),
                ),
              ],
            ),
            if (wallet.error != null) ErrorText(wallet.error!),
            const SizedBox(height: 20),
            GradientButton(
              onPressed: wallet.loading ? null : _submit,
              child: wallet.loading
                  ? const ButtonSpinner()
                  : Text(wallet.offline ? 'Queue transfer' : 'Move money'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountPicker extends StatelessWidget {
  const _AccountPicker({required this.label, required this.account, required this.onTap});

  final String label;
  final LinkedAccount account;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppCard(
        onTap: onTap,
        child: Row(
          children: [
            AccountBadge(account: account),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  Text(account.provider,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.ink)),
                  Text('${account.masked} · ${Money.formatWithCurrency(account.balanceCents, 'USD')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.expand_more, color: AppColors.muted),
          ],
        ),
      );
}
