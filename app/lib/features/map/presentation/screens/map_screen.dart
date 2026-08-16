import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/map_controller.dart';
import '../widgets/map_pin_preview_sheet.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();

  // Mumbai as default centre — overridden immediately with real GPS
  static const LatLng _defaultCenter = LatLng(19.0760, 72.8777);
  static const double _defaultZoom = 13.0;

  static const List<Map<String, String>> _categories = [
    {'id': 'all', 'labelKey': 'feed_filter_all', 'key': 'mapFilterChip_all'},
    {'id': 'road', 'labelKey': 'cat_road', 'key': 'mapFilterChip_road'},
    {
      'id': 'sanitation',
      'labelKey': 'cat_sanitation',
      'key': 'mapFilterChip_sanitation',
    },
    {'id': 'water', 'labelKey': 'cat_water', 'key': 'mapFilterChip_water'},
    {
      'id': 'lighting',
      'labelKey': 'cat_lighting',
      'key': 'mapFilterChip_lighting',
    },
    {'id': 'other', 'labelKey': 'cat_other', 'key': 'mapFilterChip_other'},
  ];

  @override
  void initState() {
    super.initState();
    _centerOnUserLocation();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _centerOnUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      if (mounted) {
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          _defaultZoom,
        );
        // Fetch pins for the new user location bounds
        final bounds = _mapController.camera.visibleBounds;
        final mapNotifier = ref.read(mapPinsNotifierProvider.notifier);
        mapNotifier.updateBounds(
          MapBounds(
            minLat: bounds.southWest.latitude,
            maxLat: bounds.northEast.latitude,
            minLng: bounds.southWest.longitude,
            maxLng: bounds.northEast.longitude,
          ),
        );
        mapNotifier.fetchPins();
      }
    } catch (_) {
      // Stay at default centre; initial fetchPins() in notifier fires on construction.
    }
  }

  Color _categoryPinColor(String category) => AppColors.pinColorFor(category);

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'road':
        return Icons.alt_route;
      case 'sanitation':
        return Icons.cleaning_services;
      case 'water':
        return Icons.water_drop;
      case 'lighting':
        return Icons.lightbulb;
      default:
        return Icons.place;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapPinsNotifierProvider);
    final mapNotifier = ref.read(mapPinsNotifierProvider.notifier);
    final pins = mapState.pins.valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('map_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'My location',
            onPressed: _centerOnUserLocation,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => mapNotifier.fetchPins(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Real OpenStreetMap tile layer ──────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: _defaultZoom,
              onTap: (tapPos, point) => mapNotifier.clearSelectedPin(),
              onMapEvent: (event) {
                if (event is MapEventMoveEnd ||
                    event is MapEventScrollWheelZoom ||
                    event is MapEventDoubleTapZoomEnd ||
                    event is MapEventFlingAnimationEnd) {
                  final bounds = _mapController.camera.visibleBounds;
                  mapNotifier.updateBounds(
                    MapBounds(
                      minLat: bounds.southWest.latitude,
                      maxLat: bounds.northEast.latitude,
                      minLng: bounds.southWest.longitude,
                      maxLng: bounds.northEast.longitude,
                    ),
                  );
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.locallens.app',
                maxNativeZoom: 19,
              ),
              MarkerLayer(
                markers: pins.map((pin) {
                  final isSelected = mapState.selectedPin?.id == pin.id;
                  final color = _categoryPinColor(pin.category);
                  return Marker(
                    key: Key('mapPin_${pin.id}'),
                    point: LatLng(pin.latitude, pin.longitude),
                    width: isSelected ? 56 : 44,
                    height: isSelected ? 56 : 44,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => mapNotifier.selectPin(pin),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.black26,
                            width: isSelected ? 3 : 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: isSelected ? 10 : 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          _categoryIcon(pin.category),
                          size: isSelected ? 26 : 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // ── Non-blocking loading bar ───────────────────────────
          if (mapState.pins.isLoading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(minHeight: 3),
            ),

          // ── Category filter chips ──────────────────────────────
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = mapState.selectedCategory == cat['id'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      key: Key(cat['key']!),
                      label: Text(context.tr(cat['labelKey']!)),
                      selected: isSelected,
                      showCheckmark: false,
                      selectedColor: AppColors.brand.withValues(alpha: 0.14),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.brand
                            : Theme.of(context).colorScheme.outlineVariant,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppColors.brand
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      onSelected: (selected) =>
                          mapNotifier.selectCategory(cat['id']!),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // ── "Search this area" FAB ─────────────────────────────
          if (mapState.isBoundsDirty)
            Positioned(
              top: 70,
              left: 0,
              right: 0,
              child: Center(
                child: FloatingActionButton.extended(
                  key: const Key('searchThisAreaButton'),
                  onPressed: () => mapNotifier.searchThisArea(),
                  icon: const Icon(Icons.search),
                  label: Text(context.tr('map_search_area')),
                ),
              ),
            ),

          // ── Non-blocking error banner ─────────────────────────
          if (mapState.pins.hasError)
            Positioned(
              top: 68,
              left: 16,
              right: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkCard
                    : Colors.white,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.urgent.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.urgent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Failed to load map pins',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextButton(
                        key: const Key('mapErrorRetryButton'),
                        onPressed: () => mapNotifier.fetchPins(),
                        child: Text(context.tr('action_retry')),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Empty state ────────────────────────────────────────
          if (mapState.pins.hasValue && pins.isEmpty)
            Positioned(
              top: 130,
              left: 20,
              right: 20,
              child: Card(
                key: const Key('mapEmptyState'),
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: 0.92),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 16.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(context.tr('map_empty')),
                    ],
                  ),
                ),
              ),
            ),

          // ── Pin preview sheet ──────────────────────────────────
          if (mapState.selectedPin != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MapPinPreviewSheet(
                pin: mapState.selectedPin!,
                onClose: () => mapNotifier.clearSelectedPin(),
              ),
            ),
        ],
      ),
    );
  }
}
