import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/network_providers.dart';

class MapPin {
  final int id;
  final String title;
  final String category;
  final String status;
  final double latitude;
  final double longitude;
  final String wardName;
  final bool isShielded;
  final int upvotesCount;
  final DateTime createdAt;

  const MapPin({
    required this.id,
    required this.title,
    required this.category,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.wardName,
    required this.isShielded,
    required this.upvotesCount,
    required this.createdAt,
  });

  factory MapPin.fromJson(Map<String, dynamic> json) {
    return MapPin(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? 'other',
      status: json['status'] as String? ?? 'unacknowledged',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      wardName: json['ward_name'] as String? ?? '',
      isShielded: json['is_shielded'] as bool? ?? false,
      upvotesCount: json['upvotes_count'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'ward_name': wardName,
      'is_shielded': isShielded,
      'upvotes_count': upvotesCount,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

final mapApiProvider = Provider<MapApi>((ref) {
  return MapApi(ref.watch(apiClientProvider));
});

class MapApi {
  final ApiClient _apiClient;

  MapApi(this._apiClient);

  Future<List<MapPin>> getMapPins({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
    String? category,
    String? status,
  }) async {
    final query = <String, dynamic>{
      'min_lat': minLat,
      'max_lat': maxLat,
      'min_lng': minLng,
      'max_lng': maxLng,
    };
    if (category != null && category.isNotEmpty && category != 'all') {
      query['category'] = category;
    }
    if (status != null && status.isNotEmpty && status != 'all') {
      query['status'] = status;
    }

    final data = await _apiClient.getJson('/geo/map-pins', query: query);
    if (data is List) {
      return data
          .map((item) => MapPin.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
