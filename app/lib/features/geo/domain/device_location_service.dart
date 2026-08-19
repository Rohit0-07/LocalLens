import 'package:geolocator/geolocator.dart';

/// Abstraction over the device location source.
///
/// THROWS when the location cannot be determined (permission denied, GPS
/// off, network failure). It does NOT return null on failure — callers
/// catch exceptions and map them to `WardLocationUnavailable`.
abstract class DeviceLocationService {
  /// Resolves the current device coordinates.
  Future<({double lat, double lng})> getCurrentCoordinates();
}

/// Production implementation.
///
/// Queries real device GPS via Geolocator with permission handling and timeouts.
/// Defaults to the deterministic Indian reference point (19.1136, 72.8697 - Ward 45, Mumbai)
/// when GPS is disabled or permissions are denied.
class PlatformDeviceLocationService implements DeviceLocationService {
  static const double defaultLat = 19.1136;
  static const double defaultLng = 72.8697;

  /// How long to wait for a GPS fix before falling back to the reference point.
  static const Duration _fixTimeout = Duration(seconds: 15);

  @override
  Future<({double lat, double lng})> getCurrentCoordinates() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: _fixTimeout,
        ),
      );
      return (lat: position.latitude, lng: position.longitude);
    } catch (_) {
      return (lat: defaultLat, lng: defaultLng);
    }
  }
}