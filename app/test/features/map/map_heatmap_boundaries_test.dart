// F-B map heatmap + ward-boundary widget tests (FE-MAP-02..FE-MAP-11).
//
// Contract source: the F-B phase-6 contract inlined verbatim to this phase
// (FE-MAP-02..FE-MAP-11; FE-MAP-01 is covered by the existing map tests and
// FE-MAP-12 is a source-import assertion, so both are deliberately not
// duplicated here). The `docs/3_test_plan.md` on disk predates F-B (it is the
// F-03 reverse-geocode plan) and does not mention this feature.
//
// Harness: mirrors `map_modes_test.dart` (ProviderContainer overriding
// `mapApiProvider`, `wardRepositoryProvider`, `locationServiceProvider`).
// `ProviderContainer` + `UncontrolledProviderScope` is used so the tests can
// drive the map controller directly (house style of
// `map_pins_extended_test.dart` FE-MAP-04).
//
// RECONCILED AGAINST IMPLEMENTATION (the phase-6 write-only agent could not
// read `src`; these facts come from the reconciled read of `app/lib/**`):
//   1. Heatmap and ward-boundary area fills are flutter_map `PolygonLayer`
//      widgets (one per 0.003° grid cell / per ward), keyed
//      `heatmapCell_<latKey>_<lngKey>` and `wardBoundary_<slug>`.
//      `Polygon` is a plain (non-Widget) data class, so tests read
//      `layer.polygons` off the layer widgets instead of `find.byType(...)`.
//   2. `WardBoundary` lives in `features/map/data/map_api.dart` (fields
//      `slug/name/code/ring`); boundaries are fetched by `MapApi`
//      (`GET /geo/ward-boundaries`) through the `wardBoundariesProvider`
//      FutureProvider in `map_controller.dart` — NOT `WardRepository`.
//   3. The map controller is the `mapPinsNotifierProvider` notifier; the
//      debounced (~800 ms) pan-refetch is `updateBounds(MapBounds)`, not
//      `move(...)`.
//   4. MapScreen runs a ~30 s periodic poll (FE-MAP-05). Every test unmounts
//      the tree before finishing so the periodic timer is cancelled before
//      the framework's pending-timer check. `refreshIfIdle` only refetches
//      once `state.pins.hasValue`.
//   5. When `wardBoundariesProvider` is empty/errored, `WardBoundaryLayer`
//      falls back to a deterministic 8-point derived octagon ring
//      (`WardBoundaryLayer.derivedWardRing`), so the fallback polygon always
//      has exactly 8 points.
//
// Heatmap cells: pins are bucketed into fixed 0.003° cells. The
// FE-MAP-02/03/11 fixtures space pins >= 0.003 deg apart in a distinct grid so
// distinct cells are guaranteed, while the 5-pin cluster in FE-MAP-03 is
// packed within ~0.0003 deg so it collapses into a single cell.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:local_lens/core/services/location_service.dart';
import 'package:local_lens/features/map/data/map_api.dart';
import 'package:local_lens/features/map/presentation/controllers/map_controller.dart';
import 'package:local_lens/features/map/presentation/screens/map_screen.dart';
import 'package:local_lens/features/ward/data/repositories/ward_repository.dart';
import 'package:local_lens/features/ward/domain/ward_list_response.dart';
import 'package:local_lens/features/ward/domain/ward_summary_out.dart';
import 'package:local_lens/features/ward/presentation/providers/ward_providers.dart';
import 'package:mocktail/mocktail.dart';

class MockMapApi extends Mock implements MapApi {}

class MockWardRepository extends Mock implements WardRepository {}

/// Instantly returns null so the notifier constructor doesn't block on GPS.
class _ImmediateNullLocationService implements LocationService {
  @override
  Future<Position?> getCurrentPosition() async => null;
}

// ---------------------------------------------------------------------------
// Sample data
// ---------------------------------------------------------------------------

