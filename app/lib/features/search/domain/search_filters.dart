enum SearchDatePreset { anyTime, past24Hours, past7Days, past30Days }

enum SearchDistanceOption { any, within }

class SearchFilters {
  const SearchFilters({
    this.status,
    this.categories = const <String>[],
    this.distanceOption = SearchDistanceOption.any,
    this.radiusKm = 5.0,
    this.datePreset = SearchDatePreset.anyTime,
  });

  static const Object _unset = Object();

  final String? status;
  final List<String> categories;
  final SearchDistanceOption distanceOption;
  final double radiusKm;
  final SearchDatePreset datePreset;

  bool get isActive =>
      status != null ||
      categories.isNotEmpty ||
      distanceOption == SearchDistanceOption.within ||
      datePreset != SearchDatePreset.anyTime;

  SearchFilters copyWith({
    Object? status = _unset,
    List<String>? categories,
    SearchDistanceOption? distanceOption,
    double? radiusKm,
    SearchDatePreset? datePreset,
  }) {
    return SearchFilters(
      status: identical(status, _unset) ? this.status : status as String?,
      categories: categories ?? this.categories,
      distanceOption: distanceOption ?? this.distanceOption,
      radiusKm: radiusKm ?? this.radiusKm,
      datePreset: datePreset ?? this.datePreset,
    );
  }

  SearchFilters reset() => const SearchFilters();
}

const kSearchStatusOptions = <String>[
  'unacknowledged',
  'under_review',
  'escalating',
  'forwarded',
  'pending_quorum',
  'resolved',
  'disputed',
];

const kSearchCategoryOptions = <String>[
  'road',
  'water',
  'power',
  'lighting',
  'waste',
  'sewage',
  'other',
];
