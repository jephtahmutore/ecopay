/// Small date helpers, so we do not need an extra package.
class Dates {
  Dates._();

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// 22 Nov
  static String short(DateTime d) => '${d.day} ${_months[d.month - 1]}';

  /// 22 Nov, 14:05
  static String withTime(DateTime d) => '${short(d)}, ${_two(d.hour)}:${_two(d.minute)}';

  /// Just now, 5 min ago, Yesterday, 3 days ago, 12 Nov
  static String relative(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inDays < 1) return '${diff.inHours} h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return short(d);
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}
