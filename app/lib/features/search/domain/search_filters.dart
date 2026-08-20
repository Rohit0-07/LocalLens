enum SearchDatePreset { anyTime, past24Hours, past7Days, past30Days, custom }

enum SearchDistanceOption { any, within }

class SearchFilters {
  const SearchFilters({
    this.status,
    this.categories = const <String>[],
    this.distanceOption = SearchDistanceOption.any,
    this.radiusKm = 5.0,
    this.datePreset = SearchDatePreset.anyTime,
    this.startDate,
    this.endDate,
    this.ward,
    this.account,
  });

  static const Object _unset = Object();

  final String? status;
  final List<String> categories;
  final SearchDistanceOption distanceOption;
  final double radiusKm;
  final SearchDatePreset datePreset;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? ward;
  final String? account;

  bool get isActive =>
      status != null ||
      categories.isNotEmpty ||
      distanceOption == SearchDistanceOption.within ||
      datePreset != SearchDatePreset.anyTime ||
      startDate != null ||
      endDate != null ||
      (ward != null && ward!.isNotEmpty) ||
      (account != null && account!.isNotEmpty);

  SearchFilters copyWith({
    Object? status = _unset,
    List<String>? categories,
    SearchDistanceOption? distanceOption,
    double? radiusKm,
    SearchDatePreset? datePreset,
    Object? startDate = _unset,
    Object? endDate = _unset,
    Object? ward = _unset,
    Object? account = _unset,
  }) {
    return SearchFilters(
      status: identical(status, _unset) ? this.status : status as String?,
      categories: categories ?? this.categories,
      distanceOption: distanceOption ?? this.distanceOption,
      radiusKm: radiusKm ?? this.radiusKm,
      datePreset: datePreset ?? this.datePreset,
      startDate: identical(startDate, _unset)
          ? this.startDate
          : startDate as DateTime?,
      endDate:
          identical(endDate, _unset) ? this.endDate : endDate as DateTime?,
      ward: identical(ward, _unset) ? this.ward : ward as String?,
      account:
          identical(account, _unset) ? this.account : account as String?,
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
