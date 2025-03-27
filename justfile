# Variables loaded from .env file
# Note: This requires `just` version 1.14.0 or later for the `load` function.
# If using an older version, you might need to use shell commands within the recipe.
load ".env"

# Default recipe to run the app in debug mode
default: run

# Run the Flutter app with the WebSocket URL injected
run:
    #!/usr/bin/env bash
    # Ensure the WEBSOCKET_URL variable is loaded from .env
    if [ -z "$WEBSOCKET_URL" ]; then
        echo "Error: WEBSOCKET_URL is not set in .env file or environment."
        exit 1
    fi
    echo "Running app with WEBSOCKET_URL=${WEBSOCKET_URL}"
    flutter run --dart-define=WEBSOCKET_URL="{{WEBSOCKET_URL}}"
