# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter Android application called "Coach Android" that helps users focus by monitoring app usage and showing overlays when distracted. The app combines Flutter UI with native Android services and communicates with a WebSocket server for focus management.

## Architecture

### Multi-Engine Architecture
The app uses a dual Flutter engine approach:
- **Main UI Engine**: Handles the primary Flutter UI (`main.dart`)
- **Background Engine**: Runs independently via `backgroundMain()` in `main.dart` for monitoring and WebSocket communication

### Native Android Integration
- **MainActivity.kt**: Handles permissions (Usage Stats, Overlay), manages overlays, and provides method channels
- **FocusMonitorService.kt**: Background foreground service that initializes the background Flutter engine and monitors app changes
- **AppMonitorHandler.kt**: Monitors foreground app changes using Usage Stats API

### State Management
Uses Riverpod for state management with Freezed models:
- **FocusState**: Main focus state with loading/ready/error status
- **FocusData**: Core focus data (focusing status, time left, focus count)
- All models use Freezed for immutability and JSON serialization

### Communication Flow
1. Native service detects app changes → Background Flutter engine
2. Background engine applies focus logic → Shows/hides overlay via native methods
3. WebSocket server provides focus updates → Background engine → UI engine via method channels

## Key Components

### WebSocket Service (`lib/services/websocket_service.dart`)
- Singleton service managing WebSocket connection with exponential backoff reconnection
- Handles focus commands (`focus`) and status requests (`get_focusing`)
- Provides broadcast stream for focus updates
- Configured via `WEBSOCKET_URL` environment variable

### Background Monitor Handler (`lib/background_monitor_handler.dart`)
- Core logic for determining when to show focus overlays
- Manages state synchronization between engines using SharedPreferences
- Handles method calls from native service (refresh focus state, start focus)

### Focus Service (`lib/services/focus_service.dart`)
- Main interface for UI to interact with native focus monitoring service
- Handles service lifecycle and permission requests

## Development Commands

### Environment Setup
Requires `.env` file with `WEBSOCKET_URL` variable.

### Build and Run
```bash
# Development run (uses fvm if available, otherwise system flutter)
just run

# Build release APK only
just build-release

# Build and install release APK
just install-release
```

### Code Generation
```bash
# Generate freezed/json_serializable code
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### Permissions Required
- **Usage Stats Permission**: For monitoring foreground apps
- **Overlay Permission**: For showing focus interruption overlays

## Configuration

### WebSocket URL
Set `WEBSOCKET_URL` in `.env` file. The app uses `--dart-define` to pass this to both Flutter engines.

### Monitored Apps
Selected apps are stored in SharedPreferences under key `selected_app_packages` as JSON array of package names.

### Focus State Persistence
Focus state is persisted in SharedPreferences:
- `focusing_state`: Boolean indicating if currently focusing
- Other focus data keys: `sinceLastChange`, `focusTimeLeft`, `numFocuses`

## Channel Names

Method and event channels are defined in:
- **Dart**: `lib/constants/channel_names.dart`  
- **Kotlin**: `android/app/src/main/kotlin/com/example/coach_android/ChannelNames.kt`

Key channels:
- `com.example.coach_android/main_methods`: Main UI ↔ Native communication
- `com.example.coach_android/background_methods`: Background engine ↔ Native
- `com.example.coach_android/background_events`: Native → Background engine events

## Testing

No specific test framework configured. Check for test files in `test/` directory and use standard Flutter testing commands.

## Key Files to Understand

1. `lib/main.dart` - Entry points for both UI and background engines
2. `lib/background_monitor_handler.dart` - Core focus logic and state management  
3. `android/app/src/main/kotlin/com/example/coach_android/FocusMonitorService.kt` - Background service orchestration
4. `lib/services/websocket_service.dart` - WebSocket communication layer
5. `lib/state_management/models/focus_state.dart` - State management models