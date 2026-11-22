import 'package:flutter/material.dart';

import '../models/corridor.dart';
import '../models/transfer.dart';
import '../theme/app_theme.dart';
import '../utils/money.dart';
import 'glass.dart';

/// Icon for each kind of payout, used in lists and receipts.
IconData iconForTransfer(Transfer transfer) {
  if (transfer.isAirtime) return Icons.phone_android_rounded;
  return switch (transfer.deliveryMethod) {
    DeliveryMethod.ecocash => Icons.account_balance_wallet_rounded,
    DeliveryMethod.mobileWallet => Icons.smartphone_rounded,
    DeliveryMethod.bank => Icons.account_balance_rounded,
    DeliveryMethod.cashPickup => Icons.storefront_rounded,
  };
}

class TransferTile extends StatelessWidget {
  const TransferTile({super.key, required this.transfer, this.onTap});

  final Transfer transfer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final q = transfer.quote;
    final completed = transfer.status == TransferStatus.completed;
    final statusColor = completed ? AppColors.mint : AppColors.amber;
    final subtitle = transfer.isAirtime
        ? 'Airtime to ${transfer.recipientPhone}'
        : '${Money.formatWithCurrency(q.receiveCents, q.receiveCurrency)} via ${transfer.deliveryMethod.label}';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            GlassIconBadge(
              icon: iconForTransfer(transfer),
              color: transfer.isAirtime ? AppColors.mint : AppColors.cyan,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transfer.recipientName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '-${Money.formatWithCurrency(q.totalCents, q.sendCurrency)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  completed ? 'Completed' : transfer.status.name,
                  style: TextStyle(fontSize: 12, color: statusColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
