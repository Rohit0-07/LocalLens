import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/media_preview_widget.dart';
import '../../../ward/domain/local_talk_post.dart';

/// Ward discussion card — feed-first (Twitter) with the author identity of
/// Instagram. Violet accent ties it to the "local talk" brand moment.
class LocalTalkCard extends StatelessWidget {
  final LocalTalkPost post;

  const LocalTalkCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    final hasMedia = post.mediaUrls.isNotEmpty ||
        (post.imageUrl != null && post.imageUrl!.trim().isNotEmpty) ||
        (post.videoUrl != null && post.videoUrl!.trim().isNotEmpty);

    return Card(
      key: Key('localTalkCard_${post.id}'),
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              key: Key('localTalkAuthor_${post.id}'),
              onTap: post.authorId != null
                  ? () => context.push(
                        RoutePaths.publicProfileFor(post.authorId!),
                      )
                  : null,
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.brand.withValues(alpha: 0.12),
                      border: Border.all(
                        color: AppColors.brand.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.forum_outlined,
                      size: 18,
                      color: AppColors.brand,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          post.topic.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: AppColors.brand,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              post.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              post.body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (hasMedia) ...[
              const SizedBox(height: 10),
              MediaPreviewWidget(
                key: Key('localTalkMedia_${post.id}'),
                mediaUrls: post.mediaUrls,
                imageUrl: post.imageUrl,
                videoUrl: post.videoUrl,
                maxHeight: 180,
                heroTagPrefix: 'talk_${post.id}',
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brand.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.mode_comment_outlined,
                        size: 15,
                        color: AppColors.brand,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${post.repliesCount} replies',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.brand,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '${post.createdAt.day}/${post.createdAt.month}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
