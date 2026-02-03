package com.example.coach_android.ui.navigation

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Build
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.example.coach_android.ui.apps.AppsScreen
import com.example.coach_android.ui.debug.DebugScreen
import com.example.coach_android.ui.logs.LogsScreen
import com.example.coach_android.ui.settings.SettingsScreen
import com.example.coach_android.ui.stats.StatsScreen

sealed class Screen(
    val route: String,
    val label: String,
    val icon: ImageVector,
) {
    data object Apps : Screen("apps", "Apps", Icons.Default.Home)

    data object Stats : Screen("stats", "Stats", Icons.Default.Star)
}

private val bottomTabs = listOf(Screen.Apps, Screen.Stats)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AppNavigation() {
    val navController = rememberNavController()
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination

    val currentRoute = currentDestination?.route
    val showBottomBar = currentRoute in bottomTabs.map { it.route }

    Scaffold(
        topBar = {
            if (showBottomBar) {
                TopAppBar(
                    title = { Text("Coach") },
                    actions = {
                        IconButton(onClick = {
                            navController.navigate("debug") {
                                launchSingleTop = true
                            }
                        }) {
                            Icon(Icons.Default.Build, contentDescription = "Debug")
                        }
                        IconButton(onClick = {
                            navController.navigate("settings") {
                                launchSingleTop = true
                            }
                        }) {
                            Icon(Icons.Default.Settings, contentDescription = "Settings")
                        }
                    },
                )
            } else {
                TopAppBar(
                    title = {
                        Text(
                            when (currentRoute) {
                                "settings" -> "Settings"
                                "debug" -> "Debug"
                                "logs" -> "Logs"
                                else -> "Coach"
                            },
                        )
                    },
                    navigationIcon = {
                        TextButton(onClick = { navController.popBackStack() }) {
                            Text("Back")
                        }
                    },
                )
            }
        },
        bottomBar = {
            if (showBottomBar) {
                NavigationBar {
                    bottomTabs.forEach { screen ->
                        NavigationBarItem(
                            icon = { Icon(screen.icon, contentDescription = screen.label) },
                            label = { Text(screen.label) },
                            selected = currentDestination?.hierarchy?.any { it.route == screen.route } == true,
                            onClick = {
                                navController.navigate(screen.route) {
                                    popUpTo(navController.graph.findStartDestination().id) {
                                        saveState = true
                                    }
                                    launchSingleTop = true
                                    restoreState = true
                                }
                            },
                        )
                    }
                }
            }
        },
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = Screen.Apps.route,
            modifier = Modifier.padding(innerPadding),
        ) {
            composable(Screen.Apps.route) { AppsScreen() }
            composable(Screen.Stats.route) { StatsScreen() }
            composable("settings") { SettingsScreen() }
            composable("debug") {
                DebugScreen(
                    onNavigateToLogs = {
                        navController.navigate("logs") { launchSingleTop = true }
                    },
                )
            }
            composable("logs") { LogsScreen() }
        }
    }
}
