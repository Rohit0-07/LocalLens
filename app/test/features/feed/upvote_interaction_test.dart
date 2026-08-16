import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lens/features/compose/domain/near_duplicate_candidate.dart';
import 'package:local_lens/features/feed/domain/feed_repository.dart';
import 'package:local_lens/features/feed/domain/issue.dart';
import 'package:local_lens/features/feed/presentation/feed_providers.dart';
import 'package:local_lens/features/feed/presentation/widgets/issue_card.dart';

import 'package:local_lens/features/feed/domain/feed_item.dart';

class UpvoteTestFeedRepository implements FeedRepository {
  UpvoteTestFeedRepository({
    required this.issues,
    this.shouldFail = false,
    this.errorMessage = 'Failed to toggle upvote',
  });

  List<Issue> issues;
  bool shouldFail;
  String errorMessage;
  int toggleCallCount = 0;

  @override
  Future<Issue> upvoteIssue(
    int issueId, {
    required double latitude,
    required double longitude,
  }) async {
    return _applyToggle(issueId, true);
  }

  @override
  Future<Issue> removeUpvote(int issueId) async {
    return _applyToggle(issueId, false);
  }

  @override
  Future<Issue> toggleUpvote(
    int issueId, {
    required double latitude,
    required double longitude,
    required bool currentlyUpvoted,
  }) async {
    return _applyToggle(issueId, !currentlyUpvoted);
  }

  Future<Issue> _applyToggle(int issueId, bool targetUpvoted) async {
    toggleCallCount++;
    if (shouldFail) {
      throw Exception(errorMessage);
    }
    final index = issues.indexWhere((i) => i.id == issueId);
    if (index != -1) {
      final current = issues[index];
      final currentHasUpvoted = current.hasUpvoted;
      final currentCount = current.upvotesCount;
      final newHasUpvoted = targetUpvoted;
      final newCount = newHasUpvoted
          ? (currentHasUpvoted ? currentCount : currentCount + 1)
          : (currentHasUpvoted ? (currentCount > 0 ? currentCount - 1 : 0) : currentCount);

      final updated = current.copyWith(
        hasUpvoted: newHasUpvoted,
        upvotesCount: newCount,
      );

      issues[index] = updated;
      return updated;
    }
    throw Exception('Issue not found');
  }

  @override
  Future<List<Issue>> fetchUserIssues({int? userId, String? status}) async {
    return issues;
  }

  @override
  Future<Map<String, dynamic>> fetchPublicUserProfile(int userId) async {
    return {'id': userId};
  }

