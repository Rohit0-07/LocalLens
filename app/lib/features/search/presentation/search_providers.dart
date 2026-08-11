import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../../../core/storage/storage_providers.dart';
import '../../feed/domain/issue.dart';
import '../../feed/presentation/feed_providers.dart';
import '../data/recent_search_store.dart';
import '../data/search_api.dart';
import '../domain/search_filters.dart';
import '../domain/search_repository.dart';
import 'search_filters_provider.dart';

final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => SearchApi(ref.watch(apiClientProvider)),
);

final recentSearchStoreProvider = Provider<RecentSearchStore>(
  (ref) => HiveRecentSearchStore(ref.watch(localStoreProvider)),
);

final searchQueryProvider = StateProvider<String>((ref) => '');

final recentSearchesProvider =
    NotifierProvider<RecentSearchesNotifier, List<String>>(
  RecentSearchesNotifier.new,
);

final searchResultsProvider =
    AsyncNotifierProvider<SearchResultsNotifier, List<Issue>>(
  SearchResultsNotifier.new,
);

class RecentSearchesNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    return ref.watch(recentSearchStoreProvider).load();
  }

  Future<void> add(String q) async {
    await ref.read(recentSearchStoreProvider).add(q);
    state = ref.read(recentSearchStoreProvider).load();
  }

  Future<void> clear() async {
    await ref.read(recentSearchStoreProvider).clear();
    state = const <String>[];
  }
}

class SearchResultsNotifier extends AsyncNotifier<List<Issue>> {
  @override
  Future<List<Issue>> build() async {
    return const <Issue>[];
  }

  Future<void> runQuery(String q, {double? latitude, double? longitude}) async {
    final query = q.trim();
    if (query.isEmpty) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final filters = ref.read(searchFiltersProvider);
      double? effectiveLatitude = latitude;
      double? effectiveLongitude = longitude;
      double? radiusKm;
      if (filters.distanceOption == SearchDistanceOption.within) {
        radiusKm = filters.radiusKm;
        effectiveLatitude ??= defaultLatitude;
        effectiveLongitude ??= defaultLongitude;
      }
      final createdAfter = switch (filters.datePreset) {
        SearchDatePreset.anyTime => null,
        SearchDatePreset.past24Hours =>
          DateTime.now().toUtc().subtract(const Duration(hours: 24)),
        SearchDatePreset.past7Days =>
          DateTime.now().toUtc().subtract(const Duration(days: 7)),
        SearchDatePreset.past30Days =>
          DateTime.now().toUtc().subtract(const Duration(days: 30)),
      };
      final results = await ref
          .read(searchRepositoryProvider)
          .search(
            query: query,
            latitude: effectiveLatitude,
            longitude: effectiveLongitude,
            status: filters.status,
            categories: filters.categories,
            radiusKm: radiusKm,
            createdAfter: createdAfter,
          );
      await ref.read(recentSearchesProvider.notifier).add(query);
      return results;
    });
  }
}