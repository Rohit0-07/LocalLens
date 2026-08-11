import '../../../core/network/api_client.dart';
import '../../feed/domain/issue.dart';
import '../domain/search_repository.dart';

class SearchApi implements SearchRepository {
  SearchApi(this._client);

  final ApiClient _client;

  @override
  Future<List<Issue>> search({
    required String query,
    double? latitude,
    double? longitude,
    String? status,
    List<String> categories = const <String>[],
    double? radiusKm,
    DateTime? createdAfter,
    DateTime? createdBefore,
  }) async {
    final data = await _client.getJson(
      '/search',
      query: {
        'q': query,
        'latitude': ?latitude,
        'longitude': ?longitude,
        'status': ?status,
        if (categories.isNotEmpty) 'categories': categories,
        'radius_km': ?radiusKm,
        if (createdAfter != null)
          'created_after': createdAfter.toUtc().toIso8601String(),
        if (createdBefore != null)
          'created_before': createdBefore.toUtc().toIso8601String(),
        'limit': 20,
      },
    );
    final items = data as List<dynamic>;
    return items
        .map((item) => Issue.fromJson(item as Map<String, Object?>))
        .toList(growable: false);
  }
}