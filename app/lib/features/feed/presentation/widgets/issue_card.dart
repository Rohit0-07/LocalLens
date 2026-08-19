import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/media_url.dart';
import '../../../../core/utils/profile_navigation.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/utils/string_formatters.dart';
import '../../../../shared/widgets/media_preview_widget.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../../auth/presentation/widgets/guest_guard.dart';
import '../../../issue_detail/presentation/controllers/issue_detail_controller.dart';
import '../../../issue_detail/presentation/widgets/comments_section.dart';
import '../../../issues/presentation/widgets/flag_issue_dialog.dart';
import '../../domain/feed_item.dart';
import '../../domain/issue.dart';
import '../feed_providers.dart';

/// Clean, modern civic issue card.
///
/// Decluttered vertical stack: header meta, one subtle status row, title,
/// description, lighter media block, meta chips, and a single footer action
/// row. High-contrast typography with zero artificial gradient noise.
class IssueCard extends ConsumerWidget {
  const IssueCard({super.key, required this.issue});

  final Issue issue;

  static const _categoryIcons = <String, IconData>{
    'road': Icons.alt_route_rounded,
    'water': Icons.water_drop_outlined,
    'power': Icons.bolt_rounded,
    'lighting': Icons.lightbulb_outline_rounded,
    'waste': Icons.delete_outline_rounded,
    'sanitation': Icons.recycling_rounded,
    'sewage': Icons.water_rounded,
    'other': Icons.flag_outlined,
  };

