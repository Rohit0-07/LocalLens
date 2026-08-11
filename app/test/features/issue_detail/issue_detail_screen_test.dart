import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lens/features/issue_detail/presentation/issue_detail_screen.dart';

import '../../helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('IssueDetailScreen renders issue detail, escalation ladder, and quorum section',
      (tester) async {
    final fakeFeed = FakeFeedRepository(
      issues: [
        buildIssue(id: 42, title: 'Severed electric wire', status: 'pending_quorum'),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: mockOverrides(feedRepository: fakeFeed),
        child: const MaterialApp(
          home: IssueDetailScreen(issueId: 42),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Severed electric wire'), findsOneWidget);
    expect(find.text('Escalation Ladder Audit'), findsOneWidget);
    expect(find.text('Quorum-Backed Resolution'), findsOneWidget);
    expect(find.byKey(const Key('quorum_vote_confirm')), findsOneWidget);
    expect(find.byKey(const Key('quorum_vote_dispute')), findsOneWidget);
  });
}
