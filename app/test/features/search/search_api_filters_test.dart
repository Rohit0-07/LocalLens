import 'package:flutter_test/flutter_test.dart';
import 'package:local_lens/core/network/api_client.dart';
import 'package:local_lens/features/search/data/search_api.dart';

/// F-08 Advanced Search Filters — `SearchApi` param-mapping tests (code-blind).
///
/// Per `docs/specs/F-08_filters_contracts.md` §2.7 and §3.2 case 13: `SearchApi`
/// must encode active filters into the request query (`status`, repeated
/// `categories` list, `radius_km`, UTC `created_after`/`created_before` ending
/// in `Z`) alongside `q` and `limit: 20`, and must omit every filter key when
/// no filters are active.

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

Map<String, Object?> _issueJson(int id, String title) => <String, Object?>{
  'id': id,
  'title': title,
  'description': 'desc',
  'category': 'road',
  'status': 'open',
  'latitude': 19.1136,
  'longitude': 72.8697,
  'is_anonymous': false,
  'reporter_label': 'Verified citizen',
  'created_at': '2026-08-09T10:00:00.000Z',
};

void main() {
  test('SearchApi maps every active filter param onto the query', () async {
    final client = _FakeApiClient(<Object?>[_issueJson(1, 'alpha')]);
    final api = SearchApi(client);

    await api.search(
      query: 'pothole',
      status: 'resolved',
      categories: const <String>['road', 'water'],
      radiusKm: 5.0,
      createdAfter: DateTime.utc(2026, 8, 3, 12),
      createdBefore: DateTime.utc(2026, 8, 4, 12),
    );

    expect(client.lastPath, '/search');
    final query = client.lastQuery!;
    expect(query['q'], 'pothole');
    expect(query['limit'], 20);
    expect(query['status'], 'resolved');
    expect(query['categories'], <String>['road', 'water']);
    expect(query['radius_km'], 5.0);
    expect(query['created_after'], '2026-08-03T12:00:00.000Z');
    expect((query['created_after'] as String).endsWith('Z'), isTrue);
    expect(query['created_before'], '2026-08-04T12:00:00.000Z');
    expect((query['created_before'] as String).endsWith('Z'), isTrue);
  });

  test('SearchApi omits every filter key when none are active', () async {
    final client = _FakeApiClient(<Object?>[_issueJson(1, 'alpha')]);
    final api = SearchApi(client);

    await api.search(query: 'pothole');

    final query = client.lastQuery!;
    expect(query['q'], 'pothole');
    expect(query['limit'], 20);
    expect(query.containsKey('status'), isFalse);
    expect(query.containsKey('categories'), isFalse);
    expect(query.containsKey('radius_km'), isFalse);
    expect(query.containsKey('created_after'), isFalse);
    expect(query.containsKey('created_before'), isFalse);
  });
}