  void _showCommentsModal(BuildContext context, Issue activeIssue) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activeIssue.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(ctx)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.categorySurfaceFor(
                                      activeIssue.category,
                                      isDark: Theme.of(ctx).brightness ==
                                          Brightness.dark,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    StringFormatters.humanize(activeIssue.category).toUpperCase(),
                                    style: TextStyle(
                                      color: AppColors.categoryColorFor(
                                        activeIssue.category,
                                      ),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    activeIssue.ward,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(ctx)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(ctx)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.open_in_new, size: 18),
                        tooltip: 'View Full Issue',
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.push(
                            RoutePaths.issueDetailFor(activeIssue.id),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: CommentsSection(issueId: activeIssue.id),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final multiFeed = ref.watch(multiTypeFeedProvider);
    final multiIssue = multiFeed.asData?.value
        .where((item) => item.itemType == FeedItemType.issue)
        .map((item) => item.issue)
        .firstWhere((i) => i?.id == issue.id, orElse: () => null);
    final activeIssue = multiIssue ?? issue;

    final categoryColor = AppColors.categoryColorFor(activeIssue.category);
    final categoryIcon =
        _categoryIcons[activeIssue.category.toLowerCase()] ??
        Icons.flag_outlined;
    final isAnonymous = activeIssue.isAnonymous;

    return Card(
      key: Key('issueCard_${activeIssue.id}'),
      elevation: 0,
      color: isDark ? AppColors.darkCard : AppColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(RoutePaths.issueDetailFor(activeIssue.id)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1) Header: Identity & Meta ───────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: InkWell(
                      key: Key('issueCardReporter_${activeIssue.id}'),
                      onTap: () =>
                          openReporterProfile(context, ref, activeIssue.reporterId),
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        children: [
                          _CleanAvatar(
                            isAnonymous: isAnonymous,
                            reporterName: activeIssue.reporterLabel,
                            photoUrl: activeIssue.reporterPhotoUrl,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        activeIssue.reporterLabel,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    if (!isAnonymous) ...[
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.verified,
                                        color: AppColors.verified,
                                        size: 15,
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  key: Key('issueHeaderMeta_${activeIssue.id}'),
                                  children: [
                                    Icon(
                                      categoryIcon,
                                      size: 13,
                                      color: categoryColor,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      StringFormatters.humanize(activeIssue.category).toUpperCase(),
                                      style: TextStyle(
                                        color: categoryColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '•',
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 12,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 2),
                                    Flexible(
                                      child: Text(
                                        activeIssue.ward,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: colorScheme.onSurfaceVariant,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '•',
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      formatRelativeTime(activeIssue.createdAt),
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    key: Key('issueCardOverflow_${activeIssue.id}'),
                    icon: Icon(
                      Icons.more_horiz_rounded,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        key: Key('flagIssueOption_${activeIssue.id}'),
                        value: 'flag',
                        onTap: () {
                          final session = ref.read(sessionProvider);
                          final isGuestUser =
                              session == null || session.isGuest;
                          if (isGuestUser) {
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
                        child: Row(
                          children: [
                            const Icon(
                              Icons.flag_outlined,
                              size: 18,
                              color: AppColors.urgent,
                            ),
                            const SizedBox(width: 8),
                            Text(context.tr('flag_issue')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── 2) Status Row ────────────────────────────────────────
              Row(
                key: Key('issueStatusRow_${activeIssue.id}'),
                children: [
                  StatusBadge(status: activeIssue.status),
                  if (activeIssue.isEscalating) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.local_fire_department,
                      size: 14,
                      color: AppColors.urgent,
                    ),
                    const SizedBox(width: 3),
                    const Text(
                      'ESCALATING',
                      style: TextStyle(
                        color: AppColors.urgent,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ] else if (activeIssue.isPendingQuorum) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.how_to_vote,
                      size: 14,
                      color: AppColors.verified,
                    ),
                    const SizedBox(width: 3),
                    const Text(
                      'VERIFY',
                      style: TextStyle(
                        color: AppColors.verified,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 10),

              // ── 3) Title ─────────────────────────────────────────────
              Text(
                activeIssue.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  height: 1.3,
                  color: colorScheme.onSurface,
                ),
              ),
              if (activeIssue.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                _ExpandableDescription(
                  text: activeIssue.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],

              // ── 5) Visual Media (Photos, Video Demo, Resolution proof) ─
              if (activeIssue.mediaUrls.isNotEmpty ||
                  (activeIssue.videoUrl != null &&
                      activeIssue.videoUrl!.trim().isNotEmpty) ||
                  (activeIssue.resolutionProof != null &&
                      activeIssue.resolutionProof!.trim().isNotEmpty)) ...[
                const SizedBox(height: 10),
                MediaPreviewWidget(
                  key: Key('issueMedia_${activeIssue.id}'),
                  mediaUrls: activeIssue.mediaUrls,
                  videoUrl: activeIssue.videoUrl,
                  resolutionProof: activeIssue.resolutionProof,
                  maxHeight: 180,
                  heroTagPrefix: 'issue_${activeIssue.id}',
                ),
              ],

              // ── 6) Meta tags (Shielded / Fuzzed) ─────────────────────
              if (activeIssue.isFuzzed || activeIssue.isShielded) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (activeIssue.isFuzzed)
                      _MetaChip(
                        icon: Icons.blur_on_rounded,
                        label: context.tr('fuzzed'),
                      ),
                    if (activeIssue.isShielded)
                      _MetaChip(
                        icon: Icons.shield_outlined,
                        label: context.tr('shielded'),
                        iconColor: AppColors.brand,
                      ),
                  ],
                ),
              ],

              // ── 7) Footer Actions (single action row, no divider) ─────
              const SizedBox(height: 12),
              Row(
                key: Key('issueActions_${activeIssue.id}'),
                children: [
                  _SocialAction(
                    key: Key('upvote_button_${activeIssue.id}'),
                    icon: activeIssue.hasUpvoted
                        ? Icons.thumb_up_rounded
                        : Icons.thumb_up_outlined,
                    color: activeIssue.hasUpvoted
                        ? AppColors.brand
                        : colorScheme.onSurfaceVariant,
                    backgroundColor: activeIssue.hasUpvoted
                        ? AppColors.brand.withValues(alpha: 0.12)
                        : Colors.transparent,
                    label: Text('${activeIssue.upvotesCount}'),
                    onTap: () async {
                      try {
                        await ref
                            .read(multiTypeFeedProvider.notifier)
                            .toggleUpvote(
                              activeIssue.id,
                              activeIssue.latitude,
                              activeIssue.longitude,
                              currentlyUpvoted: activeIssue.hasUpvoted,
                            );
                      } catch (err) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(upvoteErrorMessage(err)),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  _SocialAction(
                    key: Key('comment_button_${activeIssue.id}'),
                    icon: Icons.chat_bubble_outline_rounded,
                    color: colorScheme.onSurfaceVariant,
                    label: _CommentCount(issueId: activeIssue.id),
                    onTap: () => _showCommentsModal(context, activeIssue),
                  ),
                  const Spacer(),
                  _SocialAction(
                    key: Key('share_button_${activeIssue.id}'),
                    icon: Icons.share_outlined,
                    color: colorScheme.onSurfaceVariant,
                    label: const SizedBox.shrink(),
                    tooltip: context.tr('action_share'),
                    onTap: () {
                      final shareText =
                          '${activeIssue.title} (Issue #${activeIssue.id}) — LocalLens\n'
                          'locallens://issue/${activeIssue.id}';
                      SharePlus.instance.share(ShareParams(text: shareText));
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Clean reporter avatar with solid styling.
class _CleanAvatar extends StatelessWidget {
  const _CleanAvatar({
    required this.isAnonymous,
    required this.reporterName,
    this.photoUrl,
  });

  final bool isAnonymous;
  final String reporterName;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (isAnonymous) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.anonMask.withValues(alpha: 0.14),
          border: Border.all(
            color: AppColors.anonMask.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: const Icon(
          Icons.shield_outlined,
          size: 18,
          color: AppColors.anonMask,
        ),
      );
    }

    final resolvedPhoto = photoUrl != null && photoUrl!.isNotEmpty
        ? resolveMediaUrl(photoUrl!)
        : null;
    if (resolvedPhoto != null) {
      return ClipOval(
        child: SizedBox(
          width: 36,
          height: 36,
          child: Image.network(
            resolvedPhoto,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _initialAvatar(
              colorScheme,
              reporterName,
            ),
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : _initialAvatar(colorScheme, reporterName),
          ),
        ),
      );
    }

    return _initialAvatar(colorScheme, reporterName);
  }

  Widget _initialAvatar(ColorScheme colorScheme, String reporterName) {
    final initial = reporterName.isNotEmpty
        ? reporterName.substring(0, 1).toUpperCase()
        : 'U';

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.primaryContainer,
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({this.icon, required this.label, this.iconColor});

  final IconData? icon;
  final String label;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 13,
              color: iconColor ?? colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
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
    this.backgroundColor,
    this.tooltip,
  });

  final IconData icon;
  final Color color;
  final Widget label;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      enabled: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 5),
                DefaultTextStyle(
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  child: label,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Description text that can expand beyond the collapsed 2-line preview.
/// A "Read more" affordance appears only when the text actually overflows.
class _ExpandableDescription extends StatefulWidget {
  const _ExpandableDescription({required this.text, required this.style});

  final String text;
  final TextStyle? style;

  @override
  State<_ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  static const _collapsedLines = 2;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          maxLines: _collapsedLines,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              maxLines: _expanded ? null : _collapsedLines,
              overflow: _expanded ? null : TextOverflow.ellipsis,
              style: widget.style,
            ),
            if (overflows)
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 2),
                  child: Text(
                    _expanded
                        ? context.tr('show_less')
                        : context.tr('read_more'),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
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