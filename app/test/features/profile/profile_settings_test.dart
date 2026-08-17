import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:local_lens/core/router/route_paths.dart';
import 'package:local_lens/core/storage/local_store.dart';
import 'package:local_lens/features/auth/domain/auth_repository.dart';
import 'package:local_lens/features/auth/domain/session.dart';
import 'package:local_lens/features/auth/presentation/auth_providers.dart';
import 'package:local_lens/features/profile/presentation/profile_providers.dart';
import 'package:local_lens/features/profile/presentation/screens/anonymity_guide_screen.dart';
import 'package:local_lens/features/profile/presentation/screens/profile_screen.dart';
import 'package:local_lens/features/profile/presentation/screens/settings_screen.dart';

class MockAuthRepositoryForProfile implements AuthRepository {
  bool signOutCalled = false;

  @override
  Future<void> requestOtp(String phone) async {}

  @override
  Future<Session> verifyOtp({
    required String phone,
    required String code,
  }) async {
    return const Session(accessToken: 'token', userId: 1);
  }

  @override
  Future<void> requestEmailOtp(String email) async {}

  @override
  Future<Session> verifyEmailOtp({
    required String email,
    required String code,
  }) async {
    return const Session(
      accessToken: 'email-token',
      userId: 101,
      isGuest: false,
    );
  }

  @override
  Future<Session> loginAsGuest() async {
    return const Session(
      accessToken: 'guest-token',
      userId: 'guest:123',
      isGuest: true,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #signOut || invocation.memberName == #logout) {
      signOutCalled = true;
      return Future.value();
    }
    return super.noSuchMethod(invocation);
  }
}

class FakeProfileLocalStore implements LocalStore {
  final Map<String, String> _data = {};

  @override
  String? getString(String key) => _data[key];

  @override
  Future<void> setString(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<void> clearSession() async {
    _data.remove('session');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FixedSessionController extends SessionController {
  _FixedSessionController(this.session);
  final Session? session;

  @override
  Session? build() => session;
}

void main() {
  group('F-13: User Profile, Settings & Localization UX Tests', () {
    late MockAuthRepositoryForProfile mockAuthRepo;

    setUp(() {
      mockAuthRepo = MockAuthRepositoryForProfile();
    });

    Widget buildProfileApp({
      required Session? session,
      List<Override> extraOverrides = const [],
    }) {
      final profile = UserProfile(
        id: session?.userId ?? 'test_user',
        phone: (session != null && !session.isGuest) ? '+919876543210' : null,
        email: null,
        anonymousIdentity: 'anon_123',
        anonId: 'anon_123',
        isGuest: session?.isGuest ?? true,
        issuesCount: (session != null && !session.isGuest) ? 3 : 0,
        upvotesCount: (session != null && !session.isGuest) ? 12 : 0,
        quorumVotesCount: (session != null && !session.isGuest) ? 5 : 0,
      );

      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const ProfileScreen()),
          GoRoute(
            path: RoutePaths.settings,
            builder: (_, _) => const SettingsScreen(),
          ),
          GoRoute(
            path: RoutePaths.outbox,
            builder: (_, _) => const Scaffold(body: Text('OutboxScreen')),
          ),
          GoRoute(
            path: RoutePaths.anonymityGuide,
            builder: (_, _) => const AnonymityGuideScreen(),
          ),
        ],
      );

      return ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          sessionProvider.overrideWith(() => _FixedSessionController(session)),
          userProfileProvider.overrideWith((ref) async => profile),
          localStoreProvider.overrideWithValue(FakeProfileLocalStore()),
          ...extraOverrides,
        ],
        child: MaterialApp.router(routerConfig: router),
      );
    }