MapPin buildPin({
  required int id,
  required double lat,
  required double lng,
  String category = 'road',
}) {
  return MapPin(
    id: id,
    title: 'Issue $id',
    category: category,
    status: 'unacknowledged',
    latitude: lat,
    longitude: lng,
    wardName: 'Ward 45, Urban Central',
    isShielded: false,
    upvotesCount: 1,
    createdAt: DateTime.now(),
  );
}

WardBoundary buildWardBoundary({
  String slug = 'ward-45-urban-central',
  String name = 'Ward 45, Urban Central',
  String code = 'W-45',
}) {
  return WardBoundary(
    slug: slug,
    name: name,
    code: code,
    ring: const [
      LatLng(19.08, 72.82),
      LatLng(19.14, 72.82),
      LatLng(19.14, 72.90),
      LatLng(19.08, 72.90),
    ],
  );
}

final sampleWard1 = WardSummaryOut(
  slug: 'ward-45-urban-central',
  name: 'Ward 45, Urban Central',
  code: 'W-45',
  centerLatitude: 19.10,
  centerLongitude: 72.85,
  totalIssues: 24,
  activeIssues: 12,
  escalatedIssues: 3,
  resolvedIssues: 9,
  resolutionRatePct: 37.5,
);

// ---------------------------------------------------------------------------
// Harness (mirrors map_modes_test.dart overrides)
// ---------------------------------------------------------------------------

