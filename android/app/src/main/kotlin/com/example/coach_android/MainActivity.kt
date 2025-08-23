package com.example.coach_android

import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
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
import android.widget.TextView
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler

class MainActivity : FlutterActivity(), MethodCallHandler {
    private val APP_COUNT_CHANNEL = "com.example.coach_android/appCount"
    private val MAIN_METHOD_CHANNEL = ChannelNames.MAIN_METHODS
    
    private var mainMethodChannel: MethodChannel? = null
    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var layoutInflater: LayoutInflater? = null
    
    companion object {
        const val TAG = "MainActivity"
        
        private var instance: MainActivity? = null
        
        fun getInstance(): MainActivity? = instance
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        instance = this
        
        setupServices()

        // Method Channel for app list
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_COUNT_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledAppsCount" -> result.success(getInstalledAppsCount())
                "getInstalledApps" -> result.success(getInstalledApps())
                else -> result.notImplemented()
            }
        }
        
        // Main method channel for focus monitoring functionality
        mainMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MAIN_METHOD_CHANNEL)
        mainMethodChannel?.setMethodCallHandler(this)
        Log.d(TAG, "Main method channel setup complete for $MAIN_METHOD_CHANNEL")
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        super.cleanUpFlutterEngine(flutterEngine)
        teardownServices()
        instance = null
    }
    
    private fun setupServices() {
        this.layoutInflater = LayoutInflater.from(this)
        this.windowManager = this.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    }
    
    private fun teardownServices() {
        mainMethodChannel?.setMethodCallHandler(null)
        mainMethodChannel = null
        hideOverlay()
        windowManager = null
        layoutInflater = null
    }


    // --- MethodCallHandler Implementation ---
    
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "requestUsageStatsPermission" -> {
                Log.d(TAG, "Received requestUsageStatsPermission call")
                try {
                    val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    Log.e(TAG, "Error opening Usage Access Settings", e)
                    result.error("ERROR_OPENING_SETTINGS", "Could not open Usage Access Settings.", e.localizedMessage)
                }
            }
            "checkUsageStatsPermission" -> {
                Log.d(TAG, "Received checkUsageStatsPermission call")
                val hasPermission = hasUsageStatsPermission()
                Log.d(TAG, "Usage Stats permission status: $hasPermission")
                result.success(hasPermission)
            }
            "checkOverlayPermission" -> {
                result.success(hasOverlayPermission())
            }
            "requestOverlayPermission" -> {
                try {
                    requestOverlayPermission()
                    result.success(true)
                } catch (e: Exception) {
                    Log.e(TAG, "Error opening Overlay Permission Settings", e)
                    result.error("ERROR_OPENING_SETTINGS", "Could not open Overlay Permission Settings.", e.localizedMessage)
                }
            }
            "showOverlay" -> {
                val packageName = call.argument<String>("packageName")
                Log.d(TAG, "Received showOverlay call with packageName: $packageName")
                showOverlay(packageName)
                result.success(null)
            }
            "hideOverlay" -> {
                hideOverlay()
                result.success(null)
            }
            "startFocusMonitorService" -> {
                startFocusMonitorService()
                result.success(true)
            }
            "stopFocusMonitorService" -> {
                stopFocusMonitorService()
                result.success(true)
            }
            "isServiceRunning" -> {
                val isRunning = FocusMonitorService.getInstance() != null
                Log.d(TAG, "Service running check: $isRunning")
                result.success(isRunning)
            }
            "requestFocusStateRefresh" -> {
                Log.d(TAG, "Received focus state refresh request from main UI")
                val service = FocusMonitorService.getInstance()
                if (service != null) {
                    service.requestFocusStateRefresh()
                    result.success(true)
                } else {
                    Log.w(TAG, "Service not running, cannot refresh focus state")
                    result.error("SERVICE_NOT_RUNNING", "FocusMonitorService is not running", null)
                }
            }
            "testMethodCall" -> {
                Log.d(TAG, "Received test method call from UI")
                result.success("Test method call successful")
            }
            else -> {
                Log.w(TAG, "Method not implemented: ${call.method}")
                result.notImplemented()
            }
        }
    }

    // --- Permission Management ---
    
    private fun hasOverlayPermission(): Boolean {
        return Settings.canDrawOverlays(this)
    }

    private fun hasUsageStatsPermission(): Boolean {
        Log.d(TAG, "Checking for Usage Stats permission...")
        val appOpsManager = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager?
            ?: run {
                Log.w(TAG, "AppOpsManager is not available. Cannot check permission.")
                return false
            }

        val mode = appOpsManager.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            packageName
        )
        val granted = mode == AppOpsManager.MODE_ALLOWED
        Log.d(TAG, "Usage Stats permission check result: mode=$mode, granted=$granted")
        return granted
    }

    private fun requestOverlayPermission() {
        val intent = Intent(
            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
            Uri.parse("package:$packageName")
        )
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }

    // --- Overlay Management ---

    private fun showOverlay(packageName: String?) {
        if (overlayView != null) {
            Log.d(TAG, "Overlay already shown for $packageName.")
            return
        }
        if (!hasOverlayPermission()) {
            Log.w(TAG, "Cannot show overlay: Permission not granted.")
            return
        }

        Log.d(TAG, "Showing overlay for package: $packageName")
        overlayView = layoutInflater?.inflate(R.layout.overlay_layout, null)

        // Update the TextView
        overlayView?.findViewById<TextView>(R.id.overlay_text)?.let { textView ->
            val displayText = if (packageName != null && packageName.isNotEmpty()) {
                "I detected app $packageName.\nIt's time to focus!"
            } else {
                "Focus Time!"
            }
            textView.text = displayText
            Log.d(TAG, "Set overlay text to: $displayText")
        }

        // Find the close button and set its click listener
        overlayView?.findViewById<Button>(R.id.close_overlay_button)?.setOnClickListener {
            Log.d(TAG, "Close button clicked, simulating Home press and hiding overlay.")

            // Simulate Home button press
            val homeIntent = Intent(Intent.ACTION_MAIN)
            homeIntent.addCategory(Intent.CATEGORY_HOME)
            homeIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            try {
                startActivity(homeIntent)
                Log.d(TAG, "Sent Home intent.")
            } catch (e: Exception) {
                Log.e(TAG, "Error sending Home intent", e)
            }

            // Hide the overlay after simulating Home press
            hideOverlay()
        }

        // Define layout parameters for the overlay
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
            PixelFormat.TRANSLUCENT
        )

        try {
            windowManager?.addView(overlayView, params)
            Log.d(TAG, "Overlay added to window manager.")
        } catch (e: Exception) {
            Log.e(TAG, "Error adding overlay view to window manager", e)
            overlayView = null
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
            overlayView = null
            Log.d(TAG, "Overlay removed from window manager.")
        } catch (e: Exception) {
            Log.e(TAG, "Error removing overlay view from window manager", e)
        }
    }

    // --- Service Management ---
    
    private fun startFocusMonitorService() {
        Log.d(TAG, "Starting FocusMonitorService")
        
        val intent = Intent(this, FocusMonitorService::class.java).apply {
            action = FocusMonitorService.ACTION_START_SERVICE
        }
        
        try {
            startForegroundService(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Error starting service", e)
        }
    }
    
    private fun stopFocusMonitorService() {
        Log.d(TAG, "Stopping FocusMonitorService")
        
        val intent = Intent(this, FocusMonitorService::class.java).apply {
            action = FocusMonitorService.ACTION_STOP_SERVICE
        }
        
        try {
            startService(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping service", e)
        }
    }
    
    // --- Service Event Callbacks ---
    
    fun showOverlayFromService(packageName: String) {
        Log.d(TAG, "Background service requests show overlay for: $packageName")
        runOnUiThread {
            showOverlay(packageName)
        }
    }
    
    fun hideOverlayFromService() {
        Log.d(TAG, "Background service requests hide overlay")
        runOnUiThread {
            hideOverlay()
        }
    }
    
    fun notifyFocusStateChanged(data: Map<String, Any>) {
        Log.d(TAG, "Background service notifies focus state changed: $data")
        // Forward to the main UI via method channel
        runOnUiThread {
            try {
                Log.d(TAG, "Calling focusStateChanged on method channel: $mainMethodChannel")
                Log.d(TAG, "Data to send: $data")
                Log.d(TAG, "Data type: ${data.javaClass.simpleName}")
                
                mainMethodChannel?.invokeMethod("focusStateChanged", data, object : MethodChannel.Result {
                    override fun success(result: Any?) {
                        Log.d(TAG, "focusStateChanged success: $result")
                    }
                    
                    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                        Log.e(TAG, "focusStateChanged error: $errorCode - $errorMessage")
                    }
                    
                    override fun notImplemented() {
                        Log.w(TAG, "focusStateChanged not implemented")
                    }
                })
                Log.d(TAG, "focusStateChanged method call initiated")
            } catch (e: Exception) {
                Log.e(TAG, "Exception calling focusStateChanged", e)
            }
        }
    }

    // --- App List Methods ---
    
    private fun getInstalledAppsCount(): Int {
        val pm = packageManager
        val packages = pm.getInstalledApplications(PackageManager.GET_META_DATA)
        return packages.size
    }
    
    private fun getInstalledApps(): List<Map<String, Any>> {
        val pm = packageManager
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
