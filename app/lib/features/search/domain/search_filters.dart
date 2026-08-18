enum SearchDatePreset { anyTime, past24Hours, past7Days, past30Days }

enum SearchDistanceOption { any, within }

class SearchFilters {
  const SearchFilters({
    this.status,
    this.categories = const <String>[],
    this.distanceOption = SearchDistanceOption.any,
    this.radiusKm = 5.0,
    this.datePreset = SearchDatePreset.anyTime,
    this.ward,
  });

  static const Object _unset = Object();

  final String? status;
  final List<String> categories;
  final SearchDistanceOption distanceOption;
  final double radiusKm;
  final SearchDatePreset datePreset;
  final String? ward;

  bool get isActive =>
      status != null ||
      categories.isNotEmpty ||
      distanceOption == SearchDistanceOption.within ||
      datePreset != SearchDatePreset.anyTime ||
      ward != null;

  SearchFilters copyWith({
    Object? status = _unset,
    List<String>? categories,
    SearchDistanceOption? distanceOption,
    double? radiusKm,
    SearchDatePreset? datePreset,
    Object? ward = _unset,
  }) {
    return SearchFilters(
      status: identical(status, _unset) ? this.status : status as String?,
      categories: categories ?? this.categories,
      distanceOption: distanceOption ?? this.distanceOption,
      radiusKm: radiusKm ?? this.radiusKm,
      datePreset: datePreset ?? this.datePreset,
      ward: identical(ward, _unset) ? this.ward : ward as String?,
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