ProviderContainer buildContainer({
  required MockMapApi mapApi,
  required MockWardRepository wardRepo,
}) {
  final container = ProviderContainer(
    overrides: [
      mapApiProvider.overrideWithValue(mapApi),
      wardRepositoryProvider.overrideWithValue(wardRepo),
      locationServiceProvider.overrideWithValue(_ImmediateNullLocationService()),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Widget wrap(ProviderContainer container, Widget child) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(home: child),
  );
}

/// Pumps MapScreen through its initial load (mirrors map_modes_test.dart).
Future<void> pumpMap(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(wrap(container, const MapScreen()));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();
}

/// Unmounts the map so the periodic poll timer is cancelled before the test
/// framework's pending-timer check (note 4).
Future<void> unmountMap(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

bool _keyHasPrefix(Key? key, String prefix) =>
    key is ValueKey<String> && key.value.startsWith(prefix);

/// Heatmap cell fills: the `PolygonLayer` widgets keyed `heatmapCell_*`.
Finder heatmapLayerFinder() => find.byWidgetPredicate(
      (w) => w is PolygonLayer && _keyHasPrefix(w.key, 'heatmapCell_'),
    );

/// All `Polygon` data objects across the heatmap layers (one per cell).
List<Polygon> heatmapPolygons(WidgetTester tester) {
  final layers = tester
      .widgetList<PolygonLayer>(heatmapLayerFinder())
      .toList();
  return [for (final layer in layers) ...layer.polygons];
}

/// The single ward-boundary layer relayed for a slug, keyed
/// `wardBoundary_<slug>`; null when the ward does not render a layer.
PolygonLayer? wardBoundaryLayer(WidgetTester tester, String slug) {
  final finder =
      find.byWidgetPredicate((w) => w is PolygonLayer && w.key == Key('wardBoundary_$slug'));
  if (finder.evaluate().isEmpty) return null;
  return tester.widget<PolygonLayer>(finder);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockMapApi mockMapApi;
  late MockWardRepository mockWardRepo;

  setUp(() {
    mockMapApi = MockMapApi();
    mockWardRepo = MockWardRepository();

    when(() => mockMapApi.getMapPins(
          minLat: any(named: 'minLat'),
          maxLat: any(named: 'maxLat'),
          minLng: any(named: 'minLng'),
          maxLng: any(named: 'maxLng'),
          category: any(named: 'category'),
          status: any(named: 'status'),
        )).thenAnswer((_) async => [buildPin(id: 101, lat: 19.10, lng: 72.85)]);

    when(() => mockWardRepo.getWards()).thenAnswer(
      (_) async =>
          WardListResponse(items: [sampleWard1], total: 1, limit: 20, offset: 0),
    );

    // Default: no stored boundaries (exercises the fallback path safely in
    // tests that never enter ward mode). Boundaries come from `MapApi` via the
    // `wardBoundariesProvider` FutureProvider, not `WardRepository`.
    when(() => mockMapApi.getWardBoundaries()).thenAnswer((_) async => []);
  });

  group('F-B heatmap: area fill, not circles (FE-MAP-02..FE-MAP-03)', () {
    testWidgets(
      'FE-MAP-02: 3 pins in 3 distinct cells render 3 heatmap PolygonLayers '
      '(no circle layer), heatmapCell_* keys, and the legend',
      (tester) async {
        when(() => mockMapApi.getMapPins(
              minLat: any(named: 'minLat'),
              maxLat: any(named: 'maxLat'),
              minLng: any(named: 'minLng'),
              maxLng: any(named: 'maxLng'),
              category: any(named: 'category'),
              status: any(named: 'status'),
            )).thenAnswer((_) async => [
              buildPin(id: 101, lat: 19.10, lng: 72.85),
              buildPin(id: 102, lat: 19.15, lng: 72.86),
              buildPin(id: 103, lat: 19.18, lng: 72.88),
            ]);

        final container =
            buildContainer(mapApi: mockMapApi, wardRepo: mockWardRepo);
        await pumpMap(tester, container);

        await tester.tap(find.text('Heatmap'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();

        // Area fill, not circles: one PolygonLayer (with a filled Polygon) per
        // populated cell, and never a CircleLayer.
        final layers =
            tester.widgetList<PolygonLayer>(heatmapLayerFinder()).toList();
        expect(layers.length, 3,
            reason: 'one PolygonLayer per populated 0.003° cell');
        expect(heatmapPolygons(tester), hasLength(3));
        expect(find.byType(CircleLayer), findsNothing);

        // Per-cell keys are present.
        expect(heatmapLayerFinder(), findsNWidgets(3));

        // Legend still renders (F-08-MAP regression).
        expect(find.text('Density:'), findsOneWidget);
        expect(find.text('Hotspot'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await unmountMap(tester);
      },
    );

    testWidgets(
      'FE-MAP-03: a 1-pin cell and a 5-pin cell render different fill colors',
      (tester) async {
        // Cell A: a single pin. Cell B: five pins packed within ~0.0003 deg
        // so they collapse into one cell.
        when(() => mockMapApi.getMapPins(
              minLat: any(named: 'minLat'),
              maxLat: any(named: 'maxLat'),
              minLng: any(named: 'minLng'),
              maxLng: any(named: 'maxLng'),
              category: any(named: 'category'),
              status: any(named: 'status'),
            )).thenAnswer((_) async => [
              buildPin(id: 101, lat: 19.1000, lng: 72.8500),
              buildPin(id: 102, lat: 19.1500, lng: 72.8600),
              buildPin(id: 103, lat: 19.1501, lng: 72.8601),
              buildPin(id: 104, lat: 19.1502, lng: 72.8600),
              buildPin(id: 105, lat: 19.1501, lng: 72.8602),
              buildPin(id: 106, lat: 19.1503, lng: 72.8601),
            ]);

        final container =
            buildContainer(mapApi: mockMapApi, wardRepo: mockWardRepo);
        await pumpMap(tester, container);

        await tester.tap(find.text('Heatmap'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();

        final polygons = heatmapPolygons(tester);
        expect(polygons.length, greaterThanOrEqualTo(2),
            reason: 'one Polygon per populated cell (1-pin cell + 5-pin cell)');

        final fillColors = polygons.map((p) => p.color).toSet();
        expect(fillColors.length, greaterThanOrEqualTo(2),
            reason: '1-pin cell and 5-pin cell must render different '
                'Polygon.color values');
        expect(tester.takeException(), isNull);

        await unmountMap(tester);
      },
    );
  });

  group('F-B refetch triggers (FE-MAP-04..FE-MAP-06)', () {
    testWidgets(
      'FE-MAP-04: updateBounds() auto-refetches with new bounds after the '
      'debounce window (no refetch within 400 ms, one after > 800 ms)',
      (tester) async {
        var getMapPinsCalls = 0;
        when(() => mockMapApi.getMapPins(
              minLat: any(named: 'minLat'),
              maxLat: any(named: 'maxLat'),
              minLng: any(named: 'minLng'),
              maxLng: any(named: 'maxLng'),
              category: any(named: 'category'),
              status: any(named: 'status'),
            )).thenAnswer((_) async {
              getMapPinsCalls += 1;
              return [buildPin(id: 101, lat: 19.10, lng: 72.85)];
            });

        final container =
            buildContainer(mapApi: mockMapApi, wardRepo: mockWardRepo);
        await pumpMap(tester, container);
        expect(getMapPinsCalls, 1, reason: 'initial load');

        // F-B contract: the map controller pans; the refetch is debounced
        // (~800 ms window) via `updateBounds` on the mapPinsNotifierProvider.
        final mapNotifier = container.read(mapPinsNotifierProvider.notifier);
        mapNotifier.updateBounds(const MapBounds(
            minLat: 19.05, maxLat: 19.25, minLng: 72.82, maxLng: 72.92));

        // Inside the debounce window: still only the initial call.
        await tester.pump(const Duration(milliseconds: 400));
        expect(getMapPinsCalls, 1,
            reason: 'debounce window must suppress the refetch');

        // Past the window (> 800 ms after updateBounds): exactly one refetch,
        // with the new bounds.
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();
        expect(getMapPinsCalls, 2, reason: 'debounced refetch after the window');

        verify(() => mockMapApi.getMapPins(
              minLat: 19.05,
              maxLat: 19.25,
              minLng: 72.82,
              maxLng: 72.92,
              category: any(named: 'category'),
              status: any(named: 'status'),
            )).called(1);

        await unmountMap(tester);
      },
    );

    testWidgets(
      'FE-MAP-05: 30 s poll triggers an additional getMapPins call',
      (tester) async {
        var getMapPinsCalls = 0;
        when(() => mockMapApi.getMapPins(
              minLat: any(named: 'minLat'),
              maxLat: any(named: 'maxLat'),
              minLng: any(named: 'minLng'),
              maxLng: any(named: 'maxLng'),
              category: any(named: 'category'),
              status: any(named: 'status'),
            )).thenAnswer((_) async {
              getMapPinsCalls += 1;
              return [buildPin(id: 101, lat: 19.10, lng: 72.85)];
            });

        final container =
            buildContainer(mapApi: mockMapApi, wardRepo: mockWardRepo);
        await pumpMap(tester, container);
        expect(getMapPinsCalls, 1);

        await tester.pump(const Duration(seconds: 31));
        expect(getMapPinsCalls, 2, reason: 'poll must refetch at the 30 s tick');

        await unmountMap(tester);
      },
    );

    testWidgets(
      'FE-MAP-06: app resume triggers a refetch',
      (tester) async {
        var getMapPinsCalls = 0;
        when(() => mockMapApi.getMapPins(
              minLat: any(named: 'minLat'),
              maxLat: any(named: 'maxLat'),
              minLng: any(named: 'minLng'),
              maxLng: any(named: 'maxLng'),
              category: any(named: 'category'),
              status: any(named: 'status'),
            )).thenAnswer((_) async {
              getMapPinsCalls += 1;
              return [buildPin(id: 101, lat: 19.10, lng: 72.85)];
            });

        final container =
            buildContainer(mapApi: mockMapApi, wardRepo: mockWardRepo);
        await pumpMap(tester, container);
        expect(getMapPinsCalls, 1);

        // Force a lifecycle transition so the resume observer actually fires.
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(getMapPinsCalls, 2, reason: 'resume must refetch');

        // Restore the binding so later tests in this file are unaffected.
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await unmountMap(tester);
      },
    );
  });

  group('F-B ward boundaries (FE-MAP-07..FE-MAP-08)', () {
    testWidgets(
      'FE-MAP-07: ward mode renders wardBoundary_<slug> PolygonLayer from the '
      'fetched ring, no circle layer, and keeps the marker pill + W-45',
      (tester) async {
        when(() => mockMapApi.getWardBoundaries())
            .thenAnswer((_) async => [buildWardBoundary()]);

        final container =
            buildContainer(mapApi: mockMapApi, wardRepo: mockWardRepo);
        await pumpMap(tester, container);

        await tester.tap(find.text('Ward Map'));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();

        // Boundary ring per ward, rendered as a PolygonLayer fill — never a
        // circle layer. The 4-point ring comes from MapApi.getWardBoundaries().
        final layer = wardBoundaryLayer(tester, 'ward-45-urban-central');
        expect(layer, isNotNull);
        expect(layer!.polygons.single.points, hasLength(4),
            reason: 'fetched ring must be used verbatim');
        expect(find.byType(CircleLayer), findsNothing);

        // F-09 regression: the ward marker pill and its code are still present.
        expect(
          find.byKey(const Key('wardMarker_ward-45-urban-central')),
          findsOneWidget,
        );
        expect(find.text('W-45'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await unmountMap(tester);
      },
    );

    testWidgets(
      'FE-MAP-08: getWardBoundaries() throwing falls back to the 8-point '
      'derived octagon ring - no crash',
      (tester) async {
        when(() => mockMapApi.getWardBoundaries())
            .thenThrow(Exception('offline'));

        final container =
            buildContainer(mapApi: mockMapApi, wardRepo: mockWardRepo);
        await pumpMap(tester, container);

        await tester.tap(find.text('Ward Map'));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();

        // No crash / no red error screen.
        expect(tester.takeException(), isNull);

        // Derived fallback octagon ring (exactly 8 points) renders per ward.
        final layer = wardBoundaryLayer(tester, 'ward-45-urban-central');
        expect(layer, isNotNull);
        expect(layer!.polygons.single.points, hasLength(8),
            reason: 'derived octagon fallback must have 8 points');

        // The ward map still works: marker pill remains.
        expect(
          find.byKey(const Key('wardMarker_ward-45-urban-central')),
          findsOneWidget,
        );

        await unmountMap(tester);
      },
    );

    testWidgets(
      'FE-MAP-08b: getWardBoundaries() returning [] falls back to the '
      '8-point derived octagon ring - no crash',
      (tester) async {
        when(() => mockMapApi.getWardBoundaries()).thenAnswer((_) async => []);

        final container =
            buildContainer(mapApi: mockMapApi, wardRepo: mockWardRepo);
        await pumpMap(tester, container);

        await tester.tap(find.text('Ward Map'));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();

        expect(tester.takeException(), isNull);
        final layer = wardBoundaryLayer(tester, 'ward-45-urban-central');
        expect(layer, isNotNull);
        expect(layer!.polygons.single.points, hasLength(8),
            reason: 'derived octagon fallback must have 8 points');
        expect(
          find.byKey(const Key('wardMarker_ward-45-urban-central')),
          findsOneWidget,
        );

        await unmountMap(tester);
      },
    );
  });

  group('F-B states (FE-MAP-09..FE-MAP-10)', () {
    testWidgets(
      'FE-MAP-09: no pins - empty state in pins mode, zero polygons in '
      'heatmap mode',
      (tester) async {
        when(() => mockMapApi.getMapPins(
              minLat: any(named: 'minLat'),
              maxLat: any(named: 'maxLat'),
              minLng: any(named: 'minLng'),
              maxLng: any(named: 'maxLng'),
              category: any(named: 'category'),
              status: any(named: 'status'),
            )).thenAnswer((_) async => []);

        final container =
            buildContainer(mapApi: mockMapApi, wardRepo: mockWardRepo);
        await pumpMap(tester, container);

        expect(find.byKey(const Key('mapEmptyState')), findsOneWidget);
        expect(find.text('No issues found in this area'), findsOneWidget);

        await tester.tap(find.text('Heatmap'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();

        expect(heatmapPolygons(tester), isEmpty);
        expect(tester.takeException(), isNull);

        await unmountMap(tester);
      },
    );

    testWidgets(
      'FE-MAP-10: offline - error banner, zero heatmap polygons, retry '
      'recovers',
      (tester) async {
        when(() => mockMapApi.getMapPins(
              minLat: any(named: 'minLat'),
              maxLat: any(named: 'maxLat'),
              minLng: any(named: 'minLng'),
              maxLng: any(named: 'maxLng'),
              category: any(named: 'category'),
              status: any(named: 'status'),
            )).thenThrow(Exception('Failed to fetch pins from server'));

        final container =
            buildContainer(mapApi: mockMapApi, wardRepo: mockWardRepo);
        await pumpMap(tester, container);

        expect(find.textContaining('Failed to load map pins'), findsOneWidget);
        expect(find.byKey(const Key('mapErrorRetryButton')), findsOneWidget);

        await tester.tap(find.text('Heatmap'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();
        expect(heatmapPolygons(tester), isEmpty);

        // Back to pins mode; the network recovers.
        when(() => mockMapApi.getMapPins(
              minLat: any(named: 'minLat'),
              maxLat: any(named: 'maxLat'),
              minLng: any(named: 'minLng'),
              maxLng: any(named: 'maxLng'),
              category: any(named: 'category'),
              status: any(named: 'status'),
            )).thenAnswer((_) async => [buildPin(id: 101, lat: 19.10, lng: 72.85)]);

        await tester.tap(find.text('Pins'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();

        await tester.tap(find.byKey(const Key('mapErrorRetryButton')));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();

        expect(find.textContaining('Failed to load map pins'), findsNothing);
        expect(find.byKey(const Key('mapPin_101')), findsOneWidget);
        expect(tester.takeException(), isNull);

        await unmountMap(tester);
      },
    );
  });

  group('F-B filters (FE-MAP-11)', () {
    testWidgets(
      'FE-MAP-11: road filter chip selects category, refetches, and the '
      'filtered subset drives heatmap density',
      (tester) async {
        final roadPin =
            buildPin(id: 101, lat: 19.10, lng: 72.85, category: 'road');
        final waterPin =
            buildPin(id: 102, lat: 19.15, lng: 72.86, category: 'water');

        when(() => mockMapApi.getMapPins(
              minLat: any(named: 'minLat'),
              maxLat: any(named: 'maxLat'),
              minLng: any(named: 'minLng'),
              maxLng: any(named: 'maxLng'),
              category: any(named: 'category'),
              status: any(named: 'status'),
            )).thenAnswer((_) async => [roadPin, waterPin]);

        var roadFilterCalls = 0;
        when(() => mockMapApi.getMapPins(
              minLat: any(named: 'minLat'),
              maxLat: any(named: 'maxLat'),
              minLng: any(named: 'minLng'),
              maxLng: any(named: 'maxLng'),
              category: 'road',
              status: any(named: 'status'),
            )).thenAnswer((_) async {
              roadFilterCalls += 1;
              return [roadPin];
            });

        final container =
            buildContainer(mapApi: mockMapApi, wardRepo: mockWardRepo);
        await pumpMap(tester, container);

        expect(find.byKey(const Key('mapFilterChip_road')), findsOneWidget);

        await tester.tap(find.byKey(const Key('mapFilterChip_road')));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();

        // selectCategory('road') -> refetch with category='road' (black-box
        // proxy: the API is called with the road filter at least once).
        expect(roadFilterCalls, greaterThanOrEqualTo(1),
            reason: 'selectCategory(road) must trigger a filtered refetch');

        // Just the road pin remains in pins mode (water filtered out).
        expect(find.byKey(const Key('mapPin_101')), findsOneWidget);
        expect(find.byKey(const Key('mapPin_102')), findsNothing);

        // filteredPins drives heatmap density: only the road cell remains.
        await tester.tap(find.text('Heatmap'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();

        final polygons = heatmapPolygons(tester);
        expect(polygons, hasLength(1),
            reason: 'only the filtered road pin cell may contribute density');
        expect(tester.takeException(), isNull);

        await unmountMap(tester);
      },
    );
  });
}