package com.example.coach_android.ui.components

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.example.coach_android.data.model.FocusData
import com.example.coach_android.util.TimeFormatter

@Composable
fun FocusStatusCard(
    focusData: FocusData,
    isConnected: Boolean,
    onFocusClick: () -> Unit,
    onRefreshClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Card(
        modifier = modifier.fillMaxWidth(),
        colors =
            CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.surfaceContainerHighest,
            ),
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            if (focusData.isFocusing) {
                // Focusing state
                Surface(
                    shape = MaterialTheme.shapes.medium,
                    color = MaterialTheme.colorScheme.primary.copy(alpha = 0.15f),
                ) {
                    Text(
                        text = "Focusing",
                        style = MaterialTheme.typography.titleMedium,
                        color = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                    )
                }

                Spacer(Modifier.height(8.dp))

                if (focusData.focusTimeLeft > 0) {
                    Text(
                        text = TimeFormatter.formatFocusTime(focusData.focusTimeLeft),
                        style = MaterialTheme.typography.headlineMedium,
                        color = MaterialTheme.colorScheme.primary,
                    )
                    Text(
                        text = "remaining",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }

                if (focusData.numFocuses > 0) {
                    Spacer(Modifier.height(4.dp))
                    Text(
                        text = "${focusData.numFocuses} focus session${if (focusData.numFocuses != 1) "s" else ""} today",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            } else {
                // Not focusing state
                Button(
                    onClick = onFocusClick,
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    Text("Focus")
                }

                if (focusData.numFocuses > 0) {
                    Spacer(Modifier.height(4.dp))
                    Text(
                        text = "${focusData.numFocuses} focus session${if (focusData.numFocuses != 1) "s" else ""} today",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }

            Spacer(Modifier.height(8.dp))

            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.Center,
            ) {
                Surface(
                    shape = MaterialTheme.shapes.small,
                    color =
                        if (isConnected) {
                            Color(0xFF4CAF50).copy(alpha = 0.2f)
                        } else {
                            Color(0xFFFF5252).copy(alpha = 0.2f)
                        },
                ) {
                    Text(
                        text = if (isConnected) "Connected" else "Disconnected",
                        style = MaterialTheme.typography.labelSmall,
                        color = if (isConnected) Color(0xFF4CAF50) else Color(0xFFFF5252),
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                    )
                }

                Spacer(Modifier.width(8.dp))

                TextButton(onClick = onRefreshClick) {
                    Text("Refresh", style = MaterialTheme.typography.labelSmall)
                }
            }
        }
    }
}
