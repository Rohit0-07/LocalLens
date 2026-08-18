import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig({required this.apiBaseUrl, this.useMockAuth = false});

  final String apiBaseUrl;
  final bool useMockAuth;

  /// Compile-time override baked in via
  /// `--dart-define=API_BASE_URL=http://<host>:8000/api/v1` (e.g. a LAN IP for
  /// physical devices or a staging URL). Empty when not provided.
  static const _envApiBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Smart per-platform default host. The Android emulator reaches the host
  /// machine via the special alias 10.0.2.2; every other target (iOS sim,
  /// macOS desktop, web, physical devices configured via dart-define) uses
  /// loopback.
  static String get _defaultHost {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return '10.0.2.2';
    }
    return '127.0.0.1';
  }

  /// Resolves the API base URL: an explicit [override] (test seam) or the
  /// compile-time `API_BASE_URL` dart-define wins; otherwise falls back to
  /// `http://<platform default host>:8000/api/v1`.
  static String resolveApiBaseUrl([String? override]) {
    final env = override ?? _envApiBaseUrl;
    if (env.isNotEmpty) return env;
    return 'http://$_defaultHost:8000/api/v1';
  }

  /// Local FastAPI backend on the same machine (iOS sim / macOS desktop),
  /// Android emulator, or the configured dart-define URL.
  static AppConfig get dev => AppConfig(apiBaseUrl: resolveApiBaseUrl());
}
