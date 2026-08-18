import '../../../core/network/api_client.dart';
import '../../compose/domain/near_duplicate_candidate.dart';
import '../domain/feed_item.dart';
import '../domain/feed_repository.dart';
import '../domain/issue.dart';

class FeedApi implements FeedRepository {
  FeedApi(this._client);

  final ApiClient _client;

  @override
  Future<List<Issue>> fetchNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    final data = await _client.getJson(
      '/issues',
      query: {
        'latitude': latitude,
        'longitude': longitude,
        'radius_km': radiusKm,
      },
    );
    final items = data as List<dynamic>;
    return items
        .map((item) => Issue.fromJson(item as Map<String, Object?>))
        .toList(growable: false);
  }

  @override
  Future<List<FeedItem>> fetchMultiTypeFeed({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
    String type = 'all',
    String? cursor,
    int limit = 20,
  }) async {
    final query = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      'radius_km': radiusKm,
      'type': type,
      'limit': limit,
    };
    if (cursor != null) query['cursor'] = cursor;

    final data = await _client.getJson('/feed', query: query);
    final items = data as List<dynamic>;
    return items
        .map((item) => FeedItem.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }


  @override
  Future<Issue> fetchIssue(int issueId) async {
    final data = await _client.getJson('/issues/$issueId');
    return Issue.fromJson(data as Map<String, Object?>);
  }

  @override
  Future<Issue> createIssue({
    required String title,
    required String description,
    required String category,
    required double latitude,
    required double longitude,
    required bool isAnonymous,
    bool isFuzzed = false,
    bool isShielded = false,
    List<String> mediaUrls = const [],
  }) async {
    final data = await _client.postJson(
      '/issues',
      body: {
        'title': title,
        'description': description,
        'category': category,
        'latitude': latitude,
        'longitude': longitude,
        'is_anonymous': isAnonymous,
        'is_fuzzed': isFuzzed,
        'fuzz_location': isFuzzed,
        'is_shielded': isShielded,
        if (mediaUrls.isNotEmpty) 'media_urls': mediaUrls,
      },
    );
    return Issue.fromJson(data as Map<String, Object?>);
  }

  @override
  Future<List<NearDuplicateCandidate>> checkNearDuplicates({
    required double latitude,
    required double longitude,
    String? category,
    double radiusKm = 0.030,
  }) async {
    final query = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      'radius_km': radiusKm,
    };
    if (category != null && category.isNotEmpty) {
      query['category'] = category;
    }
    final data = await _client.getJson(
      '/issues/near-duplicate',
      query: query,
    );
    final items = data as List<dynamic>;
    return items
        .map((item) =>
            NearDuplicateCandidate.fromJson(item as Map<String, Object?>))
        .toList(growable: false);
  }

  @override
  Future<Issue> submitResolution({
    required int issueId,
    required String proofUrl,
    String? notes,
  }) async {
    final data = await _client.postJson(
      '/issues/$issueId/resolve',
      body: {
        'resolution_proof': proofUrl,
        'notes': notes,
      },
    );
    return Issue.fromJson(data as Map<String, Object?>);
  }

  @override
  Future<Issue> voteQuorum({
    required int issueId,
    required String vote,
    required double latitude,
    required double longitude,
    String? reason,
  }) async {
    final data = await _client.postJson(
      '/issues/$issueId/quorum-vote',
      body: {
        'vote': vote,
        'latitude': latitude,
        'longitude': longitude,
        'reason': reason,
      },
    );
    return Issue.fromJson(data as Map<String, Object?>);
  }

  @override
  Future<Issue> upvoteIssue(
    int issueId, {
    required double latitude,
    required double longitude,
  }) async {
    final data = await _client.postJson(
      '/issues/$issueId/upvote',
      body: {
        'latitude': latitude,
        'longitude': longitude,
      },
    );
    return Issue.fromJson(data as Map<String, Object?>);
  }

  @override
  Future<Issue> removeUpvote(int issueId) async {
    final data = await _client.deleteJson('/issues/$issueId/upvote');
    return Issue.fromJson(data as Map<String, Object?>);
  }

  @override
  Future<Issue> toggleUpvote(
    int issueId, {
    required double latitude,
    required double longitude,
    required bool currentlyUpvoted,
  }) async {
    if (currentlyUpvoted) {
      return removeUpvote(issueId);
    } else {
      return upvoteIssue(
        issueId,
        latitude: latitude,
        longitude: longitude,
      );
    }
  }

  @override
  Future<List<Issue>> fetchUserIssues({int? userId, String? status}) async {
    if (userId != null) {
      final profile = await _client.getJson('/users/$userId');
      final items =
          (profile as Map<dynamic, dynamic>)['public_issues'] as List<dynamic>?;
      if (items == null) return const [];
      return items
          .map((item) => Issue.fromJson(item as Map<String, Object?>))
          .toList(growable: false);
    }

    final query = <String, dynamic>{};
    if (status != null) query['status'] = status;
    final data =
        await _client.getJson('/auth/me/issues', query: query.isNotEmpty ? query : null);
    final items = data as List<dynamic>;
    return items
        .map((item) => Issue.fromJson(item as Map<String, Object?>))
        .toList(growable: false);
  }

  @override
  Future<Map<String, dynamic>> fetchPublicUserProfile(int userId) async {
    final data = await _client.getJson('/users/$userId');
    return (data as Map<dynamic, dynamic>).cast<String, dynamic>();
  }

  @override
  Future<void> deleteIssue(int issueId) async {
    await _client.deleteJson('/issues/$issueId');
  }
}

