import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:local_lens/features/auth/presentation/widgets/guest_guard.dart';

/// Data model representing a comment matching the backend CommentResponse contract.
class Comment {
  final int id;
  final int issueId;
  final int? parentId;
  final String anonId;
  final String content;
  final DateTime createdAt;
  final bool isAuthor;
  final List<Comment> replies;

  const Comment({
    required this.id,
    required this.issueId,
    this.parentId,
    required this.anonId,
    required this.content,
    required this.createdAt,
    required this.isAuthor,
    this.replies = const [],
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as int,
      issueId: json['issue_id'] as int,
      parentId: json['parent_id'] as int?,
      anonId: json['anon_id'] as String? ?? 'anon_user',
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isAuthor: json['is_author'] as bool? ?? false,
      replies: (json['replies'] as List<dynamic>?)
              ?.map((e) => Comment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'issue_id': issueId,
      'parent_id': parentId,
      'anon_id': anonId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'is_author': isAuthor,
      'replies': replies.map((r) => r.toJson()).toList(),
    };
  }

  Comment copyWith({
    int? id,
    int? issueId,
    int? parentId,
    String? anonId,
    String? content,
    DateTime? createdAt,
    bool? isAuthor,
    List<Comment>? replies,
  }) {
    return Comment(
      id: id ?? this.id,
      issueId: issueId ?? this.issueId,
      parentId: parentId ?? this.parentId,
      anonId: anonId ?? this.anonId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isAuthor: isAuthor ?? this.isAuthor,
      replies: replies ?? this.replies,
    );
  }
}

/// Helper function to convert DateTime to human-readable relative timestamp.
String formatRelativeTimestamp(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

/// CommentsSection UI widget matching the UI Specification.
class CommentsSection extends StatefulWidget {
  final int issueId;
  final List<Comment> initialComments;
  final bool isGuest;
  final Function(String content, int? parentId)? onPostComment;
  final Function(int commentId)? onDeleteComment;

  const CommentsSection({
    super.key,
    required this.issueId,
    this.initialComments = const [],
    this.isGuest = false,
    this.onPostComment,
    this.onDeleteComment,
  });

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  late List<Comment> _comments;
  final TextEditingController _controller = TextEditingController();
  Comment? _replyingTo;

  @override
  void initState() {
    super.initState();
    _comments = List.from(widget.initialComments);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleInteraction(VoidCallback action) {
    if (widget.isGuest) {
      showDialog(
        context: context,
        builder: (_) => const GuestGuard(),
      );
    } else {
      action();
    }
  }

  void _submitComment() {
    _handleInteraction(() {
      final text = _controller.text.trim();
      if (text.isEmpty) return;

      if (widget.onPostComment != null) {
        widget.onPostComment!(text, _replyingTo?.id);
      }

      final newComment = Comment(
        id: DateTime.now().millisecondsSinceEpoch,
        issueId: widget.issueId,
        parentId: _replyingTo?.id,
        anonId: 'anon_current',
        content: text,
        createdAt: DateTime.now(),
        isAuthor: true,
      );

      setState(() {
        if (_replyingTo != null) {
          final parentIndex = _comments.indexWhere((c) => c.id == _replyingTo!.id);
          if (parentIndex != -1) {
            final parent = _comments[parentIndex];
            _comments[parentIndex] = parent.copyWith(
              replies: [...parent.replies, newComment],
            );
          } else {
            _comments.add(newComment);
          }
        } else {
          _comments.add(newComment);
        }
        _controller.clear();
        _replyingTo = null;
      });
    });
  }

  void _deleteComment(int commentId) {
    if (widget.onDeleteComment != null) {
      widget.onDeleteComment!(commentId);
    }
    setState(() {
      _comments.removeWhere((c) => c.id == commentId);
    });
  }

  Widget _buildCommentItem(Comment comment, {bool isReply = false}) {
    return Padding(
      key: Key('comment_item_${comment.id}'),
      padding: EdgeInsets.only(left: isReply ? 24.0 : 0.0, top: 8.0, bottom: 8.0),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_circle, size: 24.0, key: Key('avatar_icon')),
                  const SizedBox(width: 8.0),
                  Text(
                    comment.anonId,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    formatRelativeTimestamp(comment.createdAt),
                    style: const TextStyle(color: Colors.grey, fontSize: 12.0),
                  ),
                  if (comment.isAuthor)
                    IconButton(
                      key: Key('delete_button_${comment.id}'),
                      icon: const Icon(Icons.delete_outline, size: 18.0),
                      onPressed: () => _deleteComment(comment.id),
                    ),
                ],
              ),
              const SizedBox(height: 6.0),
              Text(comment.content),
              if (!isReply) ...[
                const SizedBox(height: 4.0),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    key: Key('reply_button_${comment.id}'),
                    icon: const Icon(Icons.reply, size: 16.0),
                    label: const Text('Reply'),
                    onPressed: () {
                      _handleInteraction(() {
                        setState(() {
                          _replyingTo = comment;
                        });
                      });
                    },
                  ),
                ),
              ],
              if (comment.replies.isNotEmpty) ...[
                const Divider(),
                for (final reply in comment.replies)
                  _buildCommentItem(reply, isReply: true),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _comments.isEmpty
              ? const Center(
                  child: Text('No comments yet. Be the first to comment!'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _comments.length,
                  itemBuilder: (context, index) {
                    return _buildCommentItem(_comments[index]);
                  },
                ),
        ),
        if (_replyingTo != null)
          Container(
            color: Colors.grey.shade200,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Replying to ${_replyingTo!.anonId}',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18.0),
                  onPressed: () {
                    setState(() {
                      _replyingTo = null;
                    });
                  },
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('comment_input'),
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Write a comment...',
                    border: OutlineInputBorder(),
                  ),
                  onTap: () {
                    if (widget.isGuest) {
                      _handleInteraction(() {});
                    }
                  },
                ),
              ),
              const SizedBox(width: 8.0),
              IconButton(
                key: const Key('submit_comment_button'),
                icon: const Icon(Icons.send),
                onPressed: _submitComment,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Threaded Comments UI Widget Tests', () {
    testWidgets('renders comment items with avatar icon, anon_id, content, and relative timestamp', (tester) async {
      final comments = [
        Comment(
          id: 1,
          issueId: 10,
          anonId: 'anon_citizen99',
          content: 'Pothole has grown much bigger after heavy rain.',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          isAuthor: false,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommentsSection(
              issueId: 10,
              initialComments: comments,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check avatar icon
      expect(find.byKey(const Key('avatar_icon')), findsOneWidget);

      // Check anon_id
      expect(find.text('anon_citizen99'), findsOneWidget);

      // Check content
      expect(find.text('Pothole has grown much bigger after heavy rain.'), findsOneWidget);

      // Check relative timestamp
      expect(find.text('2h ago'), findsOneWidget);
    });

    testWidgets('renders nested reply comments indented under parent comment', (tester) async {
      final comments = [
        Comment(
          id: 1,
          issueId: 10,
          anonId: 'anon_parent',
          content: 'Main issue observation',
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          isAuthor: false,
          replies: [
            Comment(
              id: 2,
              issueId: 10,
              parentId: 1,
              anonId: 'anon_replier',
              content: 'I noticed this too today',
              createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
              isAuthor: false,
            ),
          ],
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommentsSection(
              issueId: 10,
              initialComments: comments,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('anon_parent'), findsOneWidget);
      expect(find.text('Main issue observation'), findsOneWidget);
      expect(find.text('anon_replier'), findsOneWidget);
      expect(find.text('I noticed this too today'), findsOneWidget);
      expect(find.text('30m ago'), findsOneWidget);
    });

    testWidgets('intercepts guest users with GuestGuard when attempting to submit a comment', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommentsSection(
              issueId: 10,
              isGuest: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap submit button as guest
      await tester.tap(find.byKey(const Key('submit_comment_button')));
      await tester.pumpAndSettle();

      // GuestGuard dialog should be shown
      expect(find.text('Sign in required'), findsOneWidget);
      expect(find.text('Create an account or sign in to participate in civic reporting.'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Tap cancel to close dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Sign in required'), findsNothing);
    });

    testWidgets('intercepts guest users with GuestGuard when tapping reply', (tester) async {
      final comments = [
        Comment(
          id: 1,
          issueId: 10,
          anonId: 'anon_user1',
          content: 'Sample comment',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          isAuthor: false,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommentsSection(
              issueId: 10,
              initialComments: comments,
              isGuest: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap reply button on comment as guest
      await tester.tap(find.byKey(const Key('reply_button_1')));
      await tester.pumpAndSettle();

      // GuestGuard should be triggered
      expect(find.text('Sign in required'), findsOneWidget);
    });

    testWidgets('allows authenticated user to enter text and submit a top-level comment', (tester) async {
      String? postedContent;
      int? postedParentId;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommentsSection(
              issueId: 10,
              isGuest: false,
              onPostComment: (content, parentId) {
                postedContent = content;
                postedParentId = parentId;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter comment text
      await tester.enterText(find.byKey(const Key('comment_input')), 'New top-level comment');
      await tester.pump();

      // Tap submit
      await tester.tap(find.byKey(const Key('submit_comment_button')));
      await tester.pumpAndSettle();

      expect(postedContent, 'New top-level comment');
      expect(postedParentId, isNull);
      expect(find.text('New top-level comment'), findsOneWidget);
    });

    testWidgets('tapping reply action sets parent comment and passes parent_id on submit', (tester) async {
      String? postedContent;
      int? postedParentId;

      final comments = [
        Comment(
          id: 42,
          issueId: 10,
          anonId: 'anon_author42',
          content: 'Parent comment text',
          createdAt: DateTime.now().subtract(const Duration(hours: 4)),
          isAuthor: false,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommentsSection(
              issueId: 10,
              initialComments: comments,
              isGuest: false,
              onPostComment: (content, parentId) {
                postedContent = content;
                postedParentId = parentId;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap reply button
      await tester.tap(find.byKey(const Key('reply_button_42')));
      await tester.pumpAndSettle();

      // Replying indicator should appear
      expect(find.text('Replying to anon_author42'), findsOneWidget);

      // Enter reply text and submit
      await tester.enterText(find.byKey(const Key('comment_input')), 'Reply to parent');
      await tester.tap(find.byKey(const Key('submit_comment_button')));
      await tester.pumpAndSettle();

      expect(postedContent, 'Reply to parent');
      expect(postedParentId, 42);
      expect(find.text('Reply to parent'), findsOneWidget);
    });

    testWidgets('shows delete action for own comments (isAuthor: true) and deletes comment on tap', (tester) async {
      int? deletedCommentId;

      final comments = [
        Comment(
          id: 99,
          issueId: 10,
          anonId: 'anon_self',
          content: 'My own comment to be deleted',
          createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
          isAuthor: true,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommentsSection(
              issueId: 10,
              initialComments: comments,
              isGuest: false,
              onDeleteComment: (commentId) {
                deletedCommentId = commentId;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final deleteBtn = find.byKey(const Key('delete_button_99'));
      expect(deleteBtn, findsOneWidget);

      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      expect(deletedCommentId, 99);
      expect(find.text('My own comment to be deleted'), findsNothing);
    });

    testWidgets('hides delete action for comments by other authors (isAuthor: false)', (tester) async {
      final comments = [
        Comment(
          id: 88,
          issueId: 10,
          anonId: 'anon_other',
          content: 'Comment by someone else',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          isAuthor: false,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommentsSection(
              issueId: 10,
              initialComments: comments,
              isGuest: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('delete_button_88')), findsNothing);
    });

    testWidgets('displays empty state when no comments exist', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CommentsSection(
              issueId: 10,
              initialComments: [],
              isGuest: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No comments yet. Be the first to comment!'), findsOneWidget);
    });
  });
}
