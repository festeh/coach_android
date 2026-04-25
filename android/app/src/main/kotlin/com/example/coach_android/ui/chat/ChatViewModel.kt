package com.example.coach_android.ui.chat

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.example.coach_android.FocusMonitorService
import com.example.coach_android.data.agentchat.AgentChatService
import com.example.coach_android.data.agentchat.ChatEvent
import com.example.coach_android.data.agentchat.ChatMessage
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

data class ChatUiState(
    val messages: List<ChatMessage> = emptyList(),
    val connecting: Boolean = false,
    val streaming: Boolean = false,
    val error: String? = null,
)

class ChatViewModel(
    application: Application,
) : AndroidViewModel(application) {
    private val _state = MutableStateFlow(ChatUiState())
    val state: StateFlow<ChatUiState> = _state.asStateFlow()

    private val _dismissRequests = MutableSharedFlow<Unit>(extraBufferCapacity = 1)
    val dismissRequests: SharedFlow<Unit> = _dismissRequests.asSharedFlow()

    private var forced: Boolean = false
    private var eventsJob: Job? = null
    private var focusJob: Job? = null

    fun setForced(value: Boolean) {
        forced = value
    }

    fun isForced(): Boolean = forced

    fun onStart() {
        val chat = chatService() ?: run {
            _state.value = _state.value.copy(error = "Chat service not available")
            return
        }
        eventsJob?.cancel()
        eventsJob =
            viewModelScope.launch {
                chat.events.collect { event -> reduce(event) }
            }
        focusJob?.cancel()
        focusJob =
            viewModelScope.launch {
                FocusMonitorService.getInstance()?.getMonitorLogic()?.focusData?.collect { data ->
                    if (forced && !data.isAgentLocked) {
                        _dismissRequests.tryEmit(Unit)
                    }
                }
            }
        chat.connect()
    }

    fun onStop() {
        eventsJob?.cancel()
        eventsJob = null
        focusJob?.cancel()
        focusJob = null
        chatService()?.disconnect()
    }

    fun send(content: String) {
        val trimmed = content.trim()
        if (trimmed.isEmpty()) return
        val newMessages =
            _state.value.messages +
                ChatMessage(role = ChatMessage.Role.USER, content = trimmed) +
                ChatMessage(role = ChatMessage.Role.ASSISTANT, content = "", streaming = true)
        _state.value =
            _state.value.copy(
                messages = newMessages,
                streaming = true,
                error = null,
            )
        chatService()?.send(trimmed)
    }

    fun reconnect() {
        _state.value = _state.value.copy(error = null)
        chatService()?.let {
            it.disconnect()
            it.connect()
        }
    }

    private fun reduce(event: ChatEvent) {
        when (event) {
            is ChatEvent.History -> {
                _state.value =
                    _state.value.copy(
                        messages = event.messages,
                        connecting = false,
                        error = null,
                    )
            }
            is ChatEvent.Connecting -> {
                _state.value = _state.value.copy(connecting = true)
            }
            is ChatEvent.Connected -> {
                _state.value = _state.value.copy(connecting = false, error = null)
            }
            is ChatEvent.Chunk -> {
                val msgs = _state.value.messages.toMutableList()
                val lastIdx = msgs.indexOfLast { it.role == ChatMessage.Role.ASSISTANT }
                if (lastIdx >= 0 && msgs[lastIdx].streaming) {
                    msgs[lastIdx] =
                        msgs[lastIdx].copy(content = msgs[lastIdx].content + event.text)
                } else {
                    msgs += ChatMessage(
                        role = ChatMessage.Role.ASSISTANT,
                        content = event.text,
                        streaming = true,
                    )
                }
                _state.value = _state.value.copy(messages = msgs, streaming = true)
            }
            is ChatEvent.Done -> {
                val msgs = _state.value.messages.toMutableList()
                val lastIdx = msgs.indexOfLast { it.role == ChatMessage.Role.ASSISTANT }
                if (lastIdx >= 0 && msgs[lastIdx].streaming) {
                    msgs[lastIdx] = msgs[lastIdx].copy(streaming = false)
                }
                _state.value = _state.value.copy(messages = msgs, streaming = false)
            }
            is ChatEvent.Error -> {
                val msgs = _state.value.messages.toMutableList()
                // Drop trailing empty streaming bubble if the request errored before any content.
                val lastIdx = msgs.indexOfLast { it.role == ChatMessage.Role.ASSISTANT }
                if (lastIdx >= 0 && msgs[lastIdx].streaming && msgs[lastIdx].content.isEmpty()) {
                    msgs.removeAt(lastIdx)
                }
                _state.value =
                    _state.value.copy(
                        messages = msgs,
                        streaming = false,
                        connecting = false,
                        error = event.message,
                    )
            }
        }
    }

    private fun chatService(): AgentChatService? =
        FocusMonitorService.getInstance()?.getAgentChatService()
}
