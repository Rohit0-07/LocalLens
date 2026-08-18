import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../ward/domain/ward_summary_out.dart';
import '../../../ward/presentation/providers/ward_providers.dart';
import '../controllers/map_controller.dart';
import '../widgets/map_pin_preview_sheet.dart';
import '../widgets/ward_boundary_layer.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> with WidgetsBindingObserver {
  final MapController _mapController = MapController();

  // Mumbai / Ward 45 reference centre
  static const LatLng _defaultCenter = LatLng(19.0950, 72.8650);
  static const double _defaultZoom = 13.0;

  /// Periodic poll interval: picks up issues added via compose/outbox flush
  /// without touching the compose feature.
  static const Duration _pollInterval = Duration(seconds: 30);

  Timer? _pollTimer;

  static const List<Map<String, String>> _categories = [
    {'id': 'all', 'labelKey': 'feed_filter_all', 'key': 'mapFilterChip_all'},
    {'id': 'road', 'labelKey': 'cat_road', 'key': 'mapFilterChip_road'},
    {'id': 'water', 'labelKey': 'cat_water', 'key': 'mapFilterChip_water'},
    {'id': 'power', 'labelKey': 'cat_power', 'key': 'mapFilterChip_power'},
    {
      'id': 'sanitation',
      'labelKey': 'cat_sanitation',
      'key': 'mapFilterChip_sanitation',
    },
    {
      'id': 'lighting',
      'labelKey': 'cat_lighting',
      'key': 'mapFilterChip_lighting',
    },
    {'id': 'waste', 'labelKey': 'cat_waste', 'key': 'mapFilterChip_waste'},
    {'id': 'other', 'labelKey': 'cat_other', 'key': 'mapFilterChip_other'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      if (mounted) {
        ref.read(mapPinsNotifierProvider.notifier).refreshIfIdle();
      }
    });
    _centerOnUserLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      ref.read(mapPinsNotifierProvider.notifier).refreshIfIdle();
    }
  }

  Future<void> _centerOnUserLocation() async {
    try {
      final locationService = ref.read(locationServiceProvider);
      final position = await locationService.getCurrentPosition();
      if (position != null && mounted) {
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          14.0,
        );
        ref.read(mapPinsNotifierProvider.notifier).fetchPinsForCenter(
              position.latitude,
              position.longitude,
            );
      }
    } catch (_) {
      // Stay at default India centre
    }
  }

  Color _categoryPinColor(String category) => AppColors.pinColorFor(category);

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'road':
        return Icons.alt_route;
      case 'sanitation':
      case 'waste':
        return Icons.cleaning_services;
      case 'water':
        return Icons.water_drop;
      case 'power':
        return Icons.bolt;
      case 'lighting':
        return Icons.lightbulb;
      default:
        return Icons.place;
    }
  }

  /// Snapchat-style density color ramp: green → yellow → orange → red
  Color _heatmapColor(int density, double alpha) {
    if (density <= 1) return const Color(0xFF4CAF50).withValues(alpha: alpha);
    if (density <= 3) return const Color(0xFFFFC107).withValues(alpha: alpha);
    if (density <= 6) return const Color(0xFFFF9800).withValues(alpha: alpha);
    return const Color(0xFFF44336).withValues(alpha: alpha);
  }

  /// Fill opacity scales with density: 0.18 (sparse) → 0.68 (hotspot).
  double _heatmapOpacity(int density) =>
      0.18 + (density.clamp(0, 8) / 8.0) * 0.5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mapState = ref.watch(mapPinsNotifierProvider);
    final mapNotifier = ref.read(mapPinsNotifierProvider.notifier);
    final pins = mapState.filteredPins;
    final boundariesAsync = ref.watch(wardBoundariesProvider);
    final wardListAsync = ref.watch(wardListNotifierProvider);
    final rawWards = wardListAsync.valueOrNull?.items ?? [];
    final wards = rawWards.isNotEmpty
        ? rawWards
        : const [
            WardSummaryOut(
              slug: 'ward-45-urban-central',
              name: 'Ward 45, Urban Central',
              code: 'W-45',
              centerLatitude: 19.1136,
              centerLongitude: 72.8697,
              totalIssues: 24,
              activeIssues: 12,
              escalatedIssues: 3,
              resolvedIssues: 9,
              resolutionRatePct: 37.5,
            ),
            WardSummaryOut(
              slug: 'ward-12-metro-corridor',
              name: 'Ward 12, Metro Corridor',
              code: 'W-12',
              centerLatitude: 19.0760,
              centerLongitude: 72.8777,
              totalIssues: 16,
              activeIssues: 8,
              escalatedIssues: 2,
              resolvedIssues: 6,
              resolutionRatePct: 37.5,
            ),
          ];

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('map_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'My location (India GPS)',
            onPressed: _centerOnUserLocation,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: context.tr('action_retry'),
            onPressed: () => mapNotifier.fetchPins(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Real Free OpenStreetMap tile layer (0 API Usage) ─────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: _defaultZoom,
              onTap: (tapPos, point) {
                mapNotifier.clearSelectedPin();
                mapNotifier.clearSelectedWard();
              },
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

              // ── Snapchat-Style Density Heatmap Layer (area fill) ───────
              // One PolygonLayer per fixed 0.003° grid cell, filled with the
              // density color + interpolated opacity. Cells are non-overlapping
              // so there are no alpha-blend artifacts.
              if (mapState.displayMode == MapDisplayMode.heatmap)
                for (final cell in mapState.heatmapCells)
                  PolygonLayer(
                    key: Key('heatmapCell_${cell.latKey}_${cell.lngKey}'),
                    polygons: [
                      Polygon(
                        points: [
                          LatLng(cell.minLat, cell.minLng),
                          LatLng(cell.maxLat, cell.minLng),
                          LatLng(cell.maxLat, cell.maxLng),
                          LatLng(cell.minLat, cell.maxLng),
                        ],
                        color: _heatmapColor(
                          cell.density,
                          _heatmapOpacity(cell.density),
                        ),
                        borderColor: Colors.black.withValues(alpha: 0.06),
                        borderStrokeWidth: 1,
                      ),
                    ],
                  ),

              // ── Standard Pins View Layer ────────────────────────
              if (mapState.displayMode == MapDisplayMode.pins) ...[
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

              // ── Ward Map Layer ──────────────────────────────────
              if (mapState.displayMode == MapDisplayMode.wards) ...[
                WardBoundaryLayer(
                  wards: wards,
                  boundaries: boundariesAsync.valueOrNull ?? const [],
                ),
                MarkerLayer(
                  markers: wards.map((ward) {
                    final isSelected = mapState.selectedWard?.slug == ward.slug;
                    return Marker(
                      key: Key('wardMarker_${ward.slug}'),
                      point: LatLng(ward.centerLatitude, ward.centerLongitude),
                      width: 140,
                      height: 56,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => mapNotifier.selectWard(ward),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.brand
                                : colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.brand,
                              width: 1.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                ward.code.isNotEmpty ? ward.code : ward.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : colorScheme.onSurface,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    size: 12,
                                    color: isSelected
                                        ? Colors.white70
                                        : AppColors.urgent,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${ward.activeIssues} active',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontSize: 10,
                                      color: isSelected
                                          ? Colors.white
                                          : colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
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

          // ── Controls Header: Mode Switcher & Filter Chips ─────
          Positioned(
            top: 10,
            left: 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Map View Mode Segmented Switcher ──────────────
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ModePill(
                          icon: Icons.location_on,
                          label: 'Pins',
                          isSelected:
                              mapState.displayMode == MapDisplayMode.pins,
                          onTap: () => mapNotifier
                              .setDisplayMode(MapDisplayMode.pins),
                        ),
                        _ModePill(
                          icon: Icons.blur_on,
                          label: 'Heatmap',
                          isSelected:
                              mapState.displayMode == MapDisplayMode.heatmap,
                          onTap: () => mapNotifier
                              .setDisplayMode(MapDisplayMode.heatmap),
                        ),
                        _ModePill(
                          icon: Icons.domain,
                          label: 'Ward Map',
                          isSelected:
                              mapState.displayMode == MapDisplayMode.wards,
                          onTap: () => mapNotifier
                              .setDisplayMode(MapDisplayMode.wards),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // ── Category Filters (Pins / Heatmap view) ─────────
                if (mapState.displayMode != MapDisplayMode.wards)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((cat) {
                        final isSelected =
                            mapState.selectedCategory == cat['id'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: FilterChip(
                            key: Key(cat['key']!),
                            label: Text(context.tr(cat['labelKey']!)),
                            selected: isSelected,
                            showCheckmark: false,
                            backgroundColor:
                                colorScheme.surface.withValues(alpha: 0.9),
                            selectedColor:
                                AppColors.brand.withValues(alpha: 0.16),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.brand
                                  : colorScheme.outlineVariant,
                            ),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? AppColors.brand
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            onSelected: (selected) =>
                                mapNotifier.selectCategory(cat['id']!),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),

          // ── "Search this area" FAB ─────────────────────────────
          if (mapState.isBoundsDirty)
            Positioned(
              top: 110,
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
              top: 110,
              left: 16,
              right: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                color: theme.brightness == Brightness.dark
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
                            color: colorScheme.onSurface,
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

          // ── Heatmap Legend ────────────────────────────────────
          if (mapState.displayMode == MapDisplayMode.heatmap)
            Positioned(
              left: 16,
              bottom: 24,
              child: Material(
                color: colorScheme.surface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(12),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Density:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Text('Low', style: TextStyle(fontSize: 10)),
                      const SizedBox(width: 6),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFC107),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Text('Medium', style: TextStyle(fontSize: 10)),
                      const SizedBox(width: 6),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF9800),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Text('High', style: TextStyle(fontSize: 10)),
                      const SizedBox(width: 6),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF44336),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Text('Hotspot', style: TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
              ),
            ),

          // ── Empty state ────────────────────────────────────────
          if (mapState.pins.hasValue &&
              pins.isEmpty &&
              mapState.displayMode != MapDisplayMode.wards)
            Positioned(
              top: 130,
              left: 20,
              right: 20,
              child: Card(
                key: const Key('mapEmptyState'),
                color: colorScheme.surface.withValues(alpha: 0.92),
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
                        color: colorScheme.onSurfaceVariant,
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

          // ── Ward preview sheet ─────────────────────────────────
          if (mapState.selectedWard != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _WardPreviewSheet(
                ward: mapState.selectedWard!,
                onClose: () => mapNotifier.clearSelectedWard(),
              ),
            ),
        ],
      ),
    );
  }
}

class _ModePill extends StatelessWidget {
  const _ModePill({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brand : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WardPreviewSheet extends StatelessWidget {
  const _WardPreviewSheet({
    required this.ward,
    required this.onClose,
  });

  final WardSummaryOut ward;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 12, spreadRadius: 1),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.brand.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      ward.code.isNotEmpty ? ward.code : 'WARD',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.brand,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.resolved.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${ward.resolutionRatePct.toStringAsFixed(0)}% Resolved',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.resolved,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onClose,
                tooltip: context.tr('action_close'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            ward.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _WardStatPill(
                label: 'Active Issues',
                count: '${ward.activeIssues}',
                color: AppColors.urgent,
              ),
              const SizedBox(width: 8),
              _WardStatPill(
                label: 'Escalated',
                count: '${ward.escalatedIssues}',
                color: Colors.deepOrange,
              ),
              const SizedBox(width: 8),
              _WardStatPill(
                label: 'Resolved',
                count: '${ward.resolvedIssues}',
                color: AppColors.resolved,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                context.push(RoutePaths.wardDetailFor(ward.slug));
              },
              icon: const Icon(Icons.location_city, size: 18),
              label: const Text('View Ward Hub & Activity'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WardStatPill extends StatelessWidget {
  const _WardStatPill({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final String count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
