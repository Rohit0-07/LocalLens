import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../compose/presentation/compose_providers.dart';
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
    final themeMode = ref.watch(themeModeProvider);
    final currentLocale = ref.watch(appLocaleProvider);
    final outbox = ref.watch(offlineOutboxProvider);
    final pendingOutboxCount = outbox.pendingCount;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        centerTitle: false,
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
                onPressed: () => ref.refresh(userProfileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (profile) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.anonMask.withValues(alpha: 0.15),
                        child: Icon(
                          profile.isGuest
                              ? Icons.person_outline
                              : Icons.masks_outlined,
                          size: 30,
                          color: AppColors.anonMask,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (profile.phone != null) ...[
                        Text(
                          profile.phone!,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                      ] else if (profile.email != null) ...[
                        Text(
                          profile.email!,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                      ] else ...[
                        Text(
                          profile.isGuest ? 'Guest Session' : 'Anonymous Citizen',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                      ],
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

                // Guest Banner
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

                // User Activity Stats Card
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
                          label: 'Quorum',
                          value: profile.quorumVotesCount.toString(),
                          icon: Icons.how_to_vote_outlined,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Offline Outbox Queue Section / Card
                Text(
                  'Offline Outbox Queue',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.outbox_rounded,
                          color: colorScheme.primary,
                        ),
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
                                    ? 'Items queued for cloud synchronization'
                                    : 'All reports are in sync with cloud',
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
                          child: const Text('View'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Settings Section
                Text(
                  'Settings',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'App Theme',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<ThemeMode>(
                            segments: const [
                              ButtonSegment<ThemeMode>(
                                value: ThemeMode.system,
                                label: Text('System', overflow: TextOverflow.ellipsis),
                                icon: Icon(Icons.brightness_auto, size: 16),
                              ),
                              ButtonSegment<ThemeMode>(
                                value: ThemeMode.light,
                                label: Text('Light', overflow: TextOverflow.ellipsis),
                                icon: Icon(Icons.light_mode, size: 16),
                              ),
                              ButtonSegment<ThemeMode>(
                                value: ThemeMode.dark,
                                label: Text('Dark', overflow: TextOverflow.ellipsis),
                                icon: Icon(Icons.dark_mode, size: 16),
                              ),
                            ],
                            selected: {themeMode},
                            onSelectionChanged: (Set<ThemeMode> newSelection) {
                              if (newSelection.isNotEmpty) {
                                ref
                                    .read(themeModeProvider.notifier)
                                    .set(newSelection.first);
                              }
                            },
                          ),
                        ),
                        const Divider(height: 16),
                        Text(
                          'Language',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SegmentedButton<String>(
                              showSelectedIcon: false,
                              segments: AppLocaleController.supportedLocales.map((locale) {
                                final name = AppLocaleController.languageNames[locale.languageCode] ??
                                    locale.languageCode;
                                return ButtonSegment<String>(
                                  value: locale.languageCode,
                                  label: Text(
                                    name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              selected: {currentLocale.languageCode},
                              onSelectionChanged: (Set<String> selection) {
                                if (selection.isNotEmpty) {
                                  ref
                                      .read(appLocaleProvider.notifier)
                                      .setLocale(Locale(selection.first));
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Action ListTiles
                Text(
                  'Privacy & Security',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.shield_outlined),
                        title: const Text('Anonymity & Privacy Guide', overflow: TextOverflow.ellipsis),
                        subtitle: const Text(
                          'Zero-retention HMAC, location fuzzing & guarantees',
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(RoutePaths.anonymityGuide),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        key: const Key('viewGamificationButton'),
                        dense: true,
                        leading: const Icon(Icons.workspace_premium_outlined),
                        title: const Text('View Civic Impact & Badges', overflow: TextOverflow.ellipsis),
                        subtitle: const Text(
                          'Track level, daily streak & badges',
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(RoutePaths.gamification),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        dense: true,
                        leading: Icon(Icons.logout, color: colorScheme.error),
                        title: Text(
                          profile.isGuest ? 'End Guest Session' : 'Sign Out',
                          style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold),
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
      height: 32,
      width: 1,
      color: colorScheme.outlineVariant,
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
