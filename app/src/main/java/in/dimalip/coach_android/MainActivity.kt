package `in`.dimalip.coach_android

import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.tooling.preview.Preview
import `in`.dimalip.coach_android.ui.theme.Coach_androidTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        
        val installedApps = getInstalledApps()
        
        setContent {
            Coach_androidTheme {
                Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
                    AppList(
                        appInfoList = installedApps,
                        modifier = Modifier.padding(innerPadding)
                    )
                }
            }
        }
    }

    private fun getInstalledApps(): List<AppInfo> {
        val packageManager = packageManager
        return packageManager.getInstalledApplications(PackageManager.GET_META_DATA)
            .filter { !it.flags.and(ApplicationInfo.FLAG_SYSTEM).equals(ApplicationInfo.FLAG_SYSTEM) }
            .map { AppInfo(it.loadLabel(packageManager).toString(), it.packageName) }
            .sortedBy { it.name.lowercase() }
    }
}

data class AppInfo(val name: String, val packageName: String)

@Composable
fun AppList(appInfoList: List<AppInfo>, modifier: Modifier = Modifier) {
    LazyColumn(modifier = modifier) {
        items(appInfoList) { appInfo ->
            Text(text = appInfo.name)
        }
    }
}

@Preview(showBackground = true)
@Composable
fun AppListPreview() {
    Coach_androidTheme {
        AppList(listOf(AppInfo("Sample App", "com.example.sampleapp")))
    }
}
