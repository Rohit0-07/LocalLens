import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/feedback/app_messenger.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/storage/local_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/media_url.dart';
import '../../../compose/data/media_service.dart';
import '../../../compose/presentation/compose_providers.dart';
import '../../../feed/domain/issue.dart';
import '../../../feed/presentation/feed_providers.dart';
import '../profile_providers.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/profile_role_badge.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();

  String _savedBio = '';
  bool _isEditingBio = false;
  bool _bioChanged = false;

  @override
  void initState() {
    super.initState();
    _bioController.addListener(_onBioChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.removeListener(_onBioChanged);
    _bioController.dispose();
    super.dispose();
  }

  void _onBioChanged() {
    final changed = _bioController.text.trim() != _savedBio;
    if (changed != _bioChanged) {
      setState(() => _bioChanged = changed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final outbox = ref.watch(offlineOutboxProvider);
    final pendingOutboxCount = outbox.pendingCount;
    final selectedFilter = ref.watch(myIssuesFilterProvider);
    final myIssuesAsync = ref.watch(myIssuesProvider);
    final settings = ref.watch(userSettingsProvider);
    final settingsNotifier = ref.read(userSettingsProvider.notifier);
    final draftsAsync = ref.watch(savedDraftsProvider);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final draftsCount = draftsAsync.when(
      loading: () => null,
      error: (_, _) => 0,
      data: (drafts) => drafts.length,
    );

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
                  // ── Header: photo on left, identity + bio on right ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        key: const Key('editProfilePhotoButton'),
                        onTap: profile.isGuest
                            ? null
                            : () => _editPhoto(profile),
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.25,
                                  ),
                                  width: 2,
                                ),
                              ),
                              child: ProfileAvatar(
                                photoUrl: profile.photoUrl,
                                displayName: profile.displayName,
                                isGuest: profile.isGuest,
                              ),
                            ),
                            if (!profile.isGuest)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: colorScheme.surface,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 11,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    _primaryIdentityLabel(
                                      profile,
                                      settings.showDisplayName,
                                    ),
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
                                  IconButton(
                                    key: const Key('editNameButton'),
                                    onPressed: () => _editName(profile),
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 16,
                                    ),
                                    tooltip: 'Edit Name',
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 26,
                                      minHeight: 26,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (!profile.isGuest) ...[
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  ProfileRoleBadge(
                                    key: const Key('profileRoleBadge'),
                                    role: profile.role,
                                  ),
                                  if (profile.ward != null &&
                                      profile.ward!.isNotEmpty)
                                    Chip(
                                      key: const Key('profileWardChip'),
                                      visualDensity: VisualDensity.compact,
                                      avatar: const Icon(
                                        Icons.location_on_outlined,
                                        size: 14,
                                      ),
                                      label: Text(
                                        profile.ward!,
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      backgroundColor:
                                          colorScheme.surfaceContainerHigh,
                                      side: BorderSide.none,
                                    ),
                                ],
                              ),
                            ],
                            _buildBioSection(profile),
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
                            if (!profile.isGuest) ...[
                              const SizedBox(height: 8),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: SegmentedButton<bool>(
                                  key: const Key('profileIdentityToggle'),
                                  showSelectedIcon: false,
                                  segments: const [
                                    ButtonSegment(
                                      value: true,
                                      label: Text('Display Name'),
                                    ),
                                    ButtonSegment(
                                      value: false,
                                      label: Text('Anon ID'),
                                    ),
                                  ],
                                  selected: {settings.showDisplayName},
                                  onSelectionChanged: (selection) {
                                    if (selection.isNotEmpty) {
                                      settingsNotifier.setShowDisplayName(
                                        selection.first,
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Representative Dashboard Entry (rep only) ─────────
                  if (!profile.isGuest && profile.isRepresentative) ...[
                    Card(
                      elevation: 0,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: colorScheme.outlineVariant),
                      ),
                      child: InkWell(
                        key: const Key('repDashboardEntryButton'),
                        onTap: () => context.push(RoutePaths.repDashboard),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor:
                                    colorScheme.primaryContainer,
                                child: Icon(
                                  Icons.how_to_reg_rounded,
                                  size: 20,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Representative Dashboard',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      profile.ward ?? 'Your ward',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color:
                                                colorScheme.onSurfaceVariant,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.chevron_right,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ── Guest Banner ──────────────────────────────────────
                  if (profile.isGuest) ...[
                    Card(
                      elevation: 0,
                      color: colorScheme.tertiaryContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: colorScheme.outlineVariant),
                      ),
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
                    key: const Key('profileStatsCard'),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
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

                  // ── Your Activity (Drafts & Offline Outbox) ───────────
                  Text(
                    'Your Activity',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Card(
                    elevation: 0,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          key: const Key('profileDraftsButton'),
                          leading: Icon(
                            Icons.drafts_outlined,
                            color: colorScheme.primary,
                          ),
                          title: const Text('Drafts'),
                          subtitle: Text(
                            (draftsCount ?? 0) > 0
                                ? '$draftsCount saved'
                                : 'No drafts yet',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          onTap: () => context.push(RoutePaths.drafts),
                        ),
                        Divider(
                          height: 1,
                          color: colorScheme.outlineVariant,
                        ),
                        ListTile(
                          key: const Key('viewOutboxButton'),
                          leading: Icon(
                            Icons.outbox_rounded,
                            color: colorScheme.primary,
                          ),
                          title: const Text('Offline Outbox'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pending Outbox Items: $pendingOutboxCount',
                                style: theme.textTheme.bodySmall?.copyWith(
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
                          trailing: Icon(
                            Icons.chevron_right,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          onTap: () => context.push(RoutePaths.outbox),
                        ),
                      ],
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
                          onSelected: () =>
                              ref.read(myIssuesFilterProvider.notifier).state =
                                  'all',
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          key: const Key('myIssuesFilter_active'),
                          label: 'Unresolved',
                          selected: selectedFilter == 'active',
                          onSelected: () =>
                              ref.read(myIssuesFilterProvider.notifier).state =
                                  'active',
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          key: const Key('myIssuesFilter_resolved'),
                          label: 'Resolved',
                          selected: selectedFilter == 'resolved',
                          onSelected: () =>
                              ref.read(myIssuesFilterProvider.notifier).state =
                                  'resolved',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // List of User Issues
                  if (profile.isGuest)
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: colorScheme.outlineVariant),
                      ),
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
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: colorScheme.outlineVariant),
                        ),
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
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: colorScheme.outlineVariant,
                              ),
                            ),
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
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
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
                              onDelete: () => _confirmDeleteIssue(issue),
                            );
                          },
                        );
                      },
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

  String _primaryIdentityLabel(UserProfile profile, bool showDisplayName) {
    if (!showDisplayName) {
      return _truncateAnonId(profile.anonId);
    }
    if (profile.displayName != null && profile.displayName!.isNotEmpty) {
      return profile.displayName!;
    }
    if (profile.phone != null) return profile.phone!;
    if (profile.email != null) return profile.email!;
    if (profile.isGuest) return 'Guest Session';
    return 'Anonymous Citizen';
  }

  Future<void> _showChangeLimitsNoticeIfNeeded() async {
    final store = ref.read(localStoreProvider);
    if (store.getString('has_seen_change_limits') == 'true') return;
    await store.setString('has_seen_change_limits', 'true');
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Profile Change Limits'),
        content: const Text(
          'Your display name can be changed up to 2 times in total. '
          'Your bio can be updated once per week and your profile photo once '
          'per hour. Your first-time setup does not count toward these limits.',
        ),
        actions: [
          FilledButton(
            key: const Key('changeLimitsOkButton'),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _editName(UserProfile profile) async {
    await _showChangeLimitsNoticeIfNeeded();
    if (!mounted) return;
    _nameController.text = profile.displayName ?? '';
    final remaining = profile.displayNameChangesRemaining;
    final saved = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Display Name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const Key('editNameField'),
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                hintText: 'What neighbours will see on your reports',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Changes remaining: $remaining',
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('saveNameButton'),
            onPressed: () => Navigator.of(ctx).pop(_nameController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved == null || saved.isEmpty || !mounted) return;
    await _patchProfile({
      'display_name': saved,
    }, successMessage: 'Display name updated');
  }

  Future<void> _startEditBio(UserProfile profile) async {
    await _showChangeLimitsNoticeIfNeeded();
    if (!mounted) return;
    setState(() {
      _savedBio = profile.bio ?? '';
      _bioController.text = profile.bio ?? '';
      _isEditingBio = true;
    });
  }

  void _cancelEditBio() {
    setState(() {
      _bioController.text = _savedBio;
      _isEditingBio = false;
    });
  }

  Future<void> _saveBio() async {
    final saved = _bioController.text.trim();
    setState(() => _isEditingBio = false);
    await _patchProfile({'bio': saved}, successMessage: 'Bio updated');
  }

  Widget _buildBioSection(UserProfile profile) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bio = profile.bio?.trim().isNotEmpty == true
        ? profile.bio!.trim()
        : null;

    if (!_isEditingBio) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                bio ?? 'Add a short bio',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: bio == null
                      ? colorScheme.onSurfaceVariant.withValues(alpha: 0.6)
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          if (!profile.isGuest)
            IconButton(
              key: const Key('editBioButton'),
              onPressed: () => _startEditBio(profile),
              icon: const Icon(Icons.edit_outlined, size: 16),
              tooltip: bio == null ? 'Add Bio' : 'Edit Bio',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: const Key('editBioField'),
          controller: _bioController,
          autofocus: true,
          minLines: 2,
          maxLines: 3,
          maxLength: 280,
          decoration: const InputDecoration(
            isDense: true,
            hintText: 'Tell your neighbours a little about you',
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (_bioChanged) ...[
              TextButton(
                onPressed: _cancelEditBio,
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                key: const Key('saveBioButton'),
                onPressed: _saveBio,
                child: const Text('Save'),
              ),
            ] else
              IconButton(
                onPressed: _cancelEditBio,
                icon: const Icon(Icons.close, size: 18),
                tooltip: 'Close',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _editPhoto(UserProfile profile) async {
    await _showChangeLimitsNoticeIfNeeded();
    if (!mounted) return;
    // Backend timestamps are naive UTC; interpret them as UTC so the limit
    // countdown isn't shown 5h30m in the past/future.
    final nextAllowed = _toUtc(profile.photoNextChangeAllowedAt);
    final blockedUntil = (nextAllowed != null && nextAllowed.isAfter(DateTime.now()))
        ? nextAllowed
        : null;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (blockedUntil != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  'Next photo change allowed: ${_formatDateTime(blockedUntil)}',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ListTile(
              key: const Key('pickPhotoGalleryButton'),
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);
    if (image == null || !mounted) return;
    final bytes = await image.readAsBytes();
    if (!mounted) return;
    try {
      final media = ref.read(mediaServiceProvider);
      final result = await media.uploadMedia(
        bytes: bytes,
        isInAppCamera: false,
      );
      if (!mounted) return;
      await _patchProfile({
        'photo_url': result.url,
      }, successMessage: 'Profile photo updated');
    } catch (err) {
      if (mounted) {
        ref
            .read(appMessengerProvider.notifier)
            .show('Photo upload failed. $err');
      }
    }
  }

  Future<void> _patchProfile(
    Map<String, dynamic> body, {
    required String successMessage,
  }) async {
    try {
      await ref.read(apiClientProvider).patchJson('/auth/me', body: body);
      ref.invalidate(userProfileProvider);
      if (mounted) {
        ref.read(appMessengerProvider.notifier).show(successMessage);
      }
    } on ApiServerException catch (e) {
      if (mounted) {
        final message = e.statusCode == 429
            ? 'Change limit reached. ${e.message}'
            : 'Could not update profile. ${e.message}';
        ref.read(appMessengerProvider.notifier).show(message);
      }
    } catch (err) {
      if (mounted) {
        ref
            .read(appMessengerProvider.notifier)
            .show('Could not update profile. $err');
      }
    }
  }

  Future<void> _confirmDeleteIssue(Issue issue) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Report'),
        content: const Text(
          'Are you sure you want to delete this report? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirmDeleteIssueButton'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(feedRepositoryProvider).deleteIssue(issue.id);
      if (!mounted) return;
      ref.invalidate(myIssuesProvider);
      ref.invalidate(userProfileProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report deleted'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (err) {
      if (mounted) {
        ref
            .read(appMessengerProvider.notifier)
            .show('Could not delete report. $err');
      }
    }
  }

  static String _truncateAnonId(String id) {
    if (id.length <= 16) return id;
    return '${id.substring(0, 8)}...${id.substring(id.length - 6)}';
  }

  static String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/${local.year} $hour:$minute';
  }

  /// Interprets a backend naive-UTC timestamp as UTC (Java-style naive
  /// datetimes get displayed 5h30m early on IST otherwise).
  static DateTime? _toUtc(DateTime? value) {
    if (value == null) return null;
    if (value.isUtc) return value;
    return DateTime.utc(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
      value.second,
      value.millisecond,
      value.microsecond,
    );
  }

  Widget _buildDivider(ColorScheme colorScheme) {
    return Container(height: 32, width: 1, color: colorScheme.outlineVariant);
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
        color: selected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
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
    this.onDelete,
  });

  final Issue issue;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categoryColor = AppColors.categoryColorFor(issue.category);

    return GestureDetector(
      key: Key('userIssueItem_${issue.id}'),
      onTap: onTap,
      onLongPress: onDelete,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (issue.mediaUrls.isNotEmpty && issue.mediaUrls.first.isNotEmpty)
              Image.network(
                resolveMediaUrl(issue.mediaUrls.first),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    _gridFallback(theme, colorScheme, categoryColor),
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
            if (onDelete != null)
              Positioned(
                right: 4,
                top: 4,
                child: GestureDetector(
                  key: Key('deleteIssue_${issue.id}'),
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      size: 11,
                      color: Colors.white,
                    ),
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
      child: Icon(Icons.flag_outlined, size: 26, color: categoryColor),
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
