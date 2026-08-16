import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/relative_time.dart';
import '../../notifications/domain/notification_item.dart';
import '../../notifications/presentation/controllers/notifications_controller.dart';

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  IconData _iconForType(String type) {
    switch (type) {
      case 'escalation':
        return Icons.trending_up_rounded;
      case 'quorum_request':
        return Icons.how_to_vote_rounded;
      case 'upvote_milestone':
        return Icons.thumb_up_alt_rounded;
      case 'comment_reply':
        return Icons.chat_bubble_outline_rounded;
      case 'system_notice':
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _colorForType(BuildContext context, String type) {
    final theme = Theme.of(context);
    switch (type) {
      case 'escalation':
        return AppColors.urgent;
      case 'quorum_request':
        return AppColors.review;
      case 'upvote_milestone':
        return AppColors.resolved;
      case 'comment_reply':
        return theme.colorScheme.primary;
      case 'system_notice':
      default:
        return theme.colorScheme.secondary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifState = ref.watch(notificationsControllerProvider);
    final unreadCount = notifState.unreadCount;
    final controller = ref.read(notificationsControllerProvider.notifier);

    final recentItems = notifState.notifications.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('inbox_title')),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                tooltip: context.tr('action_notifications'),
                onPressed: () => context.push(RoutePaths.notifications),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 8,
                      minHeight: 8,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.refresh(),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Digest Header Card
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.mark_email_unread_outlined,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            unreadCount > 0
                                ? context
                                    .tr('inbox_unread_updates')
                                    .replaceFirst('{count}', '$unreadCount')
                                : context.tr('inbox_up_to_date'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.tr('inbox_digest_sub'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Notifications Digest Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr('inbox_digest_header'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push(RoutePaths.notifications),
                  child: Text(context.tr('inbox_view_all')),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (notifState.isLoading && recentItems.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (recentItems.isEmpty)
              Card(
                elevation: 0,
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Center(
                    child: Text(
                      context.tr('inbox_empty'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ),
                ),
              )
            else
              ...recentItems.map(
                (item) => _buildDigestTile(context, item, controller),
              ),

            const SizedBox(height: 24),
            Text(
              context.tr('inbox_activity_stream'),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            _buildActivityInfoCard(
              context,
              icon: Icons.shield_outlined,
              title: context.tr('inbox_quorum_title'),
              description: context.tr('inbox_quorum_desc'),
            ),
            const SizedBox(height: 8),
            _buildActivityInfoCard(
              context,
              icon: Icons.schedule_rounded,
              title: context.tr('inbox_escalation_title'),
              description: context.tr('inbox_escalation_desc'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDigestTile(
    BuildContext context,
    NotificationItem item,
    NotificationsController controller,
  ) {
    final theme = Theme.of(context);
    final icon = _iconForType(item.type);
    final color = _colorForType(context, item.type);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: item.isRead
          ? theme.colorScheme.surface
          : theme.colorScheme.primaryContainer.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: item.isRead
              ? theme.colorScheme.outlineVariant.withValues(alpha: 0.3)
              : theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (!item.isRead) {
            controller.markAsRead(item.id);
          }
          if (item.referenceId != null && item.referenceId!.isNotEmpty) {
            final issueId = int.tryParse(item.referenceId!);
            if (issueId != null && issueId > 0) {
              context.push('/issues/$issueId');
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: item.isRead ? FontWeight.w500 : FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatRelativeTime(item.createdAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
