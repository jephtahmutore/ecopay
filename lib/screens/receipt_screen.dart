import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/corridor.dart';
import '../models/transfer.dart';
import '../theme/app_theme.dart';
import '../utils/money.dart';
import '../widgets/glass.dart';
import '../widgets/transfer_tile.dart';

/// Feature: a digital receipt with live tracking of each step of the transfer.
class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({super.key, required this.transfer});

  final Transfer transfer;

  static String formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]} ${d.year}, ${two(d.hour)}:${two(d.minute)}';
  }

  /// The tracking steps shown on the receipt, in order.
  static List<String> stepsFor(Transfer t) {
    if (t.isAirtime) {
      return ['Order placed', 'Paid from your wallet', 'Airtime loaded on the Econet line'];
    }
    final payout = switch (t.deliveryMethod) {
      DeliveryMethod.ecocash => 'Paid into the EcoCash wallet',
      DeliveryMethod.mobileWallet => 'Paid into the mobile wallet',
      DeliveryMethod.bank => 'Paid into the bank account',
      DeliveryMethod.cashPickup => 'Ready for cash pickup',
    };
    return ['Transfer created', 'Paid from your wallet', 'Rate locked and sent to ${t.country}', payout];
  }

  void _copyReference(BuildContext context) {
    Clipboard.setData(ClipboardData(text: transfer.id));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reference copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = transfer.quote;
    final done = transfer.status == TransferStatus.completed;
    final steps = stepsFor(transfer);
    final text = Theme.of(context).textTheme;

    Widget row(String label, String value, {bool strong = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.muted)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(fontWeight: strong ? FontWeight.w700 : FontWeight.w500),
                ),
              ),
            ],
          ),
        );

    return GlassScaffold(
      title: 'Receipt',
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            GlassCard(
              tint: done ? AppColors.mint : AppColors.amber,
              child: Column(
                children: [
                  GlassIconBadge(
                    icon: done ? Icons.check_rounded : Icons.schedule_rounded,
                    color: done ? AppColors.mint : AppColors.amber,
                    size: 64,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    transfer.isAirtime ? 'Airtime sent' : 'Money sent',
                    style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Money.formatWithCurrency(q.receiveCents, q.receiveCurrency),
                    key: const Key('receiptAmount'),
                    style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    transfer.isAirtime ? 'to ${transfer.recipientPhone}' : 'to ${transfer.recipientName}',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                children: [
                  if (!transfer.isAirtime) ...[
                    row('Recipient', transfer.recipientName),
                    row('Phone', transfer.recipientPhone),
                    row('Country', transfer.country),
                    row('Paid out by', transfer.deliveryMethod.label),
                    row('Exchange rate', '1 ${q.sendCurrency} = ${q.rate.toStringAsFixed(4)} ${q.receiveCurrency}'),
                  ] else
                    row('Econet line', transfer.recipientPhone),
                  row('Amount', Money.formatWithCurrency(q.sendCents, q.sendCurrency)),
                  row('Fee', Money.formatWithCurrency(q.feeCents, q.sendCurrency)),
                  const Divider(height: 20),
                  row('Total paid', Money.formatWithCurrency(q.totalCents, q.sendCurrency), strong: true),
                  row('Date', formatDate(transfer.createdAt)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('Reference', style: TextStyle(color: AppColors.muted)),
                      const Spacer(),
                      Flexible(
                        child: Text(
                          transfer.id,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'monospace'),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copy reference',
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        onPressed: () => _copyReference(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GlassIconBadge(icon: iconForTransfer(transfer), size: 36),
                      const SizedBox(width: 10),
                      const Text('Tracking', style: TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  for (var i = 0; i < steps.length; i++)
                    _TimelineStep(
                      label: steps[i],
                      done: done || i == 0,
                      isLast: i == steps.length - 1,
                      time: i == 0 || done ? formatDate(transfer.createdAt) : null,
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

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({required this.label, required this.done, required this.isLast, this.time});

  final String label;
  final bool done;
  final bool isLast;
  final String? time;

  @override
  Widget build(BuildContext context) {
    final color = done ? AppColors.mint : AppColors.faint;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? AppColors.mint : Colors.transparent,
                  border: Border.all(color: color, width: 2),
                ),
                child: done ? const Icon(Icons.check, size: 14, color: AppColors.ink) : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: color.withValues(alpha: 0.5)),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: done ? Colors.white : AppColors.muted)),
                  if (time != null)
                    Text(time!, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
