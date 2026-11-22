import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/activity.dart';
import '../models/linked_account.dart';
import '../theme/app_theme.dart';
import '../utils/dates.dart';
import '../utils/money.dart';

typedef Look = ({IconData icon, Color color});

/// Icon and colour for each spending category.
Look categoryLook(String category) => switch (category) {
      'Family' => (icon: Icons.favorite_outline, color: AppColors.blue),
      'School fees' => (icon: Icons.school_outlined, color: AppColors.orange),
      'Electricity' => (icon: Icons.bolt, color: AppColors.warning),
      'Groceries' => (icon: Icons.shopping_basket_outlined, color: AppColors.primary),
      'Medical' => (icon: Icons.local_hospital_outlined, color: AppColors.danger),
      'Airtime' => (icon: Icons.cell_tower_rounded, color: AppColors.pink),
      'Mukando' => (icon: Icons.groups_rounded, color: AppColors.teal),
      _ => (icon: Icons.swap_horiz, color: AppColors.primary),
    };

Look activityLook(Activity a) => switch (a.kind) {
      ActivityKind.sendAbroad => (icon: Icons.public, color: AppColors.blue),
      ActivityKind.move => (icon: Icons.swap_horiz, color: AppColors.primary),
      ActivityKind.scheduled => (icon: Icons.event_repeat, color: AppColors.purple),
      ActivityKind.bill => categoryLook(a.category),
      ActivityKind.airtime => categoryLook('Airtime'),
      ActivityKind.savings => categoryLook('Mukando'),
    };

Look accountLook(AccountType type) => switch (type) {
      AccountType.wallet => (icon: Icons.account_balance_wallet_outlined, color: AppColors.primary),
      AccountType.bank => (icon: Icons.account_balance_outlined, color: AppColors.blue),
      AccountType.mobile => (icon: Icons.phone_iphone, color: AppColors.mint),
    };

/// Keeps content phone width on big screens such as Chrome and Windows.
class PageWidth extends StatelessWidget {
  const PageWidth({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: child,
        ),
      );
}

/// Big bold page heading used at the top of each tab.
class PageTitle extends StatelessWidget {
  const PageTitle(this.title, {super.key, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.5)),
            if (subtitle != null)
              Text(subtitle!, style: const TextStyle(color: AppColors.muted)),
          ],
        ),
      );
}

/// Frosted glass card: blurs what is behind it, with a light tint and a
/// thin bright edge. Pass [gradient] for a solid coloured card instead.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.color,
    this.gradient,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Optional tint mixed into the glass.
  final Color? color;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 24,
      tint: color,
      gradient: gradient,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// The glass effect itself: background blur, translucent fill and a soft
/// light border. Used by [AppCard], lists, tiles and the login card.
class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.radius = 24,
    this.tint,
    this.gradient,
    this.blur = 18,
    this.selected = false,
    this.selectedColor = AppColors.primary,
  });

  final Widget child;
  final double radius;
  final Color? tint;
  final Gradient? gradient;
  final double blur;
  final bool selected;
  final Color selectedColor;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    final accent = tint ?? Colors.white;
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: borderRadius, boxShadow: AppShadows.soft),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              gradient: gradient ??
                  LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: selected
                        ? [selectedColor.withValues(alpha: 0.30), selectedColor.withValues(alpha: 0.12)]
                        : [
                            accent.withValues(alpha: tint == null ? 0.13 : 0.26),
                            accent.withValues(alpha: tint == null ? 0.04 : 0.08),
                          ],
                  ),
              border: Border.all(
                color: selected ? selectedColor : Colors.white.withValues(alpha: 0.16),
                width: selected ? 1.6 : 1,
              ),
            ),
            // Gives taps inside the glass a visible ripple.
            child: Material(type: MaterialType.transparency, child: child),
          ),
        ),
      ),
    );
  }
}

/// Night sky with soft glowing colour blobs. The glass cards blur these
/// blobs, which is what makes the frosted look visible.
class GlassBackground extends StatelessWidget {
  const GlassBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0B1636), AppColors.night, Color(0xFF071F24)],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Stack(
              children: const [
                Align(alignment: Alignment(-1.3, -1.0), child: GlowBlob(color: AppColors.primary, size: 360)),
                Align(alignment: Alignment(1.4, -0.2), child: GlowBlob(color: AppColors.purple, size: 320)),
                Align(alignment: Alignment(-0.9, 1.25), child: GlowBlob(color: AppColors.blue, size: 360)),
              ],
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

/// A [Scaffold] on the glass background, with a see through app bar.
/// Every screen uses it so the glass has something to blur.
class GlassScaffold extends StatelessWidget {
  const GlassScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
        body: body,
      ),
    );
  }
}

