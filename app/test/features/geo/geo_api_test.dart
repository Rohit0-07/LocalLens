import 'package:flutter_test/flutter_test.dart';
import 'package:local_lens/core/network/api_client.dart';
import 'package:local_lens/features/geo/data/geo_api.dart';

/// F-03 Ward Awareness — `GeoApi` + `ReverseGeocode` tests (code-blind).
///
/// Contract source: `docs/4_interfaces.json` (backend-side) plus the F-03
/// reverse-geocode contract passed verbatim to Phase 6 (response shapes and
/// `ReverseGeocode` field mapping). Business scenarios: `docs/3_test_plan.md`
/// BE-01/BE-03 (response shapes), FE-10/FE-11 (app parses success and
/// out-of-coverage responses).
///
/// NOTE: `app/lib/**` is not readable in this phase. The import below follows
/// the established convention of `features/search/data/search_api.dart` used
/// by `search_api_test.dart`; the `ReverseGeocode` type is expected to be
/// exposed from the same data library as `GeoApi`.
///
/// Asserted contract choices (documented so a deviation is a test failure,
/// not a silent change):
///   * `radius_km` is always present in the query — `radiusKm` has a non-null
///     default (50.0) so it cannot be omitted (contrast: `SearchApi` omits
///     filter keys when inactive).
///   * A payload missing a *required scalar* field (`distance_km`, `found`,
///     `latitude`, `longitude`, `place`) fails with a controlled
///     `FormatException` — never a raw crash. Only the `ward` object is
///     documented null-safe/optional.
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

/// Contract-verbatim successful lookup response (BE-01 / FE-10).
Map<String, Object?> _successJson() => <String, Object?>{
      'latitude': 19.1136,
      'longitude': 72.8697,
      'place': 'Ward 45, Urban Central',
      'ward': <String, Object?>{
        'slug': 'ward-45-urban-central',
        'name': 'Ward 45, Urban Central',
        'code': 'W-45',
        'center_latitude': 19.1136,
        'center_longitude': 72.8697,
      },
      'distance_km': 0.4,
      'found': true,
    };

/// Contract-verbatim out-of-coverage response (BE-03 / FE-11).
Map<String, Object?> _outsideCoverageJson() => <String, Object?>{
      'latitude': 28.0,
      'longitude': 77.0,
      'place': 'Outside coverage',
      'ward': null,
      'distance_km': 0.0,
      'found': false,
    };

void main() {
  test('GeoApi.reverseGeocode parses a successful lookup with all fields '
      '(BE-01/FE-10)', () async {
    final client = _FakeApiClient(_successJson());
    final api = GeoApi(client);

    final result = await api.reverseGeocode(
      latitude: 19.1136,
      longitude: 72.8697,
    );

    expect(client.lastPath, '/geo/reverse-geocode');
    expect(result.latitude, 19.1136);
    expect(result.longitude, 72.8697);
    expect(result.place, 'Ward 45, Urban Central');
    expect(result.wardSlug, 'ward-45-urban-central');
    expect(result.wardName, 'Ward 45, Urban Central');
    expect(result.wardCode, 'W-45');
    expect(result.distanceKm, 0.4);
    expect(result.found, isTrue);
  });

  test('GeoApi.reverseGeocode maps out-of-coverage response to found==false '
      'with null ward (BE-03/FE-11)', () async {
    final client = _FakeApiClient(_outsideCoverageJson());
    final api = GeoApi(client);

    final result = await api.reverseGeocode(
      latitude: 28.0,
      longitude: 77.0,
    );

    expect(result.found, isFalse);
    expect(result.place, 'Outside coverage');
    expect(result.wardSlug, isNull);
    expect(result.wardName, isNull);
    expect(result.wardCode, isNull);
    expect(result.latitude, 28.0);
    expect(result.longitude, 77.0);
    expect(result.distanceKm, 0.0);
  });

  test('ReverseGeocode.fromJson is null-safe when ward is null or absent',
      () {
    // 'ward': null — the documented null-safe case.
    final withNullWard = ReverseGeocode.fromJson(_outsideCoverageJson());
    expect(withNullWard.found, isFalse);
    expect(withNullWard.place, 'Outside coverage');
    expect(withNullWard.wardSlug, isNull);
    expect(withNullWard.wardName, isNull);
    expect(withNullWard.wardCode, isNull);
    expect(withNullWard.distanceKm, 0.0);

    // 'ward' key absent entirely — must not crash either.
    final withoutWardKey = ReverseGeocode.fromJson(<String, Object?>{
      'latitude': 19.0,
      'longitude': 73.0,
      'place': 'Ward 12, East Side',
      'distance_km': 1.2,
      'found': true,
    });
    expect(withoutWardKey.found, isTrue);
    expect(withoutWardKey.place, 'Ward 12, East Side');
    expect(withoutWardKey.latitude, 19.0);
    expect(withoutWardKey.longitude, 73.0);
    expect(withoutWardKey.distanceKm, 1.2);
    expect(withoutWardKey.wardSlug, isNull);
    expect(withoutWardKey.wardName, isNull);
    expect(withoutWardKey.wardCode, isNull);
  });

  test('GeoApi.reverseGeocode sends latitude, longitude and radius_km query '
      'params', () async {
    final client = _FakeApiClient(_successJson());
    final api = GeoApi(client);

    await api.reverseGeocode(
      latitude: 19.1136,
      longitude: 72.8697,
      radiusKm: 25.0,
    );

    expect(client.lastPath, '/geo/reverse-geocode');
    expect(client.lastQuery, isNotNull);
    expect(client.lastQuery!['latitude'], 19.1136);
    expect(client.lastQuery!['longitude'], 72.8697);
    expect(client.lastQuery!['radius_km'], 25.0);

    // The 50.0 km default is still sent (non-null default, always mapped).
    await api.reverseGeocode(latitude: 19.0, longitude: 72.0);

    expect(client.lastQuery!['latitude'], 19.0);
    expect(client.lastQuery!['longitude'], 72.0);
    expect(client.lastQuery!['radius_km'], 50.0);
    expect(client.lastQuery!.length, 3);
  });

  test('ReverseGeocode.fromJson raises a controlled FormatException when a '
      'required scalar field is missing (SEC-08)', () {
    final missingScalars = <String, Object?>{
      'latitude': 19.1136,
      'longitude': 72.8697,
      'place': 'Ward 45, Urban Central',
      'ward': null,
      // 'distance_km' and 'found' intentionally absent.
    };

    expect(
      () => ReverseGeocode.fromJson(missingScalars),
      throwsA(isA<FormatException>()),
    );
  });
}
