import '../../../core/network/api_client.dart';

/// Parsed `GET /geo/reverse-geocode` response model.
///
/// JSON keys: `latitude`, `longitude`, `place`, `ward`, `distance_km`,
/// `found`. The `ward` object is optional/nullable; any other unknown keys
/// (email/phone/anon_id/device_id/etc.) are ignored.
class ReverseGeocode {
  const ReverseGeocode({
    required this.latitude,
    required this.longitude,
    required this.place,
    this.wardSlug,
    this.wardName,
    this.wardCode,
    required this.distanceKm,
    required this.found,
  });

  /// Parses a reverse-geocode payload.
  ///
  /// Required scalars — `latitude`, `longitude`, `place`, `distance_km`,
  /// `found` — must be present and of the right type, otherwise a controlled
  /// [FormatException] is thrown. `ward` may be null or absent (all ward
  /// fields become null) or an object with `slug`/`name`/`code`.
  factory ReverseGeocode.fromJson(Map<String, Object?> json) {
    final latitude = json['latitude'];
    final longitude = json['longitude'];
    final place = json['place'];
    final distanceKm = json['distance_km'];
    final found = json['found'];
    if (latitude is! num ||
        longitude is! num ||
        place is! String ||
        distanceKm is! num ||
        found is! bool) {
      throw FormatException(
        'Invalid reverse-geocode payload: missing or malformed required '
        'field(s).',
      );
    }

    String? wardSlug;
    String? wardName;
    String? wardCode;
    final ward = json['ward'];
    if (ward is Map<String, Object?>) {
      final slug = ward['slug'];
      final name = ward['name'];
      final code = ward['code'];
      if (slug is String) wardSlug = slug;
      if (name is String) wardName = name;
      if (code is String) wardCode = code;
    }

    return ReverseGeocode(
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
      place: place,
      wardSlug: wardSlug,
      wardName: wardName,
      wardCode: wardCode,
      distanceKm: distanceKm.toDouble(),
      found: found,
    );
  }

  final double latitude;
  final double longitude;
  final String place;

  /// Null when not found (`ward == null`).
  final String? wardSlug;

  /// Null when not found.
  final String? wardName;

  /// Null when not found.
  final String? wardCode;

  /// `0.0` when not found.
  final double distanceKm;

  final bool found;
}

/// HTTP wrapper for the geo feature.
class GeoApi {
  GeoApi(this._client);

  final ApiClient _client;

  /// Resolves the ward nearest to [latitude]/[longitude].
  ///
  /// GET `/geo/reverse-geocode?latitude=..&longitude=..&radius_km=..`
  /// (the `ApiClient` owns the `/api/v1` base prefix). [radiusKm] has a
  /// non-null default so `radius_km` is ALWAYS present in the query.
  Future<ReverseGeocode> reverseGeocode({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
  }) async {
    final data = await _client.getJson(
      '/geo/reverse-geocode',
      query: {
        'latitude': latitude,
        'longitude': longitude,
        'radius_km': radiusKm,
      },
    );
    return ReverseGeocode.fromJson(data as Map<String, Object?>);
  }
}
