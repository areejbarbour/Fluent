import 'package:intl/intl.dart';

/// Professional date/time formatting inspired by iOS / Slack / Instagram.
///
/// Rules:
/// - Parse backend ISO / SQL timestamps safely.
/// - Convert to device local timezone.
/// - Return null when backend sent nothing → UI hides the row.
///
/// Requires package: intl
class AppDateFormat {
  AppDateFormat._();

  static DateTime? parse(String? raw) {
    if (raw == null) return null;
    final s = raw.trim();
    if (s.isEmpty || s.toLowerCase() == 'null') return null;
    try {
      return DateTime.parse(s).toLocal();
    } catch (_) {
      try {
        return DateFormat('yyyy-MM-dd HH:mm:ss').parse(s, true).toLocal();
      } catch (_) {
        return null;
      }
    }
  }

  /// Absolute long form: "Aug 7, 2026 at 1:33 AM"
  static String? absolute(String? raw) {
    final dt = parse(raw);
    if (dt == null) return null;
    return DateFormat('MMM d, yyyy \'at\' h:mm a').format(dt);
  }

  /// Absolute short: "Aug 7, 2026"
  static String? dateOnly(String? raw) {
    final dt = parse(raw);
    if (dt == null) return null;
    return DateFormat('MMM d, yyyy').format(dt);
  }

  /// Time only: "1:33 AM"
  static String? timeOnly(String? raw) {
    final dt = parse(raw);
    if (dt == null) return null;
    return DateFormat('h:mm a').format(dt);
  }

  /// Smart primary label (global-apps style):
  /// - < 1 min   → Just now
  /// - < 60 min  → 5 minutes ago
  /// - < 24 h    → 3 hours ago
  /// - yesterday → Yesterday at 1:33 AM
  /// - < 7 days  → Thursday at 1:33 AM
  /// - same year → Aug 7 at 1:33 AM
  /// - else      → Aug 7, 2025 at 1:33 AM
  static String? smart(String? raw) {
    final dt = parse(raw);
    if (dt == null) return null;

    final now = DateTime.now();
    final diff = now.difference(dt);
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfThatDay = DateTime(dt.year, dt.month, dt.day);
    final dayDiff = startOfToday.difference(startOfThatDay).inDays;

    if (diff.inSeconds < 45) return 'Just now';

    if (diff.inMinutes < 60) {
      final m = diff.inMinutes.clamp(1, 59);
      return m == 1 ? '1 minute ago' : '$m minutes ago';
    }

    if (dayDiff == 0 && diff.inHours < 24) {
      final h = diff.inHours.clamp(1, 23);
      return h == 1 ? '1 hour ago' : '$h hours ago';
    }

    final time = DateFormat('h:mm a').format(dt);

    if (dayDiff == 1) return 'Yesterday at $time';

    if (dayDiff > 1 && dayDiff < 7) {
      final weekday = DateFormat('EEEE').format(dt); // Thursday
      return '$weekday at $time';
    }

    if (dt.year == now.year) {
      return DateFormat('MMM d \'at\' h:mm a').format(dt); // Aug 7 at 1:33 AM
    }

    return DateFormat('MMM d, yyyy \'at\' h:mm a').format(dt);
  }

  /// Secondary muted line under smart primary.
  /// Hidden when smart already contains the full absolute form
  /// (i.e. older than a week) to avoid duplication.
  static String? subtitle(String? raw) {
    final dt = parse(raw);
    if (dt == null) return null;

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfThatDay = DateTime(dt.year, dt.month, dt.day);
    final dayDiff = startOfToday.difference(startOfThatDay).inDays;

    // For recent items, show the absolute date underneath.
    if (dayDiff < 7) {
      return DateFormat('MMM d, yyyy \'at\' h:mm a').format(dt);
    }
    // For older items, smart() is already absolute — no subtitle.
    return null;
  }
}
