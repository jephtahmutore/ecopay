import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/demo_data.dart';
import '../state/wallet_provider.dart';
import '../theme/app_theme.dart';
import '../utils/money.dart';
import '../widgets/ui.dart';

/// Purpose payments: pay school fees, ZESA, groceries or a clinic directly,
/// so money sent home is used for what it was meant for.
class PayBillsScreen extends StatefulWidget {
  const PayBillsScreen({super.key});

  @override
  State<PayBillsScreen> createState() => _PayBillsScreenState();
}

class _PayBillsScreenState extends State<PayBillsScreen> {
  static const _referenceLabel = {
    'School fees': 'Student number',
    'Electricity': 'Meter number',
    'Groceries': 'Phone to receive the voucher',
    'Medical': 'Patient name or file number',
  };

  final _formKey = GlobalKey<FormState>();
  final _reference = TextEditingController();
  final _beneficiary = TextEditingController();
  final _amount = TextEditingController();
  String _category = WalletProvider.billCategories.first;
  late String _biller = DemoData.billers[_category]!.first;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<WalletProvider>().clearError();
    });
  }

  @override
  void dispose() {
    _reference.dispose();
    _beneficiary.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    if (!_formKey.currentState!.validate()) return;
    final activity = await context.read<WalletProvider>().payBill(
          category: _category,
          biller: _biller,
          reference: _reference.text,
          beneficiary: _beneficiary.text,
          cents: Money.parseToCents(_amount.text)!,
        );
    if (!mounted || activity == null) return;
    await showReceipt(context, activity);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final billers = DemoData.billers[_category]!;

    return Scaffold(
      appBar: AppBar(title: const Text('Pay for home')),
      body: PageWidth(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.mint.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.volunteer_activism, color: AppColors.primary, size: 32),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pay directly, not in cash',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.ink)),
                        SizedBox(height: 2),
                        Text(
                          'Money goes straight to the school, ZESA, shop or clinic, '
                          'so it is used for exactly what you intended.',
                          style: TextStyle(fontSize: 13, color: AppColors.ink),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('What are you paying for?',
                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.9,
              children: [
                for (final c in WalletProvider.billCategories)
                  _CategoryTile(
                    category: c,
                    selected: c == _category,
                    onTap: () => setState(() {
                      _category = c;
                      _biller = DemoData.billers[c]!.first;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Pay to', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final b in billers)
                  ChoiceChip(
                    label: Text(b),
                    selected: b == _biller,
                    showCheckmark: false,
                                        onSelected: (_) => setState(() => _biller = b),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _reference,
                    decoration: InputDecoration(
                      labelText: _referenceLabel[_category],
                      prefixIcon: const Icon(Icons.tag),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _beneficiary,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Who is this for?',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amount,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Amount', prefixText: 'USD '),
                    validator: (v) => Money.parseToCents(v ?? '') == null ? 'Enter an amount above zero' : null,
                  ),
                ],
              ),
            ),
            if (wallet.error != null) ErrorText(wallet.error!),
            const SizedBox(height: 20),
            GradientButton(
              onPressed: wallet.loading ? null : _pay,
              child: wallet.loading
                  ? const ButtonSpinner()
                  : Text(wallet.offline ? 'Queue payment' : 'Pay $_biller'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.selected, required this.onTap});

  final String category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final look = categoryLook(category);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? look.color.withValues(alpha: 0.14) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? look.color : AppColors.border, width: selected ? 1.6 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(look.icon, color: look.color, size: 28),
            const SizedBox(height: 6),
            Text(category,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink)),
          ],
        ),
      ),
    );
  }
}
