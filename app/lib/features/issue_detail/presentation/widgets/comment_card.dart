import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/issue_detail_api.dart';

class CommentCard extends StatelessWidget {
  const CommentCard({
    super.key,
    required this.comment,
    required this.onReply,
    required this.onDelete,
    this.isReply = false,
  });

  final Comment comment;
  final ValueChanged<Comment> onReply;
  final ValueChanged<dynamic> onDelete;
  final bool isReply;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      key: Key('comment_item_${comment.id}'),
      padding: EdgeInsets.only(
        left: isReply ? 8.0 : 0.0,
        top: 6.0,
        bottom: 6.0,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isReply)
              Container(
                width: 2,
                margin: const EdgeInsets.only(top: 4, bottom: 4, right: 8),
                color: theme.colorScheme.primaryContainer,
              ),
            Expanded(
              child: Card(
                margin: EdgeInsets.zero,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                color: isReply ? colorScheme.surfaceContainerLow : colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.account_circle,
                            size: 24.0,
                            key: const Key('avatar_icon'),
                            color: AppColors.anonMask,
                          ),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: Text(
                              comment.anonId,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            formatRelativeTimestamp(comment.createdAt),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (comment.isAuthor)
                            IconButton(
                              key: Key('delete_button_${comment.id}'),
                              icon: Icon(
                                Icons.delete_outline,
                                size: 18.0,
                                color: colorScheme.error,
                              ),
                              onPressed: () => onDelete(comment.id),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6.0),
                      Text(
                        comment.content,
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (!isReply) ...[
                        const SizedBox(height: 4.0),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            key: Key('reply_button_${comment.id}'),
                            icon: const Icon(Icons.reply, size: 16.0),
                            label: const Text('Reply'),
                            onPressed: () => onReply(comment),
                          ),
                        ),
                      ],
                      if (comment.replies.isNotEmpty) ...[
                        const Divider(),
                        for (final reply in comment.replies)
                          CommentCard(
                            comment: reply,
                            onReply: onReply,
                            onDelete: onDelete,
                            isReply: true,
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String formatRelativeTimestamp(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
