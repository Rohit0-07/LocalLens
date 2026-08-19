// F-G: Own Profile page redesign — role badge + ward chip, rep-dashboard
// entry for representatives, guest banner, Your Activity card, my-issues
// filters.
//
// CONTRACT vs PLAN NOTE: docs/3_test_plan.md currently on disk describes a
// different feature (F-03 ward awareness) and does not cover this one, so the
// test contract inlined from the F-G plan §4 is authoritative for this file.
// Where the contract names a widget Key it is used verbatim; where it does not
// (guest banner text probe, rep-metrics tile keys, stub keys for routes), the
// identifier is taken from the public contract already exercised by existing
// tests (app/test/features/profile/profile_settings_test.dart,
// app/test/features/profile/profile_posts_and_public_profile_test.dart,
// app/test/features/rep_dashboard/rep_dashboard_test.dart).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:local_lens/core/router/route_paths.dart';
import 'package:local_lens/core/storage/local_store.dart';
import 'package:local_lens/features/auth/domain/session.dart';
import 'package:local_lens/features/auth/presentation/auth_providers.dart';
import 'package:local_lens/features/compose/domain/compose_draft.dart';
import 'package:local_lens/features/compose/domain/draft_store.dart';
import 'package:local_lens/features/compose/presentation/compose_providers.dart';
import 'package:local_lens/features/compose/presentation/drafts_screen.dart';
import 'package:local_lens/features/feed/domain/feed_repository.dart';
import 'package:local_lens/features/feed/domain/issue.dart';
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

/// In-memory LocalStore with the full surface implemented so any draft/outbox
/// read (e.g. loadOutbox) sees empty data instead of hitting noSuchMethod.
class _FakeProfileRedesignLocalStore implements LocalStore {
  final Map<String, String> _data = {};

  @override
  String? getString(String key) => _data[key];

