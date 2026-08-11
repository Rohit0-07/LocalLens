import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart';
import '../../data/geo_api.dart';
import '../../domain/device_location_service.dart';

/// Sealed state machine consumed by both surfaces (compose + feed).
sealed class WardLocationState {
  const WardLocationState();
}

class WardLocationLoading extends WardLocationState {
  const WardLocationLoading();
}

class WardLocationUnavailable extends WardLocationState {
  const WardLocationUnavailable();
}

class WardLocationSuccess extends WardLocationState {
  const WardLocationSuccess({
    required this.place,
    this.wardSlug,
    this.code = '',
  });

  /// Ward place text; "Outside coverage" when `found == false`.
  final String place;

  /// Null when `found == false`.
  final String? wardSlug;

  /// Ward code (e.g. "W-45"); '' when `found == false`.
  final String code;
}

final geoApiProvider = Provider<GeoApi>(
  (ref) => GeoApi(ref.watch(apiClientProvider)),
);

/// Mock seam for widget tests: override with a fake that returns fixed
/// coordinates or throws.
final deviceLocationProvider = Provider<DeviceLocationService>(
  (ref) => PlatformDeviceLocationService(),
);

/// Deterministic reference point (19.1136, 72.8697); never by itself
/// produces a `success` state — the injectable [deviceLocationProvider] gates
/// every success.
final currentCoordinatesProvider = Provider<({double lat, double lng})>(
  (ref) => (lat: 19.1136, lng: 72.8697),
);

/// Device coordinates for feed queries. Falls back to the deterministic
/// reference point when the platform location source is unavailable or
/// errors. Re-resolves whenever [deviceLocationProvider] emits.
final feedCoordinatesProvider =
    FutureProvider<({double lat, double lng})>((ref) async {
  try {
    return await ref.watch(deviceLocationProvider).getCurrentCoordinates();
  } catch (_) {
    return ref.read(currentCoordinatesProvider);
  }
});

/// Resolves the ward location once per provider lifetime. Both surfaces
/// (compose + feed) watch this same provider, so a single resolution serves
/// both.
final wardLocationProvider =
    NotifierProvider<WardLocationController, WardLocationState>(
  WardLocationController.new,
);

class WardLocationController extends Notifier<WardLocationState> {
  @override
  WardLocationState build() {
    state = const WardLocationLoading();
    Future.microtask(_resolve);
    return state;
  }

  /// Non-blocking, never throws: failures map to [WardLocationUnavailable].
  Future<void> _resolve() async {
    final ({double lat, double lng}) coords;
    try {
      coords = await ref.read(deviceLocationProvider).getCurrentCoordinates();
    } catch (_) {
      state = const WardLocationUnavailable();
      return;
    }

    try {
      final result = await ref.read(geoApiProvider).reverseGeocode(
            latitude: coords.lat,
            longitude: coords.lng,
            radiusKm: 50.0,
          );
      if (result.found) {
        state = WardLocationSuccess(
          place: result.place,
          wardSlug: result.wardSlug,
          code: result.wardCode ?? '',
        );
      } else {
        state = const WardLocationSuccess(
          place: 'Outside coverage',
          wardSlug: null,
          code: '',
        );
      }
    } catch (_) {
      state = const WardLocationUnavailable();
    }
  }
}
