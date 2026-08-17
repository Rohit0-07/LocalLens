import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:local_lens/core/router/route_paths.dart';
import 'package:local_lens/core/storage/local_store.dart';
import 'package:local_lens/features/auth/domain/session.dart';
import 'package:local_lens/features/auth/presentation/auth_providers.dart';
import 'package:local_lens/features/feed/domain/feed_repository.dart';
import 'package:local_lens/features/feed/domain/issue.dart';
import 'package:local_lens/features/feed/presentation/feed_providers.dart';
import 'package:local_lens/features/profile/presentation/profile_providers.dart';
import 'package:local_lens/features/profile/presentation/screens/profile_screen.dart';
import 'package:local_lens/features/profile/presentation/widgets/profile_avatar.dart';

import '../../helpers.dart';

class _FixedSessionController extends SessionController {
  _FixedSessionController(this.session);
  final Session? session;

  @override
  Session? build() => session;
}

class FakeProfileIdentityLocalStore implements LocalStore {
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

class RecordingFeedRepo extends FakeFeedRepository {
  RecordingFeedRepo({required super.issues});

  final List<int> deletedIssueIds = [];
  int fetchUserIssuesCalls = 0;

  @override
  Future<List<Issue>> fetchUserIssues({int? userId, String? status}) async {
    fetchUserIssuesCalls += 1;
    return issues;
  }

