import '../../compose/domain/near_duplicate_candidate.dart';
import 'feed_item.dart';
import 'issue.dart';

abstract interface class FeedRepository {
  Future<List<Issue>> fetchNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  });

  Future<List<FeedItem>> fetchMultiTypeFeed({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
    String type = 'all',
    String? cursor,
    int limit = 20,
  });

  Future<Issue> fetchIssue(int issueId);

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
  });

  Future<List<NearDuplicateCandidate>> checkNearDuplicates({
    required double latitude,
    required double longitude,
    String? category,
    double radiusKm = 0.030,
  });

  Future<Issue> submitResolution({
    required int issueId,
    required String proofUrl,
    String? notes,
  });

  Future<Issue> voteQuorum({
    required int issueId,
    required String vote,
    required double latitude,
    required double longitude,
    String? reason,
  });

  Future<Issue> upvoteIssue(
    int issueId, {
    required double latitude,
    required double longitude,
  });

  Future<Issue> removeUpvote(int issueId);

  Future<Issue> toggleUpvote(
    int issueId, {
    required double latitude,
    required double longitude,
    required bool currentlyUpvoted,
  });

  Future<List<Issue>> fetchUserIssues({int? userId, String? status});

  Future<Map<String, dynamic>> fetchPublicUserProfile(int userId);

  Future<void> deleteIssue(int issueId);
}


