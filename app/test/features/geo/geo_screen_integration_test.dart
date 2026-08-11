import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lens/features/compose/presentation/compose_screen.dart';
import 'package:local_lens/features/feed/presentation/feed_screen.dart';
import 'package:local_lens/features/geo/data/geo_api.dart';
import 'package:local_lens/features/geo/domain/device_location_service.dart';
import 'package:local_lens/features/geo/presentation/providers/geo_providers.dart';

import '../../helpers.dart';

/// F-03 Ward Awareness — SCREEN-LEVEL integration tests (FE-05 / FE-06).
///
/// Contract source: `docs/3_test_plan.md` FE-05 ("Compose screen shows the
/// location chip with the ward label") and FE-06 ("Feed app bar shows the
/// nearby-area label"), implementing contract F-09 / F-10 of the F-03
/// contract. These are the two screen-level cases that complete the F-03
/// DoD's 11 contracted frontend cases (9 already exist under
/// `app/test/features/geo/`).
///
/// Code-blind Phase 6: `app/lib/**` is not readable in this phase. The tests
/// pump the REAL `ComposeScreen` / `FeedScreen` and drive the REAL
/// `wardLocationProvider` to success by overriding only its two dependencies
/// — `deviceLocationProvider` and `geoApiProvider` — with the fakes from
/// `geo_widget_test.dart` (reused verbatim). The device location service
/// returns the reference coordinates (19.1136, 72.8697) and the geo API
/// resolves to the known ward ("Ward 45, Urban Central", code W-45).
///
/// The asserted widget keys (`composeLocationChip`, `feedAreaLabel`) and the
/// resolved place text are contract values (F-09 / F-10), not observations
/// of any implementation.

const double kTestLat = 19.1136;
const double kTestLng = 72.8697;
const String kTestPlace = 'Ward 45, Urban Central';
const String kTestSlug = 'ward-45-urban-central';

/// Canned success lookup (BE-01 / FE-10 shape; see geo_api_test.dart).
final ReverseGeocode sampleReverseGeocode = ReverseGeocode.fromJson(
  <String, Object?>{
    'latitude': kTestLat,
    'longitude': kTestLng,
    'place': kTestPlace,
    'ward': <String, Object?>{
      'slug': kTestSlug,
      'name': kTestPlace,
      'code': 'W-45',
      'center_latitude': kTestLat,
      'center_longitude': kTestLng,
    },
    'distance_km': 0.4,
    'found': true,
  },
);

class FakeDeviceLocationService implements DeviceLocationService {
  FakeDeviceLocationService({this.coordinates, this.error, this.gate});

  /// When non-null, getCurrentCoordinates() waits on this before resolving,
  /// so the provider can be held in its loading state deterministically.
  final Completer<void>? gate;
  ({double lat, double lng})? coordinates;
  Object? error;
  int callCount = 0;

  @override
  Future<({double lat, double lng})> getCurrentCoordinates() async {
    callCount += 1;
    if (gate != null) await gate!.future;
    if (error != null) throw error!;
    return coordinates ?? (lat: kTestLat, lng: kTestLng);
  }
}

class FakeGeoApi implements GeoApi {
  FakeGeoApi({this.result, this.error});

  ReverseGeocode? result;
  Object? error;
  int callCount = 0;
  double? lastLatitude;
  double? lastLongitude;
  double? lastRadiusKm;

  @override
  Future<ReverseGeocode> reverseGeocode({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
  }) async {
    callCount += 1;
    lastLatitude = latitude;
    lastLongitude = longitude;
    lastRadiusKm = radiusKm;
    if (error != null) throw error!;
    return result ?? sampleReverseGeocode;
  }
}

/// Geo provider overrides shared by both screen tests: the device location
/// service reports the reference coordinates and the geo API resolves to the
/// known ward, so `wardLocationProvider` reaches `WardLocationSuccess`.
List<Override> geoOverrides() {
  return [
    deviceLocationProvider.overrideWithValue(FakeDeviceLocationService()),
    geoApiProvider.overrideWithValue(FakeGeoApi(result: sampleReverseGeocode)),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('F-03 geo screen integration (FE-05 / F-09, FE-06 / F-10)', () {
    testWidgets(
      'FE-05 / F-09: ComposeScreen shows Key(composeLocationChip) with the '
      'resolved ward place text',
      (tester) async {
        final fakeAuth = FakeAuthRepository();
        final fakeFeed = FakeFeedRepository();
        final container = ProviderContainer(
          overrides: [
            ...mockOverrides(
              authRepository: fakeAuth,
              feedRepository: fakeFeed,
            ),
            ...geoOverrides(),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: ComposeScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Contract F-09: the compose screen's location chip is present and
        // carries the resolved ward place label (FE-05).
        expect(find.byKey(const Key('composeLocationChip')), findsOneWidget);
        expect(find.textContaining(kTestPlace), findsOneWidget);

        // The geo providers were driven to a successful resolve.
        expect(
          container.read(wardLocationProvider),
          isA<WardLocationSuccess>(),
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'FE-06 / F-10: FeedScreen app bar shows Key(feedAreaLabel) with the '
      'resolved ward place text',
      (tester) async {
        final fakeFeed = FakeFeedRepository();
        final container = ProviderContainer(
          overrides: [
            ...mockOverrides(feedRepository: fakeFeed),
            ...geoOverrides(),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: FeedScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Contract F-10: the feed app bar's nearby-area label is present and
        // shows the resolved ward place name (FE-06).
        expect(find.byKey(const Key('feedAreaLabel')), findsOneWidget);
        expect(find.textContaining(kTestPlace), findsOneWidget);

        // The geo providers were driven to a successful resolve.
        expect(
          container.read(wardLocationProvider),
          isA<WardLocationSuccess>(),
        );
        expect(tester.takeException(), isNull);
      },
    );
  });
}
