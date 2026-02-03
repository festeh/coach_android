package com.example.coach_android.ui.settings

import android.app.Application
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.example.coach_android.data.model.AppSettings
import com.example.coach_android.data.preferences.PreferencesManager
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

data class SimpleAppInfo(
    val name: String,
    val packageName: String,
)

data class SettingsUiState(
    val settings: AppSettings = AppSettings(),
    val installedApps: List<SimpleAppInfo> = emptyList(),
    val isLoading: Boolean = true,
)

class SettingsViewModel(
    application: Application,
) : AndroidViewModel(application) {
    private val prefs = PreferencesManager(application)
    private val _state = MutableStateFlow(SettingsUiState())
    val state: StateFlow<SettingsUiState> = _state.asStateFlow()

    init {
        load()
    }

    private fun load() {
        viewModelScope.launch {
            val settings = prefs.loadSettings()
            val apps = withContext(Dispatchers.IO) { loadApps() }
            _state.value =
                SettingsUiState(
                    settings = settings,
                    installedApps = apps,
                    isLoading = false,
                )
        }
    }

    private fun loadApps(): List<SimpleAppInfo> {
        val pm = getApplication<Application>().packageManager
        return pm
            .getInstalledApplications(PackageManager.GET_META_DATA)
            .filter { (it.flags and ApplicationInfo.FLAG_SYSTEM) == 0 }
            .mapNotNull { info ->
                try {
                    SimpleAppInfo(
                        name = info.loadLabel(pm).toString(),
                        packageName = info.packageName,
                    )
                } catch (_: Exception) {
                    null
                }
            }.sortedBy { it.name.lowercase() }
    }

    fun updateSettings(transform: (AppSettings) -> AppSettings) {
        val updated = transform(_state.value.settings)
        _state.value = _state.value.copy(settings = updated)
        prefs.saveSettings(updated)
    }
}
