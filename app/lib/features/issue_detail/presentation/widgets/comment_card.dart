import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../data/issue_detail_api.dart';

/// Displays a comment and its nested replies with a clean threaded layout.
/// Replies deeper than [maxVisibleDepth] are collapsed behind a toggle so the
/// list never breaks apart on long threads.
class CommentCard extends StatefulWidget {
  const CommentCard({
    super.key,
    required this.comment,
    required this.onReply,
    required this.onDelete,
    this.depth = 0,
  });

  final Comment comment;
  final ValueChanged<Comment> onReply;
  final ValueChanged<dynamic> onDelete;
  final int depth;

  static const int maxVisibleDepth = 1;

  @override
  State<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard> {
  bool _expandedReplies = false;

  bool get _canNestMore => widget.depth < CommentCard.maxVisibleDepth;

  int get _visibleReplyCount {
    final replies = widget.comment.replies;
    if (_canNestMore) return replies.length;
    return _expandedReplies ? replies.length : 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final comment = widget.comment;
    final replies = comment.replies;
    final isNested = widget.depth > 0;
    final visibleCount = _visibleReplyCount;

    return Padding(
      key: Key('comment_item_${comment.id}'),
      padding: EdgeInsets.only(
        top: 8.0,
        bottom: isNested ? 2.0 : 8.0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isNested)
            Container(
              width: 2.5,
              margin: const EdgeInsets.only(top: 22, right: 10),
              height: 1000,
              color: colorScheme.primaryContainer.withValues(alpha: 0.7),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CommentBubble(
                  comment: comment,
                  onReply: () => widget.onReply(comment),
                  onDelete: () => widget.onDelete(comment.id),
                ),
                if (replies.isNotEmpty &&
                    (visibleCount > 0 ||
                        !_canNestMore && replies.isNotEmpty)) ...[
                  const SizedBox(height: 4),
                  if (_canNestMore)
                    for (final reply in replies.take(visibleCount))
                      CommentCard(
                        comment: reply,
                        onReply: widget.onReply,
                        onDelete: widget.onDelete,
                        depth: widget.depth + 1,
                      )
                  else
                    _buildCollapsedReplies(context, replies, colorScheme),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedReplies(
    BuildContext context,
    List<Comment> replies,
    ColorScheme colorScheme,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_expandedReplies)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: InkWell(
              key: const Key('viewMoreRepliesButton'),
              onTap: () => setState(() => _expandedReplies = true),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: Text(
                  'View all ${replies.length} replies',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          )
        else
          for (final reply in replies)
            CommentCard(
              comment: reply,
              onReply: widget.onReply,
              onDelete: widget.onDelete,
              depth: widget.depth + 1,
            ),
      ],
    );
  }
}

class _CommentBubble extends StatelessWidget {
  const _CommentBubble({
    required this.comment,
    required this.onReply,
    required this.onDelete,
  });

  final Comment comment;
  final VoidCallback onReply;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final initial = comment.anonId.isEmpty
        ? '?'
        : comment.anonId.toString().characters.first.toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: InkWell(
                key: Key('commentAuthor_${comment.id}'),
                onTap: comment.userId != null
                    ? () => context.push(
                          RoutePaths.publicProfileFor(comment.userId!),
                        )
                    : null,
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Text(
                        initial,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  comment.anonId,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (comment.isAuthor) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'You',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            formatCommentTime(comment.createdAt),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (comment.isAuthor)
              IconButton(
                key: Key('delete_button_${comment.id}'),
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                icon: Icon(Icons.delete_outline,
                    size: 18, color: colorScheme.error),
                onPressed: onDelete,
              ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 38),
          child: Text(
            comment.content,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 34, top: 4),
          child: InkWell(
            key: Key('reply_button_${comment.id}'),
            onTap: onReply,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.reply_outlined,
                      size: 15, color: colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Reply',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String formatCommentTime(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}