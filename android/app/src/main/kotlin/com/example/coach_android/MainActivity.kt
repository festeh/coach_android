package com.example.coach_android

import android.content.Intent
import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.example.coach_android.ui.navigation.AppNavigation
import com.example.coach_android.ui.theme.CoachTheme

class MainActivity : ComponentActivity() {
    companion object {
        const val TAG = "MainActivity"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "onCreate")

        enableEdgeToEdge()

        // Start the foreground service
        startFocusMonitorService()

        setContent {
            CoachTheme {
                AppNavigation()
            }
        }
    }

    private fun startFocusMonitorService() {
        Log.d(TAG, "Starting FocusMonitorService")
        val intent =
            Intent(this, FocusMonitorService::class.java).apply {
                action = FocusMonitorService.ACTION_START_SERVICE
            }
        try {
            startForegroundService(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Error starting service", e)
        }
    }
}
