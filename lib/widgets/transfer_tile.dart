import 'package:flutter/material.dart';

import '../models/transfer.dart';
import '../utils/money.dart';

class TransferTile extends StatelessWidget {
  const TransferTile({super.key, required this.transfer});

  final Transfer transfer;

  @override
  Widget build(BuildContext context) {
    final q = transfer.quote;
    final completed = transfer.status == TransferStatus.completed;
    return ListTile(
      leading: CircleAvatar(
        child: Text(transfer.recipientName.isEmpty ? '?' : transfer.recipientName[0].toUpperCase()),
      ),
      title: Text(transfer.recipientName),
      subtitle: Text('${Money.formatWithCurrency(q.receiveCents, q.receiveCurrency)} received'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(Money.formatWithCurrency(q.totalCents, q.sendCurrency),
              style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(completed ? 'Completed' : transfer.status.name,
              style: TextStyle(fontSize: 12, color: completed ? Colors.green : Colors.orange)),
        ],
      ),
    );
  }
}
