import 'dart:convert';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/local_store.dart';
import '../../domain/official_response.dart';
import '../../domain/representative_profile.dart';
import '../../domain/ward_issues_response.dart';

class RepDashboardRepository {
  final ApiClient _apiClient;
  final LocalStore _localStore;

  RepDashboardRepository(this._apiClient, this._localStore);

  Future<RepresentativeProfile> fetchRepresentativeProfile() async {
    try {
      final json = await _apiClient.getJson('/representatives/me');
      final profile = RepresentativeProfile.fromJson(json as Map<String, dynamic>);
      await _localStore.setString('rep_profile', jsonEncode(profile.toJson()));
      return profile;
    } catch (e) {
      final cachedJsonStr = _localStore.getString('rep_profile');
      if (cachedJsonStr != null && cachedJsonStr.isNotEmpty) {
        try {
          final cachedMap = jsonDecode(cachedJsonStr) as Map<String, dynamic>;
          return RepresentativeProfile.fromJson(cachedMap);
        } catch (_) {
          // If decoding cache fails, rethrow original error
        }
      }
      rethrow;
    }
  }

  Future<WardIssuesResponse> fetchWardIssues({
    String filter = 'all',
    int limit = 20,
    int offset = 0,
  }) async {
    final json = await _apiClient.getJson(
      '/representatives/ward-issues',
      query: {
        'filter': filter,
        'limit': limit,
        'offset': offset,
      },
    );
    return WardIssuesResponse.fromJson(json as Map<String, dynamic>);
  }

  Future<OfficialResponse> postOfficialResponse({
    required int issueId,
    required String message,
    int? estimatedResolutionDays,
    String? statusUpdate,
  }) async {
    final body = <String, dynamic>{
      'message': message,
      'estimated_resolution_days': ?estimatedResolutionDays,
      'status_update': ?statusUpdate,
    };
    final json = await _apiClient.postJson(
      '/issues/$issueId/official-response',
      body: body,
    );
    return OfficialResponse.fromJson(json as Map<String, dynamic>);
  }

  Future<List<OfficialResponse>> fetchOfficialResponses(int issueId) async {
    final json = await _apiClient.getJson('/issues/$issueId/official-responses');
    final list = json as List<dynamic>;
    return list.map((e) => OfficialResponse.fromJson(e as Map<String, dynamic>)).toList();
  }
}
