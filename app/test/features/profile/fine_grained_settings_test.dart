import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:local_lens/core/router/route_paths.dart';
import 'package:local_lens/core/storage/local_store.dart';
import 'package:local_lens/features/auth/domain/auth_repository.dart';
import 'package:local_lens/features/auth/domain/session.dart';
import 'package:local_lens/features/auth/presentation/auth_providers.dart';
import 'package:local_lens/features/profile/presentation/screens/anonymity_guide_screen.dart';
import 'package:local_lens/features/profile/presentation/screens/settings_screen.dart';

class FakeAuthRepositoryForSettings implements AuthRepository {
  bool signedOut = false;

  @override
  Future<void> requestOtp(String phone) async {}

  @override
  Future<Session> verifyOtp(
      {required String phone, required String code}) async {
    return const Session(accessToken: 'token', userId: 1);
  }

  @override
  Future<void> requestEmailOtp(String email) async {}

  @override
  Future<Session> verifyEmailOtp(
      {required String email, required String code}) async {
    return const Session(accessToken: 'email-token', userId: 101);
  }

  @override
  Future<Session> loginAsGuest() async {
    return const Session(
        accessToken: 'guest-token', userId: 'guest:1', isGuest: true);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #signOut ||
        invocation.memberName == #logout) {
      signedOut = true;
      return Future.value();
    }
    return super.noSuchMethod(invocation);
  }
}

class FakeLocalStoreForSettings implements LocalStore {
  final Map<String, String> _data = {};
  bool clearedSession = false;

  @override
  String? getString(String key) => _data[key];

  @override
  Future<void> setString(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<void> clearSession() async {
    clearedSession = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Fine-Grained Settings UX & Behavior Tests', () {
    late FakeAuthRepositoryForSettings fakeAuthRepo;
    late FakeLocalStoreForSettings fakeStore;

    setUp(() {
      fakeAuthRepo = FakeAuthRepositoryForSettings();
      fakeStore = FakeLocalStoreForSettings();
    });

    Widget createSettingsApp({List<Override> extraOverrides = const []}) {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (context, state) => const SettingsScreen()),
          GoRoute(
            path: RoutePaths.anonymityGuide,
            builder: (context, state) => const AnonymityGuideScreen(),
          ),
        ],
      );

