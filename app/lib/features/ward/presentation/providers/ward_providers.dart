import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/network/network_providers.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../data/repositories/ward_repository.dart';
import '../../domain/ward_detail_out.dart';
import '../../domain/ward_list_response.dart';

final wardRepositoryProvider = Provider<WardRepository>((ref) {
  return WardRepositoryImpl(ref.watch(apiClientProvider));
});

final wardDetailNotifierProvider =
    FutureProvider.family.autoDispose<WardDetailOut, String>((ref, slug) async {
  final store = ref.read(localStoreProvider);
  final cachedJson = store.getWardDetailCache(slug);
  WardDetailOut? cachedDetail;
  if (cachedJson != null) {
    try {
      cachedDetail = WardDetailOut.fromJson(jsonDecode(cachedJson) as Map<String, dynamic>);
    } catch (_) {}
  }

  final repository = ref.read(wardRepositoryProvider);
  try {
    final freshDetail = await repository.getWardDetail(slug);
    try {
      await store.saveWardDetailCache(slug, jsonEncode(freshDetail.toJson()));
    } catch (_) {}
    return freshDetail;
  } catch (e) {
    if (cachedDetail != null) {
      return cachedDetail;
    }
    rethrow;
  }
});

final wardListNotifierProvider =
    FutureProvider<WardListResponse>((ref) async {
  final repository = ref.read(wardRepositoryProvider);
  return await repository.getWards();
});

/// Boundary polygon rings for a single ward, keyed by slug.
///
/// Calls `GET /api/v1/geo/ward-boundaries` (added by the map feature) and
/// returns the outer ring(s) for [slug] as `List<LatLng>` polygons. An empty
/// list is returned when the endpoint is unavailable, the ward has no boundary
/// data, or the payload is malformed — the ward mini-map then renders its
/// graceful "Boundary map coming soon" fallback.
final wardBoundaryProvider =
    FutureProvider.family<List<List<LatLng>>, String>((ref, slug) async {
  final client = ref.watch(apiClientProvider);
  try {
    final data = await client.getJson('/geo/ward-boundaries');
    if (data is! List) return const [];
    for (final item in data) {
      if (item is! Map<String, dynamic>) continue;
      if (item['ward_slug'] != slug) continue;
      final raw = item['boundary'];
      if (raw is! List) return const [];
      final ring = <LatLng>[];
      for (final point in raw) {
        if (point is! List || point.length < 2) return const [];
        final lat = point[0];
        final lng = point[1];
        if (lat is! num || lng is! num) return const [];
        ring.add(LatLng(lat.toDouble(), lng.toDouble()));
      }
      if (ring.length < 3) return const [];
      return [ring];
    }
    return const [];
  } catch (_) {
    // Boundary data is an enhancement; never fail the page over it.
    return const [];
  }
});

