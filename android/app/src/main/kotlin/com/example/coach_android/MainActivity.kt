package com.example.coach_android

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.util.Log
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.Timer
import java.util.TimerTask

class MainActivity : FlutterActivity() {
    private val METHOD_CHANNEL = "com.example.coach_android/appCount"
    private val EVENT_CHANNEL_FOREGROUND_APP = "com.example.coach_android/foregroundApp"
    private var foregroundAppStreamHandler: ForegroundAppStreamHandler? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Method Channel for app list
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledAppsCount" -> result.success(getInstalledAppsCount())
                "getInstalledApps" -> result.success(getInstalledApps())
                else -> result.notImplemented()
            }
        }

        // Event Channel for foreground app monitoring
        foregroundAppStreamHandler = ForegroundAppStreamHandler(context)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL_FOREGROUND_APP).setStreamHandler(foregroundAppStreamHandler)
    }

     override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        super.cleanUpFlutterEngine(flutterEngine)
        // Clean up the stream handler when the engine is destroyed
        foregroundAppStreamHandler?.onCancel(null) // Explicitly cancel
        foregroundAppStreamHandler = null
    }


    private fun getInstalledAppsCount(): Int {
        val pm = context.packageManager
        val packages = pm.getInstalledApplications(PackageManager.GET_META_DATA)
        return packages.size
    }
    
    private fun getInstalledApps(): List<Map<String, Any>> {
        val pm = context.packageManager
        val packages = pm.getInstalledApplications(PackageManager.GET_META_DATA)
        
        return packages
            .filter { appInfo -> 
                // Filter for non-system apps (likely installed by user from Play Store)
                (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) == 0
            }
            .mapNotNull { appInfo ->
                try {
                    val appName = appInfo.loadLabel(pm).toString()
                    val packageName = appInfo.packageName
                    // Ensure we have both name and package name
                    if (appName.isNotEmpty() && packageName.isNotEmpty()) {
                         mapOf("name" to appName, "packageName" to packageName)
                    } else {
                        null // Skip if essential info is missing
                    }
                } catch (e: Exception) {
                    // Log error or handle specific exceptions if needed
                    null // Skip on error loading app info
                }
            }
            .sortedBy { it["name"] as String } // Sort by app name
    }
}


// Handles the stream for foreground app events
class ForegroundAppStreamHandler(private val context: Context) : EventChannel.StreamHandler {
    private val TAG = "ForegroundAppStream"
    private var handler: Handler? = null
    private var eventSink: EventChannel.EventSink? = null
    private var runnable: Runnable? = null
    private var lastForegroundApp: String? = null

    override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
        Log.d(TAG, "onListen called")
        if (sink == null) {
            Log.e(TAG, "EventSink is null in onListen")
            return
        }
        eventSink = sink

        if (!hasUsageStatsPermission()) {
            Log.w(TAG, "Usage stats permission not granted.")
            eventSink?.error("PERMISSION_DENIED", "Usage stats permission is required.", null)
            // Don't start the handler if permission is missing
            // The app should guide the user to grant permission
            return
        }

        handler = Handler(Looper.getMainLooper())
        runnable = object : Runnable {
            @RequiresApi(Build.VERSION_CODES.LOLLIPOP_MR1) // UsageStatsManager requires Lollipop MR1 (API 22)
            override fun run() {
                val foregroundApp = getForegroundAppPackageName()
                if (foregroundApp != null && foregroundApp != lastForegroundApp) {
                     Log.d(TAG, "Foreground app changed: $foregroundApp")
                     eventSink?.success(foregroundApp)
                     lastForegroundApp = foregroundApp
                } else if (foregroundApp == null) {
                    Log.w(TAG, "Could not determine foreground app.")
                }
                // Schedule the next check
                handler?.postDelayed(this, 1000) // Check every 1 second
            }
        }
        // Start the periodic check immediately
        handler?.post(runnable!!)
        Log.d(TAG, "Started foreground app monitoring task.")
    }

    override fun onCancel(arguments: Any?) {
        Log.d(TAG, "onCancel called")
        handler?.removeCallbacks(runnable!!) // Stop the periodic task
        runnable = null
        handler = null
        eventSink = null
        lastForegroundApp = null
         Log.d(TAG, "Stopped foreground app monitoring task.")
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP_MR1)
    private fun getForegroundAppPackageName(): String? {
        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager?
        if (usageStatsManager == null) {
            Log.e(TAG, "UsageStatsManager is not available.")
            return null
        }

        val time = System.currentTimeMillis()
        // Query events in the last 10 seconds. Adjust window as needed.
        val usageEvents = usageStatsManager.queryEvents(time - 10 * 1000, time)
        var foregroundApp: String? = null
        var lastEventTime: Long = 0

        while (usageEvents.hasNextEvent()) {
            val event = android.app.usage.UsageEvents.Event()
            usageEvents.getNextEvent(event)

            // Look for the latest MOVE_TO_FOREGROUND event
            if (event.eventType == android.app.usage.UsageEvents.Event.MOVE_TO_FOREGROUND) {
                 if (event.timeStamp > lastEventTime) {
                    foregroundApp = event.packageName
                    lastEventTime = event.timeStamp
                 }
            }
        }
         // Log.d(TAG, "Latest foreground event package: $foregroundApp at $lastEventTime")
        return foregroundApp
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOpsManager = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager?
        val mode = appOpsManager?.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            context.packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }
}
