package com.example.coach_android

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Binder
import android.os.IBinder
import android.os.SystemClock
import android.util.Log
import com.example.coach_android.data.model.FocusData
import com.example.coach_android.di.AppContainer
import com.example.coach_android.service.MonitorLogic
import java.util.concurrent.atomic.AtomicBoolean

class FocusMonitorService : Service() {
    private val binder = FocusMonitorBinder()
    private lateinit var notificationManager: ServiceNotificationManager
    private lateinit var popNotificationManager: PopNotificationManager
    private lateinit var appMonitor: AppMonitorHandler

    private var monitorLogic: MonitorLogic? = null
    private var overlayManager: OverlayManager? = null

    private val isRunning = AtomicBoolean(false)

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

        notificationManager = ServiceNotificationManager(this)
        popNotificationManager = PopNotificationManager(this)
        appMonitor = AppMonitorHandler(this)

        notificationManager.createNotificationChannel()

        initializeMonitorLogic()
    }

    override fun onStartCommand(
        intent: Intent?,
        flags: Int,
        startId: Int,
    ): Int {
        Log.d(TAG, "Service onStartCommand with action: ${intent?.action}")

        when (intent?.action) {
            ACTION_START_SERVICE, null -> {
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
        monitorLogic?.dispose()
        monitorLogic = null
        serviceInstance = null
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        Log.d(TAG, "Task removed - scheduling service restart")

        val restartIntent =
            Intent(applicationContext, FocusMonitorService::class.java).apply {
                action = ACTION_START_SERVICE
            }

        val pendingIntent =
            PendingIntent.getService(
                applicationContext,
                1,
                restartIntent,
                PendingIntent.FLAG_ONE_SHOT or PendingIntent.FLAG_IMMUTABLE,
            )

        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.set(
            AlarmManager.ELAPSED_REALTIME_WAKEUP,
            SystemClock.elapsedRealtime() + 1000,
            pendingIntent,
        )
    }

    private fun startForegroundService() {
        if (isRunning.get()) {
            Log.d(TAG, "Service already running")
            return
        }

        Log.d(TAG, "Starting foreground service")

        val focusData = monitorLogic?.focusData?.value
        val notification =
            if (focusData != null) {
                notificationManager.createServiceNotification(
                    focusData.isFocusing,
                    focusData.numFocuses,
                    focusData.focusTimeLeft,
                )
            } else {
                notificationManager.createServiceNotification()
            }
        startForeground(ServiceNotificationManager.NOTIFICATION_ID, notification)

        isRunning.set(true)
        appMonitor.startMonitoring()

        Log.d(TAG, "Service started")
    }

    private fun stopForegroundService() {
        if (!isRunning.get()) {
            Log.d(TAG, "Service not running")
            return
        }

        Log.d(TAG, "Stopping foreground service")

        isRunning.set(false)
        appMonitor.stopMonitoring()

        @Suppress("DEPRECATION")
        stopForeground(true)
        stopSelf()
    }

    // --- MonitorLogic initialization ---

    private fun initializeMonitorLogic() {
        try {
            Log.d(TAG, "Initializing MonitorLogic...")

            // Get or create AppContainer
            val app = application
            val webSocketUrl = getWebSocketUrl()
            val container = AppContainer(app, webSocketUrl)

            val logic = container.monitorLogic
            monitorLogic = logic

            // Wire callbacks
            logic.onFocusDataChanged = { data -> onFocusDataChanged(data) }
            logic.onCheckFocusReminder = { sinceLastChange, isFocusing ->
                popNotificationManager.checkAndShowFocusReminder(sinceLastChange, isFocusing)
            }
            logic.onNotificationTimeUpdated = {
                popNotificationManager.forceShowFocusReminder()
            }

            // Wire overlay controller via OverlayManager (no Activity dependency)
            val overlay = OverlayManager(applicationContext)
            overlay.onChallengeCompleted = { ruleId -> logic.onChallengeCompleted(ruleId) }
            overlayManager = overlay

            logic.overlayController =
                object : com.example.coach_android.service.OverlayController {
                    override fun showOverlay(
                        packageName: String,
                        overlayType: String?,
                        challengeType: String?,
                        ruleId: String?,
                    ) {
                        overlay.show(packageName, overlayType, challengeType, ruleId)
                    }

                    override fun hideOverlay() {
                        overlay.hide()
                    }
                }

            logic.initialize()

            Log.d(TAG, "MonitorLogic initialized successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize MonitorLogic", e)
        }
    }

    private fun getWebSocketUrl(): String {
        // Read from BuildConfig or meta-data; fall back to empty
        return try {
            val ai = packageManager.getApplicationInfo(packageName, android.content.pm.PackageManager.GET_META_DATA)
            ai.metaData?.getString("WEBSOCKET_URL") ?: ""
        } catch (e: Exception) {
            ""
        }
    }

    // --- Called by AppMonitorHandler ---

    fun notifyAppDetected(packageName: String) {
        popNotificationManager.updateActivity()
        monitorLogic?.onAppChanged(packageName)
    }

    // --- Focus data changed callback ---

    private fun onFocusDataChanged(data: FocusData) {
        if (!isRunning.get()) return

        notificationManager.updateNotification(
            data.isFocusing,
            data.numFocuses,
            data.focusTimeLeft,
            monitorLogic?.getWebSocketConnectionStatus()?.get("isConnected") as? Boolean ?: false,
        )

        // ViewModels observe MonitorLogic.focusData directly for UI updates.
    }

    // --- Public API for UI / debug ---

    fun requestFocusStateRefresh() {
        monitorLogic?.refreshFocusState()
    }

    fun sendFocusCommand() {
        monitorLogic?.sendFocusCommand()
    }

    fun updateNotificationTimeInBackground() {
        monitorLogic?.updateNotificationTime()
    }

    fun notifyChallengeCompleted(ruleId: String) {
        monitorLogic?.onChallengeCompleted(ruleId)
    }

    fun forceShowFocusReminder() {
        monitorLogic?.forceShowFocusReminder()
    }

    fun reloadMonitoredPackages() {
        monitorLogic?.reloadMonitoredPackages()
    }

    fun getMonitorLogic(): MonitorLogic? = monitorLogic

    // --- Focus Now action from notification ---

    private fun handleFocusNowAction() {
        Log.d(TAG, "Handling Focus Now action from reminder notification")
        popNotificationManager.dismissReminder()
        sendFocusCommand()

        val openAppIntent =
            packageManager.getLaunchIntentForPackage(packageName)?.apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }
        if (openAppIntent != null) {
            startActivity(openAppIntent)
        }
    }
}
