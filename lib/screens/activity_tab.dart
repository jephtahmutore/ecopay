import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/activity.dart';
import '../state/wallet_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

class ActivityTab extends StatefulWidget {
  const ActivityTab({super.key});

  @override
  State<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<ActivityTab> {
  static const _filters = ['All', 'Family', 'Bills', 'Airtime', 'Mukando', 'Moves', 'Queued'];
  String _filter = 'All';

  bool _matches(Activity a) => switch (_filter) {
        'Family' => a.category == 'Family',
        'Bills' => a.kind == ActivityKind.bill,
        'Airtime' => a.kind == ActivityKind.airtime,
        'Mukando' => a.kind == ActivityKind.savings,
        'Moves' => a.kind == ActivityKind.move,
        'Queued' => a.status != ActivityStatus.completed,
        _ => true,
      };

  @override
  Widget build(BuildContext context) {
    final items = context.watch<WalletProvider>().activities.where(_matches).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const PageTitle('Activity', subtitle: 'Tap any payment to see its receipt'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              for (final f in _filters)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: f == _filter,
                    showCheckmark: false,
                                        onSelected: (_) => setState(() => _filter = f),
                  ),
                ),
            ],
          ),
        ),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Text('Nothing here yet', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
          )
        else
          ActivityList(items: items),
      ],
    );
  }
}
