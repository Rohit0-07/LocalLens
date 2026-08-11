class AppConfig {
  const AppConfig({required this.apiBaseUrl, this.useMockAuth = false});

  final String apiBaseUrl;
  final bool useMockAuth;

  /// Local FastAPI backend on the same machine (iOS sim / macOS desktop).
  /// Android emulators reach the host via 10.0.2.2 -- see README.
  static const dev = AppConfig(apiBaseUrl: 'http://127.0.0.1:8000/api/v1');
}
