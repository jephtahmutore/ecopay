import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/corridor.dart';
import '../models/insights.dart';
import '../models/quote.dart';
import '../state/wallet_provider.dart';
import '../theme/app_theme.dart';
import '../utils/money.dart';
import '../utils/phone.dart';
import '../widgets/glass.dart';
import 'receipt_screen.dart';

class SendMoneyScreen extends StatefulWidget {
  const SendMoneyScreen({super.key, this.recipient});

  /// When set, the form is filled in for a repeat transfer.
  final SavedRecipient? recipient;

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _amount = TextEditingController();
  late Corridor _corridor;
  late DeliveryMethod _method;

  @override
  void initState() {
    super.initState();
    final saved = widget.recipient;
    _corridor = saved == null ? Corridor.all.first : Corridor.byCountry(saved.country);
    _method = saved != null && _corridor.methods.contains(saved.deliveryMethod)
        ? saved.deliveryMethod
        : _corridor.methods.first;
    if (saved != null) {
      _name.text = saved.name;
      _phone.text = saved.phone;
    }
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

  String get _currency => _corridor.currency;

  Future<void> _getQuote() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<WalletProvider>().getQuote(
          sendCents: Money.parseToCents(_amount.text)!,
          receiveCurrency: _currency,
        );
  }

  Future<void> _confirm() async {
    final wallet = context.read<WalletProvider>();
    final transfer = await wallet.confirm(
      recipientName: _name.text,
      recipientPhone: _phone.text,
      country: _corridor.country,
      deliveryMethod: _method,
    );
    if (!mounted || transfer == null) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => ReceiptScreen(transfer: transfer)),
    );
  }

  void _changeCorridor(Corridor corridor) {
    setState(() {
      _corridor = corridor;
      _method = corridor.methods.first;
    });
    context.read<WalletProvider>().clearQuote();
    if (_phone.text.isNotEmpty) _formKey.currentState?.validate();
  }

  String? _validatePhone(String? v) {
    final value = v ?? '';
    if (_method == DeliveryMethod.ecocash) {
      return PhoneNumbers.isEconetNumber(value)
          ? null
          : 'EcoCash needs an Econet number starting with 077 or 078';
    }
    return PhoneNumbers.isValidInternational(value) ? null : 'Enter a valid phone number';
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final quote = wallet.quote;

    return GlassScaffold(
      title: 'Send money',
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<Corridor>(
                      key: const Key('country'),
                      initialValue: _corridor,
                      dropdownColor: AppColors.navy,
                      borderRadius: BorderRadius.circular(16),
                      decoration: const InputDecoration(
                        labelText: 'Send to',
                        prefixIcon: Icon(Icons.public_rounded),
                      ),
                      items: Corridor.all
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text('${c.flag}  ${c.country} (${c.currency})'),
                              ))
                          .toList(),
                      onChanged: (c) {
                        if (c != null) _changeCorridor(c);
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Recipient gets it by', style: TextStyle(color: AppColors.muted)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final m in _corridor.methods)
                          ChoiceChip(
                            key: Key('method_${m.name}'),
                            label: Text(m.label),
                            selected: _method == m,
                            onSelected: (_) {
                              setState(() => _method = m);
                              if (_phone.text.isNotEmpty) _formKey.currentState?.validate();
                            },
                          ),
                      ],
                    ),
                    if (_method == DeliveryMethod.ecocash) ...[
                      const SizedBox(height: 12),
                      const Row(
                        children: [
                          Icon(Icons.bolt_rounded, size: 16, color: AppColors.mint),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Lands in their EcoCash wallet in seconds, in US dollars',
                              style: TextStyle(color: AppColors.mint, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      key: const Key('recipientName'),
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Recipient full name',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (v) => (v == null || v.trim().length < 2) ? 'Enter the recipient name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('recipientPhone'),
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: _method == DeliveryMethod.ecocash
                            ? 'EcoCash number'
                            : 'Recipient phone, with country code',
                        hintText: _method == DeliveryMethod.ecocash ? '077 123 4567' : null,
                        prefixIcon: const Icon(Icons.phone_rounded),
                      ),
                      validator: _validatePhone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('amount'),
                      controller: _amount,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'You send (USD)',
                        prefixText: 'USD ',
                        prefixIcon: Icon(Icons.attach_money_rounded),
                      ),
                      onChanged: (_) => context.read<WalletProvider>().clearQuote(),
                      validator: (v) => Money.parseToCents(v ?? '') == null ? 'Enter an amount above zero' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (wallet.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(wallet.error!, style: const TextStyle(color: AppColors.rose)),
                ),
              if (quote != null) ...[
                _QuoteCard(quote: quote),
                const SizedBox(height: 16),
              ],
              if (quote == null)
                FilledButton(
                  key: const Key('getQuote'),
                  onPressed: wallet.loading ? null : _getQuote,
                  child: wallet.loading ? const _ButtonSpinner() : const Text('Get quote'),
                )
              else
                FilledButton(
                  key: const Key('confirm'),
                  onPressed: wallet.loading ? null : _confirm,
                  child: wallet.loading
                      ? const _ButtonSpinner()
                      : Text('Confirm and send ${Money.formatWithCurrency(quote.totalCents, quote.sendCurrency)}'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.quote});

  final Quote quote;

  @override
  Widget build(BuildContext context) {
    Widget row(String label, String value, {bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: AppColors.muted)),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w500),
                ),
              ),
            ],
          ),
        );

    return GlassCard(
      tint: AppColors.cyan,
      child: Column(
        children: [
          row('You send', Money.formatWithCurrency(quote.sendCents, quote.sendCurrency)),
          row('Fee', Money.formatWithCurrency(quote.feeCents, quote.sendCurrency)),
          row('Exchange rate', '1 ${quote.sendCurrency} = ${quote.rate.toStringAsFixed(4)} ${quote.receiveCurrency}'),
          const Divider(height: 20),
          row('Total to pay', Money.formatWithCurrency(quote.totalCents, quote.sendCurrency), bold: true),
          row('Recipient gets', Money.formatWithCurrency(quote.receiveCents, quote.receiveCurrency), bold: true),
          const SizedBox(height: 6),
          const Row(
            children: [
              Icon(Icons.timer_outlined, size: 14, color: AppColors.muted),
              SizedBox(width: 4),
              Text('Quote valid for 5 minutes', style: TextStyle(color: AppColors.muted, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner();

  @override
  Widget build(BuildContext context) =>
      const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2));
}
