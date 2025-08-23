package com.example.foreground_app_monitor

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
        val stopIntent = Intent(context, FocusMonitorService::class.java).apply {
            action = FocusMonitorService.ACTION_STOP_SERVICE
        }
        
        val stopPendingIntent = PendingIntent.getService(
            context,
            0,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        return NotificationCompat.Builder(context, CHANNEL_ID)
            .setContentTitle("Focus Monitor Active")
            .setContentText("Monitoring apps and focus mode")
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
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(content)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setOngoing(true)
            .setShowWhen(false)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
            
        notificationManager.notify(NOTIFICATION_ID, notification)
    }
}