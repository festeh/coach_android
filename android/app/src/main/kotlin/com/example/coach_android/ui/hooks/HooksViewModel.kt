package com.example.coach_android.ui.hooks

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.example.coach_android.data.db.HookResultEntity
import com.example.coach_android.data.db.UsageDatabase
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn

class HooksViewModel(
    application: Application,
) : AndroidViewModel(application) {
    private val db = UsageDatabase.create(application)
    private val hookResultDao = db.hookResultDao()

    val results: StateFlow<List<HookResultEntity>> =
        hookResultDao
            .getAll()
            .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())
}
