package com.example.foreground_app_monitor

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.provider.Settings
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.Button
import androidx.annotation.RequiresApi
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler

/** ForegroundAppMonitorPlugin */
class ForegroundAppMonitorPlugin : FlutterPlugin, MethodCallHandler { // Implement MethodCallHandler
    private var eventChannel: EventChannel? = null
    private var methodChannel: MethodChannel? = null // Add MethodChannel
    private var streamHandler: ForegroundAppStreamHandler? = null
    private lateinit var context: Context
    private lateinit var messenger: BinaryMessenger
    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var layoutInflater: LayoutInflater? = null


    companion object {
        const val EVENT_CHANNEL_NAME = "com.example.foreground_app_monitor/foregroundApp"
        const val METHOD_CHANNEL_NAME = "com.example.foreground_app_monitor/methods" // Define method channel name
        const val TAG = "FgAppMonitorPlugin"
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
        this.context = context.applicationContext // Use application context
        this.messenger = messenger
        this.layoutInflater = LayoutInflater.from(this.context)
        this.windowManager = this.context.getSystemService(Context.WINDOW_SERVICE) as WindowManager

        // Setup EventChannel
        eventChannel = EventChannel(messenger, EVENT_CHANNEL_NAME)
        streamHandler = ForegroundAppStreamHandler(context)
        eventChannel?.setStreamHandler(streamHandler)
        Log.d(TAG, "Event channel setup complete for $EVENT_CHANNEL_NAME")

        // Setup MethodChannel
        methodChannel = MethodChannel(messenger, METHOD_CHANNEL_NAME)
        methodChannel?.setMethodCallHandler(this) // Set this class as the handler
        Log.d(TAG, "Method channel setup complete for $METHOD_CHANNEL_NAME")
    }

    private fun teardownChannels() {
        // Teardown EventChannel
        eventChannel?.setStreamHandler(null)
        streamHandler?.onCancel(null) // Explicitly cancel the handler's work
        eventChannel = null
        streamHandler = null
        Log.d(TAG, "Event channel teardown complete")

        // Teardown MethodChannel
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        Log.d(TAG, "Method channel teardown complete")

        // Clean up overlay if shown
        hideOverlay()
        windowManager = null
        layoutInflater = null
    }

    // --- Overlay Management ---

