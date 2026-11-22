/// A monthly send, for example an allowance for parents.
class ScheduledSend {
  const ScheduledSend({
    required this.id,
    required this.name,
    required this.phone,
    required this.amountCents,
    required this.dayOfMonth,
    this.note = '',
  });

  final String id;
  final String name;
  final String phone;
  final int amountCents;

  /// 1 to 28, so it exists in every month.
  final int dayOfMonth;
  final String note;

  DateTime nextDate([DateTime? from]) {
    final now = from ?? DateTime.now();
    final thisMonth = DateTime(now.year, now.month, dayOfMonth);
    return thisMonth.isAfter(now) ? thisMonth : DateTime(now.year, now.month + 1, dayOfMonth);
  }
}
