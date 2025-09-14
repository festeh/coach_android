package com.example.coach_android

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat

class ServiceNotificationManager(private val context: Context) {
    
    companion object {
        const val NOTIFICATION_ID = 1001
        const val CHANNEL_ID = "focus_monitor_service"
        const val CHANNEL_NAME = "Focus Monitor Service"
        const val CHANNEL_DESCRIPTION = "Monitors apps and shows focus reminders"
    }
    
    private val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    
    fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW
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
    
    fun createServiceNotification(): Notification {
        return createServiceNotification(null, null, null)
    }

    fun createServiceNotification(isFocusing: Boolean?, numFocuses: Int?, focusTimeLeft: Int?): Notification {
        val stopIntent = Intent(context, FocusMonitorService::class.java).apply {
            action = FocusMonitorService.ACTION_STOP_SERVICE
        }

        val stopPendingIntent = PendingIntent.getService(
            context,
            0,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val (title, content) = formatNotificationContent(isFocusing, numFocuses, focusTimeLeft)

        return NotificationCompat.Builder(context, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(content)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setOngoing(true)
            .setShowWhen(false)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .addAction(
                android.R.drawable.ic_menu_close_clear_cancel,
                "Stop",
                stopPendingIntent
            )
            .build()
    }
    
    fun updateNotification(title: String, content: String) {
        val stopIntent = Intent(context, FocusMonitorService::class.java).apply {
            action = FocusMonitorService.ACTION_STOP_SERVICE
        }

        val stopPendingIntent = PendingIntent.getService(
            context,
            0,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(content)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setOngoing(true)
            .setShowWhen(false)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .addAction(
                android.R.drawable.ic_menu_close_clear_cancel,
                "Stop",
                stopPendingIntent
            )
            .build()

        notificationManager.notify(NOTIFICATION_ID, notification)
    }

    fun updateNotification(isFocusing: Boolean?, numFocuses: Int?, focusTimeLeft: Int?) {
        val (title, content) = formatNotificationContent(isFocusing, numFocuses, focusTimeLeft)
        updateNotification(title, content)
    }

    private fun formatNotificationContent(isFocusing: Boolean?, numFocuses: Int?, focusTimeLeft: Int?): Pair<String, String> {
        val status = when (isFocusing) {
            true -> "Focusing"
            false -> "Not focusing"
            null -> "Focus Monitor"
        }

        val focusCount = numFocuses ?: 0
        val focusText = when (focusCount) {
            0 -> "No focuses today"
            1 -> "1 focus today"
            else -> "$focusCount focuses today"
        }

        val title = if (isFocusing == null) {
            "Focus Monitor Active"
        } else {
            "$status • $focusText"
        }

        val content = if (isFocusing == true && focusTimeLeft != null && focusTimeLeft > 0) {
            val minutes = focusTimeLeft / 60
            val seconds = focusTimeLeft % 60
            if (minutes > 0) {
                "${minutes}m ${seconds}s remaining"
            } else {
                "${seconds}s remaining"
            }
        } else {
            "Monitoring apps and focus mode"
        }

        return Pair(title, content)
    }
}