package com.example.coach_android

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
    private lateinit var popNotificationManager: PopNotificationManager
    private lateinit var appMonitor: AppMonitorHandler

    // Background Flutter engine for running Dart code
    private var backgroundEngine: FlutterEngine? = null
    private var backgroundMethodChannel: MethodChannel? = null
    private var backgroundEventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null

    private val isRunning = AtomicBoolean(false)
    private val handler = Handler(Looper.getMainLooper())

    // Store current focus data for notification updates
    private var currentFocusData: Map<String, Any>? = null
    
    companion object {
        const val TAG = "FocusMonitorService"
        const val ACTION_START_SERVICE = "START_FOCUS_MONITOR"
        const val ACTION_STOP_SERVICE = "STOP_FOCUS_MONITOR"
        const val ACTION_FOCUS_NOW = "FOCUS_NOW"
        
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
        popNotificationManager = PopNotificationManager(this)
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
            ACTION_FOCUS_NOW -> {
                handleFocusNowAction()
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
        val notification = if (currentFocusData != null) {
            val isFocusing = currentFocusData?.get("focusing") as? Boolean
            val numFocuses = currentFocusData?.get("numFocuses") as? Int
            val focusTimeLeft = currentFocusData?.get("focusTimeLeft") as? Int
            notificationManager.createServiceNotification(isFocusing, numFocuses, focusTimeLeft)
        } else {
            notificationManager.createServiceNotification()
        }
        startForeground(ServiceNotificationManager.NOTIFICATION_ID, notification)
        
        isRunning.set(true)
        
        // Start monitoring
        startAppMonitoring()
        
        // Notify main activity about service start
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
        
        // Notify main activity about service stop
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
            // We'll handle this directly in MainActivity instead of plugin
            Log.d(TAG, "Service status changed: $status")
        }
    }
    
    fun notifyAppDetected(packageName: String) {
        // Update activity for reminder system
        popNotificationManager.updateActivity()

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
            
            // Use the 2-parameter constructor (library defaults to null)
            val backgroundEntrypoint = DartExecutor.DartEntrypoint(
                appBundlePath, // asset bundle path from FlutterInjector
                "backgroundMain" // function name (in main.dart)
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
            ChannelNames.BACKGROUND_METHODS
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
                        // Show overlay directly via MainActivity
                        MainActivity.getInstance()?.showOverlayFromService(it)
                    }
                    result.success(null)
                }
                "hideOverlay" -> {
                    Log.d(TAG, "Background isolate requests hide overlay")
                    // Hide overlay directly via MainActivity
                    MainActivity.getInstance()?.hideOverlayFromService()
                    result.success(null)
                }
                "focusStateChanged" -> {
                    Log.d(TAG, "Background isolate notifies focus state changed: ${call.arguments}")
                    val arguments = call.arguments as? Map<String, Any>
                    currentFocusData = arguments

                    // Update notification with new focus data
                    updateNotificationWithFocusData(arguments)

                    // Check if we should show focus reminder
                    checkFocusReminder(arguments)

                    // Notify UI directly via MainActivity
                    MainActivity.getInstance()?.notifyFocusStateChanged(arguments ?: emptyMap())
                    result.success(null)
                }
                "refreshFocusState" -> {
                    Log.d(TAG, "Background isolate requests focus state refresh")
                    // This is called by the background isolate to refresh its own state
                    result.success(null)
                }
                "checkFocusReminder" -> {
                    Log.d(TAG, "Background isolate requests focus reminder check")
                    val arguments = call.arguments as? Map<String, Any>
                    checkFocusReminder(arguments)
                    result.success(null)
                }
                "forceShowFocusReminder" -> {
                    Log.d(TAG, "Force showing focus reminder (debug mode)")
                    popNotificationManager.forceShowFocusReminder()
                    result.success(null)
                }
                "forceShowReminderDirect" -> {
                    Log.d(TAG, "Force showing focus reminder directly from background isolate")
                    popNotificationManager.forceShowFocusReminder()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        
        // Event channel for sending app changes to background Dart
        backgroundEventChannel = EventChannel(
            engine.dartExecutor.binaryMessenger,
            ChannelNames.BACKGROUND_EVENTS
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
    
    
    fun requestFocusStateRefresh() {
        Log.d(TAG, "Main UI requests focus state refresh - forwarding to background isolate")
        try {
            backgroundMethodChannel?.invokeMethod("refreshFocusState", null)
        } catch (e: Exception) {
            Log.e(TAG, "Error forwarding refresh request to background isolate", e)
        }
    }
    
    fun sendFocusCommand() {
        Log.d(TAG, "Main UI requests focus command - forwarding to background isolate")
        try {
            backgroundMethodChannel?.invokeMethod("startFocus", null)
        } catch (e: Exception) {
            Log.e(TAG, "Error forwarding focus command to background isolate", e)
        }
    }

    fun updateNotificationTimeInBackground() {
        Log.d(TAG, "Updating notification time in background isolate")
        try {
            backgroundMethodChannel?.invokeMethod("updateNotificationTime", null)
        } catch (e: Exception) {
            Log.e(TAG, "Error updating notification time in background isolate", e)
        }
    }

    fun forceShowFocusReminder() {
        Log.d(TAG, "Force showing focus reminder via background isolate")
        try {
            backgroundMethodChannel?.invokeMethod("forceShowFocusReminder", null)
        } catch (e: Exception) {
            Log.e(TAG, "Error forcing focus reminder via background isolate", e)
        }
    }
    
    private fun handleFocusNowAction() {
        Log.d(TAG, "Handling Focus Now action from reminder notification")

        // Dismiss the reminder notification
        popNotificationManager.dismissReminder()

        // Send focus command to background isolate
        sendFocusCommand()

        // Open main activity to show focus UI
        val openAppIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }

        if (openAppIntent != null) {
            startActivity(openAppIntent)
        }
    }

    private fun checkFocusReminder(focusData: Map<String, Any>?) {
        if (!isRunning.get() || focusData == null) {
            return
        }

        try {
            val isFocusing = focusData["focusing"] as? Boolean ?: false
            val sinceLastChange = focusData["sinceLastChange"] as? Int ?: 0

            Log.d(TAG, "Checking focus reminder: focusing=$isFocusing, sinceLastChange=$sinceLastChange")

            popNotificationManager.checkAndShowFocusReminder(sinceLastChange, isFocusing)
        } catch (e: Exception) {
            Log.e(TAG, "Error checking focus reminder", e)
        }
    }

    private fun updateNotificationWithFocusData(focusData: Map<String, Any>?) {
        if (!isRunning.get() || focusData == null) {
            return
        }

        try {
            val isFocusing = focusData["focusing"] as? Boolean
            val numFocuses = focusData["numFocuses"] as? Int
            val focusTimeLeft = focusData["focusTimeLeft"] as? Int

            Log.d(TAG, "Updating notification: focusing=$isFocusing, numFocuses=$numFocuses, focusTimeLeft=$focusTimeLeft")

            notificationManager.updateNotification(isFocusing, numFocuses, focusTimeLeft)
        } catch (e: Exception) {
            Log.e(TAG, "Error updating notification with focus data", e)
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