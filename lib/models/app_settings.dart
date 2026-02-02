class AppSettings {
  /// Time since last focus before showing a reminder (in minutes).
  final int focusGapThresholdMinutes;

  /// Minimum time between reminder notifications (in minutes).
  final int reminderCooldownMinutes;

  /// User inactivity threshold to consider user inactive (in minutes).
  final int activityTimeoutMinutes;

  /// Custom overlay message. Empty string means use the default.
  /// Supports {app} placeholder for the detected app name.
  final String overlayMessage;

  /// Overlay background color as hex string (e.g., "FF000000").
  final String overlayColor;

  /// Custom overlay button text. Empty string means use the default ("Got it!").
  final String overlayButtonText;

  /// Overlay button color as hex string (e.g., "FFFF5252").
  final String overlayButtonColor;

  const AppSettings({
    this.focusGapThresholdMinutes = defaultFocusGapThresholdMinutes,
    this.reminderCooldownMinutes = defaultReminderCooldownMinutes,
    this.activityTimeoutMinutes = defaultActivityTimeoutMinutes,
    this.overlayMessage = defaultOverlayMessage,
    this.overlayColor = defaultOverlayColor,
    this.overlayButtonText = defaultOverlayButtonText,
    this.overlayButtonColor = defaultOverlayButtonColor,
  });

  static const int defaultFocusGapThresholdMinutes = 120;
  static const int defaultReminderCooldownMinutes = 60;
  static const int defaultActivityTimeoutMinutes = 5;
  static const String defaultOverlayMessage = '';
  static const String defaultOverlayColor = 'FF000000';
  static const String defaultOverlayButtonText = '';
  static const String defaultOverlayButtonColor = 'FFFF5252';

  int get focusGapThresholdSeconds => focusGapThresholdMinutes * 60;
  int get reminderCooldownSeconds => reminderCooldownMinutes * 60;
  int get activityTimeoutSeconds => activityTimeoutMinutes * 60;

  AppSettings copyWith({
    int? focusGapThresholdMinutes,
    int? reminderCooldownMinutes,
    int? activityTimeoutMinutes,
    String? overlayMessage,
    String? overlayColor,
    String? overlayButtonText,
    String? overlayButtonColor,
  }) {
    return AppSettings(
      focusGapThresholdMinutes:
          focusGapThresholdMinutes ?? this.focusGapThresholdMinutes,
      reminderCooldownMinutes:
          reminderCooldownMinutes ?? this.reminderCooldownMinutes,
      activityTimeoutMinutes:
          activityTimeoutMinutes ?? this.activityTimeoutMinutes,
      overlayMessage: overlayMessage ?? this.overlayMessage,
      overlayColor: overlayColor ?? this.overlayColor,
      overlayButtonText: overlayButtonText ?? this.overlayButtonText,
      overlayButtonColor: overlayButtonColor ?? this.overlayButtonColor,
    );
  }
}
