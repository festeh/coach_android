package com.example.foreground_app_monitor

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.util.Log
import androidx.annotation.RequiresApi
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.PluginRegistry.Registrar // Required for older embedding

/** ForegroundAppMonitorPlugin */
class ForegroundAppMonitorPlugin : FlutterPlugin {
    private var eventChannel: EventChannel? = null
    private var streamHandler: ForegroundAppStreamHandler? = null
    private lateinit var context: Context
    private lateinit var messenger: BinaryMessenger

    // Use companion object for constants
    companion object {
        // Ensure this matches the EventChannel name used in the Dart code
        private const val EVENT_CHANNEL_NAME = "com.example.foreground_app_monitor/foregroundApp"
        private const val TAG = "FgAppMonitorPlugin" // Renamed tag for clarity

        // Deprecated registration method for compatibility with older Flutter projects.
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val plugin = ForegroundAppMonitorPlugin()
            plugin.setupChannels(registrar.context(), registrar.messenger())
        }
    }


    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Log.d(TAG, "onAttachedToEngine")
        setupChannels(binding.applicationContext, binding.binaryMessenger)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Log.d(TAG, "onDetachedFromEngine")
        teardownChannels()
    }

    private fun setupChannels(context: Context, messenger: BinaryMessenger) {
        this.context = context
        this.messenger = messenger

        eventChannel = EventChannel(messenger, EVENT_CHANNEL_NAME)
        streamHandler = ForegroundAppStreamHandler(context)
        eventChannel?.setStreamHandler(streamHandler)
        Log.d(TAG, "Event channel setup complete for $EVENT_CHANNEL_NAME")
    }

    private fun teardownChannels() {
        eventChannel?.setStreamHandler(null)
        streamHandler?.onCancel(null) // Explicitly cancel the handler's work
        eventChannel = null
        streamHandler = null
        Log.d(TAG, "Event channel teardown complete")
    }
}


// Handles the stream for foreground app events (Moved from MainActivity)
class ForegroundAppStreamHandler(private val context: Context) : EventChannel.StreamHandler {
    // Use the plugin's TAG for consistency
    private val TAG = ForegroundAppMonitorPlugin.TAG
    private var handler: Handler? = null
    private var eventSink: EventChannel.EventSink? = null
    private var runnable: Runnable? = null
    private var lastForegroundApp: String? = null

    override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
        Log.d(TAG, "StreamHandler onListen called")
        if (sink == null) {
            Log.e(TAG, "EventSink is null in onListen")
            return
        }
        eventSink = sink

        if (!hasUsageStatsPermission()) {
            Log.w(TAG, "Usage stats permission not granted.")
            eventSink?.error("PERMISSION_DENIED", "Usage stats permission is required.", null)
            // Don't start the handler if permission is missing
            return
        }

        handler = Handler(Looper.getMainLooper())
        runnable = object : Runnable {
            // Ensure API level check is present for the method call
            @RequiresApi(Build.VERSION_CODES.LOLLIPOP_MR1)
            override fun run() {
                val foregroundApp = getForegroundAppPackageName()
                // Only send event if the app has actually changed
                if (foregroundApp != null && foregroundApp != lastForegroundApp) {
                     Log.d(TAG, "Foreground app changed: $foregroundApp")
                     eventSink?.success(foregroundApp)
                     lastForegroundApp = foregroundApp
                } else if (foregroundApp == null && lastForegroundApp != null) {
                    // Optionally, send a null or empty string if no foreground app is detected
                    // eventSink?.success("") // Or handle this case as needed
                    // lastForegroundApp = null
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
        Log.d(TAG, "StreamHandler onCancel called")
        handler?.removeCallbacks(runnable!!) // Stop the periodic task
        runnable = null
        handler = null
        eventSink = null
        lastForegroundApp = null
         Log.d(TAG, "Stopped foreground app monitoring task.")
    }

    // Requires API level 22 (Lollipop MR1)
    @RequiresApi(Build.VERSION_CODES.LOLLIPOP_MR1)
    private fun getForegroundAppPackageName(): String? {
        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager?
            ?: run {
                Log.e(TAG, "UsageStatsManager is not available.")
                return null
            }

        val time = System.currentTimeMillis()
        // Query events in a reasonable window (e.g., last 10 seconds)
        val usageEvents = usageStatsManager.queryEvents(time - 10 * 1000, time)
        var foregroundApp: String? = null
        var lastEventTime: Long = 0

        while (usageEvents.hasNextEvent()) {
            val event = UsageEvents.Event()
            usageEvents.getNextEvent(event)

            // Check for MOVE_TO_FOREGROUND event type
            if (event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND) {
                 if (event.timeStamp > lastEventTime) {
                    foregroundApp = event.packageName
                    lastEventTime = event.timeStamp
                 }
            }
        }
        // Log the found package name for debugging
        // Log.v(TAG, "Latest foreground event package: $foregroundApp at $lastEventTime")
        return foregroundApp
    }

    // Requires API level 21 (Lollipop)
    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private fun hasUsageStatsPermission(): Boolean {
        val appOpsManager = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager?
            ?: return false // Cannot check permission if service is unavailable

        // Use checkOpNoThrow for safer permission check
        val mode = appOpsManager.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            context.packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }
}
