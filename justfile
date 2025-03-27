load ".env"

default: run

run:
    #!/usr/bin/env bash
    # Ensure the WEBSOCKET_URL variable is loaded from .env
    if [ -z "$WEBSOCKET_URL" ]; then
        echo "Error: WEBSOCKET_URL is not set in .env file or environment."
        exit 1
    fi
    echo "Running app with WEBSOCKET_URL=${WEBSOCKET_URL}"
    flutter run --dart-define=WEBSOCKET_URL="{{WEBSOCKET_URL}}"
