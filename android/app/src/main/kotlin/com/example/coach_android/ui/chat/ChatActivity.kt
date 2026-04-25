package com.example.coach_android.ui.chat

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.OnBackPressedCallback
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import com.example.coach_android.ui.theme.CoachTheme

class ChatActivity : ComponentActivity() {
    private val viewModel: ChatViewModel by viewModels {
        object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>): T =
                ChatViewModel(application) as T
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val forced = intent?.getBooleanExtra(EXTRA_FORCED, false) ?: false
        viewModel.setForced(forced)

        onBackPressedDispatcher.addCallback(
            this,
            object : OnBackPressedCallback(true) {
                override fun handleOnBackPressed() {
                    if (viewModel.isForced()) {
                        dismiss()
                    } else {
                        finish()
                    }
                }
            },
        )

        setContent {
            CoachTheme {
                ChatScreen(
                    viewModel = viewModel,
                    onDismissRequest = { dismiss() },
                )
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val forced = intent.getBooleanExtra(EXTRA_FORCED, false)
        // A forced re-launch should preserve forced mode; a voluntary launch
        // arriving while a forced session is open does not downgrade it.
        if (forced) viewModel.setForced(true)
    }

    override fun onStart() {
        super.onStart()
        viewModel.onStart()
    }

    override fun onStop() {
        super.onStop()
        viewModel.onStop()
    }

    private fun dismiss() {
        // Mirror OverlayManager.dismissAndNavigate: send the user to home so
        // they don't bounce straight back into the monitored app.
        val homeIntent =
            Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
        try {
            startActivity(homeIntent)
        } catch (_: Exception) {
        }
        finish()
    }

    companion object {
        const val EXTRA_FORCED = "EXTRA_FORCED"
    }
}
