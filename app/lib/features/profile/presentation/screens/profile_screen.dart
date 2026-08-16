import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/media_url.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../compose/presentation/compose_providers.dart';
import '../../../feed/domain/issue.dart';
import '../profile_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final outbox = ref.watch(offlineOutboxProvider);
    final pendingOutboxCount = outbox.pendingCount;
    final selectedFilter = ref.watch(myIssuesFilterProvider);
    final myIssuesAsync = ref.watch(myIssuesProvider);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('profile_title')),
        centerTitle: false,
        actions: [
          IconButton(
            key: const Key('openSettingsButton'),
            icon: const Icon(Icons.settings_outlined),
            tooltip: context.tr('profile_settings_header'),
            onPressed: () => context.push(RoutePaths.settings),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                'Failed to load profile',
                style: theme.textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () {
                  ref.invalidate(userProfileProvider);
                  ref.invalidate(myIssuesProvider);
                },
                child: Text(context.tr('action_retry')),
              ),
            ],
          ),
        ),
        data: (profile) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(userProfileProvider);
              ref.invalidate(myIssuesProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header section: Avatar, Anon ID & Verified Badge ──
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  colorScheme.primary.withValues(alpha: 0.25),
                              width: 2,
                            ),
                          ),
                          child: profile.photoUrl != null &&
                                  profile.photoUrl!.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    resolveMediaUrl(profile.photoUrl),
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Icon(
                                      Icons.masks_outlined,
                                      size: 34,
                                      color: AppColors.anonMask,
                                    ),
                                  ),
                                )
                              : CircleAvatar(
                                  radius: 40,
                                  backgroundColor: AppColors.anonMask.withValues(
                                    alpha: 0.14,
                                  ),
                                  child: Icon(
                                    profile.isGuest
                                        ? Icons.person_outline
                                        : Icons.masks_outlined,
                                    size: 34,
                                    color: AppColors.anonMask,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                profile.displayName != null &&
                                        profile.displayName!.isNotEmpty
                                    ? profile.displayName!
                                    : profile.phone != null
                                        ? profile.phone!
                                        : profile.email != null
                                            ? profile.email!
                                            : profile.isGuest
                                                ? 'Guest Session'
                                                : 'Anonymous Citizen',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!profile.isGuest) ...[
                              const SizedBox(width: 5),
                              const Icon(
                                Icons.verified,
                                color: AppColors.verified,
                                size: 18,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Chip(
                          visualDensity: VisualDensity.compact,
                          avatar: const Icon(Icons.fingerprint, size: 14),
                          label: Text(
                            'Anon ID: ${_truncateAnonId(profile.anonId)}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          backgroundColor: colorScheme.surfaceContainerHigh,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (!profile.isGuest)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Center(
                        child: FilledButton.tonalIcon(
                          key: const Key('editProfileButton'),
                          onPressed: () => context.push(RoutePaths.editProfile),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Edit Profile'),
                        ),
                      ),
                    ),

                  // ── Guest Banner ──────────────────────────────────────
                  if (profile.isGuest) ...[
                    Card(
                      color: colorScheme.tertiaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 20,
                              color: colorScheme.onTertiaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Guest Session Active. Your activity is not linked to an account.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onTertiaryContainer,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // ── User Activity Stats Card ──────────────────────────
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatMetric(
                            label: 'Issues',
                            value: profile.issuesCount.toString(),
                            icon: Icons.report_problem_outlined,
                          ),
                          _buildDivider(colorScheme),
                          _StatMetric(
                            label: 'Upvotes',
                            value: profile.upvotesCount.toString(),
                            icon: Icons.thumb_up_outlined,
                          ),
                          _buildDivider(colorScheme),
                          _StatMetric(
                            label: 'Verified',
                            value: profile.quorumVotesCount.toString(),
                            icon: Icons.how_to_vote_outlined,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Offline Outbox Queue & Drafts Card ─────────────────
                  Text(
                    'Offline Outbox & Drafts',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.outbox_rounded,
                              color: colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pending Outbox Items: $pendingOutboxCount',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  pendingOutboxCount > 0
                                      ? context.tr('profile_outbox_queued')
                                      : context.tr('profile_outbox_synced'),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.tonal(
                            key: const Key('viewOutboxButton'),
                            onPressed: () => context.push(RoutePaths.outbox),
                            child: Text(context.tr('profile_view')),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── My Reported Issues & Activity Section ─────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Reported Issues & Activity',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.1,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!profile.isGuest)
                        TextButton.icon(
                          onPressed: () => context.push(RoutePaths.compose),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Report New'),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Status Filter Chips: All / Active / Resolved
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          key: const Key('myIssuesFilter_all'),
                          label: 'All',
                          selected: selectedFilter == 'all',
                          onSelected: () => ref
                              .read(myIssuesFilterProvider.notifier)
                              .state = 'all',
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          key: const Key('myIssuesFilter_active'),
                          label: 'Unresolved',
                          selected: selectedFilter == 'active',
                          onSelected: () => ref
                              .read(myIssuesFilterProvider.notifier)
                              .state = 'active',
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          key: const Key('myIssuesFilter_resolved'),
                          label: 'Resolved',
                          selected: selectedFilter == 'resolved',
                          onSelected: () => ref
                              .read(myIssuesFilterProvider.notifier)
                              .state = 'resolved',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // List of User Issues
                  if (profile.isGuest)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            'Sign in to view and manage your reported issues history.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    )
                  else
                    myIssuesAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (err, _) => Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: Column(
                              children: [
                                Text(
                                  'Could not load your issues.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.error,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                FilledButton.tonal(
                                  onPressed: () =>
                                      ref.refresh(myIssuesProvider),
                                  child: Text(context.tr('action_retry')),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      data: (issues) {
                        if (issues.isEmpty) {
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.assignment_outlined,
                                      size: 36,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No issues found in this filter.',
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 4,
                            mainAxisSpacing: 4,
                          ),
                          itemCount: issues.length,
                          itemBuilder: (context, index) {
                            final issue = issues[index];
                            return _UserIssueGridTile(
                              issue: issue,
                              onTap: () => context.push(
                                RoutePaths.issueDetailFor(issue.id),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  const SizedBox(height: 16),

                  // ── Settings Link Section ────────────────────────────
                  Text(
                    context.tr('profile_settings_header'),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          key: const Key('viewGamificationButton'),
                          dense: true,
                          leading:
                              const Icon(Icons.workspace_premium_outlined),
                          title: Text(
                            context.tr('profile_gamification'),
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            context.tr('profile_gamification_sub'),
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push(RoutePaths.gamification),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          dense: true,
                          leading:
                              Icon(Icons.logout, color: colorScheme.error),
                          title: Text(
                            profile.isGuest
                                ? 'End Guest Session'
                                : 'Sign Out',
                            style: TextStyle(
                              color: colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () async {
                            await ref.read(authControllerProvider).signOut();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static String _truncateAnonId(String id) {
    if (id.length <= 16) return id;
    return '${id.substring(0, 8)}...${id.substring(id.length - 6)}';
  }

  Widget _buildDivider(ColorScheme colorScheme) {
    return Container(
        height: 32, width: 1, color: colorScheme.outlineVariant);
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected
            ? colorScheme.onPrimary
            : colorScheme.onSurfaceVariant,
      ),
      selectedColor: colorScheme.primary,
      backgroundColor: colorScheme.surfaceContainerHigh,
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _UserIssueGridTile extends StatelessWidget {
  const _UserIssueGridTile({
    required this.issue,
    required this.onTap,
  });

  final Issue issue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categoryColor = AppColors.categoryColorFor(issue.category);

    return GestureDetector(
      key: Key('userIssueItem_${issue.id}'),
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (issue.mediaUrls.isNotEmpty && issue.mediaUrls.first.isNotEmpty)
              Image.network(
                resolveMediaUrl(issue.mediaUrls.first),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _gridFallback(
                  theme,
                  colorScheme,
                  categoryColor,
                ),
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : _gridFallback(theme, colorScheme, categoryColor),
              )
            else
              _gridFallback(theme, colorScheme, categoryColor),
            Positioned(
              left: 4,
              top: 4,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      issue.isResolved
                          ? Icons.check_circle
                          : Icons.pending_outlined,
                      size: 11,
                      color: issue.isResolved
                          ? const Color(0xFF4CAF50)
                          : Colors.amberAccent,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      issue.isResolved ? 'RESOLVED' : 'ACTIVE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gridFallback(
    ThemeData theme,
    ColorScheme colorScheme,
    Color categoryColor,
  ) {
    return Container(
      color: categoryColor.withValues(alpha: 0.18),
      alignment: Alignment.center,
      child: Icon(
        Icons.flag_outlined,
        size: 26,
        color: categoryColor,
      ),
    );
  }
}

class _StatMetric extends StatelessWidget {
  const _StatMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: colorScheme.primary, size: 20),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
