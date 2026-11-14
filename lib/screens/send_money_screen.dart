import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/quote.dart';
import '../state/wallet_provider.dart';
import '../utils/money.dart';

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
    final transfer = await wallet.confirm(recipientName: _name.text, recipientPhone: _phone.text);
    if (!mounted || transfer == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sent to ${transfer.recipientName}. Reference ${transfer.id}')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final quote = wallet.quote;

    return Scaffold(
      appBar: AppBar(title: const Text('Send money')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                key: const Key('recipientName'),
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Recipient full name'),
                validator: (v) => (v == null || v.trim().length < 2) ? 'Enter the recipient name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('recipientPhone'),
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Recipient phone, with country code'),
                validator: (v) => RegExp(r'^\+?\d{9,15}$').hasMatch((v ?? '').replaceAll(' ', ''))
                    ? null
                    : 'Enter a valid phone number',
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _currency,
                decoration: const InputDecoration(labelText: 'Recipient gets'),
                items: WalletProvider.receiveCurrencies
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (c) {
                  if (c == null) return;
                  setState(() => _currency = c);
                  context.read<WalletProvider>().clearQuote();
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('amount'),
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'You send (USD)', prefixText: 'USD '),
                onChanged: (_) => context.read<WalletProvider>().clearQuote(),
                validator: (v) => Money.parseToCents(v ?? '') == null ? 'Enter an amount above zero' : null,
              ),
              const SizedBox(height: 16),
              if (wallet.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(wallet.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              if (quote != null) _QuoteCard(quote: quote),
              const SizedBox(height: 16),
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
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            row('You send', Money.formatWithCurrency(quote.sendCents, quote.sendCurrency)),
            row('Fee', Money.formatWithCurrency(quote.feeCents, quote.sendCurrency)),
            row('Exchange rate', '1 ${quote.sendCurrency} = ${quote.rate.toStringAsFixed(4)} ${quote.receiveCurrency}'),
            const Divider(),
            row('Total to pay', Money.formatWithCurrency(quote.totalCents, quote.sendCurrency), bold: true),
            row('Recipient gets', Money.formatWithCurrency(quote.receiveCents, quote.receiveCurrency), bold: true),
            const SizedBox(height: 4),
            Text('Quote valid for 5 minutes', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
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
