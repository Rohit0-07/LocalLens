import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lens/core/router/route_paths.dart';
import 'package:local_lens/features/feed/domain/issue.dart';
import 'package:local_lens/features/feed/presentation/feed_providers.dart';
import 'package:local_lens/features/feed/presentation/feed_screen.dart';
import 'package:local_lens/features/search/data/recent_search_store.dart';
import 'package:local_lens/features/search/domain/search_repository.dart';
import 'package:local_lens/features/search/presentation/search_providers.dart';
import 'package:local_lens/features/search/presentation/search_screen.dart';
import 'package:local_lens/shared/widgets/skeleton_list.dart';

import '../../helpers.dart';

class FakeSearchRepository implements SearchRepository {
  FakeSearchRepository({this.completer});

  final Completer<List<Issue>>? completer;
  List<Issue> result = const [];
  Object? error;
  int searchCount = 0;
  String? lastQuery;
  final List<String> queries = [];

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
  }) async {
    searchCount += 1;
    lastQuery = query;
    queries.add(query);
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

Future<
  ({
    ProviderContainer container,
    FakeSearchRepository repo,
    FakeRecentSearchStore store,
  })
>
buildHarness({bool seedRecents = false, List<Issue> feedIssues = const []}) async {
  final repo = FakeSearchRepository();
  final store = FakeRecentSearchStore();
  if (seedRecents) {
    await store.add('pothole');
    await store.add('graffiti');
  }
  final container = ProviderContainer(
    overrides: [
      searchRepositoryProvider.overrideWithValue(repo),
      recentSearchStoreProvider.overrideWithValue(store),
      feedRepositoryProvider.overrideWithValue(FakeFeedRepository(issues: feedIssues)),
    ],
  );
  addTearDown(container.dispose);
  return (container: container, repo: repo, store: store);
}

void main() {
  test('RoutePaths.search is /search', () {
    expect(RoutePaths.search, '/search');
  });

  group('FakeRecentSearchStore', () {
    test('caps at five newest-first and dedupes case-insensitively', () async {
      final store = FakeRecentSearchStore();
      for (final q in <String>['a', 'b', 'c', 'd', 'e', 'f']) {
        await store.add(q);
      }
      expect(store.load(), <String>['f', 'e', 'd', 'c', 'b']);
      await store.add('E');
      expect(store.load(), <String>['E', 'f', 'd', 'c', 'b']);
      await store.clear();
      expect(store.load(), isEmpty);
    });

    test('trims stored queries and ignores whitespace-only', () async {
      final store = FakeRecentSearchStore();
      await store.add(' pothole ');
      await store.add('pothole');
      await store.add('   ');
      expect(store.load(), <String>['pothole']);
    });
  });

  testWidgets('non-empty query fires one debounced search with exact query', (
    tester,
  ) async {
    final harness = await buildHarness();
    await tester.pumpWidget(wrap(harness.container));
    await tester.enterText(find.byKey(const Key('searchField')), 'Pothole');
    await pumpSearch(tester);
    expect(harness.repo.queries, <String>['Pothole']);
    expect(harness.repo.searchCount, 1);
  });

  testWidgets('results render as issue cards', (tester) async {
    final harness = await buildHarness();
    harness.repo.result = <Issue>[
      buildIssue(id: 1, title: 'Alpha pothole'),
      buildIssue(id: 2, title: 'Beta pothole'),
    ];
    await tester.pumpWidget(wrap(harness.container));
    await tester.enterText(find.byKey(const Key('searchField')), 'pothole');
    await pumpSearch(tester);
    expect(find.text('Alpha pothole'), findsOneWidget);
    expect(find.text('Beta pothole'), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
  });

  testWidgets('whitespace-only and empty input never fire a search', (
    tester,
  ) async {
    final harness = await buildHarness();
    await tester.pumpWidget(wrap(harness.container));
    await tester.enterText(find.byKey(const Key('searchField')), '   ');
    await pumpSearch(tester);
    await tester.enterText(find.byKey(const Key('searchField')), '');
    await pumpSearch(tester);
    expect(harness.repo.searchCount, 0);
  });

  testWidgets('empty results show empty state', (tester) async {
    final harness = await buildHarness();
    await tester.pumpWidget(wrap(harness.container));
    await tester.enterText(find.byKey(const Key('searchField')), 'zzz');
    await pumpSearch(tester);
    expect(find.text('No issues found'), findsOneWidget);
    expect(find.text('Try a different keyword or adjust your filters.'), findsOneWidget);
  });

  testWidgets('recent searches render and tapping one runs it', (tester) async {
    final harness = await buildHarness(seedRecents: true);
    await tester.pumpWidget(wrap(harness.container));
    expect(find.text('Recent searches'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);
    expect(find.text('pothole'), findsOneWidget);
    expect(find.text('graffiti'), findsOneWidget);

    await tester.tap(find.text('pothole'));
    await pumpSearch(tester);
    final field = tester.widget<TextField>(
      find.byKey(const Key('searchField')),
    );
    expect(field.controller!.text, 'pothole');
    expect(harness.repo.lastQuery, 'pothole');
    expect(harness.repo.searchCount, greaterThanOrEqualTo(1));
  });

  testWidgets('Clear empties recents and shows preloaded feed', (tester) async {
    final harness = await buildHarness(
      seedRecents: true,
      feedIssues: <Issue>[buildIssue(id: 7, title: 'Preloaded pothole')],
    );
    await tester.pumpWidget(wrap(harness.container));
    await tester.tap(find.byKey(const Key('clearRecentSearches')));
    await pumpSearch(tester);
    expect(harness.store.load(), isEmpty);
    expect(find.text('Recent searches'), findsNothing);
    expect(find.text('Preloaded pothole'), findsOneWidget);
  });

  testWidgets('error shows Search unavailable and Retry re-runs', (
    tester,
  ) async {
    final harness = await buildHarness();
    harness.repo.error = StateError('offline');
    harness.repo.result = <Issue>[
      buildIssue(id: 1, title: 'Recovered pothole'),
    ];
    await tester.pumpWidget(wrap(harness.container));
    await tester.enterText(find.byKey(const Key('searchField')), 'pothole');
    await pumpSearch(tester);
    expect(find.text('Search unavailable'), findsOneWidget);

    harness.repo.error = null;
    await tester.tap(find.text('Retry'));
    await pumpSearch(tester);
    expect(find.text('Recovered pothole'), findsOneWidget);
    expect(harness.repo.searchCount, 2);
  });

  testWidgets('initial state shows preloaded feed', (tester) async {
    final harness = await buildHarness(
      feedIssues: <Issue>[buildIssue(id: 1, title: 'Nearby pothole')],
    );
    await tester.pumpWidget(wrap(harness.container));
    await pumpSearch(tester);
    expect(find.text('Nearby pothole'), findsOneWidget);
    expect(find.text('No issues yet'), findsNothing);
  });

  testWidgets('initial state shows feed empty message when no issues', (
    tester,
  ) async {
    final harness = await buildHarness();
    await tester.pumpWidget(wrap(harness.container));
    await pumpSearch(tester);
    expect(find.text('No issues yet'), findsOneWidget);
  });

  testWidgets('rapid keystrokes within window fire exactly one search', (
    tester,
  ) async {
    final harness = await buildHarness();
    await tester.pumpWidget(wrap(harness.container));
    await tester.enterText(find.byKey(const Key('searchField')), 'p');
    await tester.enterText(find.byKey(const Key('searchField')), 'po');
    await pumpSearch(tester);
    expect(harness.repo.searchCount, 1);
    expect(harness.repo.lastQuery, 'po');
  });

  testWidgets('FeedScreen app bar shows the search icon', (tester) async {
    final container = ProviderContainer(
      overrides: [
        feedRepositoryProvider.overrideWithValue(
          FakeFeedRepository(issues: const []),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: FeedScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.search), findsOneWidget);
    final button = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.search),
        matching: find.byType(IconButton),
      ),
    );
    expect(button.tooltip, 'Search');
  });

  testWidgets('search field has key, hint and autofocus', (tester) async {
    final harness = await buildHarness();
    await tester.pumpWidget(wrap(harness.container));
    await tester.pump();
    expect(find.byKey(const Key('searchField')), findsOneWidget);
    expect(find.text('Search issues, categories, wards'), findsOneWidget);
    final field = tester.widget<TextField>(
      find.byKey(const Key('searchField')),
    );
    expect(field.autofocus, isTrue);
  });

  testWidgets('query is trimmed before search and recorded', (tester) async {
    final harness = await buildHarness();
    await tester.pumpWidget(wrap(harness.container));
    await tester.enterText(find.byKey(const Key('searchField')), '  pothole  ');
    await pumpSearch(tester);
    expect(harness.repo.lastQuery, 'pothole');
    expect(harness.repo.searchCount, 1);
    expect(harness.store.load(), <String>['pothole']);
  });

  testWidgets('tapping a recent search renders its results', (tester) async {
    final harness = await buildHarness(seedRecents: true);
    harness.repo.result = <Issue>[buildIssue(id: 1, title: 'Prior pothole')];
    await tester.pumpWidget(wrap(harness.container));
    await tester.pump();
    expect(find.text('Recent searches'), findsOneWidget);

    await tester.tap(find.text('pothole'));
    await pumpSearch(tester);

    expect(harness.repo.lastQuery, 'pothole');
    expect(find.text('Prior pothole'), findsOneWidget);
    expect(find.text('Recent searches'), findsNothing);
  });

  testWidgets('shows skeleton list while search is in flight', (tester) async {
    final completer = Completer<List<Issue>>();
    final repo = FakeSearchRepository(completer: completer);
    final store = FakeRecentSearchStore();
    final container = ProviderContainer(
      overrides: [
        searchRepositoryProvider.overrideWithValue(repo),
        recentSearchStoreProvider.overrideWithValue(store),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(wrap(container));
    await tester.enterText(find.byKey(const Key('searchField')), 'pothole');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.byType(SkeletonList), findsOneWidget);
    expect(find.text('No issues found'), findsNothing);

    completer.complete(<Issue>[buildIssue(id: 1, title: 'Held pothole')]);
    await tester.pump();
    await pumpSearch(tester);
    expect(find.text('Held pothole'), findsOneWidget);
    expect(find.byType(SkeletonList), findsNothing);
  });
}
