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
