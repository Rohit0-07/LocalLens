import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lens/features/feed/domain/issue.dart';
import 'package:local_lens/features/feed/presentation/feed_providers.dart';
import 'package:local_lens/features/search/data/recent_search_store.dart';
import 'package:local_lens/features/search/domain/search_filters.dart';
import 'package:local_lens/features/search/domain/search_repository.dart';
import 'package:local_lens/features/search/presentation/search_filters_provider.dart';
import 'package:local_lens/features/search/presentation/search_providers.dart';
import 'package:local_lens/features/search/presentation/search_screen.dart';
import 'package:local_lens/features/ward/domain/ward_list_response.dart';
import 'package:local_lens/features/ward/domain/ward_summary_out.dart';
import 'package:local_lens/features/ward/presentation/ward_providers.dart';

import '../../helpers.dart';

/// F-08 Advanced Search Filters — frontend contract tests (code-blind).
///
/// Widget/unit tests for the advanced-filter sheet and its integration with
/// `SearchScreen`, per `docs/specs/F-08_filters_contracts.md` §3.2 (cases 1-12
/// and 14; case 13 lives in `search_api_filters_test.dart`).
///
/// Mapping of tests to contract §3.2 cases:
///   1a -> 'filter icon is present with tooltip Filters'
///   1b -> 'tapping the filter icon opens the filter sheet'
///   2  -> 'sheet shows all seven status chips and single-select replaces'
///   3  -> 'sheet shows all seven category chips and toggling selects/deselects'
///   4  -> "within radius reveals the radius slider and any distance hides it"
///   5  -> 'tapping Past 7 days selects the date chip'
///   6  -> 'Reset clears all local selections in the sheet'
///   7  -> 'Show results pops the sheet and updates the provider'
///   8  -> 'barrier-tap dismiss returns null and leaves the provider unchanged'
///   9  -> 'Clear filters resets the provider and re-runs the last query'
///   10 -> 'active filters are passed to the repository exactly'
///   11 -> 'no active filters passes defaults to the repository'
///   12 -> 'results still render as issue cards when filters are active'
///   14 -> 'SearchFilters reset returns defaults and isActive reflects state'
class FakeSearchRepository implements SearchRepository {
  FakeSearchRepository({this.completer});

  final Completer<List<Issue>>? completer;
  List<Issue> result = const [];
  Object? error;
  int searchCount = 0;
  String? lastQuery;
  final List<String> queries = [];
  double? lastLatitude;
  double? lastLongitude;
  String? lastStatus;
  List<String> lastCategories = const <String>[];
  double? lastRadiusKm;
  DateTime? lastCreatedAfter;
  DateTime? lastCreatedBefore;

  @override
  Future<List<Issue>> search({
    required String query,
    double? latitude,
    double? longitude,
    String? status,
    List<String> categories = const <String>[],
    double? radiusKm,
    DateTime? createdAfter,
    DateTime? createdBefore,
    String? ward,
    String? account,
  }) async {
    searchCount += 1;
    lastQuery = query;
    queries.add(query);
    lastLatitude = latitude;
    lastLongitude = longitude;
    lastStatus = status;
    lastCategories = categories;
    lastRadiusKm = radiusKm;
    lastCreatedAfter = createdAfter;
    lastCreatedBefore = createdBefore;
    if (error != null) throw error!;
    if (completer != null) return completer!.future;
    return result;
  }
}

class FakeRecentSearchStore implements RecentSearchStore {
  final List<String> _items = <String>[];

  @override
  List<String> load() => List<String>.of(_items);

  @override
  Future<void> add(String query) async {
    final String trimmed = query.trim();
    if (trimmed.isEmpty) return;
    _items.removeWhere((q) => q.toLowerCase() == trimmed.toLowerCase());
    _items.insert(0, trimmed);
    if (_items.length > 5) {
      _items.removeRange(5, _items.length);
    }
  }

  @override
  Future<void> clear() async {
    _items.clear();
  }
}

