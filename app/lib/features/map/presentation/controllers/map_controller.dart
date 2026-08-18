import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/map_api.dart';
import '../../../../core/services/location_service.dart';
import '../../../ward/domain/ward_summary_out.dart';

enum MapDisplayMode {
  pins,
  heatmap,
  wards,
}

class MapBounds {
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  const MapBounds({
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapBounds &&
          runtimeType == other.runtimeType &&
          minLat == other.minLat &&
          maxLat == other.maxLat &&
          minLng == other.minLng &&
          maxLng == other.maxLng;

  @override
  int get hashCode =>
      minLat.hashCode ^ maxLat.hashCode ^ minLng.hashCode ^ maxLng.hashCode;
}

/// A fixed 0.003° grid cell (≈330 m) holding the density of pinned issues.
///
/// The cell is identified by its integer floor grid indices (the same indices
/// derived from pin coordinates), so the `heatmapCell_<lat>_<lng>` key always
/// matches what a test computes from the pin position. Bounds are derived from
/// the indices: `min = idx * cellSize`, `max = (idx + 1) * cellSize`.
class HeatmapCell {
  /// Floor grid index along latitude.
  final int latKey;

  /// Floor grid index along longitude.
  final int lngKey;

  final int density;

  const HeatmapCell({
    required this.latKey,
    required this.lngKey,
    required this.density,
  });

  static const double cellSize = 0.003;

  double get minLat => latKey * cellSize;
  double get maxLat => (latKey + 1) * cellSize;
  double get minLng => lngKey * cellSize;
  double get maxLng => (lngKey + 1) * cellSize;
}

class MapState {
  final AsyncValue<List<MapPin>> pins;
  final MapPin? selectedPin;
  final WardSummaryOut? selectedWard;
  final String selectedCategory;
  final String selectedStatus;
  final MapDisplayMode displayMode;
  final MapBounds bounds;
  final bool isBoundsDirty;
  final double? initialLat;
  final double? initialLng;

  const MapState({
    this.pins = const AsyncValue.loading(),
    this.selectedPin,
    this.selectedWard,
    this.selectedCategory = 'all',
    this.selectedStatus = 'all',
    this.displayMode = MapDisplayMode.pins,
    this.bounds = const MapBounds(
      minLat: 19.1136 - 0.08,
      maxLat: 19.1136 + 0.08,
      minLng: 72.8697 - 0.08,
      maxLng: 72.8697 + 0.08,
    ),
    this.isBoundsDirty = false,
    this.initialLat = 19.1136,
    this.initialLng = 72.8697,
  });

  List<MapPin> get filteredPins {
    final list = pins.valueOrNull ?? [];
    return list.where((pin) {
      if (selectedCategory != 'all' &&
          pin.category.toLowerCase() != selectedCategory.toLowerCase()) {
        return false;
      }
      if (selectedStatus != 'all' &&
          pin.status.toLowerCase() != selectedStatus.toLowerCase()) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Clusters filteredPins into fixed grid cells for density-based heatmap
  /// rendering. Uses ~0.003° grid cells (~330m) for granular density
  /// visualization. Cell bounds come from the integer floor grid, so cells are
  /// deterministic and non-overlapping.
  List<HeatmapCell> get heatmapCells {
    final pinList = filteredPins;
    if (pinList.isEmpty) return const [];

    const cellSize = 0.003; // ~330m grid cells
    final Map<String, List<MapPin>> grid = {};

    for (final pin in pinList) {
      final cellLat = (pin.latitude / cellSize).floor();
      final cellLng = (pin.longitude / cellSize).floor();
      final key = '$cellLat:$cellLng';
      grid.putIfAbsent(key, () => []).add(pin);
    }

    return grid.entries.map((entry) {
      final pins = entry.value;
      final cellLat = (pins.first.latitude / cellSize).floor();
      final cellLng = (pins.first.longitude / cellSize).floor();
      return HeatmapCell(
        latKey: cellLat,
        lngKey: cellLng,
        density: pins.length,
      );
    }).toList();
  }

  MapState copyWith({
    AsyncValue<List<MapPin>>? pins,
    MapPin? Function()? selectedPin,
    WardSummaryOut? Function()? selectedWard,
    String? selectedCategory,
    String? selectedStatus,
    MapDisplayMode? displayMode,
    MapBounds? bounds,
    bool? isBoundsDirty,
    double? initialLat,
    double? initialLng,
  }) {
    return MapState(
      pins: pins ?? this.pins,
      selectedPin: selectedPin != null ? selectedPin() : this.selectedPin,
      selectedWard: selectedWard != null ? selectedWard() : this.selectedWard,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      displayMode: displayMode ?? this.displayMode,
      bounds: bounds ?? this.bounds,
      isBoundsDirty: isBoundsDirty ?? this.isBoundsDirty,
      initialLat: initialLat ?? this.initialLat,
      initialLng: initialLng ?? this.initialLng,
    );
  }
}

class MapPinsNotifier extends StateNotifier<MapState> {
  final MapApi _mapApi;
  final LocationService _locationService;

  /// Debounce window for viewport-triggered refetches (rapid pan/zoom coalesce
  /// into a single fetch).
  static const Duration _debounceDelay = Duration(milliseconds: 800);

  Timer? _debounceTimer;

  /// Guards against stacked network calls: debounce/refresh no-op while a
  /// fetch is in flight.
  bool _fetching = false;

  MapPinsNotifier(this._mapApi, this._locationService) : super(const MapState()) {
    _initLocationAndFetch();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _initLocationAndFetch() async {
    final pos = await _locationService.getCurrentPosition();
    if (pos != null) {
      final bounds = MapBounds(
        minLat: pos.latitude - 0.08,
        maxLat: pos.latitude + 0.08,
        minLng: pos.longitude - 0.08,
        maxLng: pos.longitude + 0.08,
      );
      state = state.copyWith(
        bounds: bounds,
        initialLat: pos.latitude,
        initialLng: pos.longitude,
      );
    } else {
      state = state.copyWith(
        initialLat: 19.1136,
        initialLng: 72.8697,
      );
    }
    fetchPins();
  }

  Future<void> fetchPins() async {
    if (_fetching) return;
    _fetching = true;
    state = state.copyWith(
      pins: const AsyncValue.loading(),
      isBoundsDirty: false,
    );
    try {
      var fetchedPins = await _mapApi.getMapPins(
        minLat: state.bounds.minLat,
        maxLat: state.bounds.maxLat,
        minLng: state.bounds.minLng,
        maxLng: state.bounds.maxLng,
        category: state.selectedCategory,
        status: state.selectedStatus,
      );

      // If no pins found in the immediate local bounding box and filter is 'all',
      // query broad regional bounds so the user always sees available civic activity.
      if (fetchedPins.isEmpty &&
          state.selectedCategory == 'all' &&
          state.selectedStatus == 'all') {
        final broadPins = await _mapApi.getMapPins(
          minLat: 8.0,
          maxLat: 37.0,
          minLng: 68.0,
          maxLng: 97.0,
          category: state.selectedCategory,
          status: state.selectedStatus,
        );
        if (broadPins.isNotEmpty) {
          fetchedPins = broadPins;
        }
      }

      state = state.copyWith(
        pins: AsyncValue.data(fetchedPins),
        isBoundsDirty: false,
      );
    } catch (e, st) {
      state = state.copyWith(
        pins: AsyncValue.error(e, st),
        isBoundsDirty: false,
      );
    } finally {
      _fetching = false;
    }
  }

  void setDisplayMode(MapDisplayMode mode) {
    if (state.displayMode == mode) return;
    state = state.copyWith(
      displayMode: mode,
      selectedPin: () => null,
      selectedWard: () => null,
    );
  }

  void selectCategory(String category) {
    if (state.selectedCategory == category) return;
    state = state.copyWith(selectedCategory: category);
    fetchPins();
  }

  void selectStatus(String status) {
    if (state.selectedStatus == status) return;
    state = state.copyWith(selectedStatus: status);
    fetchPins();
  }

  void selectPin(MapPin? pin) {
    state = state.copyWith(selectedPin: () => pin);
  }

  void clearSelectedPin() {
    state = state.copyWith(selectedPin: () => null);
  }

  void selectWard(WardSummaryOut? ward) {
    state = state.copyWith(selectedWard: () => ward);
  }

  void clearSelectedWard() {
    state = state.copyWith(selectedWard: () => null);
  }

  void updateBounds(MapBounds newBounds) {
    if (state.bounds == newBounds) return;
    state = state.copyWith(bounds: newBounds, isBoundsDirty: true);
    // Debounced auto-refetch: rapid pan/zoom cancels and restarts the timer so
    // only one fetch fires once the viewport settles.
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDelay, () {
      if (!_fetching && !state.pins.isLoading) {
        fetchPins();
      }
    });
  }

  /// Refetches pins when idle (no in-flight request, data already loaded).
  ///
  /// Used by the periodic poll timer and the app-resume lifecycle hook so new
  /// issues (e.g. added via compose/outbox flush) show up without manual
  /// interaction. No-ops while loading/fetching.
  void refreshIfIdle() {
    if (state.pins.hasValue && !_fetching && !state.pins.isLoading) {
      fetchPins();
    }
  }

  void searchThisArea() {
    fetchPins();
  }

  /// Called by the map screen once the user's GPS position is resolved.
  /// Updates the bounds to a ~5 km radius centred on [lat],[lng] then fetches.
  void fetchPinsForCenter(double lat, double lng) {
    const delta = 0.08;
    final bounds = MapBounds(
      minLat: lat - delta,
      maxLat: lat + delta,
      minLng: lng - delta,
      maxLng: lng + delta,
    );
    state = state.copyWith(bounds: bounds, isBoundsDirty: false);
    fetchPins();
  }
}

final mapPinsNotifierProvider =
    StateNotifierProvider<MapPinsNotifier, MapState>((ref) {
  return MapPinsNotifier(
    ref.watch(mapApiProvider),
    ref.watch(locationServiceProvider),
  );
});

/// Fetches every ward's boundary ring for the ward-map mode.
///
/// Read-only, unauthenticated; the backend always returns 200 (empty list when
/// no wards exist). The map screen falls back to derived octagon rings per ward
/// when this is empty or fails.
final wardBoundariesProvider = FutureProvider<List<WardBoundary>>((ref) {
  return ref.watch(mapApiProvider).getWardBoundaries();
});
