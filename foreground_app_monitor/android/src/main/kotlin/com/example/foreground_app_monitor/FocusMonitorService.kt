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
        System.out.println("KOTLIN LOG: FocusMonitorService onCreate() called")
        
        notificationManager = ServiceNotificationManager(this)
        appMonitor = AppMonitorHandler(this)
        
        // Create notification channel
        notificationManager.createNotificationChannel()
        
        // Initialize background Flutter engine
        System.out.println("KOTLIN LOG: About to initialize background Flutter engine")
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
            Log.d(TAG, "=== STARTING BACKGROUND ENGINE INITIALIZATION ===")
            
            // Step 1: Create Flutter engine
            Log.d(TAG, "Step 1: Creating FlutterEngine with context: ${this.applicationContext}")
            backgroundEngine = FlutterEngine(this.applicationContext)
            Log.d(TAG, "Step 1: FlutterEngine created successfully: ${backgroundEngine != null}")
            
            // Step 2: Set up method channels
            Log.d(TAG, "Step 2: Setting up background channels...")
            setupBackgroundChannels()
            Log.d(TAG, "Step 2: Background channels setup completed")
            
            // Step 3: Create DartEntrypoint with explicit library path
            Log.d(TAG, "Step 3: Creating DartEntrypoint...")
            val defaultEntrypoint = DartExecutor.DartEntrypoint.createDefault()
            Log.d(TAG, "Step 3: Default entrypoint created - library: '${defaultEntrypoint.dartEntrypointLibrary}', function: '${defaultEntrypoint.dartEntrypointFunctionName}'")
            
            // Get the app bundle path from FlutterInjector
            val flutterLoader = io.flutter.FlutterInjector.instance().flutterLoader()
            val appBundlePath = flutterLoader.findAppBundlePath()
            Log.d(TAG, "Step 3: App bundle path from FlutterInjector: '$appBundlePath'")
            
            // Use the 3-parameter constructor with null library
            val backgroundEntrypoint = DartExecutor.DartEntrypoint(
                appBundlePath, // asset bundle path from FlutterInjector
                // null, // null library - let Flutter find backgroundMain
                "backgroundMain" // function name
            )
            Log.d(TAG, "Step 3: Background entrypoint created - library: '${backgroundEntrypoint.dartEntrypointLibrary}', function: '${backgroundEntrypoint.dartEntrypointFunctionName}'")
            
            // Step 4: Execute Dart entrypoint
            Log.d(TAG, "Step 4: About to execute Dart entrypoint...")
            val dartExecutor = backgroundEngine?.dartExecutor
            Log.d(TAG, "Step 4: DartExecutor obtained: ${dartExecutor != null}")
            
            if (dartExecutor != null) {
                Log.d(TAG, "Step 4: Calling executeDartEntrypoint...")
                dartExecutor.executeDartEntrypoint(backgroundEntrypoint)
                Log.d(TAG, "Step 4: executeDartEntrypoint call completed")
            } else {
                Log.e(TAG, "Step 4: ERROR - DartExecutor is null!")
            }
            
            Log.d(TAG, "=== BACKGROUND ENGINE INITIALIZATION COMPLETED ===")
            
        } catch (e: Exception) {
            Log.e(TAG, "FATAL ERROR in initializeBackgroundEngine", e)
            Log.e(TAG, "Exception type: ${e.javaClass.simpleName}")
            Log.e(TAG, "Exception message: ${e.message}")
            Log.e(TAG, "Stack trace: ${e.stackTrace.joinToString("\n")}")
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
    
    // --- WebSocket Bridge Methods ---
    
    fun requestFocusStatusFromBackground(callback: (Map<String, Any>) -> Unit) {
        backgroundMethodChannel?.invokeMethod("requestFocusStatus", null, object : MethodChannel.Result {
            override fun success(result: Any?) {
                Log.d(TAG, "Focus status response from background: $result")
                if (result is Map<*, *>) {
                    callback(result as Map<String, Any>)
                } else {
                    Log.e(TAG, "Invalid focus status response format")
                    callback(emptyMap())
                }
            }
            
            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                Log.e(TAG, "Error requesting focus status from background: $errorCode - $errorMessage")
                callback(emptyMap())
            }
            
            override fun notImplemented() {
                Log.e(TAG, "requestFocusStatus not implemented in background")
                callback(emptyMap())
            }
        })
    }
    
    fun initializeWebSocketInBackground(callback: (Boolean) -> Unit) {
        backgroundMethodChannel?.invokeMethod("initializeWebSocket", null, object : MethodChannel.Result {
            override fun success(result: Any?) {
                Log.d(TAG, "WebSocket initialization response from background: $result")
                callback(true)
            }
            
            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                Log.e(TAG, "Error initializing WebSocket in background: $errorCode - $errorMessage")
                callback(false)
            }
            
            override fun notImplemented() {
                Log.e(TAG, "initializeWebSocket not implemented in background")
                callback(false)
            }
        })
    }
    
    fun disposeWebSocketInBackground(callback: (Boolean) -> Unit) {
        backgroundMethodChannel?.invokeMethod("disposeWebSocket", null, object : MethodChannel.Result {
            override fun success(result: Any?) {
                Log.d(TAG, "WebSocket disposal response from background: $result")
                callback(true)
            }
            
            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                Log.e(TAG, "Error disposing WebSocket in background: $errorCode - $errorMessage")
                callback(false)
            }
            
            override fun notImplemented() {
                Log.e(TAG, "disposeWebSocket not implemented in background")
                callback(false)
            }
        })
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
