class AppConfig {
  static const String webSocketUrl = String.fromEnvironment(
    'WEBSOCKET_URL',
    defaultValue: '',
  );

  static bool get isWebSocketUrlAvailable => webSocketUrl.isNotEmpty;
}
