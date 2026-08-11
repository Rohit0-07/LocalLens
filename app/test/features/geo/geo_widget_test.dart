import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:local_lens/features/geo/data/geo_api.dart';
import 'package:local_lens/features/geo/domain/device_location_service.dart';
import 'package:local_lens/features/geo/presentation/providers/geo_providers.dart';
import 'package:local_lens/features/geo/presentation/widgets/ward_location_chip.dart';

/// F-03 Ward Awareness - WardLocationController / wardLocationProvider state
/// and WardLocationChip widget tests (code-blind, Phase 6).
///
/// Contract source: docs/3_test_plan.md (FE-01..FE-11) plus the F-03 contract
/// passed verbatim to Phase 6 (sealed WardLocationState, WardLocationChip
/// keys, provider wiring, strings, GeoApi signature).
///
/// TEST-NUMBERING NOTE: the Phase 6 brief renumbers the plan's FE cases; the
/// FE-04..FE-09 labels below are the brief's numbers (provider/state and chip
/// behavior), not the plan's screen-level FE-04..FE-08 numbers.
///
/// ASSUMPTIONS (minimal; documented because app/lib/** is unreadable in this
/// phase - a deviation in any of these must surface as a test failure):
///   1. DeviceLocationService is exported from
///      features/geo/domain/device_location_service.dart.
///   2. deviceLocationProvider (`Provider<DeviceLocationService>`) and a
///      geoApiProvider (`Provider<GeoApi>`) are both exported from
///      features/geo/presentation/providers/geo_providers.dart alongside
///      wardLocationProvider. The real controller is exercised; only its two
///      dependencies are faked.
///   3. WardLocationChip is a presentational widget that takes the resolved
///      state via constructor: WardLocationChip({required WardLocationState
///      state}), switches on the sealed state to pick its key, and performs
///      the /ward/:slug navigation itself on tap.
///   4. Because the sealed state has no outside-coverage variant, an
///      out-of-coverage lookup (found == false) is modeled as
///      WardLocationSuccess(place: "Outside coverage", ...) and the chip keys
///      off place == "Outside coverage".

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

