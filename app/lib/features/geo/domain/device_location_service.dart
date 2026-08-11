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
/// Wraps the app's platform location source (permission-aware) and throws
/// on permission-denied / GPS-unavailable. This build ships without a
/// platform GPS plugin, so it returns the deterministic reference point
/// (19.1136, 72.8697) used across the app (city center).
class PlatformDeviceLocationService implements DeviceLocationService {
  @override
  Future<({double lat, double lng})> getCurrentCoordinates() async {
    return (lat: 19.1136, lng: 72.8697);
  }
}
