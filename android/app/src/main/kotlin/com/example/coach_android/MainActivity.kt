package com.example.coach_android

import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.coach_android/appCount"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledAppsCount" -> result.success(getInstalledAppsCount())
                "getInstalledApps" -> result.success(getInstalledApps())
                else -> result.notImplemented()
            }
        }
    }

    private fun getInstalledAppsCount(): Int {
        val pm = context.packageManager
        val packages = pm.getInstalledApplications(PackageManager.GET_META_DATA)
        return packages.size
    }
    
    private fun getInstalledApps(): List<Map<String, Any>> {
        val pm = context.packageManager
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
