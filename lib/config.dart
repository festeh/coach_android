
/// Configuration values loaded from compile-time environment variables.
class AppConfig {
  /// The WebSocket URL to connect to.
  ///
  /// This value MUST be injected at build time using the --dart-define flag.
  /// Example command:
  /// flutter run --dart-define=WEBSOCKET_URL=$(grep '^WEBSOCKET_URL=' .env | cut -d '=' -f2-)
  static const String webSocketUrl = String.fromEnvironment(
    'WEBSOCKET_URL',
    defaultValue: '', // Default value if --dart-define is not used.
  );

  static bool get isWebSocketUrlAvailable => webSocketUrl.isNotEmpty;
}
