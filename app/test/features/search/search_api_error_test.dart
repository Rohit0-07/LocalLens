import 'package:flutter_test/flutter_test.dart';
import 'package:local_lens/core/network/api_client.dart';
import 'package:local_lens/core/network/api_exceptions.dart';
import 'package:local_lens/features/search/data/search_api.dart';

/// F-E typed error kinds — `SearchApi` parse-failure contract tests (code-blind).
///
/// Per the F-E plan §4: a response body that is a JSON map (instead of the
/// expected list) or a list containing a non-map item must surface as
/// `ApiParseException` — never as a raw `TypeError`, a partial result, or a
/// silent empty list.

class _FakeApiClient extends ApiClient {
  _FakeApiClient(this.canned)
      : super(baseUrl: 'http://test', accessTokenProvider: () => null);

  final Object canned;

  @override
  Future<dynamic> getJson(String path, {Map<String, dynamic>? query}) async {
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
  test('throws ApiParseException when the body is a JSON map instead of a list', () async {
    final client = _FakeApiClient(<String, Object?>{'detail': 'unexpected shape'});
    final api = SearchApi(client);

    await expectLater(
      api.search(query: 'pothole'),
      throwsA(isA<ApiParseException>()),
    );
  });

  test('throws ApiParseException when a list item is not a map', () async {
    final client = _FakeApiClient(<Object?>[
      _issueJson(1, 'ok item'),
      'not-a-map',
    ]);
    final api = SearchApi(client);

    await expectLater(
      api.search(query: 'pothole'),
      throwsA(isA<ApiParseException>()),
    );
  });
}
