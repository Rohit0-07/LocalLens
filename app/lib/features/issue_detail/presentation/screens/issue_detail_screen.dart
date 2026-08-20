import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/feedback/error_copy.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/media_url.dart';
import '../../../../core/utils/profile_navigation.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/media_preview_widget.dart';
import '../../../../shared/widgets/skeleton_list.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../compose/data/media_service.dart';
import '../../../feed/domain/issue.dart';
import '../../../feed/presentation/feed_providers.dart';
import '../../../rep_dashboard/presentation/rep_dashboard_providers.dart';
import '../widgets/assigned_authority_card.dart';
import '../widgets/audit_timeline_card.dart';
import '../widgets/comments_section.dart';
import '../widgets/official_response_card.dart';
import '../widgets/resolution_proof_modal.dart';

final singleIssueProvider =
    FutureProvider.family<Issue, int>((ref, issueId) async {
  final repo = ref.watch(feedRepositoryProvider);
  return repo.fetchIssue(issueId);
});

class IssueDetailScreen extends ConsumerWidget {
  const IssueDetailScreen({
    super.key,
    required this.issueId,
    this.mediaService,
    this.locationService,
  });

  final int issueId;
  final MediaService? mediaService;
  final LocationService? locationService;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncIssue = ref.watch(singleIssueProvider(issueId));

