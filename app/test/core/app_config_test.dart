import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lens/core/config/app_config.dart';

/// F-E platform-aware API base URL resolution — contract tests (code-blind).
///
/// Per the F-E plan §4: with no `API_BASE_URL` dart-define, the resolved API
/// base URL must point at the loopback host of the active platform —
/// `127.0.0.1` for iOS (simulator) and `10.0.2.2` for Android (emulator host
/// alias). The platform is faked through `debugDefaultTargetPlatformOverride`
/// and reset in `tearDown` so no other test is affected.
///
/// The plan documents a `resolveApiBaseUrl([String? override])` seam on
/// `AppConfig`; the override sub-case below asserts an explicit override is
/// returned verbatim. Per the plan, if the seam does not exist that sub-case
/// must be skipped — it is expected to exist, as the plan names its signature.
void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('resolves to 127.0.0.1 on iOS when no dart-define is present', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(AppConfig.resolveApiBaseUrl(), contains('127.0.0.1'));
  });

  test('resolves to 10.0.2.2 on Android when no dart-define is present', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(AppConfig.resolveApiBaseUrl(), contains('10.0.2.2'));
  });

  test('explicit override is returned verbatim', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(
      AppConfig.resolveApiBaseUrl('https://api.example.com/v1'),
      'https://api.example.com/v1',
    );
  });
}
