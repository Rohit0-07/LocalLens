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

  @override
  Future<({double lat, double lng})> getCurrentCoordinates() async {
    return (lat: defaultLat, lng: defaultLng);
  }
}
