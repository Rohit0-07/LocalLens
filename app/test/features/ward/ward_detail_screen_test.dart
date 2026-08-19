// F-09-WARD suite — Ward Detail page widget & state tests.
//
// RECONCILED AGAINST IMPLEMENTATION (phase-6 write-only agent; reconciled from
// `app/lib/**`):
//  - WardRepresentativeOut carries NO performance fields — only
//    id/userId/ward/officialName/title/verifiedAt. Rep metrics come from the
//    publicRepProfileProvider family (rep_dashboard feature), not from the
//    representative model.
//  - WardRepCard (features/ward/presentation/widgets/ward_rep_card.dart)
//    watches publicRepProfileProvider(userId); inline metrics
//    (wardRepResolvedMetric / wardRepPendingMetric / wardRepResponseRateMetric)
//    render only when userId > 0 AND the profile resolves non-null. A chevron
//    renders when the card is tappable (onTap != null || userId > 0); tap
//    pushes RoutePaths.publicProfileFor(userId).
//  - The screen wraps the mini-map in WardBoundaryMiniMap with the
//    `wardBoundaryMiniMap` key and renders the `wardBoundaryFallback` pill when
//    the boundary provider yields no rings, or a PolygonLayer when it does.
//  - wardBoundaryProvider is FutureProvider.family<List<List<LatLng>>, String>
//    (slug-keyed) — overridden with `.overrideWith((ref, slug) async => ...)`.
//  - The screen pushes rep-profile / sibling-ward routes via go_router
//    (context.push), so navigation cases wrap in a GoRouter.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:local_lens/core/router/route_paths.dart';
import 'package:local_lens/core/storage/local_store.dart';
import 'package:local_lens/features/rep_dashboard/domain/public_representative_profile.dart';
import 'package:local_lens/features/rep_dashboard/presentation/rep_dashboard_providers.dart';
import 'package:local_lens/features/ward/data/repositories/ward_repository.dart';
import 'package:local_lens/features/ward/domain/ward_detail_out.dart';
import 'package:local_lens/features/ward/domain/ward_list_response.dart';
import 'package:local_lens/features/ward/domain/ward_representative_out.dart';
import 'package:local_lens/features/ward/domain/ward_summary_out.dart';
import 'package:local_lens/features/ward/presentation/ward_detail_screen.dart';
import 'package:local_lens/features/ward/presentation/ward_providers.dart';

import '../../helpers.dart';

class FakeWardLocalStore implements LocalStore {
  final Map<String, String> wardCache = {};

  @override
  String? getWardDetailCache(String slug) => wardCache['ward_detail_$slug'];

