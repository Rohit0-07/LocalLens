import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:local_lens/core/network/api_client.dart';
import 'package:local_lens/core/network/network_providers.dart';
import 'package:local_lens/core/router/route_paths.dart';
import 'package:local_lens/core/storage/local_store.dart';
import 'package:local_lens/features/auth/domain/session.dart';
import 'package:local_lens/features/auth/presentation/auth_providers.dart';
import 'package:local_lens/features/compose/domain/compose_draft.dart';
import 'package:local_lens/features/compose/domain/draft_store.dart';
import 'package:local_lens/features/compose/presentation/compose_providers.dart';
import 'package:local_lens/features/compose/presentation/drafts_screen.dart';
import 'package:local_lens/features/feed/presentation/feed_providers.dart';
import 'package:local_lens/features/profile/presentation/profile_providers.dart';
import 'package:local_lens/features/profile/presentation/screens/profile_screen.dart';
import 'package:local_lens/features/profile/presentation/screens/settings_screen.dart';

import '../../helpers.dart';

class _FixedSessionController extends SessionController {
  _FixedSessionController(this.session);
  final Session? session;

  @override
  Session? build() => session;
}

class FakeProfileReworkLocalStore implements LocalStore {
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

class FakeDraftStore implements DraftStore {
  FakeDraftStore({List<ComposeDraft>? drafts}) : drafts = drafts ?? [];

  final List<ComposeDraft> drafts;
  final List<String> deletedIds = [];

  @override
  Future<void> save(ComposeDraft draft) async {}

  @override
  Future<void> clear() async {}

  @override
  List<ComposeDraft> loadAll() => List.of(drafts);

  @override
  Future<void> saveItem(ComposeDraft draft) async {}

  @override
  Future<void> deleteItem(String id) async {
    deletedIds.add(id);
  }
}

/// Records PATCH requests (e.g. /auth/me) so tests can assert the request body
/// and drive the reflected profile state.
class FakePatchApiClient extends ApiClient {
  FakePatchApiClient({this.onPatch})
    : super(baseUrl: 'http://test', accessTokenProvider: () => null);

  final void Function(Map<String, dynamic> body)? onPatch;
  final List<Map<String, dynamic>> patches = [];

