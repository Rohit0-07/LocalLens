import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/skeleton_list.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../feed/domain/issue.dart';
import '../../../feed/presentation/feed_providers.dart';
import '../../../rep_dashboard/presentation/rep_dashboard_providers.dart';
import '../widgets/comments_section.dart';
import '../widgets/official_response_card.dart';

final singleIssueProvider =
    FutureProvider.family<Issue, int>((ref, issueId) async {
  final repo = ref.watch(feedRepositoryProvider);
  return repo.fetchIssue(issueId);
});

class IssueDetailScreen extends ConsumerWidget {
  const IssueDetailScreen({super.key, required this.issueId});

  final int issueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncIssue = ref.watch(singleIssueProvider(issueId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Issue #$issueId'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
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
            title: 'Could not load issue',
            message: err.toString(),
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(singleIssueProvider(issueId)),
          ),
        ),
        data: (issue) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(singleIssueProvider(issueId)),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header Row
              Row(
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
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          '${issue.ward} • ${formatRelativeTime(issue.createdAt)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
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
                        Chip(label: Text('#${issue.category}')),
                        if (issue.isFuzzed)
                          const Chip(
                            avatar: Icon(Icons.blur_on, size: 16),
                            label: Text('Location Fuzzed'),
                          ),
                        if (issue.isShielded)
                          const Chip(
                            avatar: Icon(Icons.shield_outlined,
                                size: 16, color: Colors.purple),
                            label: Text('Shielded Mode'),
                          ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    key: Key('upvote_button_${issue.id}'),
                    onPressed: () async {
                      await ref
                          .read(multiTypeFeedProvider.notifier)
                          .toggleUpvote(
                            issue.id,
                            defaultLatitude,
                            defaultLongitude,
                          );
                      ref.invalidate(singleIssueProvider(issueId));
                    },
                    icon: Icon(
                      issue.hasUpvoted ? Icons.thumb_up : Icons.thumb_up_outlined,
                      size: 18,
                      color: issue.hasUpvoted
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    label: Text(
                      '${issue.upvotesCount}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: issue.hasUpvoted
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurfaceVariant,
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

              // Escalation Ladder Section
              _EscalationLadderWidget(issue: issue),
              const Divider(height: 32),

              // Official Representative Responses
              ref.watch(officialResponsesProvider(issueId)).when(
                    data: (responses) {
                      if (responses.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...responses.map((res) => OfficialResponseCard(response: res)),
                          const Divider(height: 32),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (err, stack) => const SizedBox.shrink(),
                  ),

              // Quorum Resolution Section
              _QuorumResolutionWidget(issue: issue, issueId: issueId),
              const Divider(height: 32),

              // Community Discussion Section
              CommentsSection(issueId: issueId),
            ],
          ),
        ),
      ),
    );
  }
}

class _EscalationLadderWidget extends StatelessWidget {
  const _EscalationLadderWidget({required this.issue});

  final Issue issue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = issue.status;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timeline_rounded, color: Colors.indigo),
                const SizedBox(width: 8),
                Text(
                  'Escalation Ladder Audit',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _TimelineStep(
              title: '1. Reported & Unacknowledged',
              subtitle: '24h window for representative acknowledgment',
              isDone: true,
              isActive: status == 'unacknowledged' || status == 'open',
            ),
            _TimelineStep(
              title: '2. 24h - 72h Escalating',
              subtitle: 'Public escalation on ward feed & ignored list',
              isDone: status == 'escalating' ||
                  status == 'under_review' ||
                  status == 'forwarded' ||
                  status == 'pending_quorum' ||
                  status == 'resolved',
              isActive: status == 'escalating',
            ),
            _TimelineStep(
              title: '3. >7d Forwarded to Council Tier',
              subtitle: 'Auto-forwarded to higher authorities',
              isDone: status == 'forwarded' ||
                  status == 'pending_quorum' ||
                  status == 'resolved',
              isActive: status == 'forwarded',
            ),
            _TimelineStep(
              title: '4. Dual Quorum Resolution',
              subtitle: 'Proof uploaded + 3 neighbor confirmations',
              isDone: status == 'resolved',
              isActive: status == 'pending_quorum',
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.title,
    required this.subtitle,
    required this.isDone,
    required this.isActive,
  });

  final String title;
  final String subtitle;
  final bool isDone;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? Colors.orange
        : (isDone ? Colors.green : Colors.grey.shade400);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.normal,
                        color: color,
                      ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuorumResolutionWidget extends ConsumerWidget {
  const _QuorumResolutionWidget({required this.issue, required this.issueId});

  final Issue issue;
  final int issueId;

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
                const Icon(Icons.people_alt_rounded, color: Colors.teal),
                const SizedBox(width: 8),
                Text(
                  'Quorum-Backed Resolution',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (issue.resolutionProof != null &&
                issue.resolutionProof!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Authority Resolution Proof:',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(issue.resolutionProof!),
                    if (issue.resolutionNotes != null &&
                        issue.resolutionNotes!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('Notes: ${issue.resolutionNotes}',
                          style: theme.textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              'Quorum Progress: ${issue.confirmationsCount} / 3 neighbor confirmations',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: (issue.confirmationsCount / 3).clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade300,
              color: isResolved ? Colors.green : Colors.teal,
            ),
            const SizedBox(height: 16),
            if (isPending) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('quorum_vote_confirm'),
                      icon: const Icon(Icons.check_circle_outline,
                          color: Colors.green),
                      label: const Text('Confirm Fix'),
                      onPressed: () async {
                        final repo = ref.read(feedRepositoryProvider);
                        try {
                          await repo.voteQuorum(
                            issueId: issueId,
                            vote: 'confirm',
                            latitude: defaultLatitude,
                            longitude: defaultLongitude,
                          );
                          ref.invalidate(singleIssueProvider(issueId));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Quorum confirm vote submitted'),
                              ),
                            );
                          }
                        } catch (err) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $err')),
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
                          color: Colors.red),
                      label: const Text('Dispute Fix'),
                      onPressed: () async {
                        final repo = ref.read(feedRepositoryProvider);
                        try {
                          await repo.voteQuorum(
                            issueId: issueId,
                            vote: 'dispute',
                            latitude: defaultLatitude,
                            longitude: defaultLongitude,
                          );
                          ref.invalidate(singleIssueProvider(issueId));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Quorum dispute vote submitted'),
                              ),
                            );
                          }
                        } catch (err) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $err')),
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
                'Note: Votes require device location within issue radius.',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ] else if (!isResolved) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('submit_resolution_button'),
                  icon: const Icon(Icons.task_alt_rounded),
                  label: const Text('Authority: Submit Resolution Proof'),
                  onPressed: () => _showSubmitResolutionDialog(context, ref),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSubmitResolutionDialog(BuildContext context, WidgetRef ref) {
    final proofController = TextEditingController();
    final notesController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Resolution Proof'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: proofController,
              decoration: const InputDecoration(
                labelText: 'Proof Image URL',
                hintText: 'https://storage.example.com/fix_photo.jpg',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Resolution Notes',
                hintText: 'Re-paved 20m asphalt road section...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (proofController.text.length < 5) return;
              final repo = ref.read(feedRepositoryProvider);
              try {
                await repo.submitResolution(
                  issueId: issueId,
                  proofUrl: proofController.text,
                  notes: notesController.text,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                ref.invalidate(singleIssueProvider(issueId));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Resolution submitted for quorum verification'),
                    ),
                  );
                }
              } catch (err) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error submitting resolution: $err')),
                  );
                }
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
