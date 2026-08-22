import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/profile_navigation.dart';
import '../../data/issue_detail_api.dart';

/// Displays a comment and its nested replies with a clean, compact threaded layout.
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

    return Container(
      key: Key('comment_item_${comment.id}'),
      margin: EdgeInsets.only(
        left: isNested ? 14.0 : 0.0,
        top: isNested ? 4.0 : 8.0,
        bottom: isNested ? 4.0 : 8.0,
      ),
      padding: isNested
          ? const EdgeInsets.only(left: 10.0)
          : const EdgeInsets.symmetric(horizontal: 4.0),
      decoration: isNested
          ? BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                  width: 2.0,
                ),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _CommentBubble(
            comment: comment,
            onReply: () => widget.onReply(comment),
            onDelete: () => widget.onDelete(comment.id),
          ),
          if (replies.isNotEmpty &&
              (visibleCount > 0 || !_canNestMore && replies.isNotEmpty)) ...[
            const SizedBox(height: 2),
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
            padding: const EdgeInsets.only(left: 8, top: 4),
            child: InkWell(
              key: const Key('viewMoreRepliesButton'),
              onTap: () => setState(() => _expandedReplies = true),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
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

class _CommentBubble extends ConsumerWidget {
  const _CommentBubble({
    required this.comment,
    required this.onReply,
    required this.onDelete,
  });

  final Comment comment;
  final VoidCallback onReply;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final initial = comment.anonId.isEmpty
        ? '?'
        : comment.anonId.toString().characters.first.toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: InkWell(
                key: Key('commentAuthor_${comment.id}'),
                onTap: comment.userId != null
                    ? () => openReporterProfile(context, ref, comment.userId)
                    : () {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'This comment was posted anonymously.',
                            ),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 13,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Text(
                        initial,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        comment.anonId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (comment.isAuthor) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'You',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 6),
                    Text(
                      '• ${formatCommentTime(comment.createdAt)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
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
                iconSize: 16,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: Icon(
                  Icons.delete_outline,
                  size: 16,
                  color: colorScheme.error,
                ),
                onPressed: onDelete,
              ),
          ],
        ),
        const SizedBox(height: 3),
        Padding(
          padding: const EdgeInsets.only(left: 34),
          child: Text(
            comment.content,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13.5,
              height: 1.35,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 30, top: 2),
          child: InkWell(
            key: Key('reply_button_${comment.id}'),
            onTap: onReply,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.reply_outlined,
                    size: 14,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'Reply',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
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
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
}