  @override
  Future<dynamic> patchJson(String path, {Object? body}) async {
    final map = body as Map<String, dynamic>? ?? {};
    patches.add(map);
    onPatch?.call(map);
    return {};
  }
}

ComposeDraft _draft(String id, String title) {
  return ComposeDraft(
    id: id,
    title: title,
    description: 'Saved description for $title',
    category: 'road',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
  );
}

UserProfile _profile({
  required Session session,
  String? bio,
  String? displayName,
}) {
  return UserProfile(
    id: session.userId,
    phone: session.isGuest ? null : '+919876543210',
    email: null,
    displayName: displayName ?? (session.isGuest ? null : 'Alice'),
    username: session.isGuest ? null : 'alice',
    bio: bio ?? 'Ward 45 resident and dog parent',
    photoUrl: null,
    anonymousIdentity: 'anon_123',
    anonId: 'anon_123',
    isGuest: session.isGuest,
    issuesCount: session.isGuest ? 0 : 3,
    upvotesCount: session.isGuest ? 0 : 12,
    quorumVotesCount: session.isGuest ? 0 : 5,
  );
}

void main() {
  group('Profile rework: photo/bio header, drafts entry, gamification tile', () {
    Widget buildProfileApp({
      required Session session,
      required UserProfile Function() profileBuilder,
      ApiClient? apiClient,
      DraftStore? draftStore,
    }) {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const ProfileScreen()),
          GoRoute(
            path: RoutePaths.settings,
            builder: (_, _) => const SettingsScreen(),
          ),
          GoRoute(
            path: RoutePaths.drafts,
            builder: (_, _) => const DraftsScreen(),
          ),
          GoRoute(
            path: RoutePaths.gamification,
            builder: (_, _) => const Scaffold(
              key: Key('gamificationStub'),
              body: Text('GamificationScreen'),
            ),
          ),
        ],
      );

      return ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          sessionProvider.overrideWith(() => _FixedSessionController(session)),
          userProfileProvider.overrideWith((ref) async => profileBuilder()),
          localStoreProvider.overrideWithValue(FakeProfileReworkLocalStore()),
          feedRepositoryProvider.overrideWithValue(FakeFeedRepository()),
          if (apiClient != null) apiClientProvider.overrideWithValue(apiClient),
          if (draftStore != null)
            draftStoreProvider.overrideWithValue(draftStore),
        ],
        child: MaterialApp.router(routerConfig: router),
      );
    }

    testWidgets(
      'Profile header: photo on the left of identity/bio and no editProfileButton',
      (tester) async {
        const session = Session(
          accessToken: 'token',
          userId: 42,
          isGuest: false,
        );
        await tester.pumpWidget(
          buildProfileApp(
            session: session,
            profileBuilder: () => _profile(session: session),
          ),
        );
        await tester.pumpAndSettle();

        final photo = find.byKey(const Key('editProfilePhotoButton'));
        final bio = find.text('Ward 45 resident and dog parent');
        expect(photo, findsOneWidget);
        expect(bio, findsOneWidget);

        // Photo is rendered to the LEFT of the bio / identity column.
        final photoDx = tester.getTopLeft(photo).dx;
        final bioDx = tester.getTopLeft(bio).dx;
        expect(photoDx, lessThan(bioDx));

        // The big Edit Profile button no longer exists.
        expect(find.byKey(const Key('editProfileButton')), findsNothing);
      },
    );

    testWidgets('Inline bio editing saves a new bio via PATCH /auth/me', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      var bio = 'Ward 45 resident and dog parent';
      const session = Session(accessToken: 'token', userId: 42, isGuest: false);
      final api = FakePatchApiClient(
        onPatch: (body) {
          if (body.containsKey('bio')) bio = body['bio'] as String;
        },
      );

      await tester.pumpWidget(
        buildProfileApp(
          session: session,
          apiClient: api,
          profileBuilder: () => _profile(session: session, bio: bio),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ward 45 resident and dog parent'), findsOneWidget);

      // First edit interaction shows the change-limits dialog first.
      await tester.tap(find.byKey(const Key('editBioButton')));
      await tester.pumpAndSettle();
      expect(find.text('Profile Change Limits'), findsOneWidget);
      await tester.tap(find.byKey(const Key('changeLimitsOkButton')));
      await tester.pumpAndSettle();

      // Inline editor appears; save hidden while unchanged.
      final bioField = find.byKey(const Key('editBioField'));
      expect(bioField, findsOneWidget);
      expect(find.byKey(const Key('saveBioButton')), findsNothing);

      // Change the text: save button appears.
      await tester.enterText(bioField, 'New bio about the ward');
      await tester.pumpAndSettle();
      final saveButton = find.byKey(const Key('saveBioButton'));
      expect(saveButton, findsOneWidget);

      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // PATCH /auth/me called with the new bio.
      expect(api.patches, isNotEmpty);
      expect(api.patches.last, containsPair('bio', 'New bio about the ward'));
      // Profile was refreshed and now displays the new bio.
      expect(find.text('New bio about the ward'), findsOneWidget);
      expect(find.text('Ward 45 resident and dog parent'), findsNothing);

      // Let the 'Bio updated' toast timer elapse so nothing stays pending.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets(
      'Bio save button stays hidden while the bio text is unchanged',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        const session = Session(
          accessToken: 'token',
          userId: 42,
          isGuest: false,
        );
        await tester.pumpWidget(
          buildProfileApp(
            session: session,
            profileBuilder: () => _profile(session: session),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('editBioButton')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('changeLimitsOkButton')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('editBioField')), findsOneWidget);
        expect(find.byKey(const Key('saveBioButton')), findsNothing);

        // Entering the same text keeps the save button hidden.
        await tester.enterText(
          find.byKey(const Key('editBioField')),
          'Ward 45 resident and dog parent',
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('saveBioButton')), findsNothing);

        // Close the inline editor.
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('editBioField')), findsNothing);
      },
    );

    testWidgets(
      'Profile drafts entry shows saved count and navigates to the drafts screen',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final store = FakeDraftStore(
          drafts: [
            _draft('draft_1', 'Draft one'),
            _draft('draft_2', 'Draft two'),
          ],
        );
        const session = Session(
          accessToken: 'token',
          userId: 42,
          isGuest: false,
        );

        await tester.pumpWidget(
          buildProfileApp(
            session: session,
            draftStore: store,
            profileBuilder: () => _profile(session: session),
          ),
        );
        await tester.pumpAndSettle();

        final draftsEntry = find.byKey(const Key('profileDraftsButton'));
        expect(draftsEntry, findsOneWidget);
        expect(find.text('2 saved'), findsOneWidget);

        await tester.tap(draftsEntry);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('draftsScreen')), findsOneWidget);
        expect(find.byKey(const Key('draftItem_draft_1')), findsOneWidget);
        expect(find.byKey(const Key('draftItem_draft_2')), findsOneWidget);
      },
    );

    testWidgets(
      'Gamification tile is absent on profile but present on settings',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        const session = Session(
          accessToken: 'token',
          userId: 42,
          isGuest: false,
        );
        await tester.pumpWidget(
          buildProfileApp(
            session: session,
            profileBuilder: () => _profile(session: session),
          ),
        );
        await tester.pumpAndSettle();

        // The settings link section was removed from the profile page.
        expect(find.byKey(const Key('viewGamificationButton')), findsNothing);

        await tester.tap(find.byKey(const Key('openSettingsButton')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('viewGamificationButton')), findsOneWidget);
      },
    );

    testWidgets('Settings gamification tile navigates to /gamification', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const session = Session(accessToken: 'token', userId: 42, isGuest: false);
      await tester.pumpWidget(
        buildProfileApp(
          session: session,
          profileBuilder: () => _profile(session: session),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('openSettingsButton')));
      await tester.pumpAndSettle();

      final tile = find.byKey(const Key('viewGamificationButton'));
      expect(tile, findsOneWidget);
      await tester.ensureVisible(tile);
      await tester.tap(tile);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('gamificationStub')), findsOneWidget);
    });
  });
}
