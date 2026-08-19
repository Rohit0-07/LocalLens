// FE-ACC suite — Representative Accountability & Performance widget tests.
//
// Contract note: docs/4_interfaces.json was NOT present at the expected path
// when this file was written (read returned "File not found"), so the public
// API below is derived from the FE-ACC-01..FE-ACC-05 scenarios in the test
// plan plus the house conventions proven by existing tests
// (rep_dashboard_test.dart, ward_detail_screen_test.dart,
// profile_posts_and_public_profile_test.dart).
//
// RECONCILED AGAINST IMPLEMENTATION (phase-6 write-only agent; reconciled from
// `app/lib/**`):
//  - RepresentativeProfile (rep_dashboard domain) carries the accountability
//    metrics (resolvedWardIssues, inProgressWardIssues, acknowledgedWardIssues,
//    responseRatePct, avgResponseTimeHours). RepDashboardScreen renders them.
//  - publicRepProfileProvider: FutureProvider.family<PublicRepresentativeProfile?,
//    int> keyed by user id (null for non-representatives and userId <= 0).
//  - WardRepCard (features/ward/presentation/widgets/ward_rep_card.dart) reads
//    publicRepProfileProvider(userId) for the `wardRepResolvedMetric`,
//    `wardRepPendingMetric`, `wardRepResponseRateMetric` inline metrics and
//    pushes RoutePaths.publicProfileFor(userId) on tap when userId > 0.
//  - PublicProfileScreen renders `publicRepPerformanceCard` with the
//    `publicRepResolvedCount`/`publicRepPendingCount`/`publicRepResponseRate`/
//    `publicRepAvgResponseTime` sub-keys and hides the section when the
//    provider yields null.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:local_lens/core/router/route_paths.dart';
import 'package:local_lens/features/auth/domain/session.dart';
import 'package:local_lens/features/auth/presentation/auth_providers.dart';
import 'package:local_lens/features/feed/domain/feed_repository.dart';
import 'package:local_lens/features/feed/domain/issue.dart';
import 'package:local_lens/features/feed/presentation/feed_providers.dart';
import 'package:local_lens/features/profile/presentation/profile_providers.dart';
import 'package:local_lens/features/profile/presentation/screens/public_profile_screen.dart';
import 'package:local_lens/features/rep_dashboard/domain/public_representative_profile.dart';
import 'package:local_lens/features/rep_dashboard/domain/representative_profile.dart';
import 'package:local_lens/features/rep_dashboard/domain/ward_issues_response.dart';
import 'package:local_lens/features/rep_dashboard/presentation/rep_dashboard_providers.dart';
import 'package:local_lens/features/rep_dashboard/presentation/rep_dashboard_screen.dart';
import 'package:local_lens/features/ward/domain/ward_representative_out.dart';
import 'package:local_lens/features/ward/presentation/widgets/ward_rep_card.dart';

import '../../helpers.dart';

/// Representative profile extended with the FE-ACC accountability metrics.
///
/// Values are chosen so every rendered number is distinct on-screen, keeping
/// the plan's "correct values" assertions unambiguous.
const sampleProfile = RepresentativeProfile(
  id: 'repr_12345',
  userId: 42,
  officialName: 'Hon. Sarah Jenkins',
  title: 'Ward Councilor',
  ward: 'Ward 45, Urban Central',
  verifiedAt: null,
  totalWardIssues: 18,
  escalatedWardIssues: 4,
  respondedWardIssues: 12,
  pendingResponseWardIssues: 6,
  // FE-ACC accountability metrics (Inferred API — see header comment).
  resolvedWardIssues: 10,
  inProgressWardIssues: 5,
  acknowledgedWardIssues: 3,
  responseRatePct: 66.7,
  avgResponseTimeHours: 48.0,
);

/// All-zero accountability profile (FE-ACC-05): every card must render
/// `0` / `0.0%` / `0.0h` without error.
const zeroMetricProfile = RepresentativeProfile(
  id: 'repr_zero',
  userId: 42,
  officialName: 'Hon. Sarah Jenkins',
  title: 'Ward Councilor',
  ward: 'Ward 45, Urban Central',
  verifiedAt: null,
  totalWardIssues: 0,
  escalatedWardIssues: 0,
  respondedWardIssues: 0,
  pendingResponseWardIssues: 0,
  resolvedWardIssues: 0,
  inProgressWardIssues: 0,
  acknowledgedWardIssues: 0,
  responseRatePct: 0.0,
  avgResponseTimeHours: 0.0,
);

/// Linked representative (userId 42) — header comes from this model, the
/// accountability metrics come from publicRepProfileProvider(42).
const sampleWardRep = WardRepresentativeOut(
  officialName: 'Hon. Sarah Jenkins',
  title: 'Ward Representative',
  verifiedAt: null,
  userId: 42,
);

