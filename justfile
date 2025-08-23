set dotenv-load

default: run

run:
    #!/usr/bin/env bash
    # Ensure the WEBSOCKET_URL variable is loaded from .env
    if [ -z "$WEBSOCKET_URL" ]; then
        echo "Error: WEBSOCKET_URL is not set in .env file or environment."
        exit 1
    fi
    echo "Running app with WEBSOCKET_URL=${WEBSOCKET_URL}"
    if ! command -v flutter &>/dev/null; then
        fvm flutter run --dart-define=WEBSOCKET_URL="${WEBSOCKET_URL}" | grep -v -E "ApkAssets"
        exit 1
    else
        flutter run --dart-define=WEBSOCKET_URL="${WEBSOCKET_URL}" | grep -v -E "ApkAssets"
    fi

install-release:
    #!/usr/bin/env bash
    # Build and install release APK
    # Ensure the WEBSOCKET_URL variable is loaded from .env
    if [ -z "$WEBSOCKET_URL" ]; then
        echo "Error: WEBSOCKET_URL is not set in .env file or environment."
        exit 1
    fi
    echo "Building release APK with WEBSOCKET_URL=${WEBSOCKET_URL}"
    if ! command -v flutter &>/dev/null; then
        echo "Using fvm flutter..."
        fvm flutter build apk --release --dart-define=WEBSOCKET_URL="${WEBSOCKET_URL}"
    else
        echo "Using system flutter..."
        flutter build apk --release --dart-define=WEBSOCKET_URL="${WEBSOCKET_URL}"
    fi
    
    # Check if build succeeded
    if [ ! -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
        echo "Error: Release APK not found. Build may have failed."
        exit 1
    fi
    
    echo "Installing release APK..."
    adb install -r build/app/outputs/flutter-apk/app-release.apk
    echo "Release APK installed successfully!"

build-release:
    #!/usr/bin/env bash
    # Build release APK only (without installing)
    # Ensure the WEBSOCKET_URL variable is loaded from .env
    if [ -z "$WEBSOCKET_URL" ]; then
        echo "Error: WEBSOCKET_URL is not set in .env file or environment."
        exit 1
    fi
    echo "Building release APK with WEBSOCKET_URL=${WEBSOCKET_URL}"
    if ! command -v flutter &>/dev/null; then
        echo "Using fvm flutter..."
        fvm flutter build apk --release --dart-define=WEBSOCKET_URL="${WEBSOCKET_URL}"
    else
        echo "Using system flutter..."
        flutter build apk --release --dart-define=WEBSOCKET_URL="${WEBSOCKET_URL}"
    fi
    
    # Check if build succeeded
    if [ ! -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
        echo "Error: Release APK not found. Build may have failed."
        exit 1
    fi
    
    echo "Release APK built successfully at: build/app/outputs/flutter-apk/app-release.apk"