/// Canned out-of-coverage lookup (BE-03 / FE-11 shape).
final ReverseGeocode outsideCoverageGeocode = ReverseGeocode.fromJson(
  <String, Object?>{
    'latitude': 28.0,
    'longitude': 77.0,
    'place': 'Outside coverage',
    'ward': null,
    'distance_km': 0.0,
    'found': false,
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

/// Renders the chip off the real wardLocationProvider so the full
/// controller -> chip wiring is exercised.
class WardLocationChipHarness extends ConsumerWidget {
  const WardLocationChipHarness({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final WardLocationState state = ref.watch(wardLocationProvider);
    return Scaffold(body: WardLocationChip(state: state));
  }
}

ProviderContainer buildContainer({
  FakeDeviceLocationService? location,
  FakeGeoApi? geoApi,
}) {
  final container = ProviderContainer(
    overrides: [
      deviceLocationProvider.overrideWithValue(
        location ?? FakeDeviceLocationService(),
      ),
      geoApiProvider.overrideWithValue(geoApi ?? FakeGeoApi()),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// Completes with the first non-loading state the provider reaches.
Future<WardLocationState> waitForResolvedState(ProviderContainer container) {
  final completer = Completer<WardLocationState>();
  final sub = container.listen<WardLocationState>(
    wardLocationProvider,
    (previous, next) {
      if (next is! WardLocationLoading && !completer.isCompleted) {
        completer.complete(next);
      }
    },
    fireImmediately: true,
  );
  addTearDown(sub.close);
  return completer.future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WardLocationProvider state (FE-04..FE-06)', () {
    test(
      'FE-04: wardLocationProvider initial state is WardLocationLoading',
      () {
        // Location resolution is gated forever so the provider can never
        // leave its initial loading state.
        final container = buildContainer(
          location: FakeDeviceLocationService(gate: Completer<void>()),
        );

        final state = container.read(wardLocationProvider);
        expect(state, isA<WardLocationLoading>());
      },
    );

    test(
      'FE-05: resolves to WardLocationSuccess with place "Ward 45, Urban '
      'Central" when API returns found=true',
      () async {
        final location = FakeDeviceLocationService();
        final geoApi = FakeGeoApi(result: sampleReverseGeocode);
        final container = buildContainer(location: location, geoApi: geoApi);

        final state = await waitForResolvedState(container);

        expect(state, isA<WardLocationSuccess>());
        final success = state as WardLocationSuccess;
        expect(success.place, 'Ward 45, Urban Central');
        expect(success.wardSlug, 'ward-45-urban-central');
        expect(success.code, 'W-45');

        // Device coordinates flow into the reverse-geocode call with the
        // contract's 50.0 km default radius.
        expect(location.callCount, 1);
        expect(geoApi.callCount, 1);
        expect(geoApi.lastLatitude, 19.1136);
        expect(geoApi.lastLongitude, 72.8697);
        expect(geoApi.lastRadiusKm, 50.0);
      },
    );

    test(
      'FE-06: resolves to WardLocationUnavailable when DeviceLocationService '
      'throws',
      () async {
        final container = buildContainer(
          location: FakeDeviceLocationService(
            error: StateError('GPS unavailable'),
          ),
          geoApi: FakeGeoApi(result: sampleReverseGeocode),
        );

        final state = await waitForResolvedState(container);
        expect(state, isA<WardLocationUnavailable>());
      },
    );
  });

  group('WardLocationChip widget (FE-02, FE-07, FE-08, outside coverage)', () {
    testWidgets(
      'FE-02: loading state shows Key(wardLocationLoading) and "Locating…"',
      (tester) async {
        final container = buildContainer(
          location: FakeDeviceLocationService(gate: Completer<void>()),
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: WardLocationChipHarness()),
          ),
        );
        await tester.pump();

        expect(find.byKey(const Key('wardLocationLoading')), findsOneWidget);
        expect(find.text('Locating…'), findsOneWidget);
        expect(container.read(wardLocationProvider), isA<WardLocationLoading>());
      },
    );

    testWidgets(
      'FE-07: success shows Key(wardLocationChip) with the ward place text',
      (tester) async {
        final container = buildContainer(
          geoApi: FakeGeoApi(result: sampleReverseGeocode),
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: WardLocationChipHarness()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('wardLocationChip')), findsOneWidget);
        // Place label (name, and code per FE-10) - textContaining guards
        // against the label being rendered as one concatenated string.
        expect(find.textContaining('Ward 45, Urban Central'), findsOneWidget);
        expect(find.textContaining('W-45'), findsOneWidget);
        expect(container.read(wardLocationProvider), isA<WardLocationSuccess>());
      },
    );

    testWidgets(
      'FE-08: error shows Key(wardLocationUnavailable), location_off icon and '
      '"Location unavailable"',
      (tester) async {
        final container = buildContainer(
          location: FakeDeviceLocationService(error: StateError('denied')),
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: WardLocationChipHarness()),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('wardLocationUnavailable')),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.location_off_outlined), findsOneWidget);
        expect(find.text('Location unavailable'), findsOneWidget);
        expect(
          container.read(wardLocationProvider),
          isA<WardLocationUnavailable>(),
        );
      },
    );

    testWidgets(
      'outside coverage shows Key(wardLocationOutsideCoverage) and '
      '"Outside coverage" (FE-07/FE-11)',
      (tester) async {
        final container = buildContainer(
          geoApi: FakeGeoApi(result: outsideCoverageGeocode),
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: WardLocationChipHarness()),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('wardLocationOutsideCoverage')),
          findsOneWidget,
        );
        expect(find.text('Outside coverage'), findsOneWidget);
        // No ward chip and no error surface in this state.
        expect(find.byKey(const Key('wardLocationChip')), findsNothing);
        expect(find.byKey(const Key('wardLocationUnavailable')), findsNothing);
      },
    );

    testWidgets(
      'FE-09: tapping the success chip navigates to /ward/:slug',
      (tester) async {
        final container = buildContainer(
          geoApi: FakeGeoApi(result: sampleReverseGeocode),
        );

        final router = GoRouter(
          initialLocation: '/feed',
          routes: [
            GoRoute(
              path: '/feed',
              builder: (context, state) =>
                  const WardLocationChipHarness(),
            ),
            GoRoute(
              path: '/ward/:slug',
              builder: (context, state) =>
                  const Scaffold(key: Key('wardDetailScreen')),
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('wardLocationChip')), findsOneWidget);
        await tester.tap(find.byKey(const Key('wardLocationChip')));
        await tester.pumpAndSettle();

        expect(router.state.matchedLocation, '/ward/ward-45-urban-central');
        expect(find.byKey(const Key('wardDetailScreen')), findsOneWidget);
      },
    );
  });
}
