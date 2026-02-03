package com.example.coach_android.service

interface OverlayController {
    fun showOverlay(
        packageName: String,
        overlayType: String? = null,
        challengeType: String? = null,
        ruleId: String? = null,
    )

    fun hideOverlay()
}