  @override
  Future<void> deleteIssue(int issueId) async {
    deletedIssueIds.add(issueId);
  }
}

void main() {
  group('Profile identity & change limits', () {
    late FakeProfileIdentityLocalStore store;

    setUp(() {
      store = FakeProfileIdentityLocalStore();
    });

    Widget buildProfileApp({
      required Session session,
      UserProfile? profile,
      FeedRepository? feedRepository,
      bool tallViewport = false,
    }) {
      final effectiveProfile =
          profile ??
          UserProfile(
            id: session.userId,
            phone: '+919876543210',
            displayName: 'Alice',
            username: 'alice',
            bio: 'Ward 45 resident and dog parent',
            photoUrl: null,
            anonymousIdentity: 'anon_123',
            anonId: 'anon_123',
            isGuest: session.isGuest,
            issuesCount: 3,
            upvotesCount: 12,
            quorumVotesCount: 5,
          );

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const ProfileScreen()),
          GoRoute(
            path: RoutePaths.issueDetail,
            builder: (ctx, state) => Scaffold(
              body: Text('IssueDetail:${state.pathParameters['id']}'),
            ),
          ),
        ],
      );

      return ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          sessionProvider.overrideWith(() => _FixedSessionController(session)),
          userProfileProvider.overrideWith((ref) async => effectiveProfile),
          localStoreProvider.overrideWithValue(store),
          if (feedRepository != null)
            feedRepositoryProvider.overrideWithValue(feedRepository),
        ],
        child: MaterialApp.router(routerConfig: router),
      );
    }

    testWidgets('Profile shows bio under the display name', (tester) async {
      const session = Session(accessToken: 'token', userId: 42, isGuest: false);
      await tester.pumpWidget(buildProfileApp(session: session));
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Ward 45 resident and dog parent'), findsOneWidget);
    });

    testWidgets('Edit Name opens dialog; Bio edits inline', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const session = Session(accessToken: 'token', userId: 42, isGuest: false);
      await tester.pumpWidget(buildProfileApp(session: session));
      await tester.pumpAndSettle();

      // Name still uses a dialog (change-limits dialog comes first on first
      // interaction).
      await tester.tap(find.byKey(const Key('editNameButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('changeLimitsOkButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('editNameField')), findsOneWidget);
      expect(find.byKey(const Key('saveNameButton')), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Bio is edited inline (no dialog). The change-limits notice was already
      // shown above, so it must not appear again.
      await tester.tap(find.byKey(const Key('editBioButton')));
      await tester.pumpAndSettle();
      expect(find.text('Profile Change Limits'), findsNothing);
      expect(find.byKey(const Key('editBioField')), findsOneWidget);
      // The save button only appears once the text differs from the saved bio.
      expect(find.byKey(const Key('saveBioButton')), findsNothing);
      // Closing the inline editor is done via its close icon.
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('editBioField')), findsNothing);
    });

    testWidgets('Edit Profile Photo button opens gallery picker sheet', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const session = Session(accessToken: 'token', userId: 42, isGuest: false);
      await tester.pumpWidget(buildProfileApp(session: session));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('editProfilePhotoButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('changeLimitsOkButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pickPhotoGalleryButton')), findsOneWidget);
      expect(find.text('Take a Photo'), findsOneWidget);
    });

    testWidgets('Change-limits info dialog appears once', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const session = Session(accessToken: 'token', userId: 42, isGuest: false);
      await tester.pumpWidget(buildProfileApp(session: session));
      await tester.pumpAndSettle();

      // First edit shows the change-limits dialog.
      await tester.tap(find.byKey(const Key('editNameButton')));
      await tester.pumpAndSettle();
      expect(find.text('Profile Change Limits'), findsOneWidget);
      await tester.tap(find.byKey(const Key('changeLimitsOkButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Second edit must NOT show it again.
      await tester.tap(find.byKey(const Key('editBioButton')));
      await tester.pumpAndSettle();
      expect(find.text('Profile Change Limits'), findsNothing);
      expect(find.byKey(const Key('editBioField')), findsOneWidget);
    });

    testWidgets('Identity toggle switches between display name and anon id', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const session = Session(accessToken: 'token', userId: 42, isGuest: false);
      await tester.pumpWidget(buildProfileApp(session: session));
      await tester.pumpAndSettle();

      // Default shows the display name.
      expect(find.text('Alice'), findsOneWidget);

      // Switch to Anon ID.
      await tester.tap(find.text('Anon ID'));
      await tester.pumpAndSettle();
      expect(find.text('anon_123'), findsOneWidget);
      expect(find.text('Alice'), findsNothing);

      // Switch back to Display Name.
      await tester.tap(find.text('Display Name'));
      await tester.pumpAndSettle();
      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets(
      'Avatar shows name-initial when no photo, guest icon for guests',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ProfileAvatar(
                photoUrl: null,
                displayName: 'Alice',
                isGuest: false,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('A'), findsOneWidget);
        expect(find.byIcon(Icons.person_outline), findsNothing);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ProfileAvatar(
                photoUrl: null,
                displayName: null,
                isGuest: true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.person_outline), findsOneWidget);
      },
    );

    testWidgets(
      'Delete on issue tile shows confirm dialog, calls deleteIssue and invalidates',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        const session = Session(
          accessToken: 'token',
          userId: 42,
          isGuest: false,
        );
        final feedRepo = RecordingFeedRepo(
          issues: [
            buildIssue(id: 101, title: 'Deep pothole near the bus stop'),
            buildIssue(id: 102, title: 'Broken streetlight'),
          ],
        );

        await tester.pumpWidget(
          buildProfileApp(session: session, feedRepository: feedRepo),
        );
        await tester.pumpAndSettle();

        final deleteButton = find.byKey(const Key('deleteIssue_101'));
        expect(deleteButton, findsOneWidget);
        await tester.ensureVisible(deleteButton);
        await tester.tap(deleteButton);
        await tester.pumpAndSettle();

        expect(find.text('Delete Report'), findsOneWidget);
        final confirm = find.byKey(const Key('confirmDeleteIssueButton'));
        expect(confirm, findsOneWidget);

        final callsBefore = feedRepo.fetchUserIssuesCalls;
        await tester.tap(confirm);
        await tester.pumpAndSettle();

        expect(feedRepo.deletedIssueIds, [101]);
        // Invalidation triggers a refetch of my issues.
        expect(feedRepo.fetchUserIssuesCalls, greaterThan(callsBefore));
      },
    );
  });
}
