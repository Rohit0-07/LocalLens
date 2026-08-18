import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService.instance;
});

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();
  factory LocationService() => instance;

  Future<Position?>? _inFlight;

  /// Fetches the user's current GPS position with permission management.
  /// Deduplicates concurrent in-flight requests to eliminate platform channel
  /// "A request for location permissions is already running" errors.
  Future<Position?> getCurrentPosition() async {
    if (_inFlight != null) {
      return await _inFlight;
    }

    final future = _fetchPositionSafely();
    _inFlight = future;

    try {
      return await future;
    } finally {
      if (identical(_inFlight, future)) {
        _inFlight = null;
      }
    }
  }

  Future<Position?> _fetchPositionSafely() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 4),
        ),
      );
    } catch (_) {
      return null;
    }
  }
}