/// The main call to action: brand gradient with a soft glow.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.gradient = AppGradients.brand,
    this.height = 56,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Gradient gradient;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final radius = BorderRadius.circular(18);
    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.6,
      duration: const Duration(milliseconds: 200),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: radius,
          boxShadow: enabled ? AppShadows.glow(AppColors.cyan) : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                widthFactor: 1,
                child: IconTheme(
                  data: const IconThemeData(color: Colors.white),
                  child: DefaultTextStyle.merge(
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A soft glowing circle of colour for dark backgrounds.
class GlowBlob extends StatelessWidget {
  const GlowBlob({super.key, required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color.withValues(alpha: 0.45), color.withValues(alpha: 0)]),
        ),
      );
}

/// Fades and slides its child in once, for a lively first impression.
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({super.key, required this.child, this.order = 0});

  final Widget child;
  final int order;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 380 + order * 90),
        curve: Curves.easeOutCubic,
        child: child,
        builder: (_, v, child) => Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, 18 * (1 - v)), child: child),
        ),
      );
}

/// Card colours for linked accounts, like real bank cards.
LinearGradient accountGradient(LinkedAccount a) => switch (a.provider) {
      'EcoPay wallet' => AppGradients.brand,
      'CBZ Bank' => const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF3B6BFD)]),
      'Stanbic Bank' => const LinearGradient(colors: [Color(0xFF0B1F4D), Color(0xFF1D4ED8)]),
      'EcoCash' => const LinearGradient(colors: [Color(0xFF0369A1), Color(0xFF06B6D4)]),
      'OneMoney' => const LinearGradient(colors: [Color(0xFF9A3412), Color(0xFFFB923C)]),
      'InnBucks' => const LinearGradient(colors: [Color(0xFF6D28D9), Color(0xFFA78BFA)]),
      _ => a.type == AccountType.bank
          ? const LinearGradient(colors: [Color(0xFF312E81), Color(0xFF6366F1)])
          : const LinearGradient(colors: [Color(0xFF047857), Color(0xFF34D399)]),
    };

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 8, 6),
        child: Row(
          children: [
            Expanded(
              child: Text(title,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
            ),
            if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
          ],
        ),
      );
}

/// Coloured rounded square with an icon inside.
class IconBadge extends StatelessWidget {
  const IconBadge({super.key, required this.look, this.size = 44});

  final Look look;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [look.color.withValues(alpha: 0.18), look.color.withValues(alpha: 0.08)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(size * 0.34),
        ),
        child: Icon(look.icon, color: look.color, size: size * 0.5),
      );
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});

  final ActivityStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ActivityStatus.completed => ('Done', AppColors.primary),
      ActivityStatus.queued => ('Queued', AppColors.warning),
      ActivityStatus.failed => ('Failed', AppColors.danger),
    };
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

String activityAmount(Activity a) {
  final amount = Money.formatWithCurrency(a.amountCents, 'USD');
  return a.kind == ActivityKind.move ? amount : '- $amount';
}

/// One row of history. Tap to open the receipt.
class ActivityTile extends StatelessWidget {
  const ActivityTile({super.key, required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showReceipt(context, activity),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            IconBadge(look: activityLook(activity)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(activity.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.ink)),
                  const SizedBox(height: 2),
                  Text('${activity.subtitle} · ${Dates.relative(activity.createdAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(activityAmount(activity),
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                if (activity.status != ActivityStatus.completed) StatusPill(activity.status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Small branded square for an account, used in lists and pickers.
class AccountBadge extends StatelessWidget {
  const AccountBadge({super.key, required this.account, this.size = 44});

  final LinkedAccount account;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: accountGradient(account),
          borderRadius: BorderRadius.circular(size * 0.34),
        ),
        child: Icon(accountLook(account.type).icon, color: Colors.white, size: size * 0.48),
      );
}

/// Branded card for the horizontal list of linked accounts.
class AccountCard extends StatelessWidget {
  const AccountCard({super.key, required this.account});

  final LinkedAccount account;

  @override
  Widget build(BuildContext context) {
    final gradient = accountGradient(account);
    return Container(
      width: 200,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient.colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.glow(gradient.colors.last),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(accountLook(account.type).icon, color: Colors.white, size: 22),
                    const Spacer(),
                    Icon(Icons.contactless_outlined, color: Colors.white.withValues(alpha: 0.7), size: 20),
                  ],
                ),
                const Spacer(),
                Text(account.provider,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                Text(account.masked,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12, letterSpacing: 1)),
                const SizedBox(height: 8),
                Text(Money.formatWithCurrency(account.balanceCents, 'USD'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Glass container that holds a list of activity rows.
class ActivityList extends StatelessWidget {
  const ActivityList({super.key, required this.items});

  final List<Activity> items;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Glass(
          child: Material(
            type: MaterialType.transparency,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) const Divider(indent: 76, endIndent: 16),
                    ActivityTile(activity: items[i]),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
}

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.queued, required this.onGoOnline});

  final int queued;
  final VoidCallback onGoOnline;

  @override
  Widget build(BuildContext context) {
    final message = queued == 0
        ? 'Payments you make now are queued and sent when the network is back.'
        : '$queued payment${queued == 1 ? '' : 's'} queued. '
            'They send automatically when you are back online.';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('You are offline',
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                Text(message, style: const TextStyle(fontSize: 13, color: AppColors.ink)),
              ],
            ),
          ),
          TextButton(onPressed: onGoOnline, child: const Text('Go online')),
        ],
      ),
    );
  }
}

