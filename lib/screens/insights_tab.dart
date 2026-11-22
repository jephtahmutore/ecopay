import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/wallet_provider.dart';
import '../theme/app_theme.dart';
import '../utils/money.dart';
import '../widgets/ui.dart';

class InsightsTab extends StatelessWidget {
  const InsightsTab({super.key});

  /// What a typical remittance company charges, used for the savings card.
  static const typicalFeePercent = 10;

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final totals = wallet.spendingByCategory();
    final total = totals.values.fold(0, (sum, v) => sum + v);
    final fees = wallet.feesPaid();
    final typical = wallet.familySentCents() * typicalFeePercent ~/ 100;
    final saved = typical > fees ? typical - fees : 0;

    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        const PageTitle('Insights', subtitle: 'Where your money went in the last 30 days'),

        // Donut chart and legend
        FadeSlideIn(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: AppCard(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  SizedBox(
                    width: 190,
                    height: 190,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (_, progress, __) => CustomPaint(
                        painter: _DonutPainter(
                          values: totals.values.toList(),
                          colors: totals.keys.map((c) => categoryLook(c).color).toList(),
                          progress: progress,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Spent', style: TextStyle(color: AppColors.muted)),
                              Text(
                                Money.formatWithCurrency(total, 'USD'),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (totals.isEmpty)
                    const Text('No spending yet', style: TextStyle(color: AppColors.muted))
                  else
                    for (final e in totals.entries)
                      _LegendRow(category: e.key, cents: e.value, percent: e.value * 100 ~/ total),
                ],
              ),
            ),
          ),
        ),

        // Savings
        FadeSlideIn(
          order: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: AppCard(
              gradient: AppGradients.brand,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.savings_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('You saved ${Money.formatWithCurrency(saved, 'USD')}',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
                        Text(
                          'in fees, compared with a typical $typicalFeePercent% remittance fee. '
                          'EcoPay charged you ${Money.formatWithCurrency(fees, 'USD')}.',
                          style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.85)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Scam shield status
        FadeSlideIn(
          order: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: AppCard(
              child: Row(
                children: [
                  const IconBadge(look: (icon: Icons.shield_rounded, color: AppColors.blue)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Scam shield is ${wallet.scamShield ? 'on' : 'off'}',
                            style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
                        const Text(
                          'New recipients, name mismatches and large amounts are checked before you send.',
                          style: TextStyle(fontSize: 13, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.category, required this.cents, required this.percent});

  final String category;
  final int cents;
  final int percent;

  @override
  Widget build(BuildContext context) {
    final look = categoryLook(category);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          IconBadge(look: look, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Text(category, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
          ),
          Text('$percent%', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          Text(Money.formatWithCurrency(cents, 'USD'),
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
        ],
      ),
    );
  }
}

/// Draws the spending donut, one rounded arc per category.
class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.values, required this.colors, required this.progress});

  final List<int> values;
  final List<Color> colors;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 20.0;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.surface;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);

    final total = values.fold(0, (sum, v) => sum + v);
    if (total == 0) return;

    const gap = 0.06;
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = values[i] / total * math.pi * 2 * progress;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = colors[i];
      if (sweep > gap) canvas.drawArc(rect, start + gap / 2, sweep - gap, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.progress != progress || old.values != values;
}