/// Representative with no linked user account (userId 0) — the card must
/// render its header only: no metrics, no crash (FE-ACC-03).
const noLinkedUserWardRep = WardRepresentativeOut(
  officialName: 'Hon. Sarah Jenkins',
  title: 'Ward Representative',
  verifiedAt: null,
  userId: 0,
);

/// Public rep profile overridden into publicRepProfileProvider(42) for the
/// WardRepCard / PublicProfileScreen accountability assertions. Values are
/// distinct from every other rendered number so the plan's "correct values"
/// remain unambiguous.
const samplePublicProfile = PublicRepresentativeProfile(
  id: 'repr_12345',
  userId: 42,
  officialName: 'Hon. Sarah Jenkins',
  title: 'Ward Representative',
  ward: 'Ward 45, Urban Central',
  verifiedAt: null,
  totalWardIssues: 18,
  escalatedWardIssues: 4,
  respondedWardIssues: 12,
  pendingResponseWardIssues: 6,
  resolvedWardIssues: 10,
  inProgressWardIssues: 5,
  acknowledgedWardIssues: 3,
  responseRatePct: 66.7,
  avgResponseTimeHours: 48.0,
);

/// All-zero public rep profile (FE-ACC-05): every metric renders `0` /
/// `0.0%` / `0.0h` without error.
const zeroPublicProfile = PublicRepresentativeProfile(
  id: 'repr_zero',
  userId: 42,
  officialName: 'Hon. Sarah Jenkins',
  title: 'Ward Representative',
  ward: 'Ward 45, Urban Central',
  verifiedAt: null,
  totalWardIssues: 0,
  escalatedWardIssues: 0,
  respondedWardIssues: 0,
  pendingResponseWardIssues: 0,
  resolvedWardIssues: 0,
  inProgressWardIssues: 0,
  acknowledgedWardIssues: 0,
  responseRatePct: 0.0,
  avgResponseTimeHours: 0.0,
);

final sampleIssue1 = buildIssue(
  id: 101,
  title: 'Severe Pothole on Main St',
  status: 'escalated',
);

final sampleIssue2 = buildIssue(
  id: 102,
  title: 'Garbage accumulation in alley',
  status: 'unacknowledged',
);

final sampleWardIssuesAll = WardIssuesResponse(
  items: [sampleIssue1, sampleIssue2],
  total: 2,
);

class _FixedSessionController extends SessionController {
  _FixedSessionController(this.session);

  final Session? session;

  @override
  Session? build() => session;
}

/// Mirrors FakeFeedRepositoryForProfile in the public-profile tests so
/// PublicProfileScreen has everything it needs if it is reached directly.
class FakeFeedRepositoryForProfile implements FeedRepository {
  final List<Issue> issues;
  final Map<String, dynamic> publicProfileMap;

  FakeFeedRepositoryForProfile({
    this.issues = const [],
    this.publicProfileMap = const {},
  });

  @override
  Future<List<Issue>> fetchUserIssues({int? userId, String? status}) async {
    if (status == 'resolved') {
      return issues.where((i) => i.status == 'resolved').toList();
    } else if (status == 'active') {
      return issues.where((i) => i.status != 'resolved').toList();
    }
    return issues;
  }

  @override
  Future<Map<String, dynamic>> fetchPublicUserProfile(int userId) async {
    if (publicProfileMap.isNotEmpty) return publicProfileMap;
    return {
      'user_id': userId,
      'display_name': 'Aarav Sharma',
      'anon_id': 'anon_0042',
      'role': 'Ward Representative',
      'is_verified': true,
      'ward': 'Ward 45, Urban Central',
      'member_since': '2025-06-15T00:00:00.000',
      'impact_points': 340,
      'level_name': 'Community Sentinel',
      'issues_reported': 8,
      'verified_resolutions': 6,
      'upvotes_received': 92,
      'badges': [
        {
          'key': 'first_report',
          'name': 'First Alert',
          'description': 'Reported first civic issue',
          'icon_name': 'flag',
          'category': 'reporting',
          'threshold': 1,
          'is_unlocked': true,
        },
      ],
    };
  }

  @override
  Future<Issue> fetchIssue(int issueId) async {
    return issues.firstWhere(
      (i) => i.id == issueId,
      orElse: () => buildIssue(id: issueId),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Router harness for the standalone WardRepCard: '/' hosts the card, and
/// the public profile route (path `/users/:id`) renders a marker text so
/// tests can assert the destination route/location.
GoRouter buildWardRepCardRouter(WardRepresentativeOut representative) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            Scaffold(body: WardRepCard(representative: representative)),
      ),
      GoRoute(
        path: RoutePaths.publicProfile,
        builder: (context, state) => Scaffold(
          body: Text('PublicProfile:${state.pathParameters['id']}'),
        ),
      ),
    ],
  );
}