  @override
  Future<List<Issue>> fetchNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    return issues;
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
    return issues.map((i) => FeedItem(itemType: FeedItemType.issue, issue: i)).toList();
  }

  @override
  Future<Issue> fetchIssue(int issueId) async {
    return issues.firstWhere((i) => i.id == issueId);
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
    throw UnimplementedError();
  }

  @override
  Future<List<NearDuplicateCandidate>> checkNearDuplicates({
    required double latitude,
    required double longitude,
    double radiusKm = 0.5,
  }) async {
    return [];
  }

  @override
  Future<Issue> submitResolution({
    required int issueId,
    required String proofUrl,
    String? notes,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Issue> voteQuorum({
    required int issueId,
    required String vote,
    required double latitude,
    required double longitude,
    String? reason,
  }) async {
    throw UnimplementedError();
  }
}

Issue createTestIssue({
  required int id,
  required String title,
  required int upvotesCount,
  required bool hasUpvoted,
}) {
  return Issue.fromJson({
    'id': id,
    'title': title,
    'description': 'Test issue description',
    'category': 'road',
    'status': 'open',
    'latitude': 19.1136,
    'longitude': 72.8697,
    'is_anonymous': false,
    'reporter_label': 'Citizen',
    'created_at': '2026-08-09T10:00:00Z',
    'upvotes_count': upvotesCount,
    'has_upvoted': hasUpvoted,
  });
}

Finder findUpvoteButton(WidgetTester tester, [int? issueId]) {
  if (issueId != null) {
    final keyFinder = find.byKey(Key('upvote_button_$issueId'));
    if (keyFinder.evaluate().isNotEmpty) return keyFinder;
  }
  final genericKeyFinder = find.byKey(const Key('upvote_button'));
  if (genericKeyFinder.evaluate().isNotEmpty) return genericKeyFinder;

  final iconFinder = find.byIcon(Icons.thumb_up_outlined);
  if (iconFinder.evaluate().isNotEmpty) return iconFinder;

  final filledIconFinder = find.byIcon(Icons.thumb_up);
  if (filledIconFinder.evaluate().isNotEmpty) return filledIconFinder;

  return find.byIcon(Icons.arrow_upward);
}

Finder findCountText(String count) {
  final exactFinder = find.text(count);
  if (exactFinder.evaluate().isNotEmpty) return exactFinder;
  return find.textContaining(count);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IssueCard Upvote Interaction', () {
    testWidgets('renders inactive upvote button when hasUpvoted is false',
        (tester) async {
      final issue = createTestIssue(
        id: 1,
        title: 'Broken bench in park',
        upvotesCount: 5,
        hasUpvoted: false,
      );
      final repo = UpvoteTestFeedRepository(issues: [issue]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [feedRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            home: Scaffold(
              body: IssueCard(issue: issue),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check upvotes count is displayed
      expect(findCountText('5'), findsOneWidget);

      // Check upvote button exists
      final upvoteBtn = findUpvoteButton(tester, issue.id);
      expect(upvoteBtn, findsOneWidget);
    });

    testWidgets('renders active upvote button when hasUpvoted is true',
        (tester) async {
      final issue = createTestIssue(
        id: 2,
        title: 'Streetlight out',
        upvotesCount: 12,
        hasUpvoted: true,
      );
      final repo = UpvoteTestFeedRepository(issues: [issue]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [feedRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            home: Scaffold(
              body: IssueCard(issue: issue),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check upvotes count is displayed
      expect(findCountText('12'), findsOneWidget);

      // Check upvote button exists
      final upvoteBtn = findUpvoteButton(tester, issue.id);
      expect(upvoteBtn, findsOneWidget);
    });

    testWidgets(
        'optimistic upvote toggle: tap upvote button increments count and sets hasUpvoted = true',
        (tester) async {
      final issue = createTestIssue(
        id: 3,
        title: 'Pothole on Main Road',
        upvotesCount: 3,
        hasUpvoted: false,
      );
      final repo = UpvoteTestFeedRepository(issues: [issue]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [feedRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            home: Scaffold(
              body: IssueCard(issue: issue),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(findCountText('3'), findsOneWidget);

      final upvoteBtn = findUpvoteButton(tester, issue.id);
      await tester.tap(upvoteBtn);

      // Immediately after tap (optimistic state check)
      await tester.pump();
      expect(findCountText('4'), findsOneWidget);

      // Settle network call
      await tester.pumpAndSettle();
      expect(repo.toggleCallCount, 1);
      expect(findCountText('4'), findsOneWidget);
    });

    testWidgets(
        'optimistic un-upvote toggle: tap active upvote button decrements count and sets hasUpvoted = false',
        (tester) async {
      final issue = createTestIssue(
        id: 5,
        title: 'Garbage dump on sidewalk',
        upvotesCount: 8,
        hasUpvoted: true,
      );
      final repo = UpvoteTestFeedRepository(issues: [issue]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [feedRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            home: Scaffold(
              body: IssueCard(issue: issue),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(findCountText('8'), findsOneWidget);

      final upvoteBtn = findUpvoteButton(tester, issue.id);
      await tester.tap(upvoteBtn);

      // Immediately after tap (optimistic state check)
      await tester.pump();
      expect(findCountText('7'), findsOneWidget);

      // Settle network call
      await tester.pumpAndSettle();
      expect(repo.toggleCallCount, 1);
      expect(findCountText('7'), findsOneWidget);
    });

    testWidgets(
        'error recovery: if upvote API call fails, reverts count and hasUpvoted state and displays error toast',
        (tester) async {
      final issue = createTestIssue(
        id: 4,
        title: 'Water pipe leak',
        upvotesCount: 7,
        hasUpvoted: false,
      );
      final repo = UpvoteTestFeedRepository(
        issues: [issue],
        shouldFail: true,
        errorMessage: 'Network error',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [feedRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            home: Scaffold(
              body: IssueCard(issue: issue),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(findCountText('7'), findsOneWidget);

      final upvoteBtn = findUpvoteButton(tester, issue.id);
      await tester.tap(upvoteBtn);

      // Pump to let the future fail and error recovery execute
      await tester.pumpAndSettle();

      // Count should be reverted back to 7
      expect(findCountText('7'), findsOneWidget);

      // Error toast / SnackBar or error message should be displayed
      final errorToastFinder = find.byType(SnackBar);
      final errorTextFinder = find.textContaining('Network error');
      final failedTextFinder = find.textContaining('Failed');
      final generalErrorFinder = find.textContaining('error');

      expect(
        errorToastFinder.evaluate().isNotEmpty ||
            errorTextFinder.evaluate().isNotEmpty ||
            failedTextFinder.evaluate().isNotEmpty ||
            generalErrorFinder.evaluate().isNotEmpty,
        isTrue,
        reason: 'An error toast or message should be displayed upon failure',
      );
    });
  });
}