  @override
  Future<void> setString(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<void> clearDraft() async => _data.remove('current_draft');

  @override
  Future<void> clearSession() async => _data.remove('session');

  @override
  Future<void> init() async {}

  @override
  String? loadDraft() => _data['current_draft'];

  @override
  String? loadOutbox() => _data['pending_outbox'];

  @override
  String? restoreAccessToken() => null;

  @override
  String? restoreUserId() => null;

  @override
  Future<void> saveDraft(String json) async => _data['current_draft'] = json;

  @override
  Future<void> saveOutbox(String json) async =>
      _data['pending_outbox'] = json;

  @override
  Future<void> saveSession({
    required String accessToken,
    required Object userId,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDraftStore implements DraftStore {
  _FakeDraftStore({List<ComposeDraft>? drafts}) : drafts = drafts ?? [];

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

/// The shared FakeFeedRepository helper returns every issue regardless of the
/// requested status, so this subclass overrides fetchUserIssues to honour the
/// active/resolved filter — mirroring the fake used by
/// profile_posts_and_public_profile_test.dart.
class _StatusAwareFakeFeedRepository extends FakeFeedRepository {
  _StatusAwareFakeFeedRepository({required super.issues});

  @override
  Future<List<Issue>> fetchUserIssues({int? userId, String? status}) async {
    if (status == 'resolved') {
      return issues.where((i) => i.status == 'resolved').toList();
    } else if (status == 'active') {
      return issues.where((i) => i.status != 'resolved').toList();
    }
    return issues;
  }
}

UserProfile _profile({
  required Session session,
  String role = 'citizen',
  String? ward,
  int issuesCount = 3,
  int upvotesCount = 12,
  int quorumVotesCount = 5,
}) {
  return UserProfile(
    id: session.userId,
    phone: session.isGuest ? null : '+919876543210',
    email: null,
    displayName: session.isGuest ? null : 'Alice',
    username: session.isGuest ? null : 'alice',
    bio: 'Ward 45 resident and dog parent',
    photoUrl: null,
    anonymousIdentity: 'anon_123',
    anonId: 'anon_123',
    isGuest: session.isGuest,
    issuesCount: issuesCount,
    upvotesCount: upvotesCount,
    quorumVotesCount: quorumVotesCount,
    role: role,
    ward: ward,
  );
}

/// Minimal profile constructor for the parsing / role unit tests.
UserProfile _roleProfile(String role, {String? ward, bool isGuest = false}) {
  return UserProfile(
    id: 42,
    phone: isGuest ? null : '+919876543210',
    displayName: isGuest ? null : 'Alice',
    anonymousIdentity: 'anon_123',
    anonId: 'anon_123',
    isGuest: isGuest,
    issuesCount: isGuest ? 0 : 3,
    upvotesCount: isGuest ? 0 : 12,
    quorumVotesCount: isGuest ? 0 : 5,
    role: role,
    ward: ward,
  );
}

GoRouter _buildRouter() {
  return GoRouter(
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
        path: RoutePaths.outbox,
        builder: (_, _) => const Scaffold(
          key: Key('outboxStub'),
          body: Text('OutboxScreen'),
        ),
      ),
      GoRoute(
        path: RoutePaths.compose,
        builder: (_, _) => const Scaffold(
          key: Key('composeStub'),
          body: Text('ComposeScreen'),
        ),
      ),
      GoRoute(
        path: RoutePaths.repDashboard,
        builder: (_, _) => const Scaffold(
          key: Key('repDashboardStub'),
          body: Text('RepDashboardScreen'),
        ),
      ),
    ],
  );
}

Widget _buildProfileApp({
  required Session session,
  required UserProfile Function() profileBuilder,
  DraftStore? draftStore,
  FeedRepository? feedRepository,
  GoRouter? router,
}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      sessionProvider.overrideWith(() => _FixedSessionController(session)),
      userProfileProvider.overrideWith((ref) async => profileBuilder()),
      localStoreProvider.overrideWithValue(_FakeProfileRedesignLocalStore()),
      feedRepositoryProvider.overrideWithValue(
        feedRepository ?? FakeFeedRepository(),
      ),
      draftStoreProvider.overrideWithValue(draftStore ?? _FakeDraftStore()),
    ],
    child: MaterialApp.router(routerConfig: router ?? _buildRouter()),
  );
}

void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
}

