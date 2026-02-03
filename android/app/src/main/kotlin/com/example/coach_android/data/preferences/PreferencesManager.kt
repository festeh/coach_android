package com.example.coach_android.data.preferences

import android.content.Context
import android.content.SharedPreferences
import com.example.coach_android.data.model.AppRule
import com.example.coach_android.data.model.AppSettings
import com.example.coach_android.data.model.FocusData
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

class PreferencesManager(
    context: Context,
) {
    private val prefs: SharedPreferences =
        context.getSharedPreferences(
            "coach_prefs",
            Context.MODE_PRIVATE,
        )

    private val json = Json { ignoreUnknownKeys = true }

    // --- Focus Data ---

    fun loadFocusData(): FocusData =
        FocusData(
            isFocusing = prefs.getBoolean("focusingState", false),
            sinceLastChange = prefs.getInt("sinceLastChange", 0),
            focusTimeLeft = prefs.getInt("focusTimeLeft", 0),
            numFocuses = prefs.getInt("numFocuses", 0),
            lastNotificationTime = prefs.getInt("lastNotificationTime", 0),
            lastActivityTime = prefs.getInt("lastActivityTime", 0),
            lastFocusEndTime = prefs.getInt("lastFocusEndTime", 0),
        )

    fun saveFocusData(data: FocusData) {
        prefs
            .edit()
            .putBoolean("focusingState", data.isFocusing)
            .putInt("sinceLastChange", data.sinceLastChange)
            .putInt("focusTimeLeft", data.focusTimeLeft)
            .putInt("numFocuses", data.numFocuses)
            .putInt("lastNotificationTime", data.lastNotificationTime)
            .putInt("lastActivityTime", data.lastActivityTime)
            .putInt("lastFocusEndTime", data.lastFocusEndTime)
            .apply()
    }

    // --- Monitored Packages ---

    fun loadMonitoredPackages(): Set<String> {
        val jsonStr = prefs.getString("selectedAppPackages", null) ?: return emptySet()
        return try {
            json.decodeFromString<List<String>>(jsonStr).toSet()
        } catch (e: Exception) {
            emptySet()
        }
    }

    fun saveMonitoredPackages(packages: Set<String>) {
        val jsonStr = json.encodeToString(packages.toList())
        prefs.edit().putString("selectedAppPackages", jsonStr).apply()
    }

    // --- App Rules ---

    fun loadRules(): Map<String, AppRule> {
        val jsonStr = prefs.getString("appRules", null) ?: return emptyMap()
        return try {
            json.decodeFromString<Map<String, AppRule>>(jsonStr)
        } catch (e: Exception) {
            emptyMap()
        }
    }

    fun saveRules(rules: Map<String, AppRule>) {
        val jsonStr = json.encodeToString(rules)
        prefs.edit().putString("appRules", jsonStr).apply()
    }

    // --- Pending Challenges ---

    fun loadPendingChallengeIds(): List<String> {
        val jsonStr = prefs.getString("pendingChallenges", null) ?: return emptyList()
        return try {
            json.decodeFromString<List<String>>(jsonStr)
        } catch (e: Exception) {
            emptyList()
        }
    }

    fun savePendingChallengeIds(ids: List<String>) {
        val jsonStr = json.encodeToString(ids)
        prefs.edit().putString("pendingChallenges", jsonStr).apply()
    }

    // --- App Settings ---

    fun loadSettings(): AppSettings {
        val gapSeconds = prefs.getInt("settingsFocusGapThreshold", -1)
        val cooldownSeconds = prefs.getInt("settingsReminderCooldown", -1)
        val timeoutSeconds = prefs.getInt("settingsActivityTimeout", -1)

        return AppSettings(
            focusGapThresholdMinutes =
                if (gapSeconds >= 0) {
                    gapSeconds / 60
                } else {
                    AppSettings.DEFAULT_FOCUS_GAP_THRESHOLD_MINUTES
                },
            reminderCooldownMinutes =
                if (cooldownSeconds >= 0) {
                    cooldownSeconds / 60
                } else {
                    AppSettings.DEFAULT_REMINDER_COOLDOWN_MINUTES
                },
            activityTimeoutMinutes =
                if (timeoutSeconds >= 0) {
                    timeoutSeconds / 60
                } else {
                    AppSettings.DEFAULT_ACTIVITY_TIMEOUT_MINUTES
                },
            overlayMessage =
                prefs.getString("settingsOverlayMessage", null)
                    ?: AppSettings.DEFAULT_OVERLAY_MESSAGE,
            overlayColor =
                prefs.getString("settingsOverlayColor", null)
                    ?: AppSettings.DEFAULT_OVERLAY_COLOR,
            overlayButtonText =
                prefs.getString("settingsOverlayButtonText", null)
                    ?: AppSettings.DEFAULT_OVERLAY_BUTTON_TEXT,
            overlayButtonColor =
                prefs.getString("settingsOverlayButtonColor", null)
                    ?: AppSettings.DEFAULT_OVERLAY_BUTTON_COLOR,
            rulesOverlayMessage =
                prefs.getString("settingsRulesOverlayMessage", null)
                    ?: AppSettings.DEFAULT_RULES_OVERLAY_MESSAGE,
            rulesOverlayColor =
                prefs.getString("settingsRulesOverlayColor", null)
                    ?: AppSettings.DEFAULT_RULES_OVERLAY_COLOR,
            rulesOverlayButtonText =
                prefs.getString("settingsRulesOverlayButtonText", null)
                    ?: AppSettings.DEFAULT_RULES_OVERLAY_BUTTON_TEXT,
            rulesOverlayButtonColor =
                prefs.getString("settingsRulesOverlayButtonColor", null)
                    ?: AppSettings.DEFAULT_RULES_OVERLAY_BUTTON_COLOR,
            overlayTargetApp =
                prefs.getString("settingsOverlayTargetApp", null)
                    ?: AppSettings.DEFAULT_OVERLAY_TARGET_APP,
            rulesOverlayTargetApp =
                prefs.getString("settingsRulesOverlayTargetApp", null)
                    ?: AppSettings.DEFAULT_RULES_OVERLAY_TARGET_APP,
            longPressDurationSeconds =
                prefs
                    .getInt("settingsLongPressDuration", -1)
                    .let { if (it >= 0) it else AppSettings.DEFAULT_LONG_PRESS_DURATION_SECONDS },
            typingPhrase =
                prefs.getString("settingsTypingPhrase", null)
                    ?: AppSettings.DEFAULT_TYPING_PHRASE,
        )
    }

    fun saveSettings(settings: AppSettings) {
        prefs
            .edit()
            .putInt("settingsFocusGapThreshold", settings.focusGapThresholdSeconds)
            .putInt("settingsReminderCooldown", settings.reminderCooldownSeconds)
            .putInt("settingsActivityTimeout", settings.activityTimeoutSeconds)
            .putString("settingsOverlayMessage", settings.overlayMessage)
            .putString("settingsOverlayColor", settings.overlayColor)
            .putString("settingsOverlayButtonText", settings.overlayButtonText)
            .putString("settingsOverlayButtonColor", settings.overlayButtonColor)
            .putString("settingsRulesOverlayMessage", settings.rulesOverlayMessage)
            .putString("settingsRulesOverlayColor", settings.rulesOverlayColor)
            .putString("settingsRulesOverlayButtonText", settings.rulesOverlayButtonText)
            .putString("settingsRulesOverlayButtonColor", settings.rulesOverlayButtonColor)
            .putString("settingsOverlayTargetApp", settings.overlayTargetApp)
            .putString("settingsRulesOverlayTargetApp", settings.rulesOverlayTargetApp)
            .putInt("settingsLongPressDuration", settings.longPressDurationSeconds)
            .putString("settingsTypingPhrase", settings.typingPhrase)
            .apply()
    }
}