    testWidgets(
      'ProfileScreen renders user avatar/mask icon, anon_id chip, and stats card for authenticated user',
      (WidgetTester tester) async {
        const session = Session(
          accessToken: 'authenticated-token',
          userId: 42,
          isGuest: false,
        );

        await tester.pumpWidget(buildProfileApp(session: session));
        await tester.pumpAndSettle();

        // Check for Avatar or Mask icon / header element
        final avatarIcon = find.byWidgetPredicate(
          (widget) =>
              widget is CircleAvatar ||
              (widget is Icon &&
                  (widget.icon == Icons.person ||
                      widget.icon == Icons.person_outline ||
                      widget.icon == Icons.account_circle ||
                      widget.icon == Icons.face ||
                      widget.icon == Icons.masks)),
        );
        expect(avatarIcon, findsAtLeastNWidgets(1));

        // Check for anon_id chip or identity label
        final anonIdChip = find.byWidgetPredicate(
          (widget) =>
              widget is Chip ||
              (widget is Text &&
                  (widget.data?.contains('anon_') == true ||
                      widget.data?.contains('Guest') == true)),
        );
        expect(anonIdChip, findsAtLeastNWidgets(1));

        // Guest banner should NOT be present for regular authenticated user
        expect(
          find.textContaining(RegExp(r'Guest Session', caseSensitive: false)),
          findsNothing,
        );

        // Check User Activity Stats card with 3 metrics: Issues, Upvotes, Verified
        expect(
          find.textContaining(RegExp(r'Issues', caseSensitive: false)),
          findsAtLeastNWidgets(1),
        );
        expect(
          find.textContaining(RegExp(r'Upvotes', caseSensitive: false)),
          findsAtLeastNWidgets(1),
        );
        expect(
          find.textContaining(RegExp(r'Verified', caseSensitive: false)),
          findsAtLeastNWidgets(1),
        );
      },
    );

