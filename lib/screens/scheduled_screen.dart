import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/scheduled_send.dart';
import '../state/wallet_provider.dart';
import '../theme/app_theme.dart';
import '../utils/dates.dart';
import '../utils/money.dart';
import '../widgets/ui.dart';

/// Monthly sends, for example an allowance for parents.
class ScheduledScreen extends StatelessWidget {
  const ScheduledScreen({super.key});

  Future<void> _runNow(BuildContext context, ScheduledSend s) async {
    final activity = await context.read<WalletProvider>().runSchedule(s.id);
    if (!context.mounted) return;
    if (activity == null) {
      final error = context.read<WalletProvider>().error ?? 'Could not send';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    await showReceipt(context, activity);
  }

  void _newSchedule(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.sheet,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => const _NewScheduleSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();

    return GlassScaffold(
      appBar: AppBar(title: const Text('Scheduled sends')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newSchedule(context),
        icon: const Icon(Icons.add),
        label: const Text('New schedule'),
      ),
      body: PageWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            const Text('Send money home automatically every month. You can also send early.',
                style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 16),
            if (wallet.schedules.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text('No schedules yet', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
              ),
            for (final s in wallet.schedules)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const IconBadge(look: (icon: Icons.event_repeat, color: AppColors.purple)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                                Text(s.note.isEmpty ? s.phone : s.note,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                              ],
                            ),
                          ),
                          Text(Money.formatWithCurrency(s.amountCents, 'USD'),
                              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: AppColors.muted),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Every month on day ${s.dayOfMonth}. Next: ${Dates.short(s.nextDate())}',
                              style: const TextStyle(color: AppColors.muted, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => wallet.removeSchedule(s.id),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GradientButton(
                              onPressed: wallet.loading ? null : () => _runNow(context, s),
                              child: Text(wallet.offline ? 'Queue now' : 'Send now'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NewScheduleSheet extends StatefulWidget {
  const _NewScheduleSheet();

  @override
  State<_NewScheduleSheet> createState() => _NewScheduleSheetState();
}

class _NewScheduleSheetState extends State<_NewScheduleSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  double _day = 25;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.read<WalletProvider>().addSchedule(
          name: _name.text,
          phone: _phone.text,
          cents: Money.parseToCents(_amount.text)!,
          dayOfMonth: _day.round(),
          note: _note.text,
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
              const Text('New monthly send',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Recipient name', prefixIcon: Icon(Icons.person_outline)),
                validator: (v) => (v == null || v.trim().length < 2) ? 'Enter a name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_outlined)),
                validator: (v) => RegExp(r'^\+?\d{9,15}$').hasMatch((v ?? '').replaceAll(' ', ''))
                    ? null
                    : 'Enter a valid phone number',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount', prefixText: 'USD '),
                validator: (v) => Money.parseToCents(v ?? '') == null ? 'Enter an amount above zero' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _note,
                decoration: const InputDecoration(labelText: 'Note (optional)', prefixIcon: Icon(Icons.notes)),
              ),
              const SizedBox(height: 16),
              Text('Send on day ${_day.round()} of every month',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Slider(
                value: _day,
                min: 1,
                max: 28,
                divisions: 27,
                label: '${_day.round()}',
                onChanged: (v) => setState(() => _day = v),
              ),
              const SizedBox(height: 8),
              GradientButton(onPressed: _save, child: const Text('Save schedule')),
            ],
          ),
        ),
      ),
    );
  }
}
