import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/map_api.dart';

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

  const MapState({
    this.pins = const AsyncValue.loading(),
    this.selectedPin,
    this.selectedCategory = 'all',
    this.selectedStatus = 'all',
    this.bounds = const MapBounds(
      minLat: 8.0,
      maxLat: 37.0,
      minLng: 68.0,
      maxLng: 97.0,
    ),
    this.isBoundsDirty = false,
  });

  MapState copyWith({
    AsyncValue<List<MapPin>>? pins,
    MapPin? Function()? selectedPin,
    String? selectedCategory,
    String? selectedStatus,
    MapBounds? bounds,
    bool? isBoundsDirty,
  }) {
    return MapState(
      pins: pins ?? this.pins,
      selectedPin: selectedPin != null ? selectedPin() : this.selectedPin,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      bounds: bounds ?? this.bounds,
      isBoundsDirty: isBoundsDirty ?? this.isBoundsDirty,
    );
  }
}

class MapPinsNotifier extends StateNotifier<MapState> {
  final MapApi _mapApi;

  MapPinsNotifier(this._mapApi) : super(const MapState()) {
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
}

final mapPinsNotifierProvider =
    StateNotifierProvider<MapPinsNotifier, MapState>((ref) {
  return MapPinsNotifier(ref.watch(mapApiProvider));
});
