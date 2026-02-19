package com.example.coach_android

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.os.Build
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import com.example.coach_android.data.db.HookResultEntity
import java.util.concurrent.atomic.AtomicInteger

class HookNotificationManager(
    private val context: Context,
) {
    companion object {
        const val TAG = "HookNotificationManager"
        const val SUMMARY_NOTIFICATION_ID = 1003
        const val CHANNEL_ID = "hook_results"
        const val CHANNEL_NAME = "Hook Results"
        const val CHANNEL_DESCRIPTION = "Notifications for hook results (e.g. AI coaching messages)"
        const val GROUP_KEY = "com.example.coach_android.HOOK_RESULTS"
        private const val MAX_CONTENT_LENGTH = 200
    }

    private val notificationManager =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    private val powerManager =
        context.getSystemService(Context.POWER_SERVICE) as PowerManager
    private val nextId = AtomicInteger(SUMMARY_NOTIFICATION_ID + 1)

    init {
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
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

    fun showIfActive(result: HookResultEntity) {
        if (!powerManager.isInteractive) {
            Log.d(TAG, "Screen off, skipping notification for hook result ${result.id}")
            return
        }

        val openAppIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val openAppPendingIntent =
            PendingIntent.getActivity(
                context,
                nextId.get(),
                openAppIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )

        val truncatedContent =
            if (result.content.length > MAX_CONTENT_LENGTH) {
                result.content.take(MAX_CONTENT_LENGTH) + "..."
            } else {
                result.content
            }

        // Individual notification
        val notification =
            NotificationCompat
                .Builder(context, CHANNEL_ID)
                .setContentText(truncatedContent)
                .setStyle(NotificationCompat.BigTextStyle().bigText(result.content))
                .setSmallIcon(R.drawable.ic_notification_lightbulb)
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .setCategory(NotificationCompat.CATEGORY_MESSAGE)
                .setAutoCancel(true)
                .setContentIntent(openAppPendingIntent)
                .setGroup(GROUP_KEY)
                .build()

        val notificationId = nextId.getAndIncrement()
        notificationManager.notify(notificationId, notification)

        // Summary notification (groups the stack)
        val summary =
            NotificationCompat
                .Builder(context, CHANNEL_ID)
                .setContentTitle("Coach")
                .setSmallIcon(R.drawable.ic_notification_lightbulb)
                .setGroup(GROUP_KEY)
                .setGroupSummary(true)
                .setAutoCancel(true)
                .build()

        notificationManager.notify(SUMMARY_NOTIFICATION_ID, summary)

        Log.i(TAG, "Hook result notification shown: ${result.hookId} (id=$notificationId)")
    }
}
