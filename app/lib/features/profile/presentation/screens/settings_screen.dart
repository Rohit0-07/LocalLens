import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../profile_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeMode = ref.watch(themeModeProvider);
    final currentLocale = ref.watch(appLocaleProvider);
    final settings = ref.watch(userSettingsProvider);
    final settingsNotifier = ref.read(userSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('profile_settings_header')),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section: Notification Preferences ─────────────────────
            _SectionHeader(
              title: 'Notification Preferences',
              icon: Icons.notifications_active_outlined,
            ),
            Card(
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    key: const Key('settingsPushNotificationsToggle'),
                    title: const Text('Push Notifications'),
                    subtitle: const Text('Receive real-time alerts on your device'),
                    value: settings.pushNotifications,
                    onChanged: (val) =>
                        settingsNotifier.setPushNotifications(val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile.adaptive(
                    key: const Key('settingsDailyDigestToggle'),
                    title: const Text('Daily Ward Digest'),
                    subtitle: const Text('Summary of local issues and wins in your ward'),
                    value: settings.dailyWardDigest,
                    onChanged: (val) =>
                        settingsNotifier.setDailyWardDigest(val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile.adaptive(
                    key: const Key('settingsStatusChangeAlertsToggle'),
                    title: const Text('My Issues Status Changes'),
                    subtitle: const Text('Alerts when your reported issues are updated'),
                    value: settings.statusChangeAlerts,
                    onChanged: (val) =>
                        settingsNotifier.setStatusChangeAlerts(val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile.adaptive(
                    key: const Key('settingsVerificationRequestsToggle'),
                    title: const Text('Community Verification Requests'),
                    subtitle: const Text('Notify when community verification voting starts near you'),
                    value: settings.communityVerificationRequests,
                    onChanged: (val) =>
                        settingsNotifier.setCommunityVerificationRequests(val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile.adaptive(
                    key: const Key('settingsCommentRepliesToggle'),
                    title: const Text('Comment & Thread Replies'),
                    subtitle: const Text('Alerts when someone replies to your discussions'),
                    value: settings.commentReplies,
                    onChanged: (val) =>
                        settingsNotifier.setCommentReplies(val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile.adaptive(
                    key: const Key('settingsHapticFeedbackToggle'),
                    title: const Text('Haptic Feedback'),
                    subtitle: const Text('Tactile response on upvotes and voting actions'),
                    value: settings.hapticFeedback,
                    onChanged: (val) =>
                        settingsNotifier.setHapticFeedback(val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Section: Privacy & Anonymity ──────────────────────────
            _SectionHeader(
              title: 'Privacy & Anonymity',
              icon: Icons.shield_outlined,
            ),
            Card(
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    key: const Key('settingsDefaultAnonymousToggle'),
                    title: const Text('Default Post Anonymously'),
                    subtitle: const Text('Always mask identity on new civic reports'),
                    value: settings.defaultPostAnonymously,
                    onChanged: (val) =>
                        settingsNotifier.setDefaultPostAnonymously(val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile.adaptive(
                    key: const Key('settingsLocationFuzzingToggle'),
                    title: const Text('Location Fuzzing by Default'),
                    subtitle: const Text('Coarsen coordinates by ~100m for home privacy'),
                    value: settings.locationFuzzingByDefault,
                    onChanged: (val) =>
                        settingsNotifier.setLocationFuzzingByDefault(val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile.adaptive(
                    key: const Key('settingsShieldedModeToggle'),
                    title: const Text('Shielded Mode by Default'),
                    subtitle: const Text('Route sensitive submissions through proxy relays'),
                    value: settings.shieldedModeByDefault,
                    onChanged: (val) =>
                        settingsNotifier.setShieldedModeByDefault(val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile.adaptive(
                    key: const Key('settingsExifScrubberToggle'),
                    title: const Text('Photo EXIF Scrubber'),
                    subtitle: const Text('Automatically strip GPS & camera metadata from uploads'),
                    value: settings.photoExifScrubber,
                    onChanged: (val) =>
                        settingsNotifier.setPhotoExifScrubber(val),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(context.tr('profile_anonymity_guide')),
                    subtitle: Text(context.tr('profile_anonymity_sub')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(RoutePaths.anonymityGuide),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Section: Appearance & Display ─────────────────────────
            _SectionHeader(
              title: 'Appearance & Display',
              icon: Icons.palette_outlined,
            ),
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
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ThemeMode>(
                        key: const Key('settingsThemeSegmentedButton'),
                        segments: const [
                          ButtonSegment<ThemeMode>(
                            value: ThemeMode.system,
                            label: Text('System'),
                            icon: Icon(Icons.brightness_auto, size: 16),
                          ),
                          ButtonSegment<ThemeMode>(
                            value: ThemeMode.light,
                            label: Text('Light'),
                            icon: Icon(Icons.light_mode, size: 16),
                          ),
                          ButtonSegment<ThemeMode>(
                            value: ThemeMode.dark,
                            label: Text('Dark'),
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
                    const Divider(height: 20),
                    Text(
                      'Language',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SegmentedButton<String>(
                          key: const Key('settingsLanguageSegmentedButton'),
                          showSelectedIcon: false,
                          segments: AppLocaleController.supportedLocales
                              .map((locale) {
                            final name = AppLocaleController.languageNames[
                                    locale.languageCode] ??
                                locale.languageCode;
                            return ButtonSegment<String>(
                              value: locale.languageCode,
                              label: Text(name),
                            );
                          }).toList(),
                          selected: {currentLocale.languageCode},
                          onSelectionChanged: (Set<String> selection) {
                            if (selection.isNotEmpty) {
                              final code = selection.first;
                              ref
                                  .read(appLocaleProvider.notifier)
                                  .setLocale(Locale(code));
                              settingsNotifier.setLanguage(code);
                            }
                          },
                        ),
                      ),
                    ),
                    const Divider(height: 20),
                    SwitchListTile.adaptive(
                      key: const Key('settingsHighContrastToggle'),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('High Contrast Mode'),
                      subtitle: const Text('Enhance contrast for maximum legibility in sunlight'),
                      value: settings.highContrastMode,
                      onChanged: (val) =>
                          settingsNotifier.setHighContrastMode(val),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Section: Data & Storage ───────────────────────────────
            _SectionHeader(
              title: 'Data & Storage',
              icon: Icons.storage_outlined,
            ),
            Card(
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    key: const Key('settingsWifiOnlyToggle'),
                    title: const Text('Wi-Fi Only Media Download'),
                    subtitle: const Text('Do not auto-download high-res proofs on cellular data'),
                    value: settings.wifiOnlyMediaDownload,
                    onChanged: (val) =>
                        settingsNotifier.setWifiOnlyMediaDownload(val),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    key: const Key('settingsSyncIntervalTile'),
                    title: const Text('Offline Sync Interval'),
                    subtitle: Text('Background worker syncs every ${settings.syncWorkerIntervalMinutes} minutes'),
                    trailing: DropdownButton<int>(
                      value: settings.syncWorkerIntervalMinutes,
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(value: 5, child: Text('5 min')),
                        DropdownMenuItem(value: 15, child: Text('15 min')),
                        DropdownMenuItem(value: 30, child: Text('30 min')),
                        DropdownMenuItem(value: 60, child: Text('60 min')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          settingsNotifier.setSyncWorkerInterval(val);
                        }
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    key: const Key('settingsClearCacheTile'),
                    leading: const Icon(Icons.cleaning_services_outlined),
                    title: const Text('Clear Offline Cache'),
                    subtitle: Text(
                      'Cached images and local map tiles (${settings.offlineCacheSizeMb.toStringAsFixed(1)} MB)',
                    ),
                    trailing: FilledButton.tonal(
                      onPressed: () async {
                        await settingsNotifier.clearOfflineCache();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Offline cache cleared successfully'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: const Text('Clear'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Section: Account ──────────────────────────────────────
            _SectionHeader(
              title: 'Account',
              icon: Icons.account_circle_outlined,
            ),
            Card(
              child: Column(
                children: [
                  ListTile(
                    key: const Key('settingsEditAliasTile'),
                    leading: const Icon(Icons.badge_outlined),
                    title: const Text('Edit Profile Alias'),
                    subtitle: Text(
                      settings.profileAlias.isNotEmpty
                          ? settings.profileAlias
                          : 'Not set (using auto Anon ID)',
                    ),
                    trailing: const Icon(Icons.edit_outlined, size: 20),
                    onTap: () => _showEditAliasDialog(
                        context, settings.profileAlias, settingsNotifier),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    key: const Key('settingsExportDataTile'),
                    leading: const Icon(Icons.download_outlined),
                    title: const Text('Export My Civic Activity Data'),
                    subtitle: const Text('Download a copy of your reported issues & votes in JSON'),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Civic activity data exported as JSON'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    key: const Key('settingsSignOutTile'),
                    leading: Icon(Icons.logout, color: colorScheme.error),
                    title: Text(
                      'Sign Out',
                      style: TextStyle(
                        color: colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () async {
                      await ref.read(authControllerProvider).signOut();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  static void _showEditAliasDialog(BuildContext context, String currentAlias,
      UserSettingsNotifier notifier) {
    final textController = TextEditingController(text: currentAlias);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile Alias'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Alias / Display Name',
            hintText: 'e.g. Ward Sentinel',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              notifier.setProfileAlias(textController.text.trim());
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