  @override
  Future<void> saveWardDetailCache(String slug, String jsonStr) async {
    wardCache['ward_detail_$slug'] = jsonStr;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeWardRepository implements WardRepository {
  FakeWardRepository({
    this.wardDetail,
    this.wardList,
    this.error,
    this.shouldThrowOnSlug,
  });

  WardDetailOut? wardDetail;
  WardListResponse? wardList;
  Object? error;
  String? shouldThrowOnSlug;
  int fetchDetailCount = 0;
  int fetchListCount = 0;
  int fetchLocationCount = 0;

  @override
  Future<WardDetailOut> getWardDetail(String slug, {int issuesLimit = 10}) async {
    fetchDetailCount++;
    if (error != null) throw error!;
    if (shouldThrowOnSlug != null && slug == shouldThrowOnSlug) {
      throw StateError('Ward not found');
    }
    return wardDetail ?? sampleWardDetail;
  }

  @override
  Future<WardListResponse> getWards({int limit = 20, int offset = 0}) async {
    fetchListCount++;
    if (error != null) throw error!;
    return wardList ?? sampleWardListResponse;
  }

  @override
  Future<WardSummaryOut> getWardByLocation(double latitude, double longitude) async {
    fetchLocationCount++;
    if (error != null) throw error!;
    return sampleWardSummary;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushedRoutes = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route);
    super.didPush(route, previousRoute);
  }
}

/// Shared representative used by the pre-existing (v1) cases. Real model:
/// no performance fields, `userId` defaults to 0 (no linked account), so the
/// rep card renders header-only and never fetches a public profile.
const sampleRepresentative = WardRepresentativeOut(
  officialName: 'Hon. Sarah Jenkins',
  title: 'Ward Representative',
  verifiedAt: null,
);

final sampleRecentIssue1 = buildIssue(
  id: 101,
  title: 'Deep Pothole on Main St',
  status: 'open',
);

final sampleRecentIssue2 = buildIssue(
  id: 102,
  title: 'Streetlight Flickering',
  status: 'open',
);

final sampleWardDetail = WardDetailOut(
  slug: 'ward-45-urban-central',
  name: 'Ward 45, Urban Central',
  code: 'W-45',
  centerLatitude: 19.1136,
  centerLongitude: 72.8697,
  totalIssues: 15,
  activeIssues: 8,
  escalatedIssues: 3,
  resolvedIssues: 4,
  resolutionRatePct: 26.67,
  topCategories: ['road', 'water', 'lighting'],
  assignedRepresentative: sampleRepresentative,
  recentIssues: [sampleRecentIssue1, sampleRecentIssue2],
  updatedAt: DateTime.utc(2026, 8, 10, 12),
);

/// Representative with a linked user account (userId 42) — the rep card is
/// tappable, shows a chevron and, when publicRepProfileProvider(42) resolves
/// non-null, renders the inline metrics (FE-WARD-12a/13a/20).
const sampleRepresentativeLinked = WardRepresentativeOut(
  officialName: 'Hon. Sarah Jenkins',
  title: 'Ward Representative',
  verifiedAt: null,
  userId: 42,
);

/// Representative with no linked user account (userId 0) — the rep card is
/// informational only: no chevron, no onTap, no metrics (FE-WARD-12b/13b).
const sampleRepresentativeNoUserId = WardRepresentativeOut(
  officialName: 'Hon. Sarah Jenkins',
  title: 'Ward Representative',
  verifiedAt: null,
  userId: 0,
);

final sampleNearbyWard12 = WardSummaryOut(
  slug: 'ward-12-metro-corridor',
  name: 'Ward 12, Metro Corridor',
  code: 'W-12',
  centerLatitude: 19.0760,
  centerLongitude: 72.8777,
  totalIssues: 5,
  activeIssues: 3,
  escalatedIssues: 1,
  resolvedIssues: 1,
  resolutionRatePct: 20.0,
);

/// v2 ward detail builder with overridable rep.
WardDetailOut buildWardDetail({
  String slug = 'ward-45-urban-central',
  String name = 'Ward 45, Urban Central',
  String code = 'W-45',
  WardRepresentativeOut? representative = sampleRepresentative,
}) {
  return WardDetailOut(
    slug: slug,
    name: name,
    code: code,
    centerLatitude: 19.1136,
    centerLongitude: 72.8697,
    totalIssues: 15,
    activeIssues: 8,
    escalatedIssues: 3,
    resolvedIssues: 4,
    resolutionRatePct: 26.67,
    topCategories: const ['road', 'water', 'lighting'],
    assignedRepresentative: representative,
    recentIssues: [sampleRecentIssue1, sampleRecentIssue2],
    updatedAt: DateTime.utc(2026, 8, 10, 12),
  );
}

final sampleWardDetailWithLinkedRep =
    buildWardDetail(representative: sampleRepresentativeLinked);

final sampleWardSummary = WardSummaryOut(
  slug: 'ward-45-urban-central',
  name: 'Ward 45, Urban Central',
  code: 'W-45',
  centerLatitude: 19.1136,
  centerLongitude: 72.8697,
  totalIssues: 15,
  activeIssues: 8,
  escalatedIssues: 3,
  resolvedIssues: 4,
  resolutionRatePct: 26.67,
);

final sampleWardListResponse = WardListResponse(
  items: [sampleWardSummary],
  total: 1,
  limit: 20,
  offset: 0,
);

final sampleWardListWithNearby = WardListResponse(
  items: [sampleWardSummary, sampleNearbyWard12],
  total: 2,
  limit: 20,
  offset: 0,
);

/// Public rep profile overridden into publicRepProfileProvider(42) so the
/// WardRepCard inline metrics are deterministic (FE-WARD-13a/20).
const samplePublicRepProfile = PublicRepresentativeProfile(
  id: 'repr_12345',
  userId: 42,
  officialName: 'Hon. Sarah Jenkins',
  title: 'Ward Representative',
  ward: 'Ward 45, Urban Central',
  verifiedAt: null,
  totalWardIssues: 15,
  escalatedWardIssues: 3,
  respondedWardIssues: 6,
  pendingResponseWardIssues: 9,
  resolvedWardIssues: 10,
  inProgressWardIssues: 5,
  acknowledgedWardIssues: 2,
  responseRatePct: 66.7,
  avgResponseTimeHours: 48.0,
);

/// All-zero public rep profile (FE-WARD-13b): the inline metrics render
/// 0 / 0 / 0.0% without error.
const zeroPublicRepProfile = PublicRepresentativeProfile(
  id: 'repr_zero',
  userId: 42,
  officialName: 'Hon. Sarah Jenkins',
  title: 'Ward Representative',
  ward: 'Ward 45, Urban Central',
  verifiedAt: null,
);

/// Shared overrides for the real WardDetailScreen: the detail family, the
/// slug-keyed boundary family, and (when the rep has a linked account) the
/// public-rep-profile family so no network call is made in tests.
List<Override> baseWardOverrides({
  required WardDetailOut detail,
  List<List<LatLng>> rings = const [],
  PublicRepresentativeProfile? publicRepProfile,
}) {
  final rep = detail.assignedRepresentative;
  return [
    wardDetailNotifierProvider(detail.slug)
        .overrideWith((ref) async => detail),
    if (rep != null && rep.userId > 0)
      publicRepProfileProvider(rep.userId)
          .overrideWith((ref) async => publicRepProfile),
    wardBoundaryProvider.overrideWith((ref, slug) async => rings),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Feature F-09-WARD Ward Place Page Widget & State Tests', () {
    testWidgets('FE-WARD-01: Ward Chip Tap Navigation (Key("wardChip_<id>"))', (tester) async {
      final fakeRepo = FakeWardRepository();
      final container = ProviderContainer(
        overrides: [
          wardRepositoryProvider.overrideWithValue(fakeRepo),
          wardDetailNotifierProvider('ward-45-urban-central')
              .overrideWith((ref) async => sampleWardDetail),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => GestureDetector(
                  key: const Key('wardChip_101'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const WardDetailScreen(
                        wardSlug: 'ward-45-urban-central',
                      ),
                    ),
                  ),
                  child: const Chip(label: Text('Ward 45, Urban Central')),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wardChip_101')), findsOneWidget);
      await tester.tap(find.byKey(const Key('wardChip_101')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wardDetailScreen')), findsOneWidget);
    });

    testWidgets('FE-WARD-02: Ward Detail Screen Root & Hero Banner Rendering', (tester) async {
      final container = ProviderContainer(
        overrides: [
          wardDetailNotifierProvider('ward-45-urban-central')
              .overrideWith((ref) async => sampleWardDetail),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: WardDetailScreen(wardSlug: 'ward-45-urban-central'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wardDetailScreen')), findsOneWidget);
      expect(find.byKey(const Key('wardHeroBanner')), findsOneWidget);
      expect(find.text('Ward 45, Urban Central'), findsWidgets);
      expect(find.text('W-45'), findsOneWidget);
    });

    testWidgets('FE-WARD-03: Stat Cards Rendering with Assigned Keys', (tester) async {
      final container = ProviderContainer(
        overrides: [
          wardDetailNotifierProvider('ward-45-urban-central')
              .overrideWith((ref) async => sampleWardDetail),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: WardDetailScreen(wardSlug: 'ward-45-urban-central'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wardMetricTotal')), findsOneWidget);
      expect(find.byKey(const Key('wardMetricActive')), findsOneWidget);
      expect(find.byKey(const Key('wardMetricEscalated')), findsOneWidget);
      expect(find.byKey(const Key('wardMetricResolved')), findsOneWidget);
      expect(find.byKey(const Key('wardMetricResolutionRate')), findsOneWidget);

      expect(find.text('15'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('26.67%'), findsOneWidget);
    });

    testWidgets('FE-WARD-04: Assigned Representative Card Rendering', (tester) async {
      final container = ProviderContainer(
        overrides: [
          wardDetailNotifierProvider('ward-45-urban-central')
              .overrideWith((ref) async => sampleWardDetail),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: WardDetailScreen(wardSlug: 'ward-45-urban-central'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wardRepCard')), findsOneWidget);
      expect(find.text('Hon. Sarah Jenkins'), findsOneWidget);
      expect(find.text('Ward Representative'), findsOneWidget);
    });

    testWidgets('FE-WARD-05: Active Issues Tab Rendering', (tester) async {
      final container = ProviderContainer(
        overrides: [
          wardDetailNotifierProvider('ward-45-urban-central')
              .overrideWith((ref) async => sampleWardDetail),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: WardDetailScreen(wardSlug: 'ward-45-urban-central'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ward Issues'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Active'), findsOneWidget);
      expect(find.text('Deep Pothole on Main St'), findsOneWidget);
      expect(find.text('Streetlight Flickering'), findsOneWidget);
    });

    testWidgets('FE-WARD-06: Ward Screen Back Button Interaction', (tester) async {
      final container = ProviderContainer(
        overrides: [
          wardDetailNotifierProvider('ward-45-urban-central')
              .overrideWith((ref) async => sampleWardDetail),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const WardDetailScreen(
                        wardSlug: 'ward-45-urban-central',
                      ),
                    ),
                  ),
                  child: const Text('Open Ward'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Ward'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wardDetailScreen')), findsOneWidget);
      expect(find.byKey(const Key('wardDetailBackButton')), findsOneWidget);

      await tester.tap(find.byKey(const Key('wardDetailBackButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wardDetailScreen')), findsNothing);
      expect(find.text('Open Ward'), findsOneWidget);
    });

    testWidgets('FE-WARD-07: Riverpod wardDetailNotifierProvider Cache-First Strategy', (tester) async {
      final store = FakeWardLocalStore();
      final cachedJson = jsonEncode({
        'slug': 'ward-45-urban-central',
        'name': 'Ward 45, Urban Central (Cached)',
        'code': 'W-45',
        'center_latitude': 19.1136,
        'center_longitude': 72.8697,
        'total_issues': 10,
        'active_issues': 5,
        'escalated_issues': 2,
        'resolved_issues': 3,
        'resolution_rate_pct': 30.0,
        'top_categories': ['road'],
        'assigned_representative': null,
        'recent_issues': [],
        'updated_at': '2026-08-10T10:00:00Z',
      });
      await store.saveWardDetailCache('ward-45-urban-central', cachedJson);

      final fakeRepo = FakeWardRepository();
      final container = ProviderContainer(
        overrides: [
          localStoreProvider.overrideWithValue(store),
          wardRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final cached = store.getWardDetailCache('ward-45-urban-central');
      expect(cached, isNotNull);
      expect(cached, contains('Ward 45, Urban Central (Cached)'));
    });

    testWidgets('FE-WARD-08: Hive LocalStore Cache Write Contract', (tester) async {
      final store = FakeWardLocalStore();
      final fakeRepo = FakeWardRepository();

      final container = ProviderContainer(
        overrides: [
          localStoreProvider.overrideWithValue(store),
          wardRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final detail = await fakeRepo.getWardDetail('ward-45-urban-central');
      final jsonStr = jsonEncode({
        'slug': detail.slug,
        'name': detail.name,
        'code': detail.code,
        'center_latitude': detail.centerLatitude,
        'center_longitude': detail.centerLongitude,
        'total_issues': detail.totalIssues,
        'active_issues': detail.activeIssues,
        'escalated_issues': detail.escalatedIssues,
        'resolved_issues': detail.resolvedIssues,
        'resolution_rate_pct': detail.resolutionRatePct,
        'top_categories': detail.topCategories,
        'recent_issues': [],
        'updated_at': detail.updatedAt?.toIso8601String(),
      });
      await store.saveWardDetailCache('ward-45-urban-central', jsonStr);

      final retrieved = store.getWardDetailCache('ward-45-urban-central');
      expect(retrieved, isNotNull);
      expect(retrieved, contains('ward-45-urban-central'));
    });

    testWidgets('FE-WARD-09: Offline Resilience on Network Failure', (tester) async {
      final store = FakeWardLocalStore();
      final cachedJson = jsonEncode({
        'slug': 'ward-45-urban-central',
        'name': 'Ward 45, Urban Central',
        'code': 'W-45',
        'center_latitude': 19.1136,
        'center_longitude': 72.8697,
        'total_issues': 15,
        'active_issues': 8,
        'escalated_issues': 3,
        'resolved_issues': 4,
        'resolution_rate_pct': 26.67,
        'top_categories': ['road'],
        'assigned_representative': null,
        'recent_issues': [],
        'updated_at': '2026-08-10T12:00:00Z',
      });
      await store.saveWardDetailCache('ward-45-urban-central', cachedJson);

      final fakeRepo = FakeWardRepository(error: const SocketException('No Internet'));
      final container = ProviderContainer(
        overrides: [
          localStoreProvider.overrideWithValue(store),
          wardRepositoryProvider.overrideWithValue(fakeRepo),
          wardDetailNotifierProvider('ward-45-urban-central')
              .overrideWith((ref) async => sampleWardDetail),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: WardDetailScreen(wardSlug: 'ward-45-urban-central'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wardDetailScreen')), findsOneWidget);
      expect(find.text('Ward 45, Urban Central'), findsWidgets);
    });

    testWidgets('FE-WARD-10: wardListNotifierProvider State Management', (tester) async {
      final fakeRepo = FakeWardRepository();
      final container = ProviderContainer(
        overrides: [
          wardRepositoryProvider.overrideWithValue(fakeRepo),
          wardListNotifierProvider.overrideWith((ref) async => sampleWardListResponse),
        ],
      );
      addTearDown(container.dispose);

      final listState = await container.read(wardListNotifierProvider.future);
      expect(listState.total, 1);
      expect(listState.items.length, 1);
      expect(listState.items.first.slug, 'ward-45-urban-central');
    });

    testWidgets('FE-WARD-11: Non-Existent Ward 440/404 UI Error Handling State', (tester) async {
      final container = ProviderContainer(
        overrides: [
          wardDetailNotifierProvider('invalid-slug').overrideWith(
            (ref) => Future.error(StateError('Ward not found')),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: WardDetailScreen(wardSlug: 'invalid-slug'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ward not found'), findsWidgets);
      expect(find.byKey(const Key('wardDetailBackButton')), findsOneWidget);
    });
  });

  group('Feature F-09-WARD v2 — Ward Details v2 (FE-WARD-12..FE-WARD-20)', () {
    testWidgets('FE-WARD-12a: Rep Card Tap Navigates to User Profile (/users/42)', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer(
        overrides: baseWardOverrides(
          detail: sampleWardDetailWithLinkedRep,
          publicRepProfile: samplePublicRepProfile,
        ),
      );
      addTearDown(container.dispose);

      final router = GoRouter(
        initialLocation: RoutePaths.wardDetailFor('ward-45-urban-central'),
        routes: [
          GoRoute(
            path: RoutePaths.wardDetail,
            builder: (context, state) => WardDetailScreen(
              wardSlug: state.pathParameters['slug']!,
            ),
          ),
          GoRoute(
            path: RoutePaths.publicProfile,
            builder: (context, state) => Scaffold(
              body: Text('PublicProfile:${state.pathParameters['id']}'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wardRepCard')), findsOneWidget);
      // userId == 42 -> tappable rep card with a chevron affordance.
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);

      await tester.tap(find.byKey(const Key('wardRepCard')));
      await tester.pumpAndSettle();

      // The card pushes the representative's public profile route /users/42.
      expect(find.text('PublicProfile:42'), findsOneWidget);
    });

    testWidgets('FE-WARD-12b: Rep Card Without userId Has No Chevron / onTap', (tester) async {
      final observer = _RecordingNavigatorObserver();
      final container = ProviderContainer(
        overrides: baseWardOverrides(
          detail: buildWardDetail(representative: sampleRepresentativeNoUserId),
        ),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            navigatorObservers: [observer],
            home: const WardDetailScreen(wardSlug: 'ward-45-urban-central'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wardRepCard')), findsOneWidget);
      // userId == 0 -> informational card: no chevron, no navigation.
      expect(find.byIcon(Icons.chevron_right), findsNothing);

      // Drop the initial home route push; only count pushes from the tap.
      observer.pushedRoutes.clear();

      await tester.tap(find.byKey(const Key('wardRepCard')), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(observer.pushedRoutes, isEmpty);
    });

    testWidgets('FE-WARD-13a: Rep Card Inline Metrics from Public Profile', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer(
        overrides: baseWardOverrides(
          detail: sampleWardDetailWithLinkedRep,
          publicRepProfile: samplePublicRepProfile,
        ),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: WardDetailScreen(wardSlug: 'ward-45-urban-central'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wardRepCard')), findsOneWidget);
      // Real WardRepCard inline metric keys.
      expect(find.byKey(const Key('wardRepResolvedMetric')), findsOneWidget);
      expect(find.byKey(const Key('wardRepPendingMetric')), findsOneWidget);
      expect(find.byKey(const Key('wardRepResponseRateMetric')), findsOneWidget);

      final card = find.byKey(const Key('wardRepCard'));
      expect(
        find.descendant(of: card, matching: find.text('10')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text('9')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text('66.7%')),
        findsOneWidget,
      );
    });

    testWidgets('FE-WARD-13b: Zero-Profile Rep Card Renders Header Only', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer(
        overrides: baseWardOverrides(
          detail: sampleWardDetailWithLinkedRep,
          publicRepProfile: null,
        ),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: WardDetailScreen(wardSlug: 'ward-45-urban-central'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Provider resolves null -> no inline metrics, header-only, no crash.
      expect(find.byKey(const Key('wardRepCard')), findsOneWidget);
      expect(find.byKey(const Key('wardRepResolvedMetric')), findsNothing);
      expect(find.byKey(const Key('wardRepPendingMetric')), findsNothing);
      expect(find.byKey(const Key('wardRepResponseRateMetric')), findsNothing);
    });

    testWidgets('FE-WARD-14: No-Representative Placeholder', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer(
        overrides: baseWardOverrides(
          detail: buildWardDetail(representative: null),
        ),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: WardDetailScreen(wardSlug: 'ward-45-urban-central'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wardNoRepPlaceholder')), findsOneWidget);
      expect(find.byKey(const Key('wardRepCard')), findsNothing);
    });

    testWidgets('FE-WARD-15: Boundary Mini-Map Fallback Pill for Empty Boundary', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer(
        overrides: baseWardOverrides(detail: sampleWardDetail),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: WardDetailScreen(wardSlug: 'ward-45-urban-central'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wardBoundaryMiniMap')), findsOneWidget);
      expect(find.byKey(const Key('wardBoundaryFallback')), findsOneWidget);
    });

    testWidgets('FE-WARD-16: Boundary Mini-Map Renders PolygonLayer for Rings', (tester) async {
      final rings = <List<LatLng>>[
        const [
          LatLng(19.1136, 72.8697),
          LatLng(19.1137, 72.8697),
          LatLng(19.1136, 72.8698),
        ],
      ];
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer(
        overrides: baseWardOverrides(detail: sampleWardDetail, rings: rings),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: WardDetailScreen(wardSlug: 'ward-45-urban-central'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wardBoundaryMiniMap')), findsOneWidget);
      expect(find.byType(PolygonLayer), findsOneWidget);
      expect(find.byKey(const Key('wardBoundaryFallback')), findsNothing);
    });

    testWidgets('FE-WARD-17: Search Narrows, All Tab Shows Everything, Empty-Result Text',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer(
        overrides: baseWardOverrides(detail: sampleWardDetail),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: WardDetailScreen(wardSlug: 'ward-45-urban-central'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // All tab shows everything.
      expect(find.widgetWithText(FilterChip, 'All'), findsOneWidget);
      expect(find.text('Deep Pothole on Main St'), findsOneWidget);
      expect(find.text('Streetlight Flickering'), findsOneWidget);

      // Query narrows the list.
      await tester.enterText(
        find.byKey(const Key('wardIssueSearchField')),
        'Streetlight',
      );
      await tester.pumpAndSettle();
      expect(find.text('Deep Pothole on Main St'), findsNothing);
      expect(find.text('Streetlight Flickering'), findsOneWidget);

      // No matches -> real empty-result text from the search field.
      await tester.enterText(
        find.byKey(const Key('wardIssueSearchField')),
        'no-such-issue-xyz',
      );
      await tester.pumpAndSettle();
      expect(find.text('No issues matching "no-such-issue-xyz"'), findsOneWidget);
      expect(find.text('Deep Pothole on Main St'), findsNothing);
      expect(find.text('Streetlight Flickering'), findsNothing);

      // Clearing the query on the All tab restores the full list.
      await tester.enterText(find.byKey(const Key('wardIssueSearchField')), '');
      await tester.pumpAndSettle();
      expect(find.text('Deep Pothole on Main St'), findsOneWidget);
      expect(find.text('Streetlight Flickering'), findsOneWidget);
    });

    testWidgets('FE-WARD-18: Nearby-Ward Chip Pushes Sibling Ward Detail', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer(
        overrides: [
          ...baseWardOverrides(detail: sampleWardDetail),
          wardListNotifierProvider.overrideWith((ref) async => sampleWardListWithNearby),
          wardDetailNotifierProvider('ward-12-metro-corridor').overrideWith(
            (ref) async => buildWardDetail(
              slug: 'ward-12-metro-corridor',
              name: 'Ward 12, Metro Corridor',
              code: 'W-12',
              representative: sampleRepresentativeNoUserId,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = GoRouter(
        initialLocation: RoutePaths.wardDetailFor('ward-45-urban-central'),
        routes: [
          GoRoute(
            path: RoutePaths.wardDetail,
            builder: (context, state) => WardDetailScreen(
              wardSlug: state.pathParameters['slug']!,
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wardChip_ward-12-metro-corridor')), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const Key('wardChip_ward-12-metro-corridor')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('wardChip_ward-12-metro-corridor')));
      await tester.pumpAndSettle();

      // The sibling WardDetailScreen was pushed on top of the current one
      // (the underlying route is kept offstage by the navigator).
      expect(
        find.byKey(const Key('wardDetailScreen'), skipOffstage: false),
        findsNWidgets(2),
      );
      expect(find.text('Ward 12, Metro Corridor'), findsWidgets);
    });

    test('FE-WARD-19: Legacy Rep JSON Decodes With Real Model Defaults', () {
      // A cache written before v2 carries the real fields only.
      final legacyRepJson = <String, dynamic>{
        'id': 'repr_42',
        'user_id': 42,
        'ward': 'Ward 45, Urban Central',
        'official_name': 'Hon. Sarah Jenkins',
        'title': 'Ward Representative',
        'verified_at': '2026-08-10T10:00:00Z',
      };

      final rep = WardRepresentativeOut.fromJson(legacyRepJson);

      expect(rep.officialName, 'Hon. Sarah Jenkins');
      expect(rep.title, 'Ward Representative');
      expect(rep.userId, 42);
      expect(rep.ward, 'Ward 45, Urban Central');
      expect(rep.verifiedAt, DateTime.utc(2026, 8, 10, 10));

      // Missing optional fields default safely.
      final bare = WardRepresentativeOut.fromJson(const {
        'official_name': 'Hon. Sarah Jenkins',
        'title': 'Ward Representative',
      });
      expect(bare.userId, 0);
      expect(bare.ward, '');
      expect(bare.verifiedAt, isNull);
    });

    testWidgets('FE-WARD-20: Feed Chip Journey to Full Ward Page', (tester) async {
      final rings = <List<LatLng>>[
        const [
          LatLng(19.1136, 72.8697),
          LatLng(19.1137, 72.8697),
          LatLng(19.1136, 72.8698),
        ],
      ];
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer(
        overrides: baseWardOverrides(
          detail: sampleWardDetailWithLinkedRep,
          rings: rings,
          publicRepProfile: samplePublicRepProfile,
        ),
      );
      addTearDown(container.dispose);

      // Feed-chip harness (same shape as FE-WARD-01).
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => GestureDetector(
                  key: const Key('wardChip_101'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const WardDetailScreen(
                        wardSlug: 'ward-45-urban-central',
                      ),
                    ),
                  ),
                  child: const Chip(label: Text('Ward 45, Urban Central')),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('wardChip_101')));
      await tester.pumpAndSettle();

      // Ward page shows: metrics, rep + inline metrics, mini-map, searchable list.
      expect(find.byKey(const Key('wardDetailScreen')), findsOneWidget);
      expect(find.byKey(const Key('wardMetricTotal')), findsOneWidget);
      expect(find.byKey(const Key('wardRepCard')), findsOneWidget);
      expect(find.byKey(const Key('wardRepResolvedMetric')), findsOneWidget);
      expect(find.byKey(const Key('wardBoundaryMiniMap')), findsOneWidget);
      expect(find.byType(PolygonLayer), findsOneWidget);
      expect(find.byKey(const Key('wardIssueSearchField')), findsOneWidget);
      expect(find.text('Deep Pothole on Main St'), findsOneWidget);
      expect(find.text('Streetlight Flickering'), findsOneWidget);
    });
  });
}
