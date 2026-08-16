import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/map_api.dart';
import '../../../../core/services/location_service.dart';

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

class MapState {
  final AsyncValue<List<MapPin>> pins;
  final MapPin? selectedPin;
  final String selectedCategory;
  final String selectedStatus;
  final MapBounds bounds;
  final bool isBoundsDirty;
  final double? initialLat;
  final double? initialLng;

  const MapState({
    this.pins = const AsyncValue.loading(),
    this.selectedPin,
    this.selectedCategory = 'all',
    this.selectedStatus = 'all',
    this.bounds = const MapBounds(
      minLat: 19.0760 - 0.05,
      maxLat: 19.0760 + 0.05,
      minLng: 72.8777 - 0.05,
      maxLng: 72.8777 + 0.05,
    ),
    this.isBoundsDirty = false,
    this.initialLat,
    this.initialLng,
  });

  MapState copyWith({
    AsyncValue<List<MapPin>>? pins,
    MapPin? Function()? selectedPin,
    String? selectedCategory,
    String? selectedStatus,
    MapBounds? bounds,
    bool? isBoundsDirty,
    double? initialLat,
    double? initialLng,
  }) {
    return MapState(
      pins: pins ?? this.pins,
      selectedPin: selectedPin != null ? selectedPin() : this.selectedPin,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedStatus: selectedStatus ?? this.selectedStatus,
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

  MapPinsNotifier(this._mapApi, this._locationService) : super(const MapState()) {
    _initLocationAndFetch();
  }

  Future<void> _initLocationAndFetch() async {
    final pos = await _locationService.getCurrentPosition();
    if (pos != null) {
      final bounds = MapBounds(
        minLat: pos.latitude - 0.05,
        maxLat: pos.latitude + 0.05,
        minLng: pos.longitude - 0.05,
        maxLng: pos.longitude + 0.05,
      );
      state = state.copyWith(
        bounds: bounds,
        initialLat: pos.latitude,
        initialLng: pos.longitude,
      );
    } else {
      state = state.copyWith(
        initialLat: 19.0760,
        initialLng: 72.8777,
      );
    }
    fetchPins();
  }

  Future<void> fetchPins() async {
    state = state.copyWith(
      pins: const AsyncValue.loading(),
      isBoundsDirty: false,
    );
    try {
      final fetchedPins = await _mapApi.getMapPins(
        minLat: state.bounds.minLat,
        maxLat: state.bounds.maxLat,
        minLng: state.bounds.minLng,
        maxLng: state.bounds.maxLng,
        category: state.selectedCategory,
        status: state.selectedStatus,
      );
      state = state.copyWith(
        pins: AsyncValue.data(fetchedPins),
        isBoundsDirty: false,
      );
    } catch (e, st) {
      state = state.copyWith(
        pins: AsyncValue.error(e, st),
        isBoundsDirty: false,
      );
    }
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

  void updateBounds(MapBounds newBounds) {
    if (state.bounds == newBounds) return;
    state = state.copyWith(bounds: newBounds, isBoundsDirty: true);
  }

  void searchThisArea() {
    fetchPins();
  }

  /// Called by the map screen once the user's GPS position is resolved.
  /// Updates the bounds to a ~5 km radius centred on [lat],[lng] then fetches.
  void fetchPinsForCenter(double lat, double lng) {
    const delta = 0.05; // ~5.5 km at equator
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
