import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/media_url.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../feed/domain/issue.dart';
import '../../../rep_dashboard/domain/official_response.dart';

/// A rich, expandable vertical audit timeline widget that clearly references
/// which user/authority posted what across the lifecycle of an issue:
/// 1. Reported by [Reporter / Anon ID] with relative time & media links.
/// 2. Assigned Authority with claimed/unclaimed status.
/// 3. Acknowledged by [Representative/Authority] (if acknowledged).
/// 4. Resolution Proof Uploaded with photo preview & resolution notes.
/// 5. Community Verification (confirmations & disputes with voter handles & nearby flags).
/// 6. Resolved (Authority Resolved vs Community Quorum Resolved).
class AuditTimelineCard extends StatefulWidget {
  const AuditTimelineCard({
    super.key,
    required this.issue,
    this.officialResponses = const [],
    this.initiallyExpanded = true,
  });

  final Issue issue;
  final List<OfficialResponse> officialResponses;
  final bool initiallyExpanded;

  @override
  State<AuditTimelineCard> createState() => _AuditTimelineCardState();
}

class _AuditTimelineCardState extends State<AuditTimelineCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  /// Deadline for the currently-active step, used to render a live
  /// countdown derived from the report timestamp per the 24h/72h/7d cadence.
  DateTime? _activeDeadline(String status) {
    final createdAt = widget.issue.createdAt;
    switch (status) {
      case 'escalating':
        return createdAt.add(const Duration(hours: 72));
      case 'forwarded':
        return createdAt.add(const Duration(days: 7));
      case 'pending_quorum':
        return createdAt.add(const Duration(days: 3));
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final issue = widget.issue;
    final status = issue.status;
    final isResolved = issue.status == 'resolved';
    final isPendingQuorum = issue.status == 'pending_quorum';
    final isAcknowledged = issue.acknowledgedAt != null ||
        widget.officialResponses.isNotEmpty ||
        (status != 'unacknowledged' && status != 'open');
    final hasProof = issue.resolutionProof != null &&
        issue.resolutionProof!.trim().isNotEmpty;
    final officialName = widget.officialResponses.isNotEmpty
        ? widget.officialResponses.first.officialName
        : (issue.assignedRepresentative?.officialName);

    final resolutionType = issue.resolutionType;
    final isOfficialResolved = resolutionType == 'official';
    final isCommunityResolved = resolutionType == 'community' ||
        (isResolved && !isOfficialResolved);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row with Expand Toggle
            Row(
              children: [
                const Icon(Icons.timeline_rounded, color: AppColors.brand),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr('activity_timeline_title'),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (isResolved)
                  Container(
                    key: const Key('resolution_type_badge'),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOfficialResolved
                          ? AppColors.brand.withValues(alpha: 0.15)
                          : AppColors.resolved.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isOfficialResolved
                            ? AppColors.brand
                            : AppColors.resolved,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      isOfficialResolved
                          ? context.tr('resolution_type_official')
                          : context.tr('resolution_type_community'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isOfficialResolved
                            ? AppColors.brand
                            : AppColors.resolved,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Concise Summary Box (Always visible)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Status: ${context.tr("status_$status")}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        formatRelativeTime(issue.createdAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: isResolved
                        ? 1.0
                        : (isPendingQuorum
                            ? 0.75
                            : (isAcknowledged ? 0.5 : 0.25)),
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    color: isResolved ? AppColors.resolved : AppColors.brand,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Toggle Expand Button
            InkWell(
              key: const Key('toggle_activity_timeline_button'),
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isExpanded
                          ? context.tr('activity_timeline_collapse')
                          : context.tr('activity_timeline_expand'),
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),

            // Expanded Full Timeline
            if (_isExpanded) ...[
              const Divider(height: 24),

              // Event 1: Reported
              _TimelineItem(
                key: const Key('timeline_event_reported'),
                isFirst: true,
                isDone: true,
                isActive: status == 'unacknowledged' || status == 'open',
                title:
                    '${context.tr('timeline_event_reported')} ${issue.reporterLabel}',
                subtitle:
                    '${issue.ward} • ${formatRelativeTime(issue.createdAt)}',
                icon: Icons.flag_rounded,
                trailingWidget: _buildReportMediaPreviews(context),
              ),

              // Event 2: Auto-Assigned / Acknowledged
              _TimelineItem(
                key: const Key('timeline_event_acknowledged'),
                isDone: isAcknowledged,
                isActive: status == 'under_review' ||
                    status == 'escalating' ||
                    status == 'forwarded',
                title: isAcknowledged
                    ? '${context.tr('timeline_event_acknowledged')} ${officialName ?? 'Ward Authority'}'
                    : 'Auto-Assigned to ${issue.assignedRepresentative?.officialName ?? issue.ward}',
                subtitle: isAcknowledged
                    ? (issue.acknowledgedAt != null
                        ? 'Acknowledged ${formatRelativeTime(issue.acknowledgedAt!)}'
                        : 'Official review recorded & scheduled')
                    : 'Authority handle: @${issue.assignedRepresentative?.handle ?? "unassigned"}',
                icon: Icons.verified_user_rounded,
                deadline: (status == 'escalating' || status == 'forwarded')
                    ? _activeDeadline(status)
                    : null,
              ),

              // Event 3: Resolution Proof Uploaded
              _TimelineItem(
                key: const Key('timeline_event_proof'),
                isDone: hasProof,
                isActive: (isPendingQuorum || hasProof) && !isResolved,
                title: hasProof
                    ? context.tr('timeline_event_proof_uploaded')
                    : 'Resolution Proof Pending',
                subtitle: hasProof
                    ? (issue.resolutionNotes != null &&
                            issue.resolutionNotes!.isNotEmpty
                        ? '${context.tr('resolution_notes_label')} ${issue.resolutionNotes}'
                        : 'Live GPS photo proof submitted on-site')
                    : 'Must be verified with live in-app camera proof',
                icon: Icons.camera_alt_rounded,
                trailingWidget:
                    hasProof ? _buildResolutionProofPreview(context) : null,
              ),

              // Event 4: Community Verification in Progress
              _TimelineItem(
                key: const Key('timeline_event_verification'),
                isDone: issue.confirmationsCount >= 3 || isResolved,
                isActive: isPendingQuorum,
                title: context.tr('timeline_event_verification'),
                subtitle: '${issue.confirmationsCount} / 3 neighbors confirmed'
                    '${issue.disputesCount > 0 ? ' • ${issue.disputesCount} disputed' : ''}',
                icon: Icons.people_alt_rounded,
                deadline: isPendingQuorum ? _activeDeadline(status) : null,
                trailingWidget: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: (issue.confirmationsCount / 3).clamp(0.0, 1.0),
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      color:
                          isResolved ? AppColors.resolved : AppColors.verified,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('inbox_quorum_desc'),
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),

              // Event 5: Resolved & Published
              _TimelineItem(
                key: const Key('timeline_event_resolved'),
                isLast: true,
                isDone: isResolved,
                isActive: isResolved,
                title: isResolved
                    ? context.tr('timeline_event_resolved')
                    : 'Pending Neighborhood Resolution',
                subtitle: isResolved
                    ? (issue.resolvedAt != null
                        ? 'Civic win verified on ${formatRelativeTime(issue.resolvedAt!)}'
                        : 'Neighborhood resolution verified and published')
                    : 'Final resolution once confirmed by 3 verified neighbors',
                icon: Icons.emoji_events_rounded,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget? _buildReportMediaPreviews(BuildContext context) {
    final mediaUrls = widget.issue.mediaUrls;
    final hasVideo =
        widget.issue.videoUrl != null && widget.issue.videoUrl!.isNotEmpty;
    if (mediaUrls.isEmpty && !hasVideo) return null;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.issue.description.isNotEmpty) ...[
            Text(
              widget.issue.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...mediaUrls.asMap().entries.map((entry) {
                final idx = entry.key;
                final url = entry.value;
                return GestureDetector(
                  key: Key('media_thumbnail_$idx'),
                  onTap: () => _showMediaDialog(context, url),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 56,
                      height: 56,
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            resolveMediaUrl(url),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.image,
                              size: 24,
                              color: Colors.grey,
                            ),
                          ),
                          Positioned(
                            left: 4,
                            bottom: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Upload ${idx + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              if (hasVideo)
                Container(
                  key: const Key('video_attached_badge'),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.videocam_rounded,
                          size: 16, color: AppColors.brand),
                      const SizedBox(width: 4),
                      Text(
                        'Video attached',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResolutionProofPreview(BuildContext context) {
    final proof = widget.issue.resolutionProof!;
    final resolved = resolveMediaUrl(proof);
    final isEmptyUrl = resolved.isEmpty;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GestureDetector(
        key: const Key('timeline_resolution_proof_preview'),
        onTap: () => _showMediaDialog(context, proof),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: AppColors.resolved.withValues(alpha: 0.5)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                if (!isEmptyUrl)
                  Image.network(
                    resolved,
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 80,
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      child: const Center(
                        child: Icon(Icons.check_circle,
                            color: AppColors.resolved, size: 32),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 80,
                    width: double.infinity,
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    padding: const EdgeInsets.all(8),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified,
                              color: AppColors.resolved),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              proof,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.zoom_in, color: Colors.white, size: 14),
                        SizedBox(width: 2),
                        Text(
                          'Proof Photo (Camera GPS)',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMediaDialog(BuildContext context, String url) {
    final resolved = resolveMediaUrl(url);
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (resolved.isNotEmpty)
              Image.network(
                resolved,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Icon(Icons.broken_image, size: 48),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(url),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single step row within the vertical timeline.
class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isDone,
    required this.isActive,
    required this.icon,
    this.isFirst = false,
    this.isLast = false,
    this.deadline,
    this.trailingWidget,
  });

  final String title;
  final String subtitle;
  final bool isDone;
  final bool isActive;
  final IconData icon;
  final bool isFirst;
  final bool isLast;
  final DateTime? deadline;
  final Widget? trailingWidget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final dotColor = isDone
        ? AppColors.resolved
        : isActive
            ? colorScheme.primary
            : colorScheme.outlineVariant;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppColors.resolved.withValues(alpha: 0.15)
                        : (isActive
                            ? colorScheme.primary.withValues(alpha: 0.15)
                            : colorScheme.surfaceContainerHighest),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: dotColor,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      isDone
                          ? Icons.check
                          : (isActive ? Icons.circle : icon),
                      size: 13,
                      color: dotColor,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isDone
                          ? AppColors.resolved.withValues(alpha: 0.5)
                          : colorScheme.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isDone || isActive
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isDone || isActive
                                ? colorScheme.onSurface
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (isActive && deadline != null) ...[
                        const SizedBox(width: 8),
                        _LiveCountdown(deadline: deadline!),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (trailingWidget != null) trailingWidget!,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Live countdown to [deadline], updating once per second while mounted.
class _LiveCountdown extends StatefulWidget {
  const _LiveCountdown({required this.deadline});

  final DateTime deadline;

  @override
  State<_LiveCountdown> createState() => _LiveCountdownState();
}

class _LiveCountdownState extends State<_LiveCountdown> {
  Timer? _timer;
  late String _label;

  @override
  void initState() {
    super.initState();
    _label = _format(widget.deadline);
    if (!widget.deadline.difference(DateTime.now()).isNegative) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        final remaining = widget.deadline.difference(DateTime.now());
        if (remaining.isNegative || remaining.inSeconds <= 0) {
          timer.cancel();
          setState(() => _label = 'Deadline passed');
          return;
        }
        final next = _format(widget.deadline);
        if (next != _label) {
          setState(() => _label = next);
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  static String _format(DateTime deadline) {
    final remaining = deadline.difference(DateTime.now());
    if (remaining.isNegative || remaining.inSeconds <= 0) {
      return 'Deadline passed';
    }
    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;
    if (days > 0) return '$days d $hours h left';
    if (hours > 0) return '$hours h $minutes m left';
    if (minutes > 0) return '$minutes m $seconds s left';
    return '$seconds s left';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      _label,
      style: theme.textTheme.labelSmall?.copyWith(
        color: AppColors.urgent,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
