import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/auth_providers.dart';
import '../../../auth/presentation/widgets/guest_guard.dart';
import '../../data/issue_detail_api.dart';
import '../controllers/issue_detail_controller.dart';
import 'comment_card.dart';

class CommentsSection extends ConsumerStatefulWidget {
  final int issueId;
  final List<Comment> initialComments;
  final bool isGuest;
  final Function(String content, dynamic parentId)? onPostComment;
  final Function(dynamic commentId)? onDeleteComment;

  const CommentsSection({
    super.key,
    required this.issueId,
    this.initialComments = const [],
    this.isGuest = false,
    this.onPostComment,
    this.onDeleteComment,
  });

  @override
  ConsumerState<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends ConsumerState<CommentsSection> {
  late List<Comment> _comments;
  final TextEditingController _controller = TextEditingController();
  Comment? _replyingTo;

  @override
  void initState() {
    super.initState();
    _comments = List.from(widget.initialComments);
  }

  @override
  void didUpdateWidget(covariant CommentsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialComments != oldWidget.initialComments &&
        widget.initialComments.isNotEmpty) {
      _comments = List.from(widget.initialComments);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _checkIsGuest() {
    final session = ref.read(sessionProvider);
    return widget.isGuest || (session == null || session.isGuest);
  }

  void _handleInteraction(VoidCallback action) {
    if (_checkIsGuest()) {
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
      } else {
        ref
            .read(commentsProvider(widget.issueId).notifier)
            .postComment(text, parentId: _replyingTo?.id);
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
          final parentIndex =
              _comments.indexWhere((c) => c.id == _replyingTo!.id);
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

  void _deleteComment(dynamic commentId) {
    _handleInteraction(() {
      if (widget.onDeleteComment != null) {
        widget.onDeleteComment!(commentId);
      } else {
        ref
            .read(commentsProvider(widget.issueId).notifier)
            .deleteComment(commentId);
      }
      setState(() {
        _comments.removeWhere((c) => c.id == commentId);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final asyncComments = ref.watch(commentsProvider(widget.issueId));

    final commentsToDisplay = widget.initialComments.isNotEmpty
        ? _comments
        : (asyncComments.asData?.value ?? _comments);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Icon(Icons.forum_outlined, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Community Discussion',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${commentsToDisplay.length}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (commentsToDisplay.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: Text(
                'No comments yet. Be the first to comment!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: commentsToDisplay.length,
            itemBuilder: (context, index) {
              final comment = commentsToDisplay[index];
              return CommentCard(
                comment: comment,
                onReply: (target) {
                  _handleInteraction(() {
                    setState(() {
                      _replyingTo = target;
                    });
                  });
                },
                onDelete: _deleteComment,
              );
            },
          ),
        if (_replyingTo != null)
          Container(
            color: colorScheme.surfaceContainerHighest,
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Replying to ${_replyingTo!.anonId}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: colorScheme.onSurfaceVariant,
                    ),
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
            border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
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
                    if (_checkIsGuest()) {
                      _handleInteraction(() {});
                    }
                  },
                ),
              ),
              const SizedBox(width: 8.0),
              IconButton(
                key: const Key('submit_comment_button'),
                icon: Icon(Icons.send, color: colorScheme.primary),
                onPressed: _submitComment,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
