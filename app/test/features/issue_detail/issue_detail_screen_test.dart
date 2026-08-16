import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lens/features/issue_detail/data/issue_detail_api.dart';
import 'package:local_lens/features/issue_detail/presentation/issue_detail_screen.dart';

import '../../helpers.dart';

class FakeIssueDetailApi implements IssueDetailApi {
  @override
  Future<List<Comment>> getComments(int issueId) async => [];

  @override
  Future<Comment> postComment(int issueId, String content,
      {dynamic parentId}) async {
    return Comment(
      id: 1,
      issueId: issueId,
      anonId: 'anon_1',
      content: content,
      createdAt: DateTime.now(),
      isAuthor: true,
    );
  }

  @override
  Future<void> deleteComment(int issueId, dynamic commentId) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'IssueDetailScreen renders issue title in appbar and header, escalation ladder audit timeline, and community verification section',
      (tester) async {
    final fakeFeed = FakeFeedRepository(
      issues: [
        buildIssue(
          id: 42,
          title: 'Severed electric wire',
          status: 'pending_quorum',
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...mockOverrides(feedRepository: fakeFeed),
          issueDetailApiProvider.overrideWithValue(FakeIssueDetailApi()),
        ],
        child: const MaterialApp(
          home: IssueDetailScreen(issueId: 42),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Title should appear in AppBar as well as the main header
    expect(find.text('Severed electric wire'), findsAtLeastNWidgets(1));
    expect(find.text('#42'), findsOneWidget);
    expect(find.text('Escalation Ladder Audit'), findsOneWidget);

    // Scroll to community verification section
    await tester.scrollUntilVisible(
      find.byKey(const Key('quorum_vote_confirm')),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Community Resolution Verification'), findsOneWidget);
    expect(
      find.text(
        '3 verified neighbors within 5 km must confirm the fix to mark this issue resolved.',
      ),
      findsAtLeastNWidgets(1),
    );
    expect(find.byKey(const Key('quorum_vote_confirm')), findsOneWidget);
    expect(find.byKey(const Key('quorum_vote_dispute')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
