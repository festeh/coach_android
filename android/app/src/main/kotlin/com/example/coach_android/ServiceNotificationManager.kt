package com.example.coach_android

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat

class ServiceNotificationManager(
    private val context: Context,
) {
    private val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel =
                NotificationChannel(
                    CHANNEL_ID,
                    CHANNEL_NAME,
                    NotificationManager.IMPORTANCE_LOW,
                ).apply {
                    description = CHANNEL_DESCRIPTION
                    setShowBadge(false)
                    enableLights(false)
                    enableVibration(false)
                    setSound(null, null)
                }

            notificationManager.createNotificationChannel(channel)
        }
    }

    fun createServiceNotification(
        isFocusing: Boolean? = null,
        numFocuses: Int? = null,
        focusTimeLeft: Int? = null,
        isConnected: Boolean = false,
    ): Notification = buildNotification(isFocusing, numFocuses, focusTimeLeft, isConnected)

    fun updateNotification(
        isFocusing: Boolean? = null,
        numFocuses: Int? = null,
        focusTimeLeft: Int? = null,
        isConnected: Boolean = false,
    ) {
        val notification = buildNotification(isFocusing, numFocuses, focusTimeLeft, isConnected)
        notificationManager.notify(NOTIFICATION_ID, notification)
    }

    private fun buildNotification(
        isFocusing: Boolean?,
        numFocuses: Int?,
        focusTimeLeft: Int?,
        isConnected: Boolean,
    ): Notification {
        val focusPendingIntent =
            PendingIntent.getService(
                context,
                0,
                Intent(context, FocusMonitorService::class.java).apply {
                    action = FocusMonitorService.ACTION_FOCUS_NOW
                },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )

        val (title, content) = formatNotificationContent(isFocusing, numFocuses, focusTimeLeft, isConnected)

        val iconRes =
            if (isFocusing == true) {
                R.drawable.ic_notification_c
            } else {
                R.drawable.ic_notification_c_crossed
            }

        return NotificationCompat
            .Builder(context, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(content)
            .setSmallIcon(iconRes)
            .setOngoing(true)
            .setShowWhen(false)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .addAction(
                android.R.drawable.ic_media_play,
                "Focus",
                focusPendingIntent,
            ).build()
    }

    private fun formatNotificationContent(
        isFocusing: Boolean?,
        numFocuses: Int?,
        focusTimeLeft: Int?,
        isConnected: Boolean,
    ): Pair<String, String> {
        val connectionStatus = if (isConnected) STATUS_ACTIVE else STATUS_INACTIVE

        val focusCount = numFocuses ?: 0
        val focusText =
            when (focusCount) {
                0 -> FOCUS_COUNT_ZERO
                1 -> FOCUS_COUNT_ONE
                else -> "$focusCount $FOCUS_COUNT_SUFFIX"
            }

        val title =
            if (isFocusing == null) {
                TITLE_DEFAULT
            } else {
                val focusStatus = if (isFocusing) STATUS_FOCUSING else STATUS_NOT_FOCUSING
                "$focusStatus • $focusText"
            }

        val content =
            if (isFocusing == true && focusTimeLeft != null && focusTimeLeft > 0) {
                val minutes = focusTimeLeft / 60
                val seconds = focusTimeLeft % 60
                if (minutes > 0) {
                    "${minutes}m ${seconds}s $TIME_REMAINING"
                } else {
                    "${seconds}s $TIME_REMAINING"
                }
            } else {
                "$CONTENT_MONITORING • $connectionStatus"
            }

        return Pair(title, content)
    }

    companion object {
        const val NOTIFICATION_ID = 1001
        const val CHANNEL_ID = "focus_monitor_service"
        const val CHANNEL_NAME = "Focus Monitor Service"
        const val CHANNEL_DESCRIPTION = "Monitors apps and shows focus reminders"

        private const val STATUS_ACTIVE = "Active"
        private const val STATUS_INACTIVE = "Inactive"
        private const val STATUS_FOCUSING = "Focusing"
        private const val STATUS_NOT_FOCUSING = "Not focusing"
        private const val TITLE_DEFAULT = "Focus Monitor"
        private const val CONTENT_MONITORING = "Monitoring"
        private const val TIME_REMAINING = "remaining"
        private const val FOCUS_COUNT_ZERO = "No focuses today"
        private const val FOCUS_COUNT_ONE = "1 focus today"
        private const val FOCUS_COUNT_SUFFIX = "focuses today"
    }
}
