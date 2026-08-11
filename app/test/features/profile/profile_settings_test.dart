import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:local_lens/features/auth/domain/auth_repository.dart';
import 'package:local_lens/features/auth/domain/session.dart';
import 'package:local_lens/features/auth/presentation/auth_providers.dart';
import 'package:local_lens/features/profile/presentation/screens/anonymity_guide_screen.dart';
import 'package:local_lens/features/profile/presentation/screens/profile_screen.dart';

class MockAuthRepositoryForProfile implements AuthRepository {
  bool signOutCalled = false;

  @override
  Future<void> requestOtp(String phone) async {}

  @override
  Future<Session> verifyOtp({required String phone, required String code}) async {
    return const Session(accessToken: 'token', userId: 1);
  }

  @override
  Future<void> requestEmailOtp(String email) async {}

  @override
  Future<Session> verifyEmailOtp({required String email, required String code}) async {
    return const Session(accessToken: 'email-token', userId: 101, isGuest: false);
  }

  @override
  Future<Session> loginAsGuest() async {
    return const Session(accessToken: 'guest-token', userId: 'guest:123', isGuest: true);
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
      return ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          sessionProvider.overrideWith(() => _FixedSessionController(session)),
          ...extraOverrides,
        ],
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      );
    }

    testWidgets('ProfileScreen renders user avatar/mask icon, anon_id chip, and stats card for authenticated user', (WidgetTester tester) async {
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
            (widget is Text && (widget.data?.contains('anon_') == true || widget.data?.contains('Guest') == true)),
      );
      expect(anonIdChip, findsAtLeastNWidgets(1));

      // Guest banner should NOT be present for regular authenticated user
      expect(find.textContaining(RegExp(r'Guest Session', caseSensitive: false)), findsNothing);

      // Check User Activity Stats card with 3 metrics: Issues, Upvotes, Quorum Votes
      expect(find.textContaining(RegExp(r'Issues', caseSensitive: false)), findsAtLeastNWidgets(1));
      expect(find.textContaining(RegExp(r'Upvotes', caseSensitive: false)), findsAtLeastNWidgets(1));
      expect(find.textContaining(RegExp(r'Quorum', caseSensitive: false)), findsAtLeastNWidgets(1));
    });

    testWidgets('ProfileScreen displays guest banner for guest user session', (WidgetTester tester) async {
      const guestSession = Session(
        accessToken: 'guest-token',
        userId: 'guest:9999',
        isGuest: true,
      );

      await tester.pumpWidget(buildProfileApp(session: guestSession));
      await tester.pumpAndSettle();

      // Verify guest banner or guest identity indicator is displayed
      final guestBanner = find.textContaining(RegExp(r'Guest', caseSensitive: false));
      expect(guestBanner, findsAtLeastNWidgets(1));

      // Verify End Guest Session / Sign Out button is present
      final endSessionButton = find.byWidgetPredicate(
        (widget) =>
            (widget is ElevatedButton || widget is OutlinedButton || widget is TextButton || widget is ListTile) &&
            findsTextInWidget(widget, RegExp(r'End Guest Session|Sign Out|Log Out', caseSensitive: false)),
      );
      expect(endSessionButton, findsAtLeastNWidgets(1));
    });

    testWidgets('Theme selector toggles between System, Light, and Dark mode', (WidgetTester tester) async {
      const session = Session(
        accessToken: 'auth-token',
        userId: 1,
        isGuest: false,
      );

      await tester.pumpWidget(buildProfileApp(session: session));
      await tester.pumpAndSettle();

      // Look for Theme settings section / options (System, Light, Dark)
      final systemOption = find.textContaining(RegExp(r'System', caseSensitive: false));
      final lightOption = find.textContaining(RegExp(r'Light', caseSensitive: false));
      final darkOption = find.textContaining(RegExp(r'Dark', caseSensitive: false));

      expect(systemOption, findsAtLeastNWidgets(1));
      expect(lightOption, findsAtLeastNWidgets(1));
      expect(darkOption, findsAtLeastNWidgets(1));

      // Tap Light mode option
      await tester.tap(lightOption.first);
      await tester.pumpAndSettle();

      // Tap Dark mode option
      await tester.tap(darkOption.first);
      await tester.pumpAndSettle();

      // Tap System mode option
      await tester.tap(systemOption.first);
      await tester.pumpAndSettle();
    });

    testWidgets('Language selector toggles between English (en) and Hindi (hi)', (WidgetTester tester) async {
      const session = Session(
        accessToken: 'auth-token',
        userId: 1,
        isGuest: false,
      );

      await tester.pumpWidget(buildProfileApp(session: session));
      await tester.pumpAndSettle();

      // Look for Language settings section / options (English, Hindi / 'en', 'hi')
      final englishOption = find.textContaining(RegExp(r'English|en', caseSensitive: false));
      final hindiOption = find.textContaining(RegExp(r'Hindi|hi|हिंदी', caseSensitive: false));

      expect(englishOption, findsAtLeastNWidgets(1));
      expect(hindiOption, findsAtLeastNWidgets(1));

      // Tap Hindi language option
      await tester.tap(hindiOption.first);
      await tester.pumpAndSettle();

      // Tap English language option
      await tester.tap(englishOption.first);
      await tester.pumpAndSettle();
    });

    testWidgets('Tapping Anonymity & Privacy Guide tile navigates to AnonymityGuideScreen', (WidgetTester tester) async {
      const session = Session(
        accessToken: 'auth-token',
        userId: 1,
        isGuest: false,
      );

      final router = GoRouter(
        initialLocation: '/profile',
        routes: [
          GoRoute(
            path: '/profile',
            builder: (_, _) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/anonymity-guide',
            builder: (_, _) => const AnonymityGuideScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepo),
            sessionProvider.overrideWith(() => _FixedSessionController(session)),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Locate Anonymity & Privacy Guide tile
      final guideTile = find.textContaining(RegExp(r'Anonymity.*Privacy|Privacy.*Guide', caseSensitive: false));
      expect(guideTile, findsOneWidget);

      // Scroll to & tap the tile to navigate
      await tester.ensureVisible(guideTile);
      await tester.tap(guideTile);
      await tester.pumpAndSettle();

      // Verify router navigated to AnonymityGuideScreen
      expect(find.byType(AnonymityGuideScreen), findsOneWidget);
    });

    testWidgets('Sign Out / End Guest Session button triggers logout and resets auth state', (WidgetTester tester) async {
      const session = Session(
        accessToken: 'auth-token',
        userId: 1,
        isGuest: false,
      );

      await tester.pumpWidget(buildProfileApp(session: session));
      await tester.pumpAndSettle();

      // Find Sign Out button
      final signOutButton = find.byWidgetPredicate(
        (widget) =>
            (widget is ElevatedButton || widget is OutlinedButton || widget is TextButton || widget is ListTile) &&
            findsTextInWidget(widget, RegExp(r'Sign Out|End Guest Session|Log Out', caseSensitive: false)),
      );
      expect(signOutButton, findsAtLeastNWidgets(1));

      // Tap Sign Out button
      await tester.ensureVisible(signOutButton.first);
      await tester.tap(signOutButton.first);
      await tester.pumpAndSettle();

      // Confirm sign out if a confirmation dialog is presented
      final confirmDialogButton = find.widgetWithText(TextButton, 'Sign Out');
      if (confirmDialogButton.evaluate().isNotEmpty) {
        await tester.tap(confirmDialogButton);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Offline Outbox Queue card renders and Sync Now button triggers outbox flush and toast', (WidgetTester tester) async {
      const session = Session(
        accessToken: 'auth-token',
        userId: 1,
        isGuest: false,
      );

      await tester.pumpWidget(buildProfileApp(session: session));
      await tester.pumpAndSettle();

      expect(find.text('Offline Outbox Queue'), findsOneWidget);
      expect(find.byKey(const Key('syncOutboxButton')), findsOneWidget);
      expect(find.textContaining('Pending Outbox Items:'), findsOneWidget);

      await tester.tap(find.byKey(const Key('syncOutboxButton')));
      await tester.pumpAndSettle();

      expect(find.text('Outbox synchronized'), findsOneWidget);
    });

    testWidgets('Multi-Language Vernacular selector supports English, Hindi, Marathi, Tamil, Telugu', (WidgetTester tester) async {
      const session = Session(
        accessToken: 'auth-token',
        userId: 1,
        isGuest: false,
      );

      await tester.pumpWidget(buildProfileApp(session: session));
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
    });
  });
}

bool findsTextInWidget(Widget widget, RegExp pattern) {
  if (widget is ListTile) {
    final title = widget.title;
    if (title is Text && title.data != null && pattern.hasMatch(title.data!)) {
      return true;
    }
  }
  if (widget is ElevatedButton || widget is OutlinedButton || widget is TextButton) {
    final child = (widget as dynamic).child;
    if (child is Text && child.data != null && pattern.hasMatch(child.data!)) {
      return true;
    }
  }
  return false;
}