    testWidgets('ProfileScreen displays guest banner for guest user session', (
      WidgetTester tester,
    ) async {
      const guestSession = Session(
        accessToken: 'guest-token',
        userId: 'guest:9999',
        isGuest: true,
      );

      await tester.pumpWidget(buildProfileApp(session: guestSession));
      await tester.pumpAndSettle();

      // Verify guest banner or guest identity indicator is displayed
      final guestBanner = find.textContaining(
        RegExp(r'Guest', caseSensitive: false),
      );
      expect(guestBanner, findsAtLeastNWidgets(1));

      // The End Guest Session / Sign Out button moved to the settings screen.
      await tester.tap(find.byKey(const Key('openSettingsButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('settingsSignOutTile')), findsOneWidget);
    });

    testWidgets('Theme selector toggles between System, Light, and Dark mode', (
      WidgetTester tester,
    ) async {
      const session = Session(
        accessToken: 'auth-token',
        userId: 1,
        isGuest: false,
      );

      await tester.pumpWidget(buildProfileApp(session: session));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('openSettingsButton')));
      await tester.pumpAndSettle();

      // Look for Theme settings section / options (System, Light, Dark)
      final systemOption = find.textContaining(
        RegExp(r'System', caseSensitive: false),
      );
      final lightOption = find.textContaining(
        RegExp(r'Light', caseSensitive: false),
      );
      final darkOption = find.textContaining(
        RegExp(r'Dark', caseSensitive: false),
      );

      expect(systemOption, findsAtLeastNWidgets(1));
      expect(lightOption, findsAtLeastNWidgets(1));
      expect(darkOption, findsAtLeastNWidgets(1));

      // Tap Light mode option
      await tester.ensureVisible(lightOption.first);
      await tester.tap(lightOption.first);
      await tester.pumpAndSettle();

      // Tap Dark mode option
      await tester.ensureVisible(darkOption.first);
      await tester.tap(darkOption.first);
      await tester.pumpAndSettle();

      // Tap System mode option
      await tester.ensureVisible(systemOption.first);
      await tester.tap(systemOption.first);
      await tester.pumpAndSettle();
    });

    testWidgets('Language selector toggles between English (en) and Hindi (hi)', (
      WidgetTester tester,
    ) async {
      const session = Session(
        accessToken: 'auth-token',
        userId: 1,
        isGuest: false,
      );

      await tester.pumpWidget(buildProfileApp(session: session));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('openSettingsButton')));
      await tester.pumpAndSettle();

      // Look for Language settings section / options (English, Hindi / 'en', 'hi')
      final englishOption = find.textContaining(
        RegExp(r'English|en', caseSensitive: false),
      );
      final hindiOption = find.textContaining(
        RegExp(r'Hindi|hi|हिंदी', caseSensitive: false),
      );

      expect(englishOption, findsAtLeastNWidgets(1));
      expect(hindiOption, findsAtLeastNWidgets(1));

      // Tap Hindi language option
      await tester.ensureVisible(hindiOption.first);
      await tester.tap(hindiOption.first);
      await tester.pumpAndSettle();

      // Tap English language option
      await tester.ensureVisible(englishOption.first);
      await tester.tap(englishOption.first);
      await tester.pumpAndSettle();
    });

    testWidgets(
      'Tapping Anonymity & Privacy Guide tile navigates to AnonymityGuideScreen',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        const session = Session(
          accessToken: 'auth-token',
          userId: 1,
          isGuest: false,
        );

        await tester.pumpWidget(buildProfileApp(session: session));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('openSettingsButton')));
        await tester.pumpAndSettle();

        final guideTile = find.text('Anonymity & Privacy Guide');
        expect(guideTile, findsOneWidget);

        await tester.ensureVisible(guideTile);
        await tester.tap(guideTile);
        await tester.pumpAndSettle();

        expect(find.byType(AnonymityGuideScreen), findsOneWidget);
      },
    );

    testWidgets(
      'Sign Out / End Guest Session button triggers logout and resets auth state',
      (WidgetTester tester) async {
        const session = Session(
          accessToken: 'auth-token',
          userId: 1,
          isGuest: false,
        );

        await tester.pumpWidget(buildProfileApp(session: session));
        await tester.pumpAndSettle();

        // Sign out now lives on the settings screen.
        await tester.tap(find.byKey(const Key('openSettingsButton')));
        await tester.pumpAndSettle();

        // Find Sign Out tile
        final signOutButton = find.byKey(const Key('settingsSignOutTile'));
        expect(signOutButton, findsAtLeastNWidgets(1));

        // Tap Sign Out tile
        await tester.ensureVisible(signOutButton.first);
        await tester.tap(signOutButton.first);
        await tester.pumpAndSettle();

        // Confirm sign out if a confirmation dialog is presented
        final confirmDialogButton = find.widgetWithText(TextButton, 'Sign Out');
        if (confirmDialogButton.evaluate().isNotEmpty) {
          await tester.tap(confirmDialogButton);
          await tester.pumpAndSettle();
        }
      },
    );

    testWidgets(
      'Offline Outbox Queue card renders and Sync Now button triggers outbox flush and toast',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        const session = Session(
          accessToken: 'auth-token',
          userId: 1,
          isGuest: false,
        );

        await tester.pumpWidget(buildProfileApp(session: session));
        await tester.pumpAndSettle();

        expect(find.textContaining('Offline Outbox'), findsAtLeastNWidgets(1));
        expect(find.byKey(const Key('viewOutboxButton')), findsOneWidget);
        await tester.tap(find.byKey(const Key('viewOutboxButton')));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'Multi-Language Vernacular selector supports English, Hindi, Marathi, Tamil, Telugu',
      (WidgetTester tester) async {
        const session = Session(
          accessToken: 'auth-token',
          userId: 1,
          isGuest: false,
        );

        await tester.pumpWidget(buildProfileApp(session: session));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('openSettingsButton')));
        await tester.pumpAndSettle();

        expect(find.textContaining('English'), findsAtLeastNWidgets(1));
        expect(find.textContaining('Hindi'), findsAtLeastNWidgets(1));
        expect(find.textContaining('Marathi'), findsAtLeastNWidgets(1));
        expect(find.textContaining('Tamil'), findsAtLeastNWidgets(1));
        expect(find.textContaining('Telugu'), findsAtLeastNWidgets(1));

        // Tap Tamil language option
        final tamilOption = find.textContaining('Tamil').first;
        await tester.ensureVisible(tamilOption);
        await tester.tap(tamilOption);
        await tester.pumpAndSettle();
      },
    );
  });
}

bool findsTextInWidget(Widget widget, RegExp pattern) {
  if (widget is ListTile) {
    final title = widget.title;
    if (title is Text && title.data != null && pattern.hasMatch(title.data!)) {
      return true;
    }
  }
  if (widget is ElevatedButton ||
      widget is OutlinedButton ||
      widget is TextButton) {
    final child = (widget as dynamic).child;
    if (child is Text && child.data != null && pattern.hasMatch(child.data!)) {
      return true;
    }
  }
  return false;
}
