package com.example.foreground_app_monitor

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Binder
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import java.util.concurrent.atomic.AtomicBoolean

class FocusMonitorService : Service() {
    private val binder = FocusMonitorBinder()
    private lateinit var notificationManager: ServiceNotificationManager
    private lateinit var appMonitor: AppMonitorHandler
    
    private val isRunning = AtomicBoolean(false)
    private val handler = Handler(Looper.getMainLooper())
    
    companion object {
        const val TAG = "FocusMonitorService"
        const val ACTION_START_SERVICE = "START_FOCUS_MONITOR"
        const val ACTION_STOP_SERVICE = "STOP_FOCUS_MONITOR"
        
        private var serviceInstance: FocusMonitorService? = null
        
        fun getInstance(): FocusMonitorService? = serviceInstance
    }
    
    inner class FocusMonitorBinder : Binder() {
        fun getService(): FocusMonitorService = this@FocusMonitorService
    }
    
    override fun onCreate() {
        super.onCreate()
        serviceInstance = this
        
        Log.d(TAG, "Service onCreate")
        
        notificationManager = ServiceNotificationManager(this)
        appMonitor = AppMonitorHandler(this)
        
        // Create notification channel
        notificationManager.createNotificationChannel()
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "Service onStartCommand with action: ${intent?.action}")
        
        when (intent?.action) {
            ACTION_START_SERVICE -> {
                startForegroundService()
            }
            ACTION_STOP_SERVICE -> {
                stopForegroundService()
            }
        }
        
        return START_STICKY
    }
    
    override fun onBind(intent: Intent?): IBinder = binder
    
    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "Service onDestroy")
        
        stopForegroundService()
        serviceInstance = null
    }
    
    private fun startForegroundService() {
        if (isRunning.get()) {
            Log.d(TAG, "Service already running")
            return
        }
        
        Log.d(TAG, "Starting foreground service")
        
        // Start foreground with notification
        val notification = notificationManager.createServiceNotification()
        startForeground(ServiceNotificationManager.NOTIFICATION_ID, notification)
        
        isRunning.set(true)
        
        // Start monitoring
        startAppMonitoring()
        
        // Notify plugin about service start
        notifyServiceStatus("started")
    }
    
    private fun stopForegroundService() {
        if (!isRunning.get()) {
            Log.d(TAG, "Service not running")
            return
        }
        
        Log.d(TAG, "Stopping foreground service")
        
        isRunning.set(false)
        
        // Stop monitoring
        stopAppMonitoring()
        
        // Stop foreground and remove notification
        stopForeground(true)
        stopSelf()
        
        // Notify plugin about service stop
        notifyServiceStatus("stopped")
    }
    
    private fun startAppMonitoring() {
        Log.d(TAG, "Starting app monitoring")
        appMonitor.startMonitoring()
    }
    
    private fun stopAppMonitoring() {
        Log.d(TAG, "Stopping app monitoring")
        appMonitor.stopMonitoring()
    }
    
    private fun notifyServiceStatus(status: String) {
        handler.post {
            ForegroundAppMonitorPlugin.getInstance()?.onServiceStatusChanged(status)
        }
    }
    
    fun notifyAppDetected(packageName: String) {
        handler.post {
            ForegroundAppMonitorPlugin.getInstance()?.onAppDetected(packageName)
        }
    }
}