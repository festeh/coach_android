package com.example.coach_android.data.model

import kotlinx.serialization.Serializable

@Serializable
data class FocusData(
    val isFocusing: Boolean = false,
    val sinceLastChange: Int = 0,
    val focusTimeLeft: Int = 0,
    val numFocuses: Int = 0,
    val lastNotificationTime: Int = 0,
    val lastActivityTime: Int = 0,
    val lastFocusEndTime: Int = 0,
    val agentReleaseTimeLeft: Int? = null,
) {
    val isAgentLocked: Boolean get() = agentReleaseTimeLeft == null

    fun hasSignificantDifference(other: FocusData): Boolean =
        isFocusing != other.isFocusing ||
            isAgentLocked != other.isAgentLocked ||
            kotlin.math.abs(sinceLastChange - other.sinceLastChange) > 10 ||
            kotlin.math.abs(focusTimeLeft - other.focusTimeLeft) > 30 ||
            numFocuses != other.numFocuses

    fun updateFromWebSocket(data: Map<String, Any?>): FocusData {
        val nowFocusing = data["focusing"] as? Boolean ?: isFocusing
        val currentTime = (System.currentTimeMillis() / 1000).toInt()
        val newLastFocusEndTime = if (isFocusing && !nowFocusing) currentTime else lastFocusEndTime

        return copy(
            isFocusing = nowFocusing,
            sinceLastChange = (data["since_last_change"] as? Number)?.toInt() ?: sinceLastChange,
            focusTimeLeft = (data["focus_time_left"] as? Number)?.toInt() ?: focusTimeLeft,
            numFocuses = (data["num_focuses"] as? Number)?.toInt() ?: numFocuses,
            lastFocusEndTime = newLastFocusEndTime,
            agentReleaseTimeLeft = parseAgentReleaseTimeLeft(data),
        )
    }

    companion object {
        fun fromWebSocketResponse(
            data: Map<String, Any?>,
            lastNotificationTime: Int = 0,
            lastActivityTime: Int = 0,
            lastFocusEndTime: Int = 0,
        ): FocusData =
            FocusData(
                isFocusing = data["focusing"] as? Boolean ?: false,
                sinceLastChange = (data["since_last_change"] as? Number)?.toInt() ?: 0,
                focusTimeLeft = (data["focus_time_left"] as? Number)?.toInt() ?: 0,
                numFocuses = (data["num_focuses"] as? Number)?.toInt() ?: 0,
                lastNotificationTime = lastNotificationTime,
                lastActivityTime = lastActivityTime,
                lastFocusEndTime = lastFocusEndTime,
                agentReleaseTimeLeft = parseAgentReleaseTimeLeft(data),
            )

        // Server sends `agent_release_time_left` as a JSON number (seconds remaining)
        // or `null` when the agent lock is engaged. The key is always present.
        private fun parseAgentReleaseTimeLeft(data: Map<String, Any?>): Int? =
            (data["agent_release_time_left"] as? Number)?.toInt()
    }
}
