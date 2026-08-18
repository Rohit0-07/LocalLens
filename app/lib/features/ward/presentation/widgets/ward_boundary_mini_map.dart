import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/ward_detail_out.dart';
import '../providers/ward_providers.dart';

/// Read-only mini map for the ward detail page.
///
/// Renders the OSM tile layer centred on the ward centre plus a center marker.
/// When the boundary feature has polygon data for this ward
/// ([wardBoundaryProvider]) the outer ring(s) are drawn as a [PolygonLayer];
/// otherwise a graceful "Boundary map coming soon" pill is overlaid on top of
/// the still-visible map. The map is purely presentational: all interaction is
/// disabled. [tileProvider] is a test seam — it defaults to the real network
/// tile provider.
class WardBoundaryMiniMap extends ConsumerWidget {
  const WardBoundaryMiniMap({
    super.key,
    required this.ward,
    this.tileProvider,
  });

  final WardDetailOut ward;

  /// Injectable tile provider so widget tests stay hermetic.
  final TileProvider? tileProvider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final boundaryAsync = ref.watch(wardBoundaryProvider(ward.slug));
    final rings = boundaryAsync.valueOrNull ?? const <List<LatLng>>[];

    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 180,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(
                  ward.centerLatitude,
                  ward.centerLongitude,
                ),
                initialZoom: 13,
                interactionOptions:
                    const InteractionOptions(flags: InteractiveFlag.none),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.locallens.app',
                  maxNativeZoom: 19,
                  tileProvider: tileProvider ?? NetworkTileProvider(),
                ),
                if (rings.isNotEmpty)
                  PolygonLayer(
                    polygons: [
                      for (final ring in rings)
                        Polygon(
                          points: ring,
                          color: AppColors.brand.withValues(alpha: 0.15),
                          borderColor: AppColors.brand,
                          borderStrokeWidth: 2,
                        ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    Marker(
                      key: const Key('wardBoundaryCenterMarker'),
                      point: LatLng(
                        ward.centerLatitude,
                        ward.centerLongitude,
                      ),
                      width: 34,
                      height: 34,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.brand,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (rings.isEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 8,
                child: Center(
                  child: Container(
                    key: const Key('wardBoundaryFallback'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Text(
                      'Boundary map coming soon',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
