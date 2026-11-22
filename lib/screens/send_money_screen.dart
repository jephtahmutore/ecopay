import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/quote.dart';
import '../state/wallet_provider.dart';
import '../theme/app_theme.dart';
import '../utils/money.dart';
import '../widgets/ui.dart';

class SendMoneyScreen extends StatefulWidget {
  const SendMoneyScreen({super.key});

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _amount = TextEditingController();
  String _currency = WalletProvider.receiveCurrencies.first;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<WalletProvider>().clearQuote();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _getQuote() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<WalletProvider>().getQuote(
          sendCents: Money.parseToCents(_amount.text)!,
          receiveCurrency: _currency,
        );
  }

  Future<void> _confirm() async {
    final wallet = context.read<WalletProvider>();
    final quote = wallet.quote;
    if (quote == null) return;

    if (wallet.scamShield) {
      final check = wallet.checkRecipient(name: _name.text, phone: _phone.text, cents: quote.sendCents);
      if (!check.isSafe) {
        final go = await showScamShield(context, check);
        if (go != true || !mounted) return;
      }
    }

    final transfer = await wallet.confirm(recipientName: _name.text, recipientPhone: _phone.text);
    if (!mounted || transfer == null) return;
    final activity = wallet.activityById(transfer.id);
    if (activity != null) await showReceipt(context, activity);
    if (mounted) Navigator.of(context).pop();
  }

  void _fill(({String name, String phone}) r) {
    _name.text = r.name;
    _phone.text = r.phone;
    context.read<WalletProvider>().clearQuote();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final quote = wallet.quote;
    final recents = wallet.recentRecipients;

    return Scaffold(
      appBar: AppBar(title: const Text('Send money')),
      body: PageWidth(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (recents.isNotEmpty) ...[
                const Text('Recent', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 86,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: recents.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => _RecipientBubble(
                      name: recents[i].name,
                      onTap: () => _fill(recents[i]),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                key: const Key('recipientName'),
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Recipient full name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => (v == null || v.trim().length < 2) ? 'Enter the recipient name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('recipientPhone'),
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone, with country code',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (v) => RegExp(r'^\+?\d{9,15}$').hasMatch((v ?? '').replaceAll(' ', ''))
                    ? null
                    : 'Enter a valid phone number',
              ),
              const SizedBox(height: 16),
              const Text('They receive in', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in WalletProvider.receiveCurrencies)
                    ChoiceChip(
                      label: Text(c),
                      selected: c == _currency,
                      showCheckmark: false,
                                            onSelected: (_) {
                        setState(() => _currency = c);
                        context.read<WalletProvider>().clearQuote();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('amount'),
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                decoration: const InputDecoration(labelText: 'You send', prefixText: 'USD '),
                onChanged: (_) => context.read<WalletProvider>().clearQuote(),
                validator: (v) => Money.parseToCents(v ?? '') == null ? 'Enter an amount above zero' : null,
              ),
              if (wallet.error != null) ErrorText(wallet.error!),
              if (quote != null) ...[
                const SizedBox(height: 16),
                _QuoteCard(quote: quote),
              ],
              const SizedBox(height: 20),
              if (quote == null)
                GradientButton(
                  key: const Key('getQuote'),
                  onPressed: wallet.loading ? null : _getQuote,
                  child: wallet.loading ? const ButtonSpinner() : const Text('Get quote'),
                )
              else
                GradientButton(
                  key: const Key('confirm'),
                  onPressed: wallet.loading ? null : _confirm,
                  child: wallet.loading
                      ? const ButtonSpinner()
                      : Text('Send ${Money.formatWithCurrency(quote.totalCents, quote.sendCurrency)}'),
                ),
              if (wallet.scamShield) ...[
                const SizedBox(height: 12),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shield_outlined, size: 16, color: AppColors.primary),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text('Scam shield checks the recipient before you send',
                          style: TextStyle(color: AppColors.muted, fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Warns the user before a risky payment. Returns true to send anyway.
Future<bool?> showScamShield(BuildContext context, ScamCheck check) {
  var trusted = false;
  return showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        icon: const Icon(Icons.shield, color: AppColors.warning, size: 36),
        title: const Text('Scam shield check'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Icon(
                        check.registeredName != null ? Icons.verified_user : Icons.help_outline,
                        color: check.registeredName != null ? AppColors.primary : AppColors.warning,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          check.registeredName != null
                              ? 'Registered name: ${check.registeredName}'
                              : 'Name not verified',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                for (final w in check.warnings)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(w)),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: trusted,
                  onChanged: (v) => setState(() => trusted = v ?? false),
                  title: const Text('I know this person and nobody is rushing me'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            onPressed: trusted ? () => Navigator.of(ctx).pop(true) : null,
            child: const Text('Send anyway'),
          ),
        ],
      ),
    ),
  );
}

class _RecipientBubble extends StatelessWidget {
  const _RecipientBubble({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          width: 72,
          child: Column(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.blue.withValues(alpha: 0.14),
                child: Text(
                  name.split(' ').where((w) => w.isNotEmpty).take(2).map((w) => w[0]).join(),
                  style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 6),
              Text(name.split(' ').first,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.ink)),
            ],
          ),
        ),
      );
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.quote});

  final Quote quote;

  @override
  Widget build(BuildContext context) {
    Widget row(String label, String value, {bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Expanded(child: Text(label, style: const TextStyle(color: AppColors.muted))),
              Text(value,
                  style: TextStyle(
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                    color: AppColors.ink,
                  )),
            ],
          ),
        );

    return AppCard(
      child: Column(
        children: [
          row('You send', Money.formatWithCurrency(quote.sendCents, quote.sendCurrency)),
          row('Fee', Money.formatWithCurrency(quote.feeCents, quote.sendCurrency)),
          row('Rate', '1 ${quote.sendCurrency} = ${quote.rate.toStringAsFixed(4)} ${quote.receiveCurrency}'),
          const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Divider()),
          row('Total to pay', Money.formatWithCurrency(quote.totalCents, quote.sendCurrency), bold: true),
          row('They get', Money.formatWithCurrency(quote.receiveCents, quote.receiveCurrency), bold: true),
          const SizedBox(height: 6),
          const Row(
            children: [
              Icon(Icons.timer_outlined, size: 14, color: AppColors.muted),
              SizedBox(width: 4),
              Text('Rate locked for 5 minutes', style: TextStyle(fontSize: 12, color: AppColors.muted)),
            ],
          ),
        ],
      ),
    );
  }
}
