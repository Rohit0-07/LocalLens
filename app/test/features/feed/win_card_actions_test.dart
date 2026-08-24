import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lens/features/feed/domain/feed_repository.dart';
import 'package:local_lens/features/feed/domain/issue.dart';
import 'package:local_lens/features/feed/domain/win.dart';
import 'package:local_lens/features/feed/presentation/feed_providers.dart';
import 'package:local_lens/features/feed/presentation/widgets/social_action.dart';
import 'package:local_lens/features/feed/presentation/widgets/win_card.dart';
import 'package:local_lens/features/issue_detail/data/issue_detail_api.dart';
import 'package:local_lens/features/issue_detail/presentation/widgets/comments_section.dart';

import '../../helpers.dart';

class _CountingFeedRepository extends FakeFeedRepository {
  int upvoteCalls = 0;

  @override
  Future<Issue> upvoteIssue(
    int issueId, {
    required double latitude,
    required double longitude,
  }) async {
    upvoteCalls++;
    return super.upvoteIssue(issueId, latitude: latitude, longitude: longitude);
  }
}

class _FakeIssueDetailApi implements IssueDetailApi {
  @override
  Future<List<Comment>> getComments(int issueId) async => [
        Comment(
          id: 1,
          issueId: issueId,
          anonId: 'anon_1',
          content: 'Great work!',
          createdAt: DateTime.utc(2026, 8, 20),
          isAuthor: false,
        ),
      ];

  @override
  Future<Comment> postComment(int issueId, String content,
      {dynamic parentId}) async {
    return Comment(
      id: 2,
      issueId: issueId,
      anonId: 'anon_2',
      content: content,
      createdAt: DateTime.now(),
      isAuthor: true,
    );
  }

  @override
  Future<void> deleteComment(int issueId, dynamic commentId) async {}

  @override
  Future<dynamic> getTimeline(int issueId) async => null;

  @override
  Future<void> reportWrongAssignment({
    required int issueId,
    String? suggestedWard,
    String? suggestedCategory,
    String? reason,
  }) async {}
}

WinItem _createWin({int id = 3, int issueId = 77}) {
  return WinItem(
    id: id,
    issueId: issueId,
    title: 'Water tanker schedule fixed',
    description: 'Two tankers dispatched on morning and evening shifts',
    category: 'water',
    ward: 'Ward 45, Urban Central',
    latitude: 19.1136,
    longitude: 72.8697,
    contributorCredits: const ['Verified Citizen'],
    createdAt: DateTime.utc(2026, 8, 20, 9),
  );
}

Future<void> _pumpWinCard(
  WidgetTester tester, {
  FeedRepository? feedRepo,
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        fakeVoterLocationOverride,
        if (feedRepo != null)
          feedRepositoryProvider.overrideWithValue(feedRepo),
        ...overrides,
      ],
      child: MaterialApp(home: Scaffold(body: WinCard(win: _createWin()))),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('WinCard renders the same action row as an issue post', (
    tester,
  ) async {
    await _pumpWinCard(tester);

    expect(find.byKey(const Key('winActions_3')), findsOneWidget);
    expect(find.byKey(const Key('upvote_button_77')), findsOneWidget);
    expect(find.byKey(const Key('comment_button_77')), findsOneWidget);
    expect(find.byKey(const Key('share_button_77')), findsOneWidget);
    expect(find.byKey(const Key('winCardOverflow_3')), findsOneWidget);
    expect(find.byType(SocialAction), findsNWidgets(3));
  });

  testWidgets('tapping like upvotes the underlying issue and updates state', (
    tester,
  ) async {
    final repo = _CountingFeedRepository();
    await _pumpWinCard(tester, feedRepo: repo);

    final upvoteButton = find.byKey(const Key('upvote_button_77'));
    expect(
      find.descendant(of: upvoteButton, matching: find.text('0')),
      findsOneWidget,
    );

    await tester.tap(upvoteButton);
    await tester.pumpAndSettle();

    expect(repo.upvoteCalls, 1);
    expect(find.byIcon(Icons.thumb_up_rounded), findsOneWidget);
    expect(
      find.descendant(of: upvoteButton, matching: find.text('1')),
      findsOneWidget,
    );

    // Tapping again removes the upvote.
    await tester.tap(upvoteButton);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.thumb_up_outlined), findsOneWidget);
    expect(
      find.descendant(of: upvoteButton, matching: find.text('0')),
      findsOneWidget,
    );
  });

  testWidgets('comment button opens the comments sheet and shows live count', (
    tester,
  ) async {
    await _pumpWinCard(
      tester,
      overrides: [
        issueDetailApiProvider.overrideWithValue(_FakeIssueDetailApi()),
      ],
    );

    // Live comment count from the underlying issue.
    final commentButton = find.byKey(const Key('comment_button_77'));
    expect(commentButton, findsOneWidget);
    expect(
      find.descendant(of: commentButton, matching: find.text('1')),
      findsOneWidget,
    );

    await tester.tap(commentButton);
    await tester.pumpAndSettle();

    expect(find.byType(CommentsSection), findsOneWidget);
  });

  testWidgets('overflow menu exposes the report (flag) option', (
    tester,
  ) async {
    await _pumpWinCard(tester);

    await tester.tap(find.byKey(const Key('winCardOverflow_3')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('flagIssueOption_77')), findsOneWidget);
  });
}
