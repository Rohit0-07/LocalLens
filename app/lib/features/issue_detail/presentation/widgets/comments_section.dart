import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/auth_providers.dart';
import '../../../auth/presentation/widgets/guest_guard.dart';
import '../../../../core/l10n/app_strings.dart';
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
  final FocusNode _composerFocus = FocusNode();

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
    _composerFocus.dispose();
    super.dispose();
  }

  bool _checkIsGuest() {
    final session = ref.read(sessionProvider);
    return widget.isGuest || (session == null || session.isGuest);
  }

  void _handleInteraction(VoidCallback action) {
    if (_checkIsGuest()) {
      showDialog(context: context, builder: (_) => const GuestGuard());
    } else {
      action();
    }
  }

  void _submitComment() {
    _handleInteraction(() {
      final text = _controller.text.trim();
      if (text.isEmpty) return;

      final parent = _replyingTo;

      if (widget.onPostComment != null) {
        widget.onPostComment!(text, parent?.id);
        _appendOptimistic(
          Comment(
            id: DateTime.now().microsecondsSinceEpoch,
            issueId: widget.issueId,
            parentId: parent?.id,
            anonId: 'you',
            content: text,
            createdAt: DateTime.now(),
            isAuthor: true,
          ),
          parent: parent,
        );
      } else {
        ref
            .read(commentsProvider(widget.issueId).notifier)
            .postComment(text, parentId: parent?.id)
            .then((created) {
              if (!mounted) return;
              _appendOptimistic(created, parent: parent);
            })
            .catchError((_) {
              if (mounted) {
                ref.read(commentsProvider(widget.issueId).notifier).refresh();
              }
            });
      }

      _controller.clear();
      _replyingTo = null;
      _composerFocus.unfocus();
    });
  }

  /// Appends a comment (either authoritative from the server or an
  /// optimistic local copy) to the local list, threading replies under their
  /// parent. The provider reload acts as the reconciliation source of truth.
  void _appendOptimistic(Comment comment, {Comment? parent}) {
    setState(() {
      if (parent != null) {
        _appendReply(parent, comment);
      } else {
        _comments.add(comment);
      }
    });
  }

  void _appendReply(Comment target, Comment reply) {
    bool found = false;
    void walk(List<Comment> list) {
      for (var i = 0; i < list.length; i++) {
        final c = list[i];
        if (c.id == target.id) {
          list[i] = c.copyWith(replies: [...c.replies, reply]);
          found = true;
          return;
        }
        if (c.replies.isNotEmpty) walk(c.replies);
      }
    }

    walk(_comments);
    if (!found) _comments.add(reply);
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
        _removeCommentDeep(_comments, commentId);
      });
    });
  }

  /// Removes a comment (and its entire reply subtree) at any nesting depth, so
  /// deleting a nested reply doesn't leave ghost children behind.
  void _removeCommentDeep(List<Comment> list, dynamic commentId) {
    final result = <Comment>[];
    for (final c in list) {
      if (c.id == commentId) continue;
      if (c.replies.isNotEmpty) {
        result.add(c.copyWith(replies: _prunedReplies(c, commentId)));
      } else {
        result.add(c);
      }
    }
    list
      ..clear()
      ..addAll(result);
  }

  List<Comment> _prunedReplies(Comment comment, dynamic commentId) {
    final result = <Comment>[];
    for (final reply in comment.replies) {
      if (reply.id == commentId) continue;
      if (reply.replies.isNotEmpty) {
        result.add(reply.copyWith(replies: _prunedReplies(reply, commentId)));
      } else {
        result.add(reply);
      }
    }
    return result;
  }

  void _startReply(Comment target) {
    _handleInteraction(() {
      setState(() => _replyingTo = target);
      _composerFocus.requestFocus();
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
                context.tr('comments_title'),
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
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Text(
                context.tr('comments_empty'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          ...commentsToDisplay.map(
            (comment) => CommentCard(
              comment: comment,
              onReply: _startReply,
              onDelete: _deleteComment,
            ),
          ),
        const Divider(height: 24),
        if (_replyingTo != null)
          Container(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
            color: colorScheme.surfaceContainerLow,
            child: Row(
              children: [
                Icon(Icons.reply, size: 15, color: colorScheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${context.tr('comments_replying_to')} ${_replyingTo!.anonId}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() {
                    _replyingTo = null;
                    _controller.clear();
                  }),
                ),
              ],
            ),
          ),
        SafeArea(
          top: false,
          child: Container(
            padding: EdgeInsets.fromLTRB(
              12,
              8,
              12,
              MediaQuery.viewInsetsOf(context).bottom > 0
                  ? MediaQuery.viewInsetsOf(context).bottom + 8
                  : 8,
            ),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('comment_input'),
                    controller: _controller,
                    focusNode: _composerFocus,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: context.tr('comments_hint'),
                      isDense: true,
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  key: const Key('submit_comment_button'),
                  icon: const Icon(Icons.send_rounded, size: 20),
                  onPressed: _submitComment,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
