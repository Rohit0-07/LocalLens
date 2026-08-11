import 'package:flutter_test/flutter_test.dart';
import 'package:local_lens/core/network/api_client.dart';
import 'package:local_lens/features/search/data/search_api.dart';

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
  test('SearchApi maps query params and parses via Issue.fromJson', () async {
    final client = _FakeApiClient(<Object?>[_issueJson(1, 'alpha'), _issueJson(2, 'beta')]);
    final api = SearchApi(client);

    final issues = await api.search(query: 'pothole');

    expect(client.lastPath, '/search');
    expect(client.lastQuery, isNotNull);
    expect(client.lastQuery!['q'], 'pothole');
    expect(client.lastQuery!['limit'], 20);
    expect(client.lastQuery!.containsKey('latitude'), isFalse);
    expect(client.lastQuery!.containsKey('longitude'), isFalse);
    expect(issues.map((issue) => issue.id), <int>[1, 2]);
    expect(issues.map((issue) => issue.title), <String>['alpha', 'beta']);

    await api.search(query: 'pothole', latitude: 19.11, longitude: 72.87);

    expect(client.lastQuery!['latitude'], 19.11);
    expect(client.lastQuery!['longitude'], 72.87);
  });
}