Widget wrap(ProviderContainer container) => UncontrolledProviderScope(
  container: container,
  child: const MaterialApp(home: SearchScreen()),
);

Future<void> pumpSearch(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();
  await tester.pumpAndSettle();
}

/// A tall surface so every sheet section (status/category/distance/date chips)
/// is on-screen and tappable without scrolling.
void useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1000, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Two-ward list fed to the filter sheet via `wardListNotifierProvider`
/// (F-E: the sheet's ward chips come from the ward list provider).
final WardListResponse _twoWards = WardListResponse(
  items: [
    WardSummaryOut(
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
    ),
    WardSummaryOut(
      slug: 'ward-12-old-town',
      name: 'Ward 12, Old Town',
      code: 'W-12',
      centerLatitude: 18.99,
      centerLongitude: 72.84,
      totalIssues: 9,
      activeIssues: 5,
      escalatedIssues: 1,
      resolvedIssues: 3,
      resolutionRatePct: 33.33,
    ),
  ],
  total: 2,
  limit: 20,
  offset: 0,
);

Future<
  ({
    ProviderContainer container,
    FakeSearchRepository repo,
    FakeRecentSearchStore store,
  })
>
buildHarness() async {
  final repo = FakeSearchRepository();
  final store = FakeRecentSearchStore();
  final container = ProviderContainer(
    overrides: [
      searchRepositoryProvider.overrideWithValue(repo),
      recentSearchStoreProvider.overrideWithValue(store),
      feedRepositoryProvider.overrideWithValue(FakeFeedRepository()),
      wardListNotifierProvider.overrideWith((ref) async => _twoWards),
    ],
  );
  addTearDown(container.dispose);
  return (container: container, repo: repo, store: store);
}