    return Scaffold(
      appBar: AppBar(
        title: asyncIssue.when(
          data: (issue) => Row(
            children: [
              Expanded(
                child: Text(
                  issue.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '#$issueId',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          loading: () => Text('Issue #$issueId'),
          error: (err, stack) => Text('Issue #$issueId'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: context.tr('action_refresh'),
            onPressed: () => ref.invalidate(singleIssueProvider(issueId)),
          ),
        ],
      ),
      body: asyncIssue.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: SkeletonList(),
        ),
        error: (err, stack) => Padding(
          padding: const EdgeInsets.all(16),
          child: EmptyState(
            icon: Icons.error_outline,
            title: context.tr('issue_load_error_title'),
            message: friendlyErrorMessage(
              err,
              fallback: context.tr('issue_load_error_msg'),
            ),
            actionLabel: context.tr('action_retry'),
            onAction: () => ref.invalidate(singleIssueProvider(issueId)),
          ),
        ),
        data: (issue) {
          final officialResponses =
              ref.watch(officialResponsesProvider(issueId)).asData?.value ?? [];

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(singleIssueProvider(issueId)),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header Row
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        key: Key('issueDetailReporter_${issue.id}'),
                        onTap: () => openReporterProfile(context, ref, issue.reporterId),
                        borderRadius: BorderRadius.circular(8),
                        child: Row(
                          children: [
                            if (issue.isAnonymous) ...[
                              Icon(Icons.face_retouching_natural,
                                  size: 18, color: AppColors.anonMask),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    issue.reporterLabel,
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                  ),
                                  Text(
                                    '${issue.ward} • ${formatRelativeTime(issue.createdAt)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    StatusBadge(status: issue.status),
                  ],
                ),
                const SizedBox(height: 16),

                // Title and Description
                Text(
                  issue.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (issue.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    issue.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
                if (issue.mediaUrls.isNotEmpty ||
                    (issue.videoUrl != null && issue.videoUrl!.isNotEmpty) ||
                    (issue.resolutionProof != null &&
                        issue.resolutionProof!.isNotEmpty)) ...[
                  const SizedBox(height: 16),
                  MediaPreviewWidget(
                    key: Key('issueDetailMedia_${issue.id}'),
                    mediaUrls: issue.mediaUrls,
                    videoUrl: issue.videoUrl,
                    resolutionProof: issue.resolutionProof,
                    maxHeight: 260,
                    heroTagPrefix: 'detail_${issue.id}',
                  ),
                ],
                const SizedBox(height: 16),

                // Tags & Upvote Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            label: Text(
                              issue.category.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          if (issue.isFuzzed)
                            Chip(
                              avatar: const Icon(Icons.blur_on, size: 16),
                              label: Text(context.tr('issue_location_fuzzed')),
                            ),
                          if (issue.isShielded)
                            Chip(
                              avatar: Icon(Icons.shield_outlined,
                                  size: 16, color: AppColors.anonMask),
                              label: Text(context.tr('issue_shielded_mode')),
                            ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      key: Key('upvote_button_${issue.id}'),
                      onPressed: () async {
                        try {
                          await ref
                              .read(multiTypeFeedProvider.notifier)
                              .toggleUpvote(
                                issue.id,
                                issue.latitude,
                                issue.longitude,
                                currentlyUpvoted: issue.hasUpvoted,
                              );
                          ref.invalidate(singleIssueProvider(issueId));
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
                      icon: Icon(
                        issue.hasUpvoted
                            ? Icons.thumb_up
                            : Icons.thumb_up_outlined,
                        size: 18,
                        color: issue.hasUpvoted
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      label: Text(
                        '${issue.upvotesCount}',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: issue.hasUpvoted
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                  fontWeight: issue.hasUpvoted
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: issue.hasUpvoted
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Colors.transparent,
                        side: BorderSide(
                          color: issue.hasUpvoted
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outlineVariant,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),

                // Assigned Department Authority
                AssignedAuthorityCard(
                  issue: issue,
                  onReportSubmitted: () {
                    ref.invalidate(singleIssueProvider(issueId));
                  },
                ),
                const SizedBox(height: 16),

                // Rich Detailed Audit Timeline
                AuditTimelineCard(
                  issue: issue,
                  officialResponses: officialResponses,
                ),
                const Divider(height: 32),

                // Official Representative Responses
                if (officialResponses.isNotEmpty) ...[
                  ...officialResponses
                      .map((res) => OfficialResponseCard(response: res)),
                  const Divider(height: 32),
                ],

                // Community / Neighbor Verification Section
                _CommunityVerificationWidget(
                  issue: issue,
                  issueId: issueId,
                  mediaService: mediaService,
                  locationService: locationService,
                ),
                const Divider(height: 32),

                // Community Discussion Section
                CommentsSection(issueId: issueId),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CommunityVerificationWidget extends ConsumerWidget {
  const _CommunityVerificationWidget({
    required this.issue,
    required this.issueId,
    this.mediaService,
    this.locationService,
  });

  final Issue issue;
  final int issueId;
  final MediaService? mediaService;
  final LocationService? locationService;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isPending = issue.status == 'pending_quorum';
    final isResolved = issue.status == 'resolved';

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people_alt_rounded, color: AppColors.verified),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr('issue_quorum_title'),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              context.tr('issue_quorum_subtitle'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),

            // Resolution proof card if present
            if (issue.resolutionProof != null &&
                issue.resolutionProof!.trim().isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.resolved.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_rounded,
                            size: 18, color: AppColors.resolved),
                        const SizedBox(width: 6),
                        Text(
                          context.tr('resolution_proof_label'),
                          style: theme.textTheme.labelMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (issue.resolutionProof!.startsWith('http'))
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          resolveMediaUrl(issue.resolutionProof!),
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(issue.resolutionProof!),
                          ),
                        ),
                      )
                    else
                      Text(
                        issue.resolutionProof!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    if (issue.resolutionNotes != null &&
                        issue.resolutionNotes!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${context.tr('resolution_notes_label')} ${issue.resolutionNotes}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            Text(
              '${context.tr('quorum_progress')} ${issue.confirmationsCount} / 3',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: (issue.confirmationsCount / 3).clamp(0.0, 1.0),
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: isResolved ? AppColors.resolved : AppColors.verified,
            ),
            const SizedBox(height: 16),

            if (isPending) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('quorum_vote_confirm'),
                      icon: const Icon(Icons.check_circle_outline,
                          color: AppColors.resolved),
                      label: Text(context.tr('quorum_confirm')),
                      onPressed: () async {
                        final repo = ref.read(feedRepositoryProvider);
                        try {
                          await repo.voteQuorum(
                            issueId: issueId,
                            vote: 'confirm',
                            latitude: issue.latitude,
                            longitude: issue.longitude,
                          );
                          ref.invalidate(singleIssueProvider(issueId));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  context.tr('quorum_confirm_submitted'),
                                ),
                              ),
                            );
                          }
                        } catch (err) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  friendlyErrorMessage(
                                    err,
                                    fallback: context.tr('quorum_vote_failed'),
                                  ),
                                ),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('quorum_vote_dispute'),
                      icon: const Icon(Icons.highlight_off_rounded,
                          color: AppColors.urgent),
                      label: Text(context.tr('quorum_dispute')),
                      onPressed: () async {
                        final repo = ref.read(feedRepositoryProvider);
                        try {
                          await repo.voteQuorum(
                            issueId: issueId,
                            vote: 'dispute',
                            latitude: issue.latitude,
                            longitude: issue.longitude,
                          );
                          ref.invalidate(singleIssueProvider(issueId));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  context.tr('quorum_dispute_submitted'),
                                ),
                              ),
                            );
                          }
                        } catch (err) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  friendlyErrorMessage(
                                    err,
                                    fallback: context.tr('quorum_vote_failed'),
                                  ),
                                ),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('quorum_note'),
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ] else if (!isResolved) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('submit_resolution_button'),
                  icon: const Icon(Icons.photo_camera_rounded),
                  label: Text(context.tr('submit_resolution_proof')),
                  onPressed: () => ResolutionProofModal.show(
                    context,
                    issueId: issueId,
                    initialLat: issue.latitude,
                    initialLng: issue.longitude,
                    mediaService: mediaService,
                    locationService: locationService,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
