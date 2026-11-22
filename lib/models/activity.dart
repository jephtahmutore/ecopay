enum ActivityKind { sendAbroad, move, bill, scheduled, airtime, savings }

enum ActivityStatus { completed, queued, failed }

/// One line in the activity history: a transfer, a bill, a move or a
/// scheduled send. [details] are shown on the receipt.
class Activity {
  const Activity({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.amountCents,
    required this.createdAt,
    required this.category,
    this.status = ActivityStatus.completed,
    this.feeCents = 0,
    this.details = const {},
  });

  final String id;
  final ActivityKind kind;
  final String title;
  final String subtitle;
  final int amountCents;
  final DateTime createdAt;

  /// Family, School fees, Electricity, Groceries, Medical, Airtime,
  /// Mukando or Own accounts.
  final String category;
  final ActivityStatus status;
  final int feeCents;
  final Map<String, String> details;

  Activity copyWith({ActivityStatus? status}) => Activity(
        id: id,
        kind: kind,
        title: title,
        subtitle: subtitle,
        amountCents: amountCents,
        createdAt: createdAt,
        category: category,
        status: status ?? this.status,
        feeCents: feeCents,
        details: details,
      );
}