    private fun hasOverlayPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(context)
        } else {
            true // Before M, permission is granted by default
        }
    }

    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:${context.packageName}")
            )
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
        }
        // No action needed for older versions
    }

    @RequiresApi(Build.VERSION_CODES.O) // TYPE_APPLICATION_OVERLAY requires API 26
    private fun showOverlay() {
        if (overlayView != null) {
            Log.d(TAG, "Overlay already shown.")
            return
        }
        if (!hasOverlayPermission()) {
             Log.w(TAG, "Cannot show overlay: Permission not granted.")
             // Optionally send an error back to Flutter or handle differently
             return
        }

        Log.d(TAG, "Showing overlay...")
        overlayView = layoutInflater?.inflate(R.layout.overlay_layout, null)

        // Find the close button and set its click listener
        overlayView?.findViewById<Button>(R.id.close_overlay_button)?.setOnClickListener {
            Log.d(TAG, "Close button clicked, hiding overlay.")
            hideOverlay()
        }

        // Define layout parameters for the overlay
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            // Use TYPE_APPLICATION_OVERLAY for Android O and above
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            // Flags: allow touches, keep screen on. Removed FLAG_NOT_FOCUSABLE and FLAG_NOT_TOUCH_MODAL
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
            // Make it transparent
            PixelFormat.TRANSLUCENT
        )

        try {
            windowManager?.addView(overlayView, params)
            Log.d(TAG, "Overlay added to window manager.")
        } catch (e: Exception) {
            Log.e(TAG, "Error adding overlay view to window manager", e)
            overlayView = null // Reset view if add failed
        }
    }


    private fun hideOverlay() {
        if (overlayView == null) {
            Log.d(TAG, "Overlay not shown or already hidden.")
            return
        }
        Log.d(TAG, "Hiding overlay...")
        try {
            windowManager?.removeView(overlayView)
            overlayView = null // Clear the reference
            Log.d(TAG, "Overlay removed from window manager.")
        } catch (e: Exception) {
            Log.e(TAG, "Error removing overlay view from window manager", e)
            // Consider how to handle this error, maybe retry or log persistently
        }
    }


    // --- MethodCallHandler Implementation ---

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "requestUsageStatsPermission" -> {
                Log.d(TAG, "Received requestUsageStatsPermission call")
                try {
                    // Create an Intent to open the Usage Access Settings screen
                    val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                    // Add FLAG_ACTIVITY_NEW_TASK because we are starting activity from a non-activity context
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    context.startActivity(intent)
                    result.success(true) // Indicate the intent was sent
                } catch (e: Exception) {
                    Log.e(TAG, "Error opening Usage Access Settings", e)
                    result.error("ERROR_OPENING_SETTINGS", "Could not open Usage Access Settings.", e.localizedMessage)
                }
            }
            "checkOverlayPermission" -> {
                result.success(hasOverlayPermission())
            }
            "requestOverlayPermission" -> {
                 try {
                    requestOverlayPermission()
                    result.success(true) // Indicate the intent was sent
                 } catch (e: Exception) {
                    Log.e(TAG, "Error opening Overlay Permission Settings", e)
                    result.error("ERROR_OPENING_SETTINGS", "Could not open Overlay Permission Settings.", e.localizedMessage)
                 }
            }
            "showOverlay" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    showOverlay()
                    result.success(null) // Indicate success
                } else {
                    result.error("UNSUPPORTED_OS", "Overlay requires Android Oreo (API 26) or higher.", null)
                }
            }
            "hideOverlay" -> {
                hideOverlay()
                result.success(null) // Indicate success
            }
            else -> {
                Log.w(TAG, "Method not implemented: ${call.method}")
                result.notImplemented()
            }
        }
    }
}


class ForegroundAppStreamHandler(private val context: Context) : EventChannel.StreamHandler {
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
            return
        }

        handler = Handler(Looper.getMainLooper())
        runnable = object : Runnable {
            override fun run() {
                val foregroundApp = getForegroundAppPackageName()
                Log.d(TAG, "Foreground app: $foregroundApp")
                // Only send event if the app has actually changed
                if (foregroundApp != null && foregroundApp != lastForegroundApp) {
                     Log.d(TAG, "Foreground app changed: $foregroundApp")
                     eventSink?.success(foregroundApp)
                     lastForegroundApp = foregroundApp
                } else if (foregroundApp == null && lastForegroundApp != null) {
                    // Optionally, send a null or empty string if no foreground app is detected
                    // eventSink?.success("") // Or handle this case as needed
                    // lastForegroundApp = null
                    // Log.w(TAG, "Could not determine foreground app.")
                }
                // Schedule the next check
                handler?.postDelayed(this, 30000) 
            }
        }
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

    private fun getForegroundAppPackageName(): String? {
        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager?
            ?: run {
                Log.e(TAG, "UsageStatsManager is not available.")
                return null
            }

        val time = System.currentTimeMillis()
        val usageEvents = usageStatsManager.queryEvents(time - 30 * 1000, time)
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
        return foregroundApp
    }

    private fun hasUsageStatsPermission(): Boolean {
        Log.d(TAG, "Checking for Usage Stats permission...")
        val appOpsManager = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager?
            ?: run {
                Log.w(TAG, "AppOpsManager is not available. Cannot check permission.")
                return false // Cannot check permission if service is unavailable
            }

        val mode = appOpsManager.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            context.packageName
        )
        val granted = mode == AppOpsManager.MODE_ALLOWED
        Log.d(TAG, "Usage Stats permission check result: mode=$mode, granted=$granted")
        return granted
    }
}
