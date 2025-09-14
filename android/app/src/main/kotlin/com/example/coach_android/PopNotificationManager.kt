package com.example.coach_android

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat

class PopNotificationManager(private val context: Context) {

    companion object {
        const val TAG = "PopNotificationManager"
        const val NOTIFICATION_ID = 1002
        const val CHANNEL_ID = "focus_reminder"
        const val CHANNEL_NAME = "Focus Reminders"
        const val CHANNEL_DESCRIPTION = "Reminds you to focus when inactive for too long"

        // Timing constants (in seconds)
        const val FOCUS_GAP_THRESHOLD = 2 * 60 * 60 // 2 hours
        const val REMINDER_COOLDOWN = 60 * 60 // 60 minutes
        const val ACTIVITY_TIMEOUT = 5 * 60 // 5 minutes to consider user inactive

        // SharedPreferences keys
        const val PREF_LAST_REMINDER_TIME = "last_focus_reminder_time"
        const val PREF_LAST_ACTIVITY_TIME = "last_activity_time"
    }

    private val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    private val sharedPrefs: SharedPreferences = context.getSharedPreferences("focus_reminders", Context.MODE_PRIVATE)

    init {
        createNotificationChannel()
    }

    fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_DEFAULT
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
        sharedPrefs.edit()
            .putLong(PREF_LAST_ACTIVITY_TIME, currentTime)
            .apply()

        Log.d(TAG, "Activity updated at: $currentTime")
    }

    fun checkAndShowFocusReminder(sinceLastChange: Int, isFocusing: Boolean) {
        val currentTime = System.currentTimeMillis() / 1000

        // Don't show reminder if already focusing
        if (isFocusing) {
            Log.d(TAG, "User is already focusing, skipping reminder")
            return
        }

        // Check if enough time has passed since last focus (2 hours)
        if (sinceLastChange < FOCUS_GAP_THRESHOLD) {
            Log.d(TAG, "Not enough time since last focus: ${sinceLastChange}s < ${FOCUS_GAP_THRESHOLD}s")
            return
        }

        // Check if user has been active recently
        val lastActivityTime = sharedPrefs.getLong(PREF_LAST_ACTIVITY_TIME, 0)
        val timeSinceActivity = currentTime - lastActivityTime

        if (timeSinceActivity > ACTIVITY_TIMEOUT) {
            Log.d(TAG, "User not active recently: ${timeSinceActivity}s > ${ACTIVITY_TIMEOUT}s")
            return
        }

        // Check cooldown period
        val lastReminderTime = sharedPrefs.getLong(PREF_LAST_REMINDER_TIME, 0)
        val timeSinceLastReminder = currentTime - lastReminderTime

        if (timeSinceLastReminder < REMINDER_COOLDOWN) {
            Log.d(TAG, "Reminder cooldown active: ${timeSinceLastReminder}s < ${REMINDER_COOLDOWN}s")
            return
        }

        // All conditions met - show reminder
        Log.i(TAG, "Showing focus reminder - gap: ${sinceLastChange}s, activity: ${timeSinceActivity}s ago, last reminder: ${timeSinceLastReminder}s ago")
        showFocusReminder()

        // Update last reminder time
        sharedPrefs.edit()
            .putLong(PREF_LAST_REMINDER_TIME, currentTime)
            .apply()
    }

    private fun showFocusReminder() {
        // Create intent for "Focus Now" action
        val focusIntent = Intent(context, FocusMonitorService::class.java).apply {
            action = FocusMonitorService.ACTION_FOCUS_NOW
        }

        val focusPendingIntent = PendingIntent.getService(
            context,
            0,
            focusIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Create intent to open main app
        val openAppIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val openAppPendingIntent = PendingIntent.getActivity(
            context,
            1,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setContentTitle("Time to focus?")
            .setContentText("You haven't focused in a while. Ready for a focus session?")
            .setSmallIcon(R.drawable.ic_notification_c)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setAutoCancel(true)
            .setContentIntent(openAppPendingIntent)
            .addAction(
                android.R.drawable.ic_media_play,
                "Focus Now",
                focusPendingIntent
            )
            .build()

        notificationManager.notify(NOTIFICATION_ID, notification)
        Log.i(TAG, "Focus reminder notification shown")

        // Update notification time in Dart via method channel
        updateNotificationTimeInDart()
    }

    private fun updateNotificationTimeInDart() {
        try {
            // Get the service instance to access the background method channel
            val service = FocusMonitorService.getInstance()
            service?.updateNotificationTimeInBackground()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to update notification time in Dart", e)
        }
    }

    fun forceShowFocusReminder() {
        Log.i(TAG, "Force showing focus reminder (debug mode - bypassing all conditions)")
        showFocusReminder()

        // Update last reminder time for tracking
        val currentTime = System.currentTimeMillis() / 1000
        sharedPrefs.edit()
            .putLong(PREF_LAST_REMINDER_TIME, currentTime)
            .apply()
        Log.d(TAG, "Updated last reminder time: $currentTime")
    }

    fun dismissReminder() {
        notificationManager.cancel(NOTIFICATION_ID)
        Log.d(TAG, "Focus reminder dismissed")
    }
}