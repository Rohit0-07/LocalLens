import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/search_filters.dart';

final searchFiltersProvider =
    NotifierProvider<SearchFiltersNotifier, SearchFilters>(
  SearchFiltersNotifier.new,
);

class SearchFiltersNotifier extends Notifier<SearchFilters> {
  @override
  SearchFilters build() => const SearchFilters();

  void setStatus(String? status) {
    state = state.copyWith(status: status);
  }

  void toggleCategory(String category) {
    final categories = List<String>.of(state.categories);
    if (categories.contains(category)) {
      categories.remove(category);
    } else {
      categories.add(category);
    }
    state = state.copyWith(categories: categories);
  }

  void setDistanceOption(SearchDistanceOption option) {
    state = state.copyWith(distanceOption: option);
  }

  void setRadiusKm(double km) {
    state = state.copyWith(radiusKm: km);
  }

  void setDatePreset(SearchDatePreset preset) {
    state = state.copyWith(datePreset: preset);
  }

  void reset() {
    state = const SearchFilters();
  }

  void apply(SearchFilters filters) {
    state = filters;
  }
}
