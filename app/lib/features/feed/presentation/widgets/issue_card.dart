import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../../auth/presentation/widgets/guest_guard.dart';
import '../../../issue_detail/presentation/controllers/issue_detail_controller.dart';
import '../../../issues/presentation/widgets/flag_issue_dialog.dart';
import '../../domain/feed_item.dart';
import '../../domain/issue.dart';
import '../feed_providers.dart';

class IssueCard extends ConsumerWidget {
  const IssueCard({super.key, required this.issue});

  final Issue issue;

  static const _categoryColors = <String, List<Color>>{
    'road': [Color(0xFF8B5A2B), Color(0xFFD4A017)],
    'water': [Color(0xFF0D47A1), Color(0xFF29B6F6)],
    'power': [Color(0xFFF9A825), Color(0xFFEF6C00)],
    'lighting': [Color(0xFF5E35B1), Color(0xFF9FA8DA)],
    'waste': [Color(0xFF2E7D32), Color(0xFF9CCC65)],
    'sewage': [Color(0xFF4E342E), Color(0xFF795548)],
    'other': [Color(0xFF00695C), Color(0xFF26A69A)],
  };

  static const _categoryIcons = <String, IconData>{
    'road': Icons.alt_route,
    'water': Icons.water_drop_outlined,
    'power': Icons.bolt,
    'lighting': Icons.lightbulb_outline,
    'waste': Icons.delete_outline,
    'sewage': Icons.water,
    'other': Icons.flag_outlined,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final multiFeed = ref.watch(multiTypeFeedProvider);
    final multiIssue = multiFeed.asData?.value
        .where((item) => item.itemType == FeedItemType.issue)
        .map((item) => item.issue)
        .firstWhere((i) => i?.id == issue.id, orElse: () => null);
    final activeIssue = multiIssue ?? issue;

    final gradient =
        _categoryColors[activeIssue.category] ??
        _categoryColors['other']!;
    final categoryIcon =
        _categoryIcons[activeIssue.category] ?? Icons.flag_outlined;

    return Card(
      key: Key('issueCard_${activeIssue.id}'),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(RoutePaths.issueDetailFor(activeIssue.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: activeIssue.isAnonymous
                        ? colorScheme.tertiaryContainer
                        : colorScheme.primaryContainer,
                    child: Icon(
                      activeIssue.isAnonymous
                          ? Icons.face_retouching_natural
                          : Icons.account_circle,
                      size: 20,
                      color: activeIssue.isAnonymous
                          ? colorScheme.onTertiaryContainer
                          : colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeIssue.reporterLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${activeIssue.ward} • ${formatRelativeTime(activeIssue.createdAt)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    key: Key('issueCardOverflow_${activeIssue.id}'),
                    iconSize: 18,
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        key: Key('flagIssueOption_${activeIssue.id}'),
                        value: 'flag',
                        onTap: () {
                          final session = ref.read(sessionProvider);
                          final isGuest = session == null || session.isGuest;
                          if (isGuest) {
                            showDialog(
                              context: context,
                              builder: (_) => const GuestGuard(),
                            );
                          } else {
                            showDialog(
                              context: context,
                              builder: (_) =>
                                  FlagIssueDialog(issueId: activeIssue.id),
                            );
                          }
                        },
                        child: const Text('Flag Issue'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Cover gradient
            Container(
              height: 96,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(categoryIcon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeIssue.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: activeIssue.status),
                ],
              ),
            ),
            // Body
            if (activeIssue.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: Text(
                  activeIssue.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Chip(
                    label: Text('#${activeIssue.category}'),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  if (activeIssue.isFuzzed)
                    Chip(
                      avatar: const Icon(Icons.blur_on, size: 14),
                      label: const Text('Fuzzed'),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  if (activeIssue.isShielded)
                    Chip(
                      avatar: const Icon(Icons.shield_outlined,
                          size: 14, color: Colors.purple),
                      label: const Text('Shielded'),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
            ),
            // Social action row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                children: [
                  _SocialAction(
                    key: Key('upvote_button_${activeIssue.id}'),
                    icon: activeIssue.hasUpvoted
                        ? Icons.thumb_up
                        : Icons.thumb_up_alt_outlined,
                    color: activeIssue.hasUpvoted
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    label: '${activeIssue.upvotesCount}',
                    onTap: () async {
                      try {
                        await ref
                            .read(multiTypeFeedProvider.notifier)
                            .toggleUpvote(activeIssue.id, defaultLatitude,
                                defaultLongitude);
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Failed to toggle upvote')),
                          );
                        }
                      }
                    },
                  ),
                  _SocialAction(
                    key: Key('comment_button_${activeIssue.id}'),
                    icon: Icons.chat_bubble_outline_rounded,
                    color: colorScheme.onSurfaceVariant,
                    label: _CommentCount(issueId: activeIssue.id),
                    onTap: () =>
                        context.push(RoutePaths.issueDetailFor(activeIssue.id)),
                  ),
                  _SocialAction(
                    key: Key('share_button_${activeIssue.id}'),
                    icon: Icons.share_outlined,
                    color: colorScheme.onSurfaceVariant,
                    label: '',
                    onTap: () => context
                        .push(RoutePaths.issueDetailFor(activeIssue.id)),
                  ),
                  const Spacer(),
                  if (activeIssue.isEscalating)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.local_fire_department,
                          color: Colors.redAccent, size: 18),
                    )
                  else if (activeIssue.isPendingQuorum)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.how_to_vote_rounded,
                          color: Colors.blue, size: 18),
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

class _SocialAction extends StatelessWidget {
  const _SocialAction({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final Widget label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 6),
            DefaultTextStyle(
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
              child: label,
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentCount extends ConsumerWidget {
  const _CommentCount({required this.issueId});

  final int issueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncComments = ref.watch(commentsProvider(issueId));
    final count = asyncComments.asData?.value.length ?? 0;
    return Text('$count');
  }
}