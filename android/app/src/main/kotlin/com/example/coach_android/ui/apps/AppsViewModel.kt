package com.example.coach_android.ui.apps

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.example.coach_android.FocusMonitorService
import com.example.coach_android.data.db.RuleCounterDao
import com.example.coach_android.data.model.AppInfo
import com.example.coach_android.data.model.AppRule
import com.example.coach_android.data.model.FocusData
import com.example.coach_android.data.preferences.PreferencesManager
import com.example.coach_android.util.TimeFormatter
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

data class AppsUiState(
    val apps: List<AppInfo> = emptyList(),
    val selectedPackages: Set<String> = emptySet(),
    val rules: Map<String, AppRule> = emptyMap(),
    val focusData: FocusData = FocusData(),
    val isConnected: Boolean = false,
    val isLoading: Boolean = true,
    val ruleCounters: Map<String, Pair<Int, Int>> = emptyMap(),
)

class AppsViewModel(
    application: Application,
) : AndroidViewModel(application) {
    private val prefs = PreferencesManager(application)
    private val _state = MutableStateFlow(AppsUiState())
    val state: StateFlow<AppsUiState> = _state.asStateFlow()

    private var ruleCounterDao: RuleCounterDao? = null

    init {
        loadData()
    }

    private fun loadData() {
        viewModelScope.launch {
            val apps = withContext(Dispatchers.IO) { AppInfo.loadInstalled(getApplication<Application>().packageManager) }
            val selected = prefs.loadMonitoredPackages()
            val rules = prefs.loadRules()
            val focusData = prefs.loadFocusData()

            _state.value =
                _state.value.copy(
                    apps = apps,
                    selectedPackages = selected,
                    rules = rules,
                    focusData = focusData,
                    isLoading = false,
                )

            // Try to get live focus data from service
            refreshFromService()
            loadRuleCounters()
        }
    }

    fun refreshFromService() {
        val logic = FocusMonitorService.getInstance()?.getMonitorLogic() ?: return

        viewModelScope.launch {
            logic.focusData.collect { data ->
                val status = logic.getWebSocketConnectionStatus()
                _state.value =
                    _state.value.copy(
                        focusData = data,
                        isConnected = status["isConnected"] as? Boolean ?: false,
                    )
            }
        }
    }

    fun toggleCoach(
        packageName: String,
        enabled: Boolean,
    ) {
        val current = _state.value.selectedPackages.toMutableSet()
        if (enabled) current.add(packageName) else current.remove(packageName)
        _state.value = _state.value.copy(selectedPackages = current)
        prefs.saveMonitoredPackages(current)
        FocusMonitorService.getInstance()?.getMonitorLogic()?.reloadMonitoredPackages()
    }

    fun saveRule(rule: AppRule) {
        val updated = _state.value.rules + (rule.id to rule)
        _state.value = _state.value.copy(rules = updated)
        prefs.saveRules(updated)
        FocusMonitorService.getInstance()?.getMonitorLogic()?.reloadRules()
    }

    fun deleteRule(rule: AppRule) {
        val updated = _state.value.rules - rule.id
        _state.value = _state.value.copy(rules = updated)
        prefs.saveRules(updated)
        FocusMonitorService.getInstance()?.getMonitorLogic()?.reloadRules()
    }

    fun resetRule(rule: AppRule) {
        viewModelScope.launch(Dispatchers.IO) {
            try {
                val service = FocusMonitorService.getInstance()
                val container = service?.getMonitorLogic()
                // Access RuleCounterDao through the service's container
                // For now, reload rules which effectively resets the in-memory state
                val today = TimeFormatter.todayString()
                // We need the DAO - get it from the database
                val dao = getRuleCounterDao()
                dao?.resetCounters(rule.id, today)
                loadRuleCounters()
            } catch (_: Exception) {
            }
        }
    }

    private fun getRuleCounterDao(): RuleCounterDao? {
        if (ruleCounterDao != null) return ruleCounterDao
        // Create a separate DB instance to query counters
        val db =
            com.example.coach_android.data.db.UsageDatabase
                .create(getApplication())
        ruleCounterDao = db.ruleCounterDao()
        return ruleCounterDao
    }

    private fun loadRuleCounters() {
        viewModelScope.launch(Dispatchers.IO) {
            val dao = getRuleCounterDao() ?: return@launch
            val today = TimeFormatter.todayString()
            val counters = mutableMapOf<String, Pair<Int, Int>>()
            for (rule in _state.value.rules.values) {
                try {
                    val c = dao.getCounters(rule.id, today)
                    if (c != null) {
                        counters[rule.id] = Pair(c.openCount, c.triggerCount)
                    }
                } catch (_: Exception) {
                }
            }
            _state.value = _state.value.copy(ruleCounters = counters)
        }
    }

    fun sendFocusCommand() {
        FocusMonitorService.getInstance()?.getMonitorLogic()?.sendFocusCommand()
    }

    fun refreshFocusState() {
        FocusMonitorService.getInstance()?.getMonitorLogic()?.refreshFocusState()
    }

    fun rulesForPackage(packageName: String): List<AppRule> =
        _state.value.rules.values
            .filter { it.packageName == packageName }
}
