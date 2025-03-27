
/// Configuration values loaded from compile-time environment variables.
class AppConfig {
  /// The WebSocket URL to connect to.
  ///
  /// This value is injected at build time using --dart-define=WEBSOCKET_URL=...
  /// It defaults to an empty string if not provided.
  static const String webSocketUrl = String.fromEnvironment(
    'WEBSOCKET_URL',
    defaultValue: '', // Or provide a sensible default like 'ws://localhost:8080' for dev
  );

  /// Checks if the WebSocket URL was provided at build time.
  static bool get isWebSocketUrlAvailable => webSocketUrl.isNotEmpty;
}
