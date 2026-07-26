/// مساعد لعرض الوقت بشكل ودّي (مثل "منذ 5 دقائق")
class TimeAgoHelper {
  static String format(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '$m ${m == 1 ? "minute" : "minutes"} ago';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return '$h ${h == 1 ? "hour" : "hours"} ago';
    }
    if (diff.inDays < 7) {
      final d = diff.inDays;
      return '$d ${d == 1 ? "day" : "days"} ago';
    }
    if (diff.inDays < 30) {
      final w = (diff.inDays / 7).floor();
      return '$w ${w == 1 ? "week" : "weeks"} ago';
    }
    if (diff.inDays < 365) {
      final mo = (diff.inDays / 30).floor();
      return '$mo ${mo == 1 ? "month" : "months"} ago';
    }
    final y = (diff.inDays / 365).floor();
    return '$y ${y == 1 ? "year" : "years"} ago';
  }

  /// تنسيق المدة (مثل 1:23:45 أو 12:34)
  static String formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    if (h > 0) {
      return '$h:$mm:$ss';
    }
    return '$mm:$ss';
  }
}