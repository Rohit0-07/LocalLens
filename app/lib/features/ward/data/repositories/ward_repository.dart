import '../../../../core/network/api_client.dart';
import '../../domain/ward_detail_out.dart';
import '../../domain/ward_list_response.dart';
import '../../domain/ward_summary_out.dart';

abstract class WardRepository {
  Future<WardDetailOut> getWardDetail(String slug, {int issuesLimit = 10});
  Future<WardListResponse> getWards({int limit = 20, int offset = 0});
  Future<WardSummaryOut> getWardByLocation(double latitude, double longitude);
  Future<Map<String, dynamic>> createTalkPost({
    required String wardSlug,
    required String title,
    required String body,
    String topic = 'General',
  });
  Future<List<Map<String, dynamic>>> getTalkPosts({
    required String wardSlug,
    int limit = 20,
    int offset = 0,
  });
}

class WardRepositoryImpl implements WardRepository {
  final ApiClient _client;

  WardRepositoryImpl(this._client);

  @override
  Future<WardDetailOut> getWardDetail(String slug, {int issuesLimit = 10}) async {
    final data = await _client.getJson(
      '/wards/$slug',
      query: {'issues_limit': issuesLimit},
    );
    return WardDetailOut.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<WardListResponse> getWards({int limit = 20, int offset = 0}) async {
    final data = await _client.getJson(
      '/wards',
      query: {'limit': limit, 'offset': offset},
    );
    return WardListResponse.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<WardSummaryOut> getWardByLocation(double latitude, double longitude) async {
    final data = await _client.getJson(
      '/wards/by-location',
      query: {'latitude': latitude, 'longitude': longitude},
    );
    return WardSummaryOut.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> createTalkPost({
    required String wardSlug,
    required String title,
    required String body,
    String topic = 'General',
  }) async {
    final data = await _client.postJson(
      '/wards/$wardSlug/talk',
      body: {
        'title': title,
        'body': body,
        'topic': topic,
      },
    );
    return data as Map<String, dynamic>;
  }

  @override
  Future<List<Map<String, dynamic>>> getTalkPosts({
    required String wardSlug,
    int limit = 20,
    int offset = 0,
  }) async {
    final data = await _client.getJson(
      '/wards/$wardSlug/talk',
      query: {'limit': limit, 'offset': offset},
    );
    final items = data as List<dynamic>;
    return items.map((item) => item as Map<String, dynamic>).toList();
  }
}