class ErrorText extends StatelessWidget {
  const ErrorText(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(color: AppColors.danger))),
          ],
        ),
      );
}

class ButtonSpinner extends StatelessWidget {
  const ButtonSpinner({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
      );
}

/// Opens the receipt for any activity as a bottom sheet.
Future<void> showReceipt(BuildContext context, Activity activity) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.sheet,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => _ReceiptSheet(activity: activity),
  );
}

class _ReceiptSheet extends StatelessWidget {
  const _ReceiptSheet({required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    final (statusText, statusIcon, statusColor) = switch (activity.status) {
      ActivityStatus.completed => ('Payment successful', Icons.check_rounded, AppColors.primary),
      ActivityStatus.queued => ('Queued. Sends when you are online', Icons.schedule, AppColors.warning),
      ActivityStatus.failed => ('Payment failed', Icons.close_rounded, AppColors.danger),
    };
    final rows = {
      ...activity.details,
      'Date': Dates.withTime(activity.createdAt),
      'Reference': activity.id,
    };
    final receiptText = StringBuffer('EcoPay receipt\n')
      ..writeln('${activity.title}: ${Money.formatWithCurrency(activity.amountCents, 'USD')}')
      ..writeln(statusText);
    rows.forEach((k, v) => receiptText.writeln('$k: $v'));

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(height: 20),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: activity.status == ActivityStatus.completed
                    ? AppGradients.brand
                    : LinearGradient(colors: [statusColor, statusColor]),
                shape: BoxShape.circle,
                boxShadow: AppShadows.glow(statusColor),
              ),
              child: Icon(statusIcon, color: Colors.white, size: 34),
            ),
            const SizedBox(height: 12),
            Text(statusText,
                textAlign: TextAlign.center,
                style: TextStyle(color: statusColor, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(Money.formatWithCurrency(activity.amountCents, 'USD'),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.ink)),
            Text(activity.title, style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18)),
              child: Column(
                children: [
                  for (final e in rows.entries)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 110,
                            child: Text(e.key, style: const TextStyle(color: AppColors.muted)),
                          ),
                          Expanded(
                            child: Text(e.value,
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Tracking(activity: activity),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: receiptText.toString()));
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text('Receipt copied, paste it in WhatsApp')));
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Copy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GradientButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The tracking steps shown on a receipt, in order.
List<String> trackingSteps(Activity a) {
  final ecoCash = (a.details['Paid out to'] ?? '').startsWith('EcoCash');
  return switch (a.kind) {
    ActivityKind.sendAbroad => [
        'Paid from your wallet',
        'Rate locked and sent',
        ecoCash ? 'Paid into their EcoCash wallet' : 'Paid out to ${a.title}',
      ],
    ActivityKind.bill => ['Paid from your wallet', 'Sent to ${a.title}', 'Payment received'],
    ActivityKind.airtime => ['Paid from your wallet', 'Loaded on the line'],
    ActivityKind.move => ['Taken from the first account', 'Arrived in the second account'],
    ActivityKind.scheduled => ['Scheduled', 'Paid from your wallet', 'Delivered'],
    ActivityKind.savings => ['Paid from your wallet', 'Added to the Mukando pot'],
  };
}

/// Step by step progress of a payment, like parcel tracking.
class _Tracking extends StatelessWidget {
  const _Tracking({required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    final steps = trackingSteps(activity);
    final allDone = activity.status == ActivityStatus.completed;
    final failed = activity.status == ActivityStatus.failed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tracking', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 12),
          for (var i = 0; i < steps.length; i++)
            _TrackingStep(
              label: steps[i],
              done: allDone || (i == 0 && !failed),
              failed: failed && i == 0,
              isLast: i == steps.length - 1,
            ),
        ],
      ),
    );
  }
}

class _TrackingStep extends StatelessWidget {
  const _TrackingStep({required this.label, required this.done, required this.failed, required this.isLast});

  final String label;
  final bool done;
  final bool failed;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = failed ? AppColors.danger : (done ? AppColors.mint : AppColors.muted);
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
                  color: done || failed ? color : Colors.transparent,
                  border: Border.all(color: color, width: 2),
                ),
                child: done || failed
                    ? Icon(failed ? Icons.close : Icons.check, size: 14, color: AppColors.night)
                    : null,
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: color.withValues(alpha: 0.45))),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: done || failed ? AppColors.ink : AppColors.muted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
