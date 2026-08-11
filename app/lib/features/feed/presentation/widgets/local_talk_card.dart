import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../ward/domain/local_talk_post.dart';

class LocalTalkCard extends StatelessWidget {
  final LocalTalkPost post;

  const LocalTalkCard({
    super.key,
    required this.post,
  });

  void _shareTalk(BuildContext context) {
    final deepLink = 'locallens://talk/${post.id}';
    Clipboard.setData(ClipboardData(text: deepLink));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Discussion link copied: $deepLink'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      key: Key('localTalkCard_${post.id}'),
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(
                  avatar: const Icon(Icons.forum_outlined, size: 14),
                  label: Text(
                    post.topic.toUpperCase(),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),
                Text(
                  post.authorName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.share_outlined, size: 20),
                  tooltip: 'Share',
                  onPressed: () => _shareTalk(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              post.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              post.body,
              style: theme.textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.mode_comment_outlined, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  '${post.repliesCount} replies',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${post.createdAt.day}/${post.createdAt.month}',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
