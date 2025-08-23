package com.example.coach_android

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.util.Log

class AppMonitorHandler(
    private val context: Context
) {
    
    companion object {
        const val TAG = "AppMonitorHandler"
        const val MONITORING_INTERVAL = 2000L // 2 seconds
        const val USAGE_STATS_INTERVAL = 5000L // 5 seconds for usage stats check
    }
    
    private val handler = Handler(Looper.getMainLooper())
    private var monitoringRunnable: Runnable? = null
    private var isMonitoring = false
    private var lastForegroundApp: String? = null
    
    private val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager?
    
    fun startMonitoring() {
        if (isMonitoring) {
            Log.d(TAG, "Already monitoring")
            return
        }
        
        if (!hasUsageStatsPermission()) {
            Log.w(TAG, "Usage stats permission not granted, cannot start monitoring")
            return
        }
        
        Log.d(TAG, "Starting app monitoring")
        isMonitoring = true
        
        monitoringRunnable = object : Runnable {
            override fun run() {
                try {
                    checkForegroundApp()
                } catch (e: Exception) {
                    Log.e(TAG, "Error in monitoring loop", e)
                }
                
                if (isMonitoring) {
                    handler.postDelayed(this, MONITORING_INTERVAL)
                }
            }
        }
        
        handler.post(monitoringRunnable!!)
    }
    
    fun stopMonitoring() {
        if (!isMonitoring) {
            Log.d(TAG, "Not monitoring")
            return
        }
        
        Log.d(TAG, "Stopping app monitoring")
        isMonitoring = false
        
        monitoringRunnable?.let { runnable ->
            handler.removeCallbacks(runnable)
        }
        monitoringRunnable = null
        lastForegroundApp = null
    }
    
    private fun checkForegroundApp() {
        val foregroundApp = getForegroundAppPackageName()
        
        if (foregroundApp != null && foregroundApp != lastForegroundApp) {
            Log.d(TAG, "Detected foreground app change: $lastForegroundApp -> $foregroundApp")
            
            handleAppChange(foregroundApp)
            lastForegroundApp = foregroundApp
        }
    }
    
    private fun handleAppChange(packageName: String) {
        Log.d(TAG, "App change detected: $packageName")
        
        // Just notify Flutter about the app change - no logic here
        val service = FocusMonitorService.getInstance()
        service?.notifyAppDetected(packageName)
    }
    
    private fun getForegroundAppPackageName(): String? {
        if (usageStatsManager == null) {
            Log.e(TAG, "UsageStatsManager is not available")
            return null
        }
        
        val time = System.currentTimeMillis()
        val usageEvents = usageStatsManager.queryEvents(time - USAGE_STATS_INTERVAL, time)
        
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
        val appOpsManager = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager?
            ?: return false
        
        val mode = appOpsManager.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            context.packageName
        )
        
        return mode == AppOpsManager.MODE_ALLOWED
    }
}