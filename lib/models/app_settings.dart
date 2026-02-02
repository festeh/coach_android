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

  /// Rules overlay message. Empty string means use the default.
  final String rulesOverlayMessage;

  /// Rules overlay background color as hex string.
  final String rulesOverlayColor;

  /// Rules overlay button text. Empty string means use the default.
  final String rulesOverlayButtonText;

  /// Rules overlay button color as hex string.
  final String rulesOverlayButtonColor;

  /// Long press challenge duration in seconds.
  final int longPressDurationSeconds;

  /// Phrase the user must type for typing challenge.
  final String typingPhrase;

  const AppSettings({
    this.focusGapThresholdMinutes = defaultFocusGapThresholdMinutes,
    this.reminderCooldownMinutes = defaultReminderCooldownMinutes,
    this.activityTimeoutMinutes = defaultActivityTimeoutMinutes,
    this.overlayMessage = defaultOverlayMessage,
    this.overlayColor = defaultOverlayColor,
    this.overlayButtonText = defaultOverlayButtonText,
    this.overlayButtonColor = defaultOverlayButtonColor,
    this.rulesOverlayMessage = defaultRulesOverlayMessage,
    this.rulesOverlayColor = defaultRulesOverlayColor,
    this.rulesOverlayButtonText = defaultRulesOverlayButtonText,
    this.rulesOverlayButtonColor = defaultRulesOverlayButtonColor,
    this.longPressDurationSeconds = defaultLongPressDurationSeconds,
    this.typingPhrase = defaultTypingPhrase,
  });

  static const int defaultFocusGapThresholdMinutes = 120;
  static const int defaultReminderCooldownMinutes = 60;
  static const int defaultActivityTimeoutMinutes = 5;
  static const String defaultOverlayMessage = '';
  static const String defaultOverlayColor = 'FF000000';
  static const String defaultOverlayButtonText = '';
  static const String defaultOverlayButtonColor = 'FFFF5252';
  static const String defaultRulesOverlayMessage = '';
  static const String defaultRulesOverlayColor = 'FF000000';
  static const String defaultRulesOverlayButtonText = '';
  static const String defaultRulesOverlayButtonColor = 'FFFF5252';
  static const int defaultLongPressDurationSeconds = 5;
  static const String defaultTypingPhrase = 'I will focus';

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
    String? rulesOverlayMessage,
    String? rulesOverlayColor,
    String? rulesOverlayButtonText,
    String? rulesOverlayButtonColor,
    int? longPressDurationSeconds,
    String? typingPhrase,
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
      rulesOverlayMessage: rulesOverlayMessage ?? this.rulesOverlayMessage,
      rulesOverlayColor: rulesOverlayColor ?? this.rulesOverlayColor,
      rulesOverlayButtonText: rulesOverlayButtonText ?? this.rulesOverlayButtonText,
      rulesOverlayButtonColor: rulesOverlayButtonColor ?? this.rulesOverlayButtonColor,
      longPressDurationSeconds: longPressDurationSeconds ?? this.longPressDurationSeconds,
      typingPhrase: typingPhrase ?? this.typingPhrase,
    );
  }
}
