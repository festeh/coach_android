package com.example.coach_android

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import com.example.coach_android.data.preferences.PreferencesManager

class PopNotificationManager(
    private val context: Context,
) {
    companion object {
        const val TAG = "PopNotificationManager"
        const val NOTIFICATION_ID = 1002
        const val CHANNEL_ID = "focus_reminder"
        const val CHANNEL_NAME = "Focus Reminders"
        const val CHANNEL_DESCRIPTION = "Reminds you to focus when inactive for too long"

        const val PREF_LAST_REMINDER_TIME = "last_focus_reminder_time"
        const val PREF_LAST_ACTIVITY_TIME = "last_activity_time"
    }

    private val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    private val sharedPrefs: SharedPreferences = context.getSharedPreferences("focus_reminders", Context.MODE_PRIVATE)
    private val prefsManager = PreferencesManager(context)

    private val settings get() = prefsManager.loadSettings()

    init {
        createNotificationChannel()
    }

    fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel =
                NotificationChannel(
                    CHANNEL_ID,
                    CHANNEL_NAME,
                    NotificationManager.IMPORTANCE_DEFAULT,
                ).apply {
                    description = CHANNEL_DESCRIPTION
                    setShowBadge(true)
                    enableLights(true)
                    enableVibration(true)
                }

            notificationManager.createNotificationChannel(channel)
        }
    }

    fun updateActivity() {
        val currentTime = System.currentTimeMillis() / 1000
        sharedPrefs
            .edit()
            .putLong(PREF_LAST_ACTIVITY_TIME, currentTime)
            .apply()

        Log.d(TAG, "Activity updated at: $currentTime")
    }

    fun checkAndShowFocusReminder(
        sinceLastChange: Int,
        isFocusing: Boolean,
    ) {
        val currentTime = System.currentTimeMillis() / 1000
        val s = settings

        Log.d(
            TAG,
            "Settings: focusGapThreshold=${s.focusGapThresholdSeconds}s, reminderCooldown=${s.reminderCooldownSeconds}s, activityTimeout=${s.activityTimeoutSeconds}s",
        )

        if (isFocusing) {
            Log.d(TAG, "User is already focusing, skipping reminder")
            return
        }

        if (sinceLastChange < s.focusGapThresholdSeconds) {
            Log.d(TAG, "Not enough time since last focus: ${sinceLastChange}s < ${s.focusGapThresholdSeconds}s")
            return
        }

        val lastActivityTime = sharedPrefs.getLong(PREF_LAST_ACTIVITY_TIME, 0)
        val timeSinceActivity = currentTime - lastActivityTime

        if (timeSinceActivity > s.activityTimeoutSeconds) {
            Log.d(TAG, "User not active recently: ${timeSinceActivity}s > ${s.activityTimeoutSeconds}s")
            return
        }

        val lastReminderTime = sharedPrefs.getLong(PREF_LAST_REMINDER_TIME, 0)
        val timeSinceLastReminder = currentTime - lastReminderTime

        if (timeSinceLastReminder < s.reminderCooldownSeconds) {
            Log.d(TAG, "Reminder cooldown active: ${timeSinceLastReminder}s < ${s.reminderCooldownSeconds}s")
            return
        }

        Log.i(
            TAG,
            "Showing focus reminder - gap: ${sinceLastChange}s, activity: ${timeSinceActivity}s ago, last reminder: ${timeSinceLastReminder}s ago",
        )
        showFocusReminder()

        sharedPrefs
            .edit()
            .putLong(PREF_LAST_REMINDER_TIME, currentTime)
            .apply()
    }

    private fun showFocusReminder() {
        val focusIntent =
            Intent(context, FocusMonitorService::class.java).apply {
                action = FocusMonitorService.ACTION_FOCUS_NOW
            }

        val focusPendingIntent =
            PendingIntent.getService(
                context,
                0,
                focusIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )

        val openAppIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val openAppPendingIntent =
            PendingIntent.getActivity(
                context,
                1,
                openAppIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )

        val notification =
            NotificationCompat
                .Builder(context, CHANNEL_ID)
                .setContentTitle("Time to focus?")
                .setContentText("You haven't focused in a while. Ready for a focus session?")
                .setSmallIcon(R.drawable.ic_notification_exclamation)
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .setCategory(NotificationCompat.CATEGORY_REMINDER)
                .setAutoCancel(true)
                .setContentIntent(openAppPendingIntent)
                .addAction(
                    android.R.drawable.ic_media_play,
                    "Focus Now",
                    focusPendingIntent,
                ).build()

        notificationManager.notify(NOTIFICATION_ID, notification)
        Log.i(TAG, "Focus reminder notification shown")

        FocusMonitorService.getInstance()?.updateNotificationTimeInBackground()
    }

    fun forceShowFocusReminder() {
        Log.i(TAG, "Force showing focus reminder (debug)")
        showFocusReminder()

        val currentTime = System.currentTimeMillis() / 1000
        sharedPrefs
            .edit()
            .putLong(PREF_LAST_REMINDER_TIME, currentTime)
            .apply()
    }

    fun dismissReminder() {
        notificationManager.cancel(NOTIFICATION_ID)
        Log.d(TAG, "Focus reminder dismissed")
    }
}
