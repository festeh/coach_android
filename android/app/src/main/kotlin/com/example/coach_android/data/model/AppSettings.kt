package com.example.coach_android.data.model

data class AppSettings(
    val focusGapThresholdMinutes: Int = DEFAULT_FOCUS_GAP_THRESHOLD_MINUTES,
    val reminderCooldownMinutes: Int = DEFAULT_REMINDER_COOLDOWN_MINUTES,
    val activityTimeoutMinutes: Int = DEFAULT_ACTIVITY_TIMEOUT_MINUTES,
    val overlayMessage: String = DEFAULT_OVERLAY_MESSAGE,
    val overlayColor: String = DEFAULT_OVERLAY_COLOR,
    val overlayButtonText: String = DEFAULT_OVERLAY_BUTTON_TEXT,
    val overlayButtonColor: String = DEFAULT_OVERLAY_BUTTON_COLOR,
    val rulesOverlayMessage: String = DEFAULT_RULES_OVERLAY_MESSAGE,
    val rulesOverlayColor: String = DEFAULT_RULES_OVERLAY_COLOR,
    val rulesOverlayButtonText: String = DEFAULT_RULES_OVERLAY_BUTTON_TEXT,
    val rulesOverlayButtonColor: String = DEFAULT_RULES_OVERLAY_BUTTON_COLOR,
    val overlayTargetApp: String = DEFAULT_OVERLAY_TARGET_APP,
    val rulesOverlayTargetApp: String = DEFAULT_RULES_OVERLAY_TARGET_APP,
    val longPressDurationSeconds: Int = DEFAULT_LONG_PRESS_DURATION_SECONDS,
    val typingPhrase: String = DEFAULT_TYPING_PHRASE,
) {
    val focusGapThresholdSeconds: Int get() = focusGapThresholdMinutes * 60
    val reminderCooldownSeconds: Int get() = reminderCooldownMinutes * 60
    val activityTimeoutSeconds: Int get() = activityTimeoutMinutes * 60

    companion object {
        const val DEFAULT_FOCUS_GAP_THRESHOLD_MINUTES = 120
        const val DEFAULT_REMINDER_COOLDOWN_MINUTES = 60
        const val DEFAULT_ACTIVITY_TIMEOUT_MINUTES = 5
        const val DEFAULT_OVERLAY_MESSAGE = ""
        const val DEFAULT_OVERLAY_COLOR = "FF000000"
        const val DEFAULT_OVERLAY_BUTTON_TEXT = ""
        const val DEFAULT_OVERLAY_BUTTON_COLOR = "FFFF5252"
        const val DEFAULT_RULES_OVERLAY_MESSAGE = ""
        const val DEFAULT_RULES_OVERLAY_COLOR = "FF000000"
        const val DEFAULT_RULES_OVERLAY_BUTTON_TEXT = ""
        const val DEFAULT_RULES_OVERLAY_BUTTON_COLOR = "FFFF5252"
        const val DEFAULT_OVERLAY_TARGET_APP = ""
        const val DEFAULT_RULES_OVERLAY_TARGET_APP = ""
        const val DEFAULT_LONG_PRESS_DURATION_SECONDS = 5
        const val DEFAULT_TYPING_PHRASE = "I will focus"
    }
}
