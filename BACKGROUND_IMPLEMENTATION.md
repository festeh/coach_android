# Background Dart Isolate Implementation

This implementation allows the Flutter app to continue running Dart code and making overlay decisions even when the main UI is destroyed.

## Architecture Overview

### Two Flutter Engines
1. **Main Engine**: Runs the Flutter UI (can be destroyed when app is closed)
2. **Background Engine**: Runs in `FocusMonitorService` (persists independently)

### Communication Flow
```
Native Service → Detects App Change → Background Dart Isolate
                                           ↓
                                   Checks monitored apps
                                   Checks focus state
                                           ↓
                                   Decides overlay needed?
                                           ↓
Background Dart → Method Channel → Native Service → Show/Hide Overlay
```

## Key Components

### 1. Background Entry Point (`lib/background_isolate.dart`)
- `@pragma('vm:entry-point')` functions that can be called by native code
- Entry point for the background Flutter isolate

### 2. Background Monitor Handler (`lib/background_monitor_handler.dart`)
- Contains all decision logic for overlay display
- Reads state from SharedPreferences
- Communicates with native service via method channels

### 3. Modified Native Service (`FocusMonitorService.kt`)
- Hosts a separate Flutter engine instance
- Runs background Dart isolate using `DartExecutor`
- Provides method channels for bidirectional communication

### 4. State Synchronization
- Main UI updates SharedPreferences when user changes settings
- Background isolate reads from SharedPreferences
- Both engines can access same persistent storage

## Benefits

✅ **All logic stays in Dart** - No decision logic in native code  
✅ **Runs independently of UI** - Continues working when app is closed  
✅ **No external packages** - Uses only Flutter's built-in capabilities  
✅ **State persistence** - Maintains state across app restarts  
✅ **Clean separation** - UI and background concerns are separate  

## Files Modified/Created

### Created
- `lib/background_isolate.dart` - Background entry point
- `lib/background_monitor_handler.dart` - Background decision logic

### Modified
- `lib/app_monitor.dart` - Added state synchronization to SharedPreferences
- `FocusMonitorService.kt` - Added Flutter engine hosting
- `ForegroundAppMonitorPlugin.kt` - Added background engine support methods
- `AndroidManifest.xml` - Registered background entry point

## How It Works

1. **Service Start**: `FocusMonitorService` starts and creates a background Flutter engine
2. **Dart Execution**: Background engine executes `backgroundMain()` function
3. **State Loading**: Background isolate loads persisted state from SharedPreferences
4. **App Detection**: Native service detects foreground app changes
5. **Decision Making**: Background Dart isolate decides if overlay should be shown
6. **Overlay Control**: Background isolate tells native service to show/hide overlay
7. **State Sync**: Main UI syncs changes to SharedPreferences for background access

This approach ensures that all decision logic remains in Dart while providing the reliability of a native background service.