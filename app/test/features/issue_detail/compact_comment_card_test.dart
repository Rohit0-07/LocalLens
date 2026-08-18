import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lens/features/issue_detail/data/issue_detail_api.dart';
import 'package:local_lens/features/issue_detail/presentation/widgets/comment_card.dart';

void main() {
  group('Compact CommentCard Layout & Spacing Tests', () {
    final rootComment = Comment(
      id: 1,
      issueId: 10,
      parentId: null,
      userId: 42,
      anonId: 'Aarav Sharma',
      content: 'Ward engineers are already surveying the area today.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      isAuthor: false,
      replies: [
        Comment(
          id: 2,
          issueId: 10,
          parentId: 1,
          userId: null,
          anonId: 'anon_7781',
          content: 'Thanks for the quick update!',
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
          isAuthor: true,
        ),
      ],
    );

    testWidgets('renders compact comment card with nested reply without unbounded height errors', (tester) async {
      Comment? repliedTo;
      dynamic deletedId;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CommentCard(
                comment: rootComment,
                onReply: (c) => repliedTo = c,
                onDelete: (id) => deletedId = id,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check root comment renders
      expect(find.byKey(const Key('comment_item_1')), findsOneWidget);
      expect(find.text('Ward engineers are already surveying the area today.'), findsOneWidget);
      expect(find.text('Aarav Sharma'), findsOneWidget);

      // Check nested reply renders with compact author badge and content
      expect(find.byKey(const Key('comment_item_2')), findsOneWidget);
      expect(find.text('Thanks for the quick update!'), findsOneWidget);
      expect(find.text('You'), findsOneWidget);

      // Tap reply on nested comment
      await tester.tap(find.byKey(const Key('reply_button_2')));
      await tester.pumpAndSettle();
      expect(repliedTo?.id, equals(2));

      // Tap delete on author comment
      await tester.tap(find.byKey(const Key('delete_button_2')));
      await tester.pumpAndSettle();
      expect(deletedId, equals(2));
    });

    testWidgets('Tapping anonymous comment author displays toast notice', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CommentCard(
                comment: rootComment,
                onReply: (_) {},
                onDelete: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on anonymous author
      await tester.tap(find.byKey(const Key('commentAuthor_2')));
      await tester.pumpAndSettle();

      expect(find.text('This comment was posted anonymously.'), findsOneWidget);
    });
  });
}
