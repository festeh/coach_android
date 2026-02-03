package com.example.coach_android.di

import android.content.Context
import com.example.coach_android.data.db.UsageDatabase
import com.example.coach_android.data.preferences.PreferencesManager
import com.example.coach_android.data.websocket.WebSocketService
import com.example.coach_android.service.MonitorLogic

class AppContainer(
    context: Context,
    webSocketUrl: String,
) {
    val preferencesManager = PreferencesManager(context)
    val database = UsageDatabase.create(context)
    val eventDao = database.eventDao()
    val ruleCounterDao = database.ruleCounterDao()
    val webSocketService = WebSocketService(webSocketUrl)

    val monitorLogic =
        MonitorLogic(
            prefs = preferencesManager,
            eventDao = eventDao,
            ruleCounterDao = ruleCounterDao,
            webSocketService = webSocketService,
        )
}
