class AppSettings {
  /// Time since last focus before showing a reminder (in minutes).
  final int focusGapThresholdMinutes;

  /// Minimum time between reminder notifications (in minutes).
  final int reminderCooldownMinutes;

  /// User inactivity threshold to consider user inactive (in minutes).
  final int activityTimeoutMinutes;

  const AppSettings({
    this.focusGapThresholdMinutes = defaultFocusGapThresholdMinutes,
    this.reminderCooldownMinutes = defaultReminderCooldownMinutes,
    this.activityTimeoutMinutes = defaultActivityTimeoutMinutes,
  });

  static const int defaultFocusGapThresholdMinutes = 120;
  static const int defaultReminderCooldownMinutes = 60;
  static const int defaultActivityTimeoutMinutes = 5;

  int get focusGapThresholdSeconds => focusGapThresholdMinutes * 60;
  int get reminderCooldownSeconds => reminderCooldownMinutes * 60;
  int get activityTimeoutSeconds => activityTimeoutMinutes * 60;

  AppSettings copyWith({
    int? focusGapThresholdMinutes,
    int? reminderCooldownMinutes,
    int? activityTimeoutMinutes,
  }) {
    return AppSettings(
      focusGapThresholdMinutes:
          focusGapThresholdMinutes ?? this.focusGapThresholdMinutes,
      reminderCooldownMinutes:
          reminderCooldownMinutes ?? this.reminderCooldownMinutes,
      activityTimeoutMinutes:
          activityTimeoutMinutes ?? this.activityTimeoutMinutes,
    );
  }
}