Future<void> openSheet(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(wrap(container));
  await tester.tap(find.byKey(const Key('filterButton')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('filter icon is present with tooltip Filters', (tester) async {
    // §3.2.1 — icon present on SearchScreen with exact tooltip.
    final harness = await buildHarness();
    await tester.pumpWidget(wrap(harness.container));
    final button = tester.widget<IconButton>(find.byKey(const Key('filterButton')));
    expect(button.tooltip, 'Filters');
    final icon = button.icon as Icon;
    expect(icon.icon, Icons.tune);
  });

  testWidgets('tapping the filter icon opens the filter sheet', (tester) async {
    // §3.2.1 — sheet header and apply button become visible.
    useTallSurface(tester);
    final harness = await buildHarness();
    await openSheet(tester, harness.container);
    expect(find.text('Filters'), findsOneWidget);
    expect(find.byKey(const Key('applyFiltersButton')), findsOneWidget);
    expect(find.byKey(const Key('resetFiltersButton')), findsOneWidget);
  });

  testWidgets('sheet shows all seven status chips and single-select replaces', (
    tester,
  ) async {
    // §3.2.2 — 7 chips; tapping a second one replaces the first.
    useTallSurface(tester);
    final harness = await buildHarness();
    await openSheet(tester, harness.container);
    for (final status in kSearchStatusOptions) {
      expect(find.byKey(Key('statusChip_$status')), findsOneWidget);
    }
    await tester.tap(find.byKey(const Key('statusChip_unacknowledged')));
    await tester.pump();
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const Key('statusChip_unacknowledged')))
          .selected,
      isTrue,
    );
    await tester.tap(find.byKey(const Key('statusChip_resolved')));
    await tester.pump();
    expect(
      tester.widget<ChoiceChip>(find.byKey(const Key('statusChip_resolved'))).selected,
      isTrue,
    );
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const Key('statusChip_unacknowledged')))
          .selected,
      isFalse,
    );
  });

  testWidgets('sheet shows all seven category chips and toggling selects/deselects', (
    tester,
  ) async {
    // §3.2.3 — multi-select; tapping an active chip deselects it.
    useTallSurface(tester);
    final harness = await buildHarness();
    await openSheet(tester, harness.container);
    for (final category in kSearchCategoryOptions) {
      expect(find.byKey(Key('categoryChip_$category')), findsOneWidget);
    }
    await tester.tap(find.byKey(const Key('categoryChip_road')));
    await tester.pump();
    expect(
      tester.widget<FilterChip>(find.byKey(const Key('categoryChip_road'))).selected,
      isTrue,
    );
    await tester.tap(find.byKey(const Key('categoryChip_road')));
    await tester.pump();
    expect(
      tester.widget<FilterChip>(find.byKey(const Key('categoryChip_road'))).selected,
      isFalse,
    );
  });

  testWidgets('within radius reveals the radius slider and any distance hides it', (
    tester,
  ) async {
    // §3.2.4 — 'Within radius' shows distanceSlider; 'Any distance' hides it.
    useTallSurface(tester);
    final harness = await buildHarness();
    await openSheet(tester, harness.container);
    expect(find.byKey(const Key('distanceAny')), findsOneWidget);
    expect(find.byKey(const Key('distanceWithin')), findsOneWidget);
    expect(find.byKey(const Key('distanceSlider')), findsNothing);
    await tester.tap(find.byKey(const Key('distanceWithin')));
    await tester.pump();
    expect(find.byKey(const Key('distanceSlider')), findsOneWidget);
    await tester.tap(find.byKey(const Key('distanceAny')));
    await tester.pump();
    expect(find.byKey(const Key('distanceSlider')), findsNothing);
  });

  testWidgets('tapping Past 7 days selects the date chip', (tester) async {
    // §3.2.5 — date preset chip single-select.
    useTallSurface(tester);
    final harness = await buildHarness();
    await openSheet(tester, harness.container);
    for (final key in <String>[
      'dateChip_anyTime',
      'dateChip_past24Hours',
      'dateChip_past7Days',
      'dateChip_past30Days',
    ]) {
      expect(find.byKey(Key(key)), findsOneWidget);
    }
    await tester.tap(find.byKey(const Key('dateChip_past7Days')));
    await tester.pump();
    expect(
      tester.widget<ChoiceChip>(find.byKey(const Key('dateChip_past7Days'))).selected,
      isTrue,
    );
    expect(
      tester.widget<ChoiceChip>(find.byKey(const Key('dateChip_anyTime'))).selected,
      isFalse,
    );
  });

  testWidgets('Reset clears all local selections in the sheet', (tester) async {
    // §3.2.6 — Reset reverts local selections without popping the sheet.
    useTallSurface(tester);
    final harness = await buildHarness();
    await openSheet(tester, harness.container);
    await tester.tap(find.byKey(const Key('statusChip_resolved')));
    await tester.tap(find.byKey(const Key('categoryChip_road')));
    await tester.tap(find.byKey(const Key('categoryChip_water')));
    await tester.tap(find.byKey(const Key('distanceWithin')));
    await tester.tap(find.byKey(const Key('dateChip_past7Days')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('resetFiltersButton')));
    await tester.pump();
    expect(
      tester.widget<ChoiceChip>(find.byKey(const Key('statusChip_resolved'))).selected,
      isFalse,
    );
    expect(
      tester.widget<FilterChip>(find.byKey(const Key('categoryChip_road'))).selected,
      isFalse,
    );
    expect(
      tester.widget<ChoiceChip>(find.byKey(const Key('dateChip_past7Days'))).selected,
      isFalse,
    );
    expect(find.byKey(const Key('distanceSlider')), findsNothing);
  });

  testWidgets('Show results pops the sheet and updates the provider', (tester) async {
    // §3.2.7 — applied selection lands in searchFiltersProvider with isActive true.
    useTallSurface(tester);
    final harness = await buildHarness();
    await openSheet(tester, harness.container);
    await tester.tap(find.byKey(const Key('statusChip_resolved')));
    await tester.tap(find.byKey(const Key('categoryChip_road')));
    await tester.tap(find.byKey(const Key('categoryChip_water')));
    await tester.tap(find.byKey(const Key('distanceWithin')));
    await tester.tap(find.byKey(const Key('dateChip_past7Days')));
    await tester.pump();
    // F-E sheet robustness: make sure the apply button is on-screen before
    // tapping it (the sheet can overflow on small surfaces).
    await tester.ensureVisible(find.byKey(const Key('applyFiltersButton')));
    await tester.tap(find.byKey(const Key('applyFiltersButton')));
    await tester.pumpAndSettle();

    final filters = harness.container.read(searchFiltersProvider);
    expect(filters.status, 'resolved');
    expect(filters.categories, containsAll(<String>['road', 'water']));
    expect(filters.distanceOption, SearchDistanceOption.within);
    expect(filters.radiusKm, 5.0);
    expect(filters.datePreset, SearchDatePreset.past7Days);
    expect(filters.isActive, isTrue);
  });

  testWidgets('barrier-tap dismiss returns null and leaves the provider unchanged', (
    tester,
  ) async {
    // §3.2.8 — dismissing the sheet discards local selections.
    useTallSurface(tester);
    final harness = await buildHarness();
    await openSheet(tester, harness.container);
    await tester.tap(find.byKey(const Key('statusChip_resolved')));
    await tester.pump();
    await tester.tapAt(const Offset(500, 50));
    await tester.pumpAndSettle();
    final filters = harness.container.read(searchFiltersProvider);
    expect(filters.status, isNull);
    expect(filters.isActive, isFalse);
  });

  testWidgets('Clear filters resets the provider and re-runs the last query', (
    tester,
  ) async {
    // §3.2.9 — Clear filters resets filters and re-runs with null/empty args.
    final harness = await buildHarness();
    harness.container.read(searchFiltersProvider.notifier).setStatus('resolved');
    harness
        .container
        .read(searchFiltersProvider.notifier)
        .setDatePreset(SearchDatePreset.past7Days);
    await tester.pumpWidget(wrap(harness.container));
    await tester.enterText(find.byKey(const Key('searchField')), 'pothole');
    await pumpSearch(tester);
    expect(find.text('Clear filters'), findsOneWidget);
    expect(find.byKey(const Key('clearFiltersButton')), findsOneWidget);

    await tester.tap(find.byKey(const Key('clearFiltersButton')));
    await pumpSearch(tester);

    expect(harness.container.read(searchFiltersProvider).isActive, isFalse);
    expect(harness.repo.lastQuery, 'pothole');
    expect(harness.repo.lastStatus, isNull);
    expect(harness.repo.lastCategories, isEmpty);
    expect(harness.repo.lastRadiusKm, isNull);
    expect(harness.repo.lastCreatedAfter, isNull);
    expect(harness.repo.lastCreatedBefore, isNull);
  });

  testWidgets('active filters are passed to the repository exactly', (tester) async {
    // §3.2.10 — status/categories/radiusKm/createdAfter/createdBefore captured.
    final harness = await buildHarness();
    final notifier = harness.container.read(searchFiltersProvider.notifier);
    notifier.setStatus('resolved');
    notifier.toggleCategory('road');
    notifier.toggleCategory('water');
    notifier.setDistanceOption(SearchDistanceOption.within);
    notifier.setRadiusKm(5.0);
    notifier.setDatePreset(SearchDatePreset.past7Days);
    await tester.pumpWidget(wrap(harness.container));
    await tester.enterText(find.byKey(const Key('searchField')), 'pothole');
    await pumpSearch(tester);

    expect(harness.repo.lastQuery, 'pothole');
    expect(harness.repo.lastStatus, 'resolved');
    expect(harness.repo.lastCategories, <String>['road', 'water']);
    expect(harness.repo.lastRadiusKm, 5.0);
    expect(harness.repo.lastCreatedAfter, isNotNull);
    expect(harness.repo.lastCreatedBefore, isNull);
    expect(harness.repo.lastLatitude, 19.1136);
    expect(harness.repo.lastLongitude, 72.8697);
  });

  testWidgets('no active filters passes defaults to the repository', (tester) async {
    // §3.2.11 — regression: unfiltered search passes null/empty filter args.
    final harness = await buildHarness();
    await tester.pumpWidget(wrap(harness.container));
    await tester.enterText(find.byKey(const Key('searchField')), 'pothole');
    await pumpSearch(tester);

    expect(harness.repo.lastQuery, 'pothole');
    expect(harness.repo.lastStatus, isNull);
    expect(harness.repo.lastCategories, isEmpty);
    expect(harness.repo.lastRadiusKm, isNull);
    expect(harness.repo.lastCreatedAfter, isNull);
    expect(harness.repo.lastCreatedBefore, isNull);
  });

  testWidgets('results still render as issue cards when filters are active', (
    tester,
  ) async {
    // §3.2.12 — filtered results render normally.
    final harness = await buildHarness();
    harness.repo.result = <Issue>[
      buildIssue(id: 1, title: 'Filtered pothole card'),
      buildIssue(id: 2, title: 'Filtered water card'),
    ];
    harness.container.read(searchFiltersProvider.notifier).setStatus('resolved');
    harness
        .container
        .read(searchFiltersProvider.notifier)
        .setDatePreset(SearchDatePreset.past7Days);
    await tester.pumpWidget(wrap(harness.container));
    await tester.enterText(find.byKey(const Key('searchField')), 'filtered');
    await pumpSearch(tester);
    expect(find.text('Filtered pothole card'), findsOneWidget);
    expect(find.text('Filtered water card'), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
  });

  test('SearchFilters reset returns defaults and isActive reflects state', () {
    // §3.2.14 — unit test for the domain value object.
    const defaults = SearchFilters();
    expect(defaults.isActive, isFalse);
    expect(defaults.status, isNull);
    expect(defaults.categories, isEmpty);
    expect(defaults.distanceOption, SearchDistanceOption.any);
    expect(defaults.radiusKm, 5.0);
    expect(defaults.datePreset, SearchDatePreset.anyTime);
    expect(defaults.reset(), const SearchFilters());

    expect(defaults.copyWith(status: 'resolved').isActive, isTrue);
    expect(defaults.copyWith(categories: const <String>['road']).isActive, isTrue);
    expect(
      defaults.copyWith(distanceOption: SearchDistanceOption.within).isActive,
      isTrue,
    );
    expect(
      defaults.copyWith(datePreset: SearchDatePreset.past30Days).isActive,
      isTrue,
    );
  });

  testWidgets('ward chip applies the slug and Any Ward resets it to null', (
    tester,
  ) async {
    // F-E: the filter sheet lists wards from wardListNotifierProvider; picking
    // one and applying it lands in searchFiltersProvider.ward; 'Any Ward'
    // clears it back to null.
    useTallSurface(tester);
    final harness = await buildHarness();
    await openSheet(tester, harness.container);

    expect(
      find.byKey(const Key('wardChip_ward-45-urban-central')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('wardChip_ward-12-old-town')), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const Key('wardChip_ward-45-urban-central')),
    );
    await tester.tap(find.byKey(const Key('wardChip_ward-45-urban-central')));
    await tester.pump();

    await tester.ensureVisible(find.byKey(const Key('applyFiltersButton')));
    await tester.tap(find.byKey(const Key('applyFiltersButton')));
    await tester.pumpAndSettle();

    expect(
      harness.container.read(searchFiltersProvider).ward,
      'ward-45-urban-central',
    );

    // Reopen the sheet and reset the ward via 'Any Ward'.
    await openSheet(tester, harness.container);
    await tester.tap(find.text('Any Ward'));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('applyFiltersButton')));
    await tester.tap(find.byKey(const Key('applyFiltersButton')));
    await tester.pumpAndSettle();

    expect(harness.container.read(searchFiltersProvider).ward, isNull);
  });
}
