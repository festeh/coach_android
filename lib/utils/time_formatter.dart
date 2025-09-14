/// Utility class for formatting time-related strings
class TimeFormatter {
  /// Formats a Unix timestamp (in seconds) as "X time ago"
  /// Returns empty string if timestamp is 0
  static String formatTimeAgo(int unixTimestamp) {
    if (unixTimestamp == 0) {
      return '';
    }

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final diffSeconds = now - unixTimestamp;

    if (diffSeconds < 0) {
      return 'just now';
    }

    if (diffSeconds < 60) {
      return '${diffSeconds}s ago';
    }

    final diffMinutes = diffSeconds ~/ 60;
    if (diffMinutes < 60) {
      return '${diffMinutes}m ago';
    }

    final diffHours = diffMinutes ~/ 60;
    if (diffHours < 24) {
      return '${diffHours}h ago';
    }

    final diffDays = diffHours ~/ 24;
    return '${diffDays}d ago';
  }

  /// Formats seconds into human-readable duration
  /// Example: 3661 -> "1h 1m 1s"
  static String formatDuration(int seconds) {
    if (seconds == 0) {
      return '0s';
    }

    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    final parts = <String>[];

    if (hours > 0) {
      parts.add('${hours}h');
    }

    if (minutes > 0) {
      parts.add('${minutes}m');
    }

    if (remainingSeconds > 0 || parts.isEmpty) {
      parts.add('${remainingSeconds}s');
    }

    return parts.join(' ');
  }

  /// Formats timing info for display in apps view
  static List<String> formatTimingInfo({
    required int lastNotificationTime,
    required int lastActivityTime,
    required int lastFocusEndTime,
    required int numFocuses,
  }) {
    final info = <String>[];

    // Always show focus count
    if (numFocuses > 0) {
      info.add('$numFocuses focuses today');
    } else {
      info.add('No focuses today');
    }

    // Show last focus time if available
    if (lastFocusEndTime > 0) {
      final focusAgo = formatTimeAgo(lastFocusEndTime);
      if (focusAgo.isNotEmpty) {
        info.add('Last focus: $focusAgo');
      }
    }

    // Show last activity time if available
    if (lastActivityTime > 0) {
      final activityAgo = formatTimeAgo(lastActivityTime);
      if (activityAgo.isNotEmpty) {
        info.add('Last activity: $activityAgo');
      }
    }

    // Show last notification time if available
    if (lastNotificationTime > 0) {
      final notificationAgo = formatTimeAgo(lastNotificationTime);
      if (notificationAgo.isNotEmpty) {
        info.add('Last reminder: $notificationAgo');
      }
    }

    return info;
  }
}