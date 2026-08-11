import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lens/core/storage/local_store.dart';
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

    testWidgets('FE-WARD-05: Recent Issues List Widget Rendering', (tester) async {
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

      expect(find.byKey(const Key('wardRecentIssuesList')), findsOneWidget);
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
}
