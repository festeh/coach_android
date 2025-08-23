package com.example.foreground_app_monitor

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Binder
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicBoolean

class FocusMonitorService : Service() {
    private val binder = FocusMonitorBinder()
    private lateinit var notificationManager: ServiceNotificationManager
    private lateinit var appMonitor: AppMonitorHandler
    
    // Background Flutter engine for running Dart code
    private var backgroundEngine: FlutterEngine? = null
    private var backgroundMethodChannel: MethodChannel? = null
    private var backgroundEventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    
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
        
        // Initialize background Flutter engine
        initializeBackgroundEngine()
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
        
        // Cleanup background engine
        cleanupBackgroundEngine()
        
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
        // Send to background Dart isolate instead of main plugin
        sendAppToBackgroundIsolate(packageName)
    }
    
    private fun initializeBackgroundEngine() {
        try {
            Log.d(TAG, "Initializing background Flutter engine...")
            
            // Create a new Flutter engine instance
            backgroundEngine = FlutterEngine(this.applicationContext)
            
            // Set up method channels for communication with background Dart
            setupBackgroundChannels()
            
            // Execute the background Dart isolate
            val dartEntrypoint = DartExecutor.DartEntrypoint(
                "lib/background_isolate.dart",
                "backgroundMain"
            )
            
            backgroundEngine?.dartExecutor?.executeDartEntrypoint(dartEntrypoint)
            
            Log.d(TAG, "Background Flutter engine initialized successfully")
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize background Flutter engine", e)
        }
    }
    
    private fun setupBackgroundChannels() {
        val engine = backgroundEngine ?: return
        
        // Method channel for communication with background Dart
        backgroundMethodChannel = MethodChannel(
            engine.dartExecutor.binaryMessenger,
            "com.example.coach_android/background"
        )
        
        backgroundMethodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "backgroundReady" -> {
                    Log.d(TAG, "Background isolate is ready")
                    result.success(true)
                }
                "showOverlay" -> {
                    val packageName = call.argument<String>("packageName")
                    Log.d(TAG, "Background isolate requests overlay for: $packageName")
                    packageName?.let { 
                        ForegroundAppMonitorPlugin.getInstance()?.showOverlayFromService(it)
                    }
                    result.success(null)
                }
                "hideOverlay" -> {
                    Log.d(TAG, "Background isolate requests hide overlay")
                    ForegroundAppMonitorPlugin.getInstance()?.hideOverlayFromService()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        
        // Event channel for sending app changes to background Dart
        backgroundEventChannel = EventChannel(
            engine.dartExecutor.binaryMessenger,
            "com.example.coach_android/background_events"
        )
        
        backgroundEventChannel?.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                Log.d(TAG, "Background event channel listener attached")
            }
            
            override fun onCancel(arguments: Any?) {
                eventSink = null
                Log.d(TAG, "Background event channel listener cancelled")
            }
        })
    }
    
    private fun sendAppToBackgroundIsolate(packageName: String) {
        try {
            eventSink?.success(packageName)
            Log.d(TAG, "Sent app '$packageName' to background isolate")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to send app to background isolate", e)
        }
    }
    
    private fun cleanupBackgroundEngine() {
        try {
            Log.d(TAG, "Cleaning up background Flutter engine...")
            
            eventSink = null
            backgroundEventChannel?.setStreamHandler(null)
            backgroundMethodChannel?.setMethodCallHandler(null)
            
            backgroundEngine?.destroy()
            backgroundEngine = null
            
            Log.d(TAG, "Background Flutter engine cleanup complete")
        } catch (e: Exception) {
            Log.e(TAG, "Error cleaning up background Flutter engine", e)
        }
    }
}