/// App harness for the standalone WardRepCard tests. Includes the feed /
/// session / own-profile providers so a directly-pushed PublicProfileScreen
/// can also render if the card navigates by pushing it itself.
Widget createWardRepCardApp({
  required GoRouter router,
  required Override publicRepOverride,
}) {
  const session = Session(accessToken: 'viewer-token', userId: 7, isGuest: false);
  final viewerProfile = UserProfile(
    id: 7,
    phone: '+919876543210',
    anonymousIdentity: 'anon_0042',
    anonId: 'anon_0042',
    isGuest: false,
    issuesCount: 3,
    upvotesCount: 88,
    quorumVotesCount: 6,
  );

  return ProviderScope(
    overrides: [
      feedRepositoryProvider.overrideWithValue(FakeFeedRepositoryForProfile()),
      sessionProvider.overrideWith(() => _FixedSessionController(session)),
      userProfileProvider.overrideWith((ref) async => viewerProfile),
      publicRepOverride,
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

/// App harness for PublicProfileScreen(userId: 42) tests (FE-ACC-04/05).
Widget createPublicProfileApp({required Override publicRepOverride}) {
  const session = Session(accessToken: 'viewer-token', userId: 7, isGuest: false);
  final viewerProfile = UserProfile(
    id: 7,
    phone: '+919876543210',
    anonymousIdentity: 'anon_0042',
    anonId: 'anon_0042',
    isGuest: false,
    issuesCount: 3,
    upvotesCount: 88,
    quorumVotesCount: 6,
  );

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const PublicProfileScreen(userId: 42),
      ),
      GoRoute(
        path: RoutePaths.publicProfile,
        builder: (context, state) => Scaffold(
          body: Text('PublicProfile:${state.pathParameters['id']}'),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      feedRepositoryProvider.overrideWithValue(FakeFeedRepositoryForProfile()),
      sessionProvider.overrideWith(() => _FixedSessionController(session)),
      userProfileProvider.overrideWith((ref) async => viewerProfile),
      publicRepOverride,
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Feature — Rep Accountability & Representative Performance (FE-ACC)', () {
    testWidgets(
      'FE-ACC-01: RepDashboardScreen shows accountability performance card '
      'with new metrics and preserves existing keys',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer(
          overrides: [
            repProfileProvider.overrideWith((ref) async => sampleProfile),
            wardIssuesFilterProvider.overrideWith((ref) => 'all'),
            wardIssuesProvider.overrideWith((ref, filter) async => sampleWardIssuesAll),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: RepDashboardScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Existing keys still present with their values.
        expect(find.byKey(const Key('repDashboardScreen')), findsOneWidget);
        expect(find.byKey(const Key('repProfileName')), findsOneWidget);
        expect(find.text('Hon. Sarah Jenkins'), findsOneWidget);
        expect(find.byKey(const Key('repProfileWard')), findsOneWidget);
        expect(find.text('Ward 45, Urban Central'), findsOneWidget);
        expect(find.byKey(const Key('metricTotalWardIssues')), findsOneWidget);
        expect(find.text('18'), findsOneWidget);
        expect(find.byKey(const Key('metricEscalatedWardIssues')), findsOneWidget);
        expect(find.text('4'), findsOneWidget);
        expect(find.byKey(const Key('metricPendingResponseWardIssues')), findsOneWidget);
        expect(find.text('6'), findsOneWidget);

        // New FE-ACC performance card and metric keys.
        expect(find.byKey(const Key('repPerformanceCard')), findsOneWidget);
        expect(find.byKey(const Key('metricResolvedWardIssues')), findsOneWidget);
        expect(find.byKey(const Key('metricRespondedWardIssues')), findsOneWidget);
        expect(find.byKey(const Key('metricInProgressWardIssues')), findsOneWidget);
        expect(find.byKey(const Key('metricAcknowledgedWardIssues')), findsOneWidget);
        expect(find.byKey(const Key('repResponseRateValue')), findsOneWidget);
        expect(find.byKey(const Key('repAvgResponseTimeValue')), findsOneWidget);

        // Correct values in the metrics grid (resolved/responded/in-progress/
        // acknowledged live in the grid, not the performance card).
        expect(
          find.descendant(
            of: find.byKey(const Key('metricResolvedWardIssues')),
            matching: find.text('10'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('metricRespondedWardIssues')),
            matching: find.text('12'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('metricInProgressWardIssues')),
            matching: find.text('5'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('metricAcknowledgedWardIssues')),
            matching: find.text('3'),
          ),
          findsOneWidget,
        );

        // Correct values inside the performance card.
        final card = find.byKey(const Key('repPerformanceCard'));
        expect(
          find.descendant(of: card, matching: find.text('66.7%')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: card, matching: find.text('48.0h')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'FE-ACC-02: WardRepCard with linked rep profile shows accountability '
      'metrics and tapping navigates to /users/42',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

final router = buildWardRepCardRouter(sampleWardRep);
        await tester.pumpWidget(
          createWardRepCardApp(
            router: router,
            publicRepOverride: publicRepProfileProvider(42)
                .overrideWith((ref) async => samplePublicProfile),
          ),
        );
        await tester.pumpAndSettle();

        // Header from the WardRepresentativeOut model.
        expect(find.byKey(const Key('wardRepCard')), findsOneWidget);
        expect(find.text('Hon. Sarah Jenkins'), findsOneWidget);
        expect(find.text('Ward Representative'), findsOneWidget);

        // Accountability metrics from the overridden publicRepProfileProvider.
        expect(find.byKey(const Key('wardRepResolvedMetric')), findsOneWidget);
        expect(find.byKey(const Key('wardRepPendingMetric')), findsOneWidget);
        expect(find.byKey(const Key('wardRepResponseRateMetric')), findsOneWidget);
        final card = find.byKey(const Key('wardRepCard'));
        expect(
          find.descendant(of: card, matching: find.text('10')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: card, matching: find.text('6')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: card, matching: find.text('66.7%')),
          findsOneWidget,
        );

        // Tapping the card opens the representative's public profile at
        // /users/42 (assert route/location).
        await tester.tap(find.text('Hon. Sarah Jenkins'));
        await tester.pumpAndSettle();

        final location = router.state.matchedLocation;
        final reachedPublicProfile =
            find.text('PublicProfile:42').evaluate().isNotEmpty ||
                location == '/users/42' ||
                find.byKey(const Key('publicRepPerformanceCard')).evaluate().isNotEmpty;
        expect(reachedPublicProfile, isTrue);
        if (location != '/') {
          expect(location, '/users/42');
        }
      },
    );

    testWidgets(
      'FE-ACC-03: WardRepCard with userId 0 renders header only, no metrics, '
      'no crash',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final router = buildWardRepCardRouter(noLinkedUserWardRep);
        await tester.pumpWidget(
          createWardRepCardApp(
            router: router,
            publicRepOverride: publicRepProfileProvider(0)
                .overrideWith((ref) async => null),
          ),
        );
        await tester.pumpAndSettle();

        // Header renders.
        expect(find.byKey(const Key('wardRepCard')), findsOneWidget);
        expect(find.text('Hon. Sarah Jenkins'), findsOneWidget);
        expect(find.text('Ward Representative'), findsOneWidget);

        // No accountability metrics for an unlinked account, and no crash.
        expect(find.byKey(const Key('wardRepResolvedMetric')), findsNothing);
        expect(find.byKey(const Key('wardRepPendingMetric')), findsNothing);
        expect(find.byKey(const Key('wardRepResponseRateMetric')), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'FE-ACC-04: PublicProfileScreen shows rep performance card for rep '
      'users and hides it for citizen users',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        // Rep user: provider returns a non-null accountability profile.
        await tester.pumpWidget(
          createPublicProfileApp(
            publicRepOverride: publicRepProfileProvider(42)
                .overrideWith((ref) async => samplePublicProfile),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('publicRepPerformanceCard')), findsOneWidget);
        // Sub-keys of the real performance card.
        expect(find.byKey(const Key('publicRepResolvedCount')), findsOneWidget);
        expect(find.byKey(const Key('publicRepPendingCount')), findsOneWidget);
        expect(find.byKey(const Key('publicRepResponseRate')), findsOneWidget);
        expect(find.byKey(const Key('publicRepAvgResponseTime')), findsOneWidget);

        final card = find.byKey(const Key('publicRepPerformanceCard'));
        expect(
          find.descendant(of: card, matching: find.text('10')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: card, matching: find.text('6')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: card, matching: find.text('66.7%')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: card, matching: find.text('48.0h')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'FE-ACC-04b: PublicProfileScreen hides the rep performance card for '
      'citizen users (provider returns null)',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          createPublicProfileApp(
            publicRepOverride: publicRepProfileProvider(42)
                .overrideWith((ref) async => null),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('publicRepPerformanceCard')), findsNothing);
        expect(find.byKey(const Key('publicRepResolvedCount')), findsNothing);
        expect(find.byKey(const Key('publicRepResponseRate')), findsNothing);
      },
    );

    testWidgets(
      'FE-ACC-05: All-zero metrics profile renders 0 / 0.0% / 0.0h without '
      'error',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          createPublicProfileApp(
            publicRepOverride: publicRepProfileProvider(42)
                .overrideWith((ref) async => zeroPublicProfile),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('publicRepPerformanceCard')), findsOneWidget);
        expect(find.text('0'), findsWidgets);
        expect(find.text('0.0%'), findsOneWidget);
        expect(find.text('0.0h'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
