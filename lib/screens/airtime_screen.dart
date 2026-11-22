import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/transfer_repository.dart';
import '../state/wallet_provider.dart';
import '../theme/app_theme.dart';
import '../utils/money.dart';
import '../utils/phone.dart';
import '../widgets/glass.dart';
import 'receipt_screen.dart';

/// Feature: buy Econet airtime for any Econet line, paid from the wallet.
class AirtimeScreen extends StatefulWidget {
  const AirtimeScreen({super.key});

  @override
  State<AirtimeScreen> createState() => _AirtimeScreenState();
}

class _AirtimeScreenState extends State<AirtimeScreen> {
  static const _presets = [100, 200, 500, 1000, 2000];

  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _custom = TextEditingController();
  int? _selectedCents = 200;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<WalletProvider>().clearQuote();
    });
  }

  @override
  void dispose() {
    _phone.dispose();
    _custom.dispose();
    super.dispose();
  }

  int? get _amountCents => _selectedCents ?? Money.parseToCents(_custom.text);

  Future<void> _buy() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final wallet = context.read<WalletProvider>();
    final purchase = await wallet.buyAirtime(phone: _phone.text, amountCents: _amountCents!);
    if (!mounted || purchase == null) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => ReceiptScreen(transfer: purchase)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final amount = _amountCents;

    return GlassScaffold(
      title: 'Econet airtime',
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              GlassCard(
                tint: AppColors.mint,
                child: Row(
                  children: [
                    const GlassIconBadge(icon: Icons.bolt_rounded, color: AppColors.mint),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Top up any Econet line instantly. No fees. '
                        'Balance: ${Money.formatWithCurrency(wallet.balanceCents, WalletProvider.sendCurrency)}',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      key: const Key('airtimePhone'),
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Econet number',
                        hintText: '077 123 4567',
                        prefixIcon: Icon(Icons.phone_iphone_rounded),
                      ),
                      validator: (v) => PhoneNumbers.isEconetNumber(v ?? '')
                          ? null
                          : 'Enter an Econet number starting with 077 or 078',
                    ),
                    const SizedBox(height: 20),
                    const Text('Amount', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final cents in _presets)
                          ChoiceChip(
                            label: Text('\$${Money.format(cents)}'),
                            selected: _selectedCents == cents,
                            onSelected: (_) => setState(() {
                              _selectedCents = cents;
                              _custom.clear();
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('airtimeCustom'),
                      controller: _custom,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Or enter another amount',
                        prefixText: 'USD ',
                      ),
                      onChanged: (_) => setState(() => _selectedCents = null),
                      validator: (_) {
                        final cents = _amountCents;
                        if (cents == null) return 'Choose or enter an amount';
                        if (cents < TransferRepository.minAirtimeCents ||
                            cents > TransferRepository.maxAirtimeCents) {
                          return 'Airtime must be between USD 0.50 and USD 50.00';
                        }
                        return null;
                      },
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
              FilledButton.icon(
                key: const Key('confirmAirtime'),
                onPressed: wallet.loading ? null : _buy,
                icon: wallet.loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.bolt_rounded),
                label: Text(amount == null ? 'Buy airtime' : 'Buy \$${Money.format(amount)} airtime'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
