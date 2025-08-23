# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Coach Android is a Flutter app that monitors foreground applications and shows overlays to help users focus better. It includes a custom Flutter plugin (`foreground_app_monitor`) that provides native Android functionality for app monitoring and overlay display.

## Architecture

### Dual Flutter Engine System
- **Main Engine**: Runs the Flutter UI (can be destroyed when app is closed)  
- **Background Engine**: Runs in `FocusMonitorService` (persists independently)
- **Communication**: Native service detects app changes → Background Dart isolate makes decisions → Controls overlay display

### Key Components
- `lib/background_isolate.dart` - Background entry point with `@pragma('vm:entry-point')` functions
- `lib/background_monitor_handler.dart` - Background decision logic for overlay display  
- `lib/state_management/` - Riverpod providers and Freezed models for state management
- `foreground_app_monitor/` - Custom Flutter plugin providing native Android functionality
- Background service runs independently using a separate Flutter engine in `FocusMonitorService.kt`

### State Management
- Uses Riverpod for state management with Freezed data classes
- SharedPreferences for persistence between main UI and background isolate
- State synchronization ensures background service has access to user settings

## Development Commands

### Running the App
```bash
# Default run command (requires .env with WEBSOCKET_URL)
just run
# Or directly with Flutter
flutter run --dart-define=WEBSOCKET_URL="ws://your-url"
```

### Code Generation
```bash
# Generate Freezed/JSON serializable code  
flutter packages pub run build_runner build
```

### Testing and Analysis
```bash
# Run static analysis
flutter analyze

# Run tests
flutter test

# Run widget tests specifically
flutter test test/widget_test.dart
```

### Plugin Development
The `foreground_app_monitor` plugin has its own development cycle:
```bash
cd foreground_app_monitor/example
flutter run  # Test plugin functionality
```

## Environment Setup

Requires `.env` file with `WEBSOCKET_URL` variable for WebSocket connectivity. The justfile automatically loads environment variables and validates the WebSocket URL is set before running.

## Code Generation Dependencies
- Uses `build_runner`, `freezed`, and `json_serializable` for code generation
- State models use Freezed for immutable data classes with JSON serialization
- Run code generation after modifying any `.freezed.dart` or `.g.dart` files