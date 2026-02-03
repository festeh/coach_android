package com.example.coach_android.ui.settings

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel

@Composable
fun SettingsScreen(viewModel: SettingsViewModel = viewModel()) {
    val state by viewModel.state.collectAsStateWithLifecycle()

    if (state.isLoading) {
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            CircularProgressIndicator()
        }
        return
    }

    val settings = state.settings

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        // Notifications section
        item { SectionHeader("Notifications") }
        item {
            SliderSetting(
                label = "Focus gap threshold",
                value = settings.focusGapThresholdMinutes.toFloat(),
                valueRange = 1f..60f,
                valueLabel = "${settings.focusGapThresholdMinutes} min",
                onValueChange = { v -> viewModel.updateSettings { it.copy(focusGapThresholdMinutes = v.toInt()) } },
            )
        }
        item {
            SliderSetting(
                label = "Reminder cooldown",
                value = settings.reminderCooldownMinutes.toFloat(),
                valueRange = 1f..60f,
                valueLabel = "${settings.reminderCooldownMinutes} min",
                onValueChange = { v -> viewModel.updateSettings { it.copy(reminderCooldownMinutes = v.toInt()) } },
            )
        }
        item {
            SliderSetting(
                label = "Activity timeout",
                value = settings.activityTimeoutMinutes.toFloat(),
                valueRange = 1f..60f,
                valueLabel = "${settings.activityTimeoutMinutes} min",
                onValueChange = { v -> viewModel.updateSettings { it.copy(activityTimeoutMinutes = v.toInt()) } },
            )
        }

        // Coach overlay section
        item { SectionHeader("Coach Overlay") }
        item {
            OverlaySettings(
                message = settings.overlayMessage,
                buttonText = settings.overlayButtonText,
                colorHex = settings.overlayColor,
                buttonColorHex = settings.overlayButtonColor,
                targetApp = settings.overlayTargetApp,
                installedApps = state.installedApps,
                onMessageChange = { viewModel.updateSettings { s -> s.copy(overlayMessage = it) } },
                onButtonTextChange = { viewModel.updateSettings { s -> s.copy(overlayButtonText = it) } },
                onColorChange = { viewModel.updateSettings { s -> s.copy(overlayColor = it) } },
                onButtonColorChange = { viewModel.updateSettings { s -> s.copy(overlayButtonColor = it) } },
                onTargetAppChange = { viewModel.updateSettings { s -> s.copy(overlayTargetApp = it) } },
            )
        }

        // Rules overlay section
        item { SectionHeader("Rules Overlay") }
        item {
            OverlaySettings(
                message = settings.rulesOverlayMessage,
                buttonText = settings.rulesOverlayButtonText,
                colorHex = settings.rulesOverlayColor,
                buttonColorHex = settings.rulesOverlayButtonColor,
                targetApp = settings.rulesOverlayTargetApp,
                installedApps = state.installedApps,
                onMessageChange = { viewModel.updateSettings { s -> s.copy(rulesOverlayMessage = it) } },
                onButtonTextChange = { viewModel.updateSettings { s -> s.copy(rulesOverlayButtonText = it) } },
                onColorChange = { viewModel.updateSettings { s -> s.copy(rulesOverlayColor = it) } },
                onButtonColorChange = { viewModel.updateSettings { s -> s.copy(rulesOverlayButtonColor = it) } },
                onTargetAppChange = { viewModel.updateSettings { s -> s.copy(rulesOverlayTargetApp = it) } },
            )
        }

        // Challenge settings
        item { SectionHeader("Challenge Settings") }
        item {
            SliderSetting(
                label = "Long press duration",
                value = settings.longPressDurationSeconds.toFloat(),
                valueRange = 1f..30f,
                valueLabel = "${settings.longPressDurationSeconds}s",
                onValueChange = { v -> viewModel.updateSettings { it.copy(longPressDurationSeconds = v.toInt()) } },
            )
        }
        item {
            OutlinedTextField(
                value = settings.typingPhrase,
                onValueChange = { viewModel.updateSettings { s -> s.copy(typingPhrase = it) } },
                label = { Text("Typing phrase") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
            )
        }
    }
}

@Composable
private fun SectionHeader(text: String) {
    Text(
        text = text,
        style = MaterialTheme.typography.titleMedium,
        color = MaterialTheme.colorScheme.primary,
    )
}

@Composable
private fun SliderSetting(
    label: String,
    value: Float,
    valueRange: ClosedFloatingPointRange<Float>,
    valueLabel: String,
    onValueChange: (Float) -> Unit,
) {
    Column {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            Text(label, style = MaterialTheme.typography.bodyMedium)
            Text(valueLabel, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.primary)
        }
        Slider(
            value = value,
            onValueChange = onValueChange,
            valueRange = valueRange,
            steps = (valueRange.endInclusive - valueRange.start).toInt() - 1,
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun OverlaySettings(
    message: String,
    buttonText: String,
    colorHex: String,
    buttonColorHex: String,
    targetApp: String,
    installedApps: List<SimpleAppInfo>,
    onMessageChange: (String) -> Unit,
    onButtonTextChange: (String) -> Unit,
    onColorChange: (String) -> Unit,
    onButtonColorChange: (String) -> Unit,
    onTargetAppChange: (String) -> Unit,
) {
    var targetExpanded by remember { mutableStateOf(false) }

    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        OutlinedTextField(
            value = message,
            onValueChange = onMessageChange,
            label = { Text("Message ({app} = app name)") },
            modifier = Modifier.fillMaxWidth(),
            singleLine = true,
        )
        OutlinedTextField(
            value = buttonText,
            onValueChange = onButtonTextChange,
            label = { Text("Button text") },
            modifier = Modifier.fillMaxWidth(),
            singleLine = true,
        )
        OutlinedTextField(
            value = colorHex,
            onValueChange = onColorChange,
            label = { Text("Background color (hex, e.g. FF000000)") },
            modifier = Modifier.fillMaxWidth(),
            singleLine = true,
        )
        OutlinedTextField(
            value = buttonColorHex,
            onValueChange = onButtonColorChange,
            label = { Text("Button color (hex, e.g. FFFF5252)") },
            modifier = Modifier.fillMaxWidth(),
            singleLine = true,
        )

        // Target app picker
        ExposedDropdownMenuBox(
            expanded = targetExpanded,
            onExpandedChange = { targetExpanded = it },
        ) {
            val appName = installedApps.find { it.packageName == targetApp }?.name ?: targetApp.ifEmpty { "Home (default)" }
            OutlinedTextField(
                value = appName,
                onValueChange = {},
                readOnly = true,
                label = { Text("Button opens") },
                modifier =
                    Modifier
                        .fillMaxWidth()
                        .menuAnchor(MenuAnchorType.PrimaryNotEditable),
                trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = targetExpanded) },
            )
            ExposedDropdownMenu(
                expanded = targetExpanded,
                onDismissRequest = { targetExpanded = false },
            ) {
                DropdownMenuItem(
                    text = { Text("Home (default)") },
                    onClick = {
                        onTargetAppChange("")
                        targetExpanded = false
                    },
                )
                installedApps.forEach { app ->
                    DropdownMenuItem(
                        text = { Text(app.name) },
                        onClick = {
                            onTargetAppChange(app.packageName)
                            targetExpanded = false
                        },
                    )
                }
            }
        }
    }
}
