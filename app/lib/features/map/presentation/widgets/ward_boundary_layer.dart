import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../ward/domain/ward_summary_out.dart';
import '../../data/map_api.dart';

/// Renders one filled polygon per ward: the fetched boundary ring when
/// available, otherwise a deterministic octagon derived from the ward centre.
///
/// Every ward always draws a meaningful polygon (never a bare circle), so the
/// empty-wards-table and malformed-boundary cases degrade gracefully. Each
/// polygon is wrapped in its own [PolygonLayer] keyed `wardBoundary_<slug>` so
/// widget tests can target individual wards.
class WardBoundaryLayer extends StatelessWidget {
  const WardBoundaryLayer({
    super.key,
    required this.wards,
    required this.boundaries,
    this.fill = AppColors.brand,
  });

  final List<WardSummaryOut> wards;
  final List<WardBoundary> boundaries;
  final Color fill;

  /// Deterministic 8-point octagon ring around `(lat, lng)`.
  ///
  /// Radius is 0.02° in latitude and `0.02 / cos(lat)` in longitude so the
  /// ring stays ~2.2 km wide regardless of latitude — the same algorithm the
  /// backend uses for its fallback rings. Points are ordered clockwise
  /// starting at due north.
  static List<LatLng> derivedWardRing(double lat, double lng) {
    const radiusLat = 0.02;
    final radiusLng = 0.02 / math.cos(lat * math.pi / 180);
    const angles = [0.0, 45.0, 90.0, 135.0, 180.0, 225.0, 270.0, 315.0];
    return [
      for (final angle in angles)
        LatLng(
          lat + radiusLat * math.cos(angle * math.pi / 180),
          lng + radiusLng * math.sin(angle * math.pi / 180),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bySlug = {for (final b in boundaries) b.slug: b};
    return Stack(
      children: [
        for (final ward in wards)
          PolygonLayer(
            key: Key('wardBoundary_${ward.slug}'),
            polygons: [
              Polygon(
                points: bySlug[ward.slug]?.ring ??
                    derivedWardRing(ward.centerLatitude, ward.centerLongitude),
                color: fill.withValues(alpha: 0.12),
                borderColor: fill,
                borderStrokeWidth: 2,
                label: ward.code,
                labelStyle: const TextStyle(
                  color: AppColors.brand,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                labelPlacementCalculator:
                    const PolygonLabelPlacementCalculator.centroid(),
              ),
            ],
          ),
      ],
    );
  }
}