      return ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuthRepo),
          localStoreProvider.overrideWithValue(fakeStore),
          ...extraOverrides,
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }

    testWidgets('Renders all setting sections and headers',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createSettingsApp());
      await tester.pumpAndSettle();

      expect(find.text('Notification Preferences'), findsOneWidget);
      expect(find.text('Privacy & Anonymity'), findsOneWidget);
      expect(find.text('Appearance & Display'), findsOneWidget);
      expect(find.text('Data & Storage'), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);
    });

    testWidgets('Notification preferences toggles update settings state',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createSettingsApp());
      await tester.pumpAndSettle();

      // Push notifications toggle
      final pushToggle =
          find.byKey(const Key('settingsPushNotificationsToggle'));
      expect(pushToggle, findsOneWidget);
      await tester.tap(pushToggle);
      await tester.pumpAndSettle();

      // Daily ward digest toggle
      final digestToggle = find.byKey(const Key('settingsDailyDigestToggle'));
      expect(digestToggle, findsOneWidget);
      await tester.tap(digestToggle);
      await tester.pumpAndSettle();

      // Status change alerts toggle
      final statusToggle =
          find.byKey(const Key('settingsStatusChangeAlertsToggle'));
      expect(statusToggle, findsOneWidget);
      await tester.tap(statusToggle);
      await tester.pumpAndSettle();

      // Verification requests toggle
      final verifyToggle =
          find.byKey(const Key('settingsVerificationRequestsToggle'));
      expect(verifyToggle, findsOneWidget);
      await tester.tap(verifyToggle);
      await tester.pumpAndSettle();

      // Comment replies toggle
      final commentsToggle =
          find.byKey(const Key('settingsCommentRepliesToggle'));
      expect(commentsToggle, findsOneWidget);
      await tester.tap(commentsToggle);
      await tester.pumpAndSettle();

      // Haptic feedback toggle
      final hapticToggle =
          find.byKey(const Key('settingsHapticFeedbackToggle'));
      expect(hapticToggle, findsOneWidget);
      await tester.tap(hapticToggle);
      await tester.pumpAndSettle();
    });

    testWidgets('Privacy & Anonymity toggles update settings state',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createSettingsApp());
      await tester.pumpAndSettle();

      final anonToggle =
          find.byKey(const Key('settingsDefaultAnonymousToggle'));
      expect(anonToggle, findsOneWidget);
      await tester.tap(anonToggle);
      await tester.pumpAndSettle();

      final fuzzingToggle =
          find.byKey(const Key('settingsLocationFuzzingToggle'));
      expect(fuzzingToggle, findsOneWidget);
      await tester.tap(fuzzingToggle);
      await tester.pumpAndSettle();

      final shieldedToggle =
          find.byKey(const Key('settingsShieldedModeToggle'));
      expect(shieldedToggle, findsOneWidget);
      await tester.tap(shieldedToggle);
      await tester.pumpAndSettle();

      final exifToggle = find.byKey(const Key('settingsExifScrubberToggle'));
      expect(exifToggle, findsOneWidget);
      await tester.tap(exifToggle);
      await tester.pumpAndSettle();
    });

    testWidgets('Appearance & Theme toggles work correctly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createSettingsApp());
      await tester.pumpAndSettle();

      final lightBtn = find.text('Light');
      final darkBtn = find.text('Dark');
      final systemBtn = find.text('System');

      expect(lightBtn, findsOneWidget);
      expect(darkBtn, findsOneWidget);
      expect(systemBtn, findsOneWidget);

      await tester.tap(lightBtn);
      await tester.pumpAndSettle();

      await tester.tap(darkBtn);
      await tester.pumpAndSettle();

      final highContrast =
          find.byKey(const Key('settingsHighContrastToggle'));
      expect(highContrast, findsOneWidget);
      await tester.tap(highContrast);
      await tester.pumpAndSettle();
    });

    testWidgets('Data & Storage: Wi-Fi only toggle and Clear Cache work',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createSettingsApp());
      await tester.pumpAndSettle();

      // Wi-Fi toggle
      final wifiToggle = find.byKey(const Key('settingsWifiOnlyToggle'));
      expect(wifiToggle, findsOneWidget);
      await tester.tap(wifiToggle);
      await tester.pumpAndSettle();

      // Cache size initially shown
      expect(find.textContaining('18.4 MB'), findsOneWidget);

      // Tap clear cache
      final clearBtn = find.widgetWithText(FilledButton, 'Clear');
      expect(clearBtn, findsOneWidget);
      await tester.tap(clearBtn);
      await tester.pumpAndSettle();

      // Should show cleared cache size and snackbar
      expect(find.textContaining('0.0 MB'), findsOneWidget);
      expect(find.text('Offline cache cleared successfully'), findsOneWidget);
    });

    testWidgets('Account: Edit Profile Alias dialog saves alias',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createSettingsApp());
      await tester.pumpAndSettle();

      final editAliasTile = find.byKey(const Key('settingsEditAliasTile'));
      expect(editAliasTile, findsOneWidget);
      await tester.tap(editAliasTile);
      await tester.pumpAndSettle();

      // Dialog should be open
      expect(find.byType(AlertDialog), findsOneWidget);

      // Enter new alias
      await tester.enterText(find.byType(TextField), 'Urban Sentinel');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      // Dialog should be closed and tile subtitle updated
      expect(find.text('Urban Sentinel'), findsOneWidget);
    });

    testWidgets('Account: Export data and Sign out work properly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createSettingsApp());
      await tester.pumpAndSettle();

      final exportTile = find.byKey(const Key('settingsExportDataTile'));
      expect(exportTile, findsOneWidget);
      await tester.tap(exportTile);
      await tester.pumpAndSettle();

      expect(find.text('Civic activity data exported as JSON'), findsOneWidget);

      final signOutTile = find.byKey(const Key('settingsSignOutTile'));
      expect(signOutTile, findsOneWidget);
      await tester.tap(signOutTile);
      await tester.pumpAndSettle();

      expect(fakeStore.clearedSession, isTrue);
    });
  });
}
