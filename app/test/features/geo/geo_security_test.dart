import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:local_lens/core/network/api_client.dart';
import 'package:local_lens/features/geo/data/geo_api.dart';
import 'package:local_lens/features/geo/domain/device_location_service.dart';
import 'package:local_lens/features/geo/presentation/providers/geo_providers.dart';
import 'package:local_lens/features/geo/presentation/widgets/ward_location_chip.dart';

/// F-03 Ward Awareness - geo feature SECURITY tests (SEC-01..SEC-08).
///
/// Code-blind Phase 6: written from `docs/3_test_plan.md` (Security section,
/// SEC-01..SEC-08) plus the F-03 contract passed verbatim to this phase.
/// `app/lib/**` is not readable here; the imports and fake harnesses mirror
/// the conventions already established by `geo_widget_test.dart` and
/// `geo_api_test.dart`.
///
/// Security rules under test (verbatim contract):
///   * no PII, no anonymous identity, no reporter info, no email/phone may be
///     rendered anywhere in the geo feature;
///   * API failure degrades to a graceful `WardLocationUnavailable` - no
///     crash, no exception surfaced to the UI (no red error screen);
///   * malformed payloads yield a controlled `FormatException` or
///     "unavailable", never an uncaught throw.
///
/// Contract choices asserted (documented so a deviation fails loudly):
///   * SEC-08 malformed payload: the parse boundary raises a controlled
///     `FormatException` (same choice as `geo_api_test.dart`); the provider
///     then converts that failure into `WardLocationUnavailable`, so BOTH
///     halves of the "FormatException OR unavailable" rule are asserted.
///   * `ReverseGeocode` exposes only the contract fields (latitude, longitude,
///     place, wardSlug?, wardName?, wardCode?, distanceKm, found) - there is
///     no getter for email/phone/anon_id to assert against. The mechanical
///     proxy is therefore: a PII-contaminated payload parses without throwing,
///     and no parsed field value (nor rendered widget text, nor navigation
///     URI) contains any PII string.
///   * SEC-02/SEC-06 request hygiene: the reverse-geocode request carries only
///     `latitude`, `longitude`, `radius_km` - no identity, anon id, email,
///     phone or device id is ever sent, stored, or reused by the feature.

const double kTestLat = 19.1136;
const double kTestLng = 72.8697;
const String kTestPlace = 'Ward 45, Urban Central';
const String kTestSlug = 'ward-45-urban-central';

/// SEC-01: a contract-valid success payload deliberately contaminated with
/// PII-looking extra fields (email / phone / anon identity / reporter info /
/// device id). The feature must parse it and surface none of them.
Map<String, Object?> piiContaminatedSuccessJson() => <String, Object?>{
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
      // PII-looking extras that must never surface (SEC-01).
      'email': 'citizen@example.com',
      'phone': '+91-98765-43210',
      'anon_id': 'anon_7f3a9c2e',
      'anonymous_identity': 'anon_7f3a9c2e',
      'reporter_label': 'citizen@example.com',
      'reporter_id': 42,
      'user_id': 42,
      'device_id': 'device-abc-123',
    };

/// SEC-01: an edge-case ("outside coverage", ward == null) payload also
/// contaminated with PII extras - "including error and edge-case responses".
Map<String, Object?> piiContaminatedOutsideCoverageJson() => <String, Object?>{
      'latitude': 28.0,
      'longitude': 77.0,
      'place': 'Outside coverage',
      'ward': null,
      'distance_km': 0.0,
      'found': false,
      'email': 'citizen@example.com',
      'phone': '+91-98765-43210',
      'anon_id': 'anon_7f3a9c2e',
    };

/// Clean success lookup (same shape as `geo_widget_test.dart`), used as the
/// default `FakeGeoApi` result.
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

/// Success lookup whose JSON was contaminated with PII extras (SEC-01). The
/// parsed model must contain only ward place information.
final ReverseGeocode piiContaminatedGeocode =
    ReverseGeocode.fromJson(piiContaminatedSuccessJson());