void main() {
  group(
    'F-G Profile redesign: role badge, ward chip, rep entry, guest banner, '
    'activity tiles, my-issues filters',
    () {
      // Case 1 — Citizen header.
      testWidgets(
        'Citizen header renders role badge, ward chip, stats card, both '
        'activity tiles and the My Reported Issues header; no rep entry',
        (tester) async {
          _useTallViewport(tester);
          const session = Session(
            accessToken: 'token',
            userId: 42,
            isGuest: false,
          );

          await tester.pumpWidget(
            _buildProfileApp(
              session: session,
              profileBuilder: () => _profile(
                session: session,
                role: 'citizen',
                ward: 'Ward 45, Urban Central',
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byKey(const Key('profileRoleBadge')), findsOneWidget);
          expect(find.text('Citizen'), findsOneWidget);

          expect(find.byKey(const Key('profileWardChip')), findsOneWidget);
          expect(find.text('Ward 45, Urban Central'), findsOneWidget);

          expect(find.byKey(const Key('profileStatsCard')), findsOneWidget);
          expect(find.byKey(const Key('profileDraftsButton')), findsOneWidget);
          expect(find.byKey(const Key('viewOutboxButton')), findsOneWidget);
          expect(
            find.text('My Reported Issues & Activity'),
            findsOneWidget,
          );

          expect(
            find.byKey(const Key('repDashboardEntryButton')),
            findsNothing,
          );
        },
      );

      // Case 2 — Rep user journey.
      testWidgets(
        'Ward Representative sees role badge + ward chip and a rep dashboard '
        'entry that navigates to /rep-dashboard; no rep metrics on the profile',
        (tester) async {
          _useTallViewport(tester);
          const session = Session(
            accessToken: 'token',
            userId: 42,
            isGuest: false,
          );
          final router = _buildRouter();

          await tester.pumpWidget(
            _buildProfileApp(
              session: session,
              router: router,
              profileBuilder: () => _profile(
                session: session,
                role: 'Ward Representative',
                ward: 'Ward 12, North',
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byKey(const Key('profileRoleBadge')), findsOneWidget);
          expect(find.text('Ward Representative'), findsOneWidget);
          expect(find.byKey(const Key('profileWardChip')), findsOneWidget);
          // The rep-entry card also shows the ward, so scope the ward-text
          // probe to the chip itself.
          expect(
            find.descendant(
              of: find.byKey(const Key('profileWardChip')),
              matching: find.text('Ward 12, North'),
            ),
            findsOneWidget,
          );

          // Rep metrics tiles belong to the dashboard screen, never the
          // profile itself (keys from rep_dashboard_test.dart).
          expect(find.byKey(const Key('repDashboardScreen')), findsNothing);
          expect(find.byKey(const Key('metricTotalWardIssues')), findsNothing);
          expect(
            find.byKey(const Key('metricEscalatedWardIssues')),
            findsNothing,
          );
          expect(
            find.byKey(const Key('metricPendingResponseWardIssues')),
            findsNothing,
          );
          expect(find.byKey(const Key('wardFilterChip_all')), findsNothing);
          expect(find.byKey(const Key('wardIssueList')), findsNothing);

          final repEntry = find.byKey(
            const Key('repDashboardEntryButton'),
          );
          expect(repEntry, findsOneWidget);
          await tester.ensureVisible(repEntry);
          await tester.tap(repEntry);
          await tester.pumpAndSettle();

          expect(router.state.matchedLocation, RoutePaths.repDashboard);
          expect(find.byKey(const Key('repDashboardStub')), findsOneWidget);
        },
      );

      // Case 3 — Guest journey.
      testWidgets(
        'Guest sees the guest banner and sign-in prompt, no role/ward/rep '
        'entry; drafts and outbox tiles still render',
        (tester) async {
          _useTallViewport(tester);
          const guestSession = Session(
            accessToken: 'guest-token',
            userId: 'guest_99',
            isGuest: true,
          );

          await tester.pumpWidget(
            _buildProfileApp(
              session: guestSession,
              profileBuilder: () => _profile(
                session: guestSession,
                role: 'guest',
                ward: null,
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byKey(const Key('profileRoleBadge')), findsNothing);
          expect(find.byKey(const Key('profileWardChip')), findsNothing);
          expect(
            find.byKey(const Key('repDashboardEntryButton')),
            findsNothing,
          );

          // The plan names no key for the guest banner; assert via the
          // case-insensitive 'Guest' text probe already used for the guest
          // banner in profile_settings_test.dart.
          expect(
            find.textContaining(RegExp(r'Guest', caseSensitive: false)),
            findsAtLeastNWidgets(1),
          );

          expect(find.byKey(const Key('profileDraftsButton')), findsOneWidget);
          expect(find.byKey(const Key('viewOutboxButton')), findsOneWidget);

          expect(
            find.text('Sign in to view and manage your reported issues '
                'history.'),
            findsOneWidget,
          );
        },
      );

      // Case 4 — Empty states.
      testWidgets(
        'Empty drafts and outbox render their empty-state messages and '
        'zero-count stats render 0',
        (tester) async {
          _useTallViewport(tester);
          const session = Session(
            accessToken: 'token',
            userId: 42,
            isGuest: false,
          );

          await tester.pumpWidget(
            _buildProfileApp(
              session: session,
              draftStore: _FakeDraftStore(),
              profileBuilder: () => _profile(
                session: session,
                issuesCount: 0,
                upvotesCount: 0,
                quorumVotesCount: 0,
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('No drafts yet'), findsOneWidget);
          expect(
            find.text('All local submissions synced'),
            findsOneWidget,
          );
          // The stats card exposes exactly three metrics (issues, upvotes,
          // quorum votes); each renders its zero count as literal text '0'.
          expect(find.text('0'), findsNWidgets(3));
        },
      );

      // Case 5 — My-issues filters (mirrors profile_posts_and_public_profile
      // test fixtures and assertions).
      testWidgets(
        'My-issues filters toggle active, resolved and all issue visibility',
        (tester) async {
          _useTallViewport(tester);
          const session = Session(
            accessToken: 'token',
            userId: 42,
            isGuest: false,
          );
          final feed = _StatusAwareFakeFeedRepository(issues: [
            Issue(
              id: 101,
              title: 'Broken water pipeline on 14th Cross',
              description: 'Water leaking heavily near primary school.',
              category: 'water',
              status: 'unacknowledged',
              latitude: 19.0760,
              longitude: 72.8777,
              ward: 'Ward 45, Urban Central',
              isAnonymous: true,
              reporterLabel: 'Anonymous Citizen',
              reporterId: 42,
              createdAt: DateTime.now().subtract(const Duration(hours: 2)),
              upvotesCount: 8,
            ),
            Issue(
              id: 102,
              title: 'Street lights malfunctioning on Main Boulevard',
              description: 'Entire street is completely dark.',
              category: 'lighting',
              status: 'escalating',
              latitude: 19.0762,
              longitude: 72.8780,
              ward: 'Ward 45, Urban Central',
              isAnonymous: false,
              reporterLabel: 'Aarav Sharma',
              reporterId: 42,
              createdAt: DateTime.now().subtract(const Duration(days: 2)),
              upvotesCount: 24,
            ),
            Issue(
              id: 103,
              title: 'Pothole repaired near market circle',
              description: 'Road surface patched and tarred.',
              category: 'road',
              status: 'resolved',
              latitude: 19.0755,
              longitude: 72.8790,
              ward: 'Ward 45, Urban Central',
              isAnonymous: false,
              reporterLabel: 'Aarav Sharma',
              reporterId: 42,
              createdAt: DateTime.now().subtract(const Duration(days: 5)),
              resolvedAt: DateTime.now().subtract(const Duration(days: 1)),
              upvotesCount: 56,
            ),
          ]);

          await tester.pumpWidget(
            _buildProfileApp(
              session: session,
              feedRepository: feed,
              profileBuilder: () => _profile(
                session: session,
                role: 'citizen',
                ward: 'Ward 45, Urban Central',
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(
            find.text('My Reported Issues & Activity'),
            findsOneWidget,
          );
          expect(find.byKey(const Key('myIssuesFilter_all')), findsOneWidget);
          expect(
            find.byKey(const Key('myIssuesFilter_active')),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('myIssuesFilter_resolved')),
            findsOneWidget,
          );

          expect(find.byKey(const Key('userIssueItem_101')), findsOneWidget);
          expect(find.byKey(const Key('userIssueItem_102')), findsOneWidget);
          expect(find.byKey(const Key('userIssueItem_103')), findsOneWidget);

          await tester.tap(find.byKey(const Key('myIssuesFilter_active')));
          await tester.pumpAndSettle();

          expect(find.byKey(const Key('userIssueItem_101')), findsOneWidget);
          expect(find.byKey(const Key('userIssueItem_102')), findsOneWidget);
          expect(find.byKey(const Key('userIssueItem_103')), findsNothing);

          await tester.tap(find.byKey(const Key('myIssuesFilter_resolved')));
          await tester.pumpAndSettle();

          expect(find.byKey(const Key('userIssueItem_103')), findsOneWidget);
          expect(find.byKey(const Key('userIssueItem_101')), findsNothing);

          await tester.tap(find.byKey(const Key('myIssuesFilter_all')));
          await tester.pumpAndSettle();

          expect(find.byKey(const Key('userIssueItem_101')), findsOneWidget);
          expect(find.byKey(const Key('userIssueItem_103')), findsOneWidget);
        },
      );

      // Case 6 — Navigation reachability.
      group('Navigation reachability', () {
        testWidgets(
          'openSettingsButton navigates to the settings screen',
          (tester) async {
            _useTallViewport(tester);
            const session = Session(
              accessToken: 'token',
              userId: 42,
              isGuest: false,
            );

            await tester.pumpWidget(
              _buildProfileApp(
                session: session,
                profileBuilder: () => _profile(session: session),
              ),
            );
            await tester.pumpAndSettle();

            final settingsButton = find.byKey(
              const Key('openSettingsButton'),
            );
            expect(settingsButton, findsOneWidget);
            await tester.ensureVisible(settingsButton);
            await tester.tap(settingsButton);
            await tester.pumpAndSettle();

            expect(find.byType(SettingsScreen), findsOneWidget);
          },
        );

        testWidgets('Report New navigates to the compose screen', (
          tester,
        ) async {
          _useTallViewport(tester);
          const session = Session(
            accessToken: 'token',
            userId: 42,
            isGuest: false,
          );

          await tester.pumpWidget(
            _buildProfileApp(
              session: session,
              profileBuilder: () => _profile(session: session),
            ),
          );
          await tester.pumpAndSettle();

          final reportNew = find.text('Report New');
          expect(reportNew, findsOneWidget);
          await tester.ensureVisible(reportNew);
          await tester.tap(reportNew);
          await tester.pumpAndSettle();

          expect(find.byKey(const Key('composeStub')), findsOneWidget);
        });

        testWidgets('Drafts tile navigates to the drafts screen', (
          tester,
        ) async {
          _useTallViewport(tester);
          const session = Session(
            accessToken: 'token',
            userId: 42,
            isGuest: false,
          );

          await tester.pumpWidget(
            _buildProfileApp(
              session: session,
              profileBuilder: () => _profile(session: session),
            ),
          );
          await tester.pumpAndSettle();

          final draftsTile = find.byKey(const Key('profileDraftsButton'));
          expect(draftsTile, findsOneWidget);
          await tester.ensureVisible(draftsTile);
          await tester.tap(draftsTile);
          await tester.pumpAndSettle();

          expect(find.byKey(const Key('draftsScreen')), findsOneWidget);
        });

        testWidgets('Outbox tile navigates to the outbox screen', (
          tester,
        ) async {
          _useTallViewport(tester);
          const session = Session(
            accessToken: 'token',
            userId: 42,
            isGuest: false,
          );

          await tester.pumpWidget(
            _buildProfileApp(
              session: session,
              profileBuilder: () => _profile(session: session),
            ),
          );
          await tester.pumpAndSettle();

          final outboxTile = find.byKey(const Key('viewOutboxButton'));
          expect(outboxTile, findsOneWidget);
          await tester.ensureVisible(outboxTile);
          await tester.tap(outboxTile);
          await tester.pumpAndSettle();

          expect(find.byKey(const Key('outboxStub')), findsOneWidget);
        });
      });
    },
  );

  // Case 7 — Parsing unit tests.
  group('UserProfile role/ward parsing and isRepresentative (F-G)', () {
    test('fromJson parses both the role and ward keys', () {
      final profile = UserProfile.fromJson({
        'role': 'ward_official',
        'ward': 'Ward 5',
      });
      expect(profile.role, 'ward_official');
      expect(profile.ward, 'Ward 5');
    });

    test('fromJson without role or ward defaults to citizen with no ward', () {
      final profile = UserProfile.fromJson(const <String, dynamic>{});
      expect(profile.role, 'citizen');
      expect(profile.ward, isNull);
    });

    test('isRepresentative is true for Ward Representative and representative',
        () {
      expect(
        _roleProfile('Ward Representative', ward: 'Ward 12, North')
            .isRepresentative,
        isTrue,
      );
      expect(
        _roleProfile('representative', ward: 'Ward 5').isRepresentative,
        isTrue,
      );
    });

    test('isRepresentative is false for citizen and guest', () {
      expect(_roleProfile('citizen').isRepresentative, isFalse);
      expect(
        _roleProfile('guest', ward: null, isGuest: true).isRepresentative,
        isFalse,
      );
    });
  });
}
