package com.example.coach_android

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.PixelFormat
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.os.Process
import android.provider.Settings
import android.text.Editable
import android.text.TextWatcher
import android.util.Log
import android.util.TypedValue
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.graphics.drawable.GradientDrawable
import android.widget.Button
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.TextView
import androidx.annotation.RequiresApi
import android.os.CountDownTimer
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
    private var currentRuleId: String? = null
    private var currentTargetApp: String? = null
    private var longPressTimer: CountDownTimer? = null
    
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
                val overlayType = call.argument<String>("overlayType")
                val challengeType = call.argument<String>("challengeType")
                val ruleId = call.argument<String>("ruleId")
                Log.d(TAG, "Received showOverlay call with packageName: $packageName, overlayType: $overlayType, challengeType: $challengeType")
                showOverlay(packageName, overlayType, challengeType, ruleId)
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
            "reloadMonitoredPackages" -> {
                Log.d(TAG, "Received reload monitored packages request from main UI")
                val service = FocusMonitorService.getInstance()
                if (service != null) {
                    service.reloadMonitoredPackages()
                    result.success(true)
                } else {
                    Log.w(TAG, "Service not running, cannot reload monitored packages")
                    result.error("SERVICE_NOT_RUNNING", "FocusMonitorService is not running", null)
                }
            }
            "sendFocusCommand" -> {
                Log.d(TAG, "Received focus command from main UI")
                val service = FocusMonitorService.getInstance()
                if (service != null) {
                    service.sendFocusCommand()
                    result.success(true)
                } else {
                    Log.w(TAG, "Service not running, cannot send focus command")
                    result.error("SERVICE_NOT_RUNNING", "FocusMonitorService is not running", null)
                }
            }
            "testMethodCall" -> {
                Log.d(TAG, "Received test method call from UI")
                result.success("Test method call successful")
            }
            "checkBatteryOptimizationExclusion" -> {
                result.success(isBatteryOptimizationExcluded())
            }
            "requestBatteryOptimizationExclusion" -> {
                try {
                    requestBatteryOptimizationExclusion()
                    result.success(true)
                } catch (e: Exception) {
                    Log.e(TAG, "Error requesting battery optimization exclusion", e)
                    result.error("ERROR_BATTERY_OPT", "Could not request battery optimization exclusion", e.localizedMessage)
                }
            }
            "forceShowFocusReminder" -> {
                Log.d(TAG, "Received force show focus reminder from UI (debug)")
                val service = FocusMonitorService.getInstance()
                if (service != null) {
                    // Call the service method directly to force show reminder
                    try {
                        service.forceShowFocusReminder()
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error forcing focus reminder", e)
                        result.error("ERROR_FORCE_REMINDER", "Failed to force show reminder", e.localizedMessage)
                    }
                } else {
                    Log.w(TAG, "Service not running, cannot force show reminder")
                    result.error("SERVICE_NOT_RUNNING", "FocusMonitorService is not running", null)
                }
            }
            "getAppUsageStats" -> {
                Log.d(TAG, "Received getAppUsageStats request")
                val startTime = call.argument<Long>("startTime")
                val endTime = call.argument<Long>("endTime")
                if (startTime != null && endTime != null) {
                    try {
                        val stats = getAppUsageStats(startTime, endTime)
                        result.success(stats)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error getting app usage stats", e)
                        result.error("ERROR_USAGE_STATS", "Failed to get usage stats", e.localizedMessage)
                    }
                } else {
                    result.error("INVALID_ARGS", "startTime and endTime are required", null)
                }
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

    private fun isBatteryOptimizationExcluded(): Boolean {
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager?
        return powerManager?.isIgnoringBatteryOptimizations(packageName) ?: false
    }

    @android.annotation.SuppressLint("BatteryLife")
    private fun requestBatteryOptimizationExclusion() {
        val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
            data = Uri.parse("package:$packageName")
        }
        startActivity(intent)
    }

    // --- Overlay Management ---

    private fun showOverlay(packageName: String?, overlayType: String? = null, challengeType: String? = null, ruleId: String? = null) {
        if (overlayView != null) {
            Log.d(TAG, "Replacing existing overlay with new one for $packageName (type: ${overlayType ?: "coach"})")
            hideOverlay()
        }
        if (!hasOverlayPermission()) {
            Log.w(TAG, "Cannot show overlay: Permission not granted.")
            return
        }

        currentRuleId = ruleId
        val effectiveChallengeType = challengeType ?: "none"

        Log.d(TAG, "Showing overlay for package: $packageName (type: ${overlayType ?: "coach"}, challenge: $effectiveChallengeType)")

        // Read overlay preferences based on overlay type
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val isRule = overlayType == "rule"
        val targetAppKey = if (isRule) "flutter.settingsRulesOverlayTargetApp" else "flutter.settingsOverlayTargetApp"
        currentTargetApp = prefs.getString(targetAppKey, "") ?: ""
        val messageKey = if (isRule) "flutter.settingsRulesOverlayMessage" else "flutter.settingsOverlayMessage"
        val colorKey = if (isRule) "flutter.settingsRulesOverlayColor" else "flutter.settingsOverlayColor"
        val buttonTextKey = if (isRule) "flutter.settingsRulesOverlayButtonText" else "flutter.settingsOverlayButtonText"
        val buttonColorKey = if (isRule) "flutter.settingsRulesOverlayButtonColor" else "flutter.settingsOverlayButtonColor"
        val customMessage = prefs.getString(messageKey, "") ?: ""
        val overlayColorHex = prefs.getString(colorKey, "FF000000") ?: "FF000000"
        val customButtonText = prefs.getString(buttonTextKey, "") ?: ""
        val buttonColorHex = prefs.getString(buttonColorKey, "FFFF5252") ?: "FFFF5252"

        // Resolve friendly app name
        val appName = if (packageName != null && packageName.isNotEmpty()) {
            try {
                val appInfo = packageManager.getApplicationInfo(packageName, 0)
                appInfo.loadLabel(packageManager).toString()
            } catch (e: PackageManager.NameNotFoundException) {
                packageName
            }
        } else {
            null
        }

        // Build display text
        val displayText = if (customMessage.isNotEmpty()) {
            if (appName != null) {
                customMessage.replace("{app}", appName)
            } else {
                customMessage.replace("{app}", "")
            }
        } else if (appName != null) {
            "I detected $appName.\nIt's time to focus!"
        } else {
            "Focus Time!"
        }

        // Parse colors
        val bgColor = try {
            java.lang.Long.parseLong(overlayColorHex, 16).toInt()
        } catch (e: NumberFormatException) {
            0xFF000000.toInt()
        }
        val bgColorWithAlpha = (0xCC shl 24) or (bgColor and 0x00FFFFFF)
        val buttonColor = try {
            java.lang.Long.parseLong(buttonColorHex, 16).toInt()
        } catch (e: NumberFormatException) {
            0xFFFF5252.toInt()
        }

        val density = resources.displayMetrics.density

        when (effectiveChallengeType) {
            "longPress" -> {
                val longPressDuration = prefs.getLong("flutter.settingsLongPressDuration", 5).toInt()
                overlayView = buildLongPressChallengeView(displayText, bgColorWithAlpha, buttonColor, density, longPressDuration)
            }
            "typing" -> {
                val typingPhrase = prefs.getString("flutter.settingsTypingPhrase", "I will focus") ?: "I will focus"
                overlayView = buildTypingChallengeView(displayText, bgColorWithAlpha, buttonColor, density, typingPhrase)
            }
            else -> {
                overlayView = buildStandardOverlayView(displayText, bgColorWithAlpha, buttonColor, customButtonText, density)
            }
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

    private fun buildStandardOverlayView(displayText: String, bgColor: Int, buttonColor: Int, customButtonText: String, density: Float): View {
        val view = layoutInflater?.inflate(R.layout.overlay_layout, null)!!

        view.findViewById<TextView>(R.id.overlay_text)?.text = displayText
        view.background = GradientDrawable().apply {
            setColor(bgColor)
            cornerRadius = 16f * density
            setStroke((1f * density).toInt(), 0xFFFFFFFF.toInt())
        }

        view.findViewById<Button>(R.id.close_overlay_button)?.let { button ->
            if (customButtonText.isNotEmpty()) {
                button.text = customButtonText
            }
            button.backgroundTintList = android.content.res.ColorStateList.valueOf(buttonColor)
            button.setOnClickListener {
                goHomeAndHideOverlay()
            }
        }

        return view
    }

    private fun buildLongPressChallengeView(displayText: String, bgColor: Int, buttonColor: Int, density: Float, durationSeconds: Int): View {
        val dp = { value: Int -> (value * density).toInt() }

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(24), dp(24), dp(24), dp(24))
            background = GradientDrawable().apply {
                setColor(bgColor)
                cornerRadius = 16f * density
                setStroke((1f * density).toInt(), 0xFFFFFFFF.toInt())
            }
        }

        // X close button at top-right
        val closeButton = TextView(this).apply {
            text = "\u2715"
            setTextColor(0xAAFFFFFF.toInt())
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 18f)
            gravity = Gravity.END
            setPadding(0, 0, 0, dp(8))
            setOnClickListener { goHomeAndHideOverlay() }
        }
        root.addView(closeButton, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ))

        // Message text
        val textView = TextView(this).apply {
            text = displayText
            setTextColor(0xFFFFFFFF.toInt())
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 20f)
            setTypeface(typeface, android.graphics.Typeface.BOLD)
            setPadding(dp(8), dp(8), dp(8), dp(8))
        }
        root.addView(textView)

        // Progress bar
        val progressBar = ProgressBar(this, null, android.R.attr.progressBarStyleHorizontal).apply {
            max = 100
            progress = 0
            progressTintList = android.content.res.ColorStateList.valueOf(buttonColor)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dp(8)
            ).apply { topMargin = dp(16) }
        }
        root.addView(progressBar)

        // Hold button
        val holdButton = Button(this).apply {
            text = "Hold to dismiss"
            setTextColor(0xFFFFFFFF.toInt())
            backgroundTintList = android.content.res.ColorStateList.valueOf(buttonColor)
            isAllCaps = false
            setTypeface(typeface, android.graphics.Typeface.BOLD)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { topMargin = dp(8) }
        }

        val durationMs = durationSeconds * 1000L

        holdButton.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    longPressTimer = object : CountDownTimer(durationMs, 50) {
                        override fun onTick(millisUntilFinished: Long) {
                            val elapsed = durationMs - millisUntilFinished
                            progressBar.progress = (elapsed * 100 / durationMs).toInt()
                        }

                        override fun onFinish() {
                            progressBar.progress = 100
                            notifyChallengeCompleted()
                        }
                    }.start()
                    true
                }
                MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                    longPressTimer?.cancel()
                    longPressTimer = null
                    progressBar.progress = 0
                    true
                }
                else -> false
            }
        }
        root.addView(holdButton)

        return root
    }

    private fun buildTypingChallengeView(displayText: String, bgColor: Int, buttonColor: Int, density: Float, phrase: String): View {
        val dp = { value: Int -> (value * density).toInt() }

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(24), dp(24), dp(24), dp(24))
            background = GradientDrawable().apply {
                setColor(bgColor)
                cornerRadius = 16f * density
                setStroke((1f * density).toInt(), 0xFFFFFFFF.toInt())
            }
        }

        // X close button at top-right
        val closeButton = TextView(this).apply {
            text = "\u2715"
            setTextColor(0xAAFFFFFF.toInt())
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 18f)
            gravity = Gravity.END
            setPadding(0, 0, 0, dp(8))
            setOnClickListener { goHomeAndHideOverlay() }
        }
        root.addView(closeButton, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ))

        // Message text
        val textView = TextView(this).apply {
            text = displayText
            setTextColor(0xFFFFFFFF.toInt())
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 20f)
            setTypeface(typeface, android.graphics.Typeface.BOLD)
            setPadding(dp(8), dp(8), dp(8), dp(8))
        }
        root.addView(textView)

        // Instruction text showing the phrase to type
        val instructionText = TextView(this).apply {
            text = "Type: \"$phrase\""
            setTextColor(0xCCFFFFFF.toInt())
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            setPadding(dp(8), dp(16), dp(8), dp(4))
        }
        root.addView(instructionText)

        // EditText for user input
        val editText = EditText(this).apply {
            setTextColor(0xFFFFFFFF.toInt())
            setHintTextColor(0x88FFFFFF.toInt())
            hint = "Type here..."
            setBackgroundColor(0x33FFFFFF.toInt())
            setPadding(dp(12), dp(10), dp(12), dp(10))
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { topMargin = dp(8) }
        }
        root.addView(editText)

        // Submit button
        val submitButton = Button(this).apply {
            text = "Submit"
            setTextColor(0xFFFFFFFF.toInt())
            backgroundTintList = android.content.res.ColorStateList.valueOf(buttonColor)
            isAllCaps = false
            setTypeface(typeface, android.graphics.Typeface.BOLD)
            isEnabled = false
            alpha = 0.5f
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { topMargin = dp(8) }
        }

        editText.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
            override fun afterTextChanged(s: Editable?) {
                val matches = s.toString().trim().equals(phrase, ignoreCase = true)
                submitButton.isEnabled = matches
                submitButton.alpha = if (matches) 1.0f else 0.5f
            }
        })

        submitButton.setOnClickListener {
            notifyChallengeCompleted()
        }
        root.addView(submitButton)

        return root
    }

    private fun goHomeAndHideOverlay() {
        val targetApp = currentTargetApp
        if (!targetApp.isNullOrEmpty()) {
            Log.d(TAG, "Launching target app: $targetApp")
            val launchIntent = packageManager.getLaunchIntentForPackage(targetApp)
            if (launchIntent != null) {
                launchIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                try {
                    startActivity(launchIntent)
                } catch (e: Exception) {
                    Log.e(TAG, "Error launching target app $targetApp, falling back to home", e)
                    launchHome()
                }
            } else {
                Log.w(TAG, "No launch intent for $targetApp, falling back to home")
                launchHome()
            }
        } else {
            launchHome()
        }
        hideOverlay()
    }

    private fun launchHome() {
        Log.d(TAG, "Sending Home intent.")
        val homeIntent = Intent(Intent.ACTION_MAIN)
        homeIntent.addCategory(Intent.CATEGORY_HOME)
        homeIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        try {
            startActivity(homeIntent)
        } catch (e: Exception) {
            Log.e(TAG, "Error sending Home intent", e)
        }
    }

    private fun notifyChallengeCompleted() {
        val ruleId = currentRuleId
        if (ruleId != null) {
            Log.d(TAG, "Challenge completed for rule: $ruleId")
            goHomeAndHideOverlay()
            FocusMonitorService.getInstance()?.notifyChallengeCompleted(ruleId)
        } else {
            Log.w(TAG, "notifyChallengeCompleted called but no currentRuleId set")
            goHomeAndHideOverlay()
        }
    }

    private fun hideOverlay() {
        if (overlayView == null) {
            Log.d(TAG, "Overlay not shown or already hidden.")
            return
        }
        Log.d(TAG, "Hiding overlay...")
        longPressTimer?.cancel()
        longPressTimer = null
        currentTargetApp = null
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
    
    fun showOverlayFromService(packageName: String, overlayType: String? = null, challengeType: String? = null, ruleId: String? = null) {
        Log.d(TAG, "Background service requests show overlay for: $packageName (type: ${overlayType ?: "coach"}, challenge: ${challengeType ?: "none"})")
        runOnUiThread {
            showOverlay(packageName, overlayType, challengeType, ruleId)
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
                Log.d(TAG, "Forwarding focusStateChanged to UI: $data")
                
                mainMethodChannel?.invokeMethod("focusStateChanged", data, object : MethodChannel.Result {
                    override fun success(result: Any?) {}
                    
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

    // --- App Usage Stats ---

    private fun getAppUsageStats(startTime: Long, endTime: Long): List<Map<String, Any>> {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager?
            ?: return emptyList()

        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        )

        return stats
            .filter { it.totalTimeInForeground > 0 }
            .map { stat ->
                mapOf(
                    "packageName" to stat.packageName,
                    "totalTimeMs" to stat.totalTimeInForeground
                )
            }
            .sortedByDescending { it["totalTimeMs"] as Long }
    }
}