/// SEC-01 / SEC-02 request-level fake: records the exact GET request so the
/// test can prove no identity/PII parameter is ever attached.
class _FakeApiClient extends ApiClient {
  _FakeApiClient(this.canned)
      : super(baseUrl: 'http://test', accessTokenProvider: () => null);

  final Object canned;
  String? lastPath;
  Map<String, dynamic>? lastQuery;

  @override
  Future<dynamic> getJson(String path, {Map<String, dynamic>? query}) async {
    lastPath = path;
    lastQuery = query;
    return canned;
  }
}

class FakeDeviceLocationService implements DeviceLocationService {
  FakeDeviceLocationService({this.error});

  final Object? error;
  int callCount = 0;

  @override
  Future<({double lat, double lng})> getCurrentCoordinates() async {
    callCount += 1;
    if (error != null) throw error!;
    return (lat: kTestLat, lng: kTestLng);
  }
}

class FakeGeoApi implements GeoApi {
  FakeGeoApi({this.result, this.error});

  ReverseGeocode? result;
  Object? error;
  int callCount = 0;

  @override
  Future<ReverseGeocode> reverseGeocode({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
  }) async {
    callCount += 1;
    if (error != null) throw error!;
    return result ?? sampleReverseGeocode;
  }
}

/// Renders the chip off the real wardLocationProvider so the full
/// controller -> chip wiring is exercised (same harness as
/// `geo_widget_test.dart`).
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

  group('ReverseGeocode PII hygiene (SEC-01, SEC-08)', () {
    test(
      'SEC-01: ReverseGeocode.fromJson ignores PII-looking extra fields '
      '(email/phone/anon_id/device_id) in a success payload - no throw and '
      'nothing surfaces through the contract fields',
      () {
        final parsed = ReverseGeocode.fromJson(piiContaminatedSuccessJson());

        // All contract fields still parse correctly.
        expect(parsed.latitude, kTestLat);
        expect(parsed.longitude, kTestLng);
        expect(parsed.place, kTestPlace);
        expect(parsed.wardSlug, kTestSlug);
        expect(parsed.wardName, kTestPlace);
        expect(parsed.wardCode, 'W-45');
        expect(parsed.distanceKm, 0.4);
        expect(parsed.found, isTrue);

        // The model exposes ONLY the contract fields, so a contaminated
        // payload cannot leak through them: none of the parsed values carry
        // any PII string (SEC-01: "no personal data (PII)").
        final surfacedValues = <String>[
          parsed.place,
          parsed.wardSlug ?? '',
          parsed.wardName ?? '',
          parsed.wardCode ?? '',
          '${parsed.latitude}',
          '${parsed.longitude}',
          '${parsed.distanceKm}',
          '${parsed.found}',
        ];
        for (final value in surfacedValues) {
          expect(value.contains('citizen@example.com'), isFalse,
              reason: 'email leaked into "$value"');
          expect(value.contains('+91-98765-43210'), isFalse,
              reason: 'phone leaked into "$value"');
          expect(value.contains('anon_7f3a9c2e'), isFalse,
              reason: 'anon identity leaked into "$value"');
          expect(value.contains('device-abc-123'), isFalse,
              reason: 'device id leaked into "$value"');
        }
      },
    );

    test(
      'SEC-01: edge-case "outside coverage" payload (ward == null) with PII '
      'extras still parses null-safe and surfaces nothing',
      () {
        final parsed = ReverseGeocode.fromJson(
          piiContaminatedOutsideCoverageJson(),
        );

        // Contract-valid edge case behavior is unchanged.
        expect(parsed.found, isFalse);
        expect(parsed.place, 'Outside coverage');
        expect(parsed.wardSlug, isNull);
        expect(parsed.wardName, isNull);
        expect(parsed.wardCode, isNull);
        expect(parsed.distanceKm, 0.0);

        // No PII string surfaces through the contract fields.
        final surfacedValues = <String>[
          parsed.place,
          '${parsed.latitude}',
          '${parsed.longitude}',
          '${parsed.distanceKm}',
          '${parsed.found}',
        ];
        for (final value in surfacedValues) {
          expect(value.contains('citizen@example.com'), isFalse,
              reason: 'email leaked into "$value"');
          expect(value.contains('+91-98765-43210'), isFalse,
              reason: 'phone leaked into "$value"');
          expect(value.contains('anon_7f3a9c2e'), isFalse,
              reason: 'anon identity leaked into "$value"');
        }
      },
    );

    test(
      'SEC-02/SEC-06: reverse-geocode request carries ONLY location query '
      'params - no identity, anon_id, email, phone or device id is ever sent, '
      'and a contaminated response still yields only ward data',
      () async {
        final client = _FakeApiClient(piiContaminatedSuccessJson());
        final api = GeoApi(client);

        final result = await api.reverseGeocode(
          latitude: kTestLat,
          longitude: kTestLng,
        );

        // Request shape: GET /geo/reverse-geocode with exactly the three
        // contract query params (peer geo_api_test.dart asserts the same 3).
        expect(client.lastPath, '/geo/reverse-geocode');
        expect(client.lastQuery, isNotNull);
        expect(
          client.lastQuery!.keys.toSet(),
          <String>{'latitude', 'longitude', 'radius_km'},
        );

        // No identity/PII can sneak into the request (SEC-02: no identity
        // required; SEC-06: location not tied to identity).
        final queryText = client.lastQuery!.values.join('|');
        expect(queryText.contains('anon'), isFalse);
        expect(queryText.contains('@'), isFalse);
        expect(queryText.contains('+91'), isFalse);
        expect(queryText.contains('email'), isFalse);
        expect(queryText.contains('phone'), isFalse);
        expect(queryText.contains('device'), isFalse);

        // The contaminated canned response still parses to ward data only.
        expect(result.place, kTestPlace);
        expect(result.wardCode, 'W-45');
        expect(result.place.contains('citizen@example.com'), isFalse);
        expect((result.wardName ?? '').contains('+91'), isFalse);
        expect((result.wardSlug ?? '').contains('anon_7f3a9c2e'), isFalse);
      },
    );

    test(
      'SEC-08: structurally invalid payload (missing required fields plus '
      'extra unknown PII fields) raises a controlled FormatException - never '
      'an uncaught throw. CHOICE (documented): controlled FormatException at '
      'the parse boundary; the provider converts it to unavailable (next '
      'test), covering both halves of the "FormatException OR unavailable" '
      'rule.',
      () {
        // Note: duplicated keys cannot be expressed in a Dart map literal
        // (last one wins), so "duplicated fields" collapses into the
        // "extra unknown fields" case here.
        final malformed = <String, Object?>{
          'latitude': kTestLat,
          'longitude': kTestLng,
          'place': kTestPlace,
          'ward': null,
          // 'distance_km' and 'found' intentionally absent (SEC-08).
          'email': 'citizen@example.com',
          'anon_id': 'anon_7f3a9c2e',
        };

        expect(
          () => ReverseGeocode.fromJson(malformed),
          throwsA(isA<FormatException>()),
        );
      },
    );
  });

  group('wardLocationProvider security behavior (SEC-08, FE-03, FE-09, FE-10)',
      () {
    test(
      'SEC-08/FE-03: provider maps a failing GeoApi - network error OR '
      'FormatException from a malformed payload - to WardLocationUnavailable; '
      'no exception ever propagates to the caller',
      () async {
        for (final error in <Object>[
          StateError('network unreachable'),
          FormatException('malformed payload'),
        ]) {
          final container = buildContainer(
            geoApi: FakeGeoApi(error: error),
          );

          final state = await waitForResolvedState(container);

          expect(state, isA<WardLocationUnavailable>(),
              reason: 'for error: $error');
          expect(
            container.read(wardLocationProvider),
            isA<WardLocationUnavailable>(),
            reason: 'for error: $error',
          );
        }
      },
    );

    testWidgets(
      'SEC-01/FE-03: widget with an erroring GeoApi still renders cleanly - '
      'Key(wardLocationUnavailable) and "Location unavailable", and NO red '
      'error screen (takeException is null)',
      (tester) async {
        final container = buildContainer(
          geoApi: FakeGeoApi(error: StateError('network unreachable')),
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: WardLocationChipHarness()),
          ),
        );
        await tester.pumpAndSettle();

        // Graceful degradation per the contract: unavailable state, message,
        // no ward chip, no error UI.
        expect(find.byKey(const Key('wardLocationUnavailable')), findsOneWidget);
        expect(find.text('Location unavailable'), findsOneWidget);
        expect(find.byKey(const Key('wardLocationChip')), findsNothing);
        expect(find.text('Locating…'), findsNothing);

        // "no red error screen": any uncaught build/layout exception would be
        // captured by the test binding and surfaced by takeException().
        expect(tester.takeException(), isNull);
        expect(
          container.read(wardLocationProvider),
          isA<WardLocationUnavailable>(),
        );
      },
    );

    testWidgets(
      'SEC-01/FE-10: success state renders ONLY ward place info - place and '
      'code present, no email/phone/anon identity/reporter info, no raw '
      'coordinates',
      (tester) async {
        final container = buildContainer(
          geoApi: FakeGeoApi(result: piiContaminatedGeocode),
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: WardLocationChipHarness()),
          ),
        );
        await tester.pumpAndSettle();

        // Ward place info is rendered (FE-10: name and code).
        expect(find.byKey(const Key('wardLocationChip')), findsOneWidget);
        expect(find.textContaining(kTestPlace), findsOneWidget);
        expect(find.textContaining('W-45'), findsOneWidget);
        expect(
          container.read(wardLocationProvider),
          isA<WardLocationSuccess>(),
        );

        // None of the PII from the contaminated payload surfaces anywhere
        // in the widget tree (SEC-01).
        expect(find.textContaining('citizen@example.com'), findsNothing);
        expect(find.textContaining('+91-98765-43210'), findsNothing);
        expect(find.textContaining('anon_7f3a9c2e'), findsNothing);
        expect(find.textContaining('device-abc-123'), findsNothing);
        expect(find.textContaining('reporter_id'), findsNothing);
        expect(find.textContaining('user_id'), findsNothing);

        // Precise device coordinates are never rendered either (SEC-06: the
        // location is used only to determine the ward label, never shown).
        expect(find.textContaining('$kTestLat'), findsNothing);
        expect(find.textContaining('$kTestLng'), findsNothing);

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'SEC-01/FE-09: tapping the success chip navigates to the ward detail '
      'page carrying ONLY the public slug - no sensitive data in the '
      'navigation',
      (tester) async {
        final container = buildContainer(
          geoApi: FakeGeoApi(result: piiContaminatedGeocode),
        );

        final router = GoRouter(
          initialLocation: '/feed',
          routes: [
            GoRoute(
              path: '/feed',
              builder: (context, state) => const WardLocationChipHarness(),
            ),
            GoRoute(
              path: '/ward/:slug',
              builder: (context, state) => const Scaffold(
                key: Key('wardDetailScreen'),
                body: Text('ward detail'),
              ),
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

        await tester.tap(find.byKey(const Key('wardLocationChip')));
        await tester.pumpAndSettle();

        // Correct ward detail destination (FE-09).
        expect(router.state.matchedLocation, '/ward/ward-45-urban-central');
        expect(find.byKey(const Key('wardDetailScreen')), findsOneWidget);

        // The navigation carries only the public ward slug as a path segment;
        // no query params, and no PII/identity text anywhere in the URI.
        expect(
          router.state.uri.pathSegments,
          <String>['ward', 'ward-45-urban-central'],
        );
        expect(router.state.uri.queryParameters, isEmpty);
        final uriText = router.state.uri.toString();
        expect(uriText.contains('citizen@example.com'), isFalse);
        expect(uriText.contains('+91'), isFalse);
        expect(uriText.contains('anon_'), isFalse);
        expect(uriText.contains('device-abc-123'), isFalse);

        // The destination page renders no sensitive data either.
        expect(find.textContaining('citizen@example.com'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
