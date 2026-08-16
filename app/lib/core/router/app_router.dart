import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/screens/admin_flagged_queue_screen.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/auth/presentation/widgets/guest_guard.dart';
import '../../features/compose/presentation/compose_screen.dart';
import '../../features/feed/presentation/feed_providers.dart';
import '../../features/feed/presentation/feed_screen.dart';
import '../../features/inbox/presentation/inbox_screen.dart';
import '../../features/issue_detail/presentation/issue_detail_screen.dart';
import '../../features/map/presentation/screens/map_screen.dart';
import '../../features/notifications/presentation/controllers/notifications_controller.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/gamification/presentation/gamification_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/outbox/presentation/outbox_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/screens/anonymity_guide_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/public_profile_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../features/reels/presentation/reels_screen.dart';
import '../../features/rep_dashboard/presentation/rep_dashboard_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/ward/presentation/ward_detail_screen.dart';
import '../../features/ward/presentation/widgets/local_talk_compose_sheet.dart';
import '../l10n/app_strings.dart';
import '../storage/storage_providers.dart';
import '../theme/app_colors.dart';
import 'route_paths.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _feedNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'feed');
final _mapNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'map');
final _reelsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'reels');
final _inboxNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'inbox');
final _profileNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

final routerProvider = Provider<GoRouter>((ref) {
  final shell = StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) =>
        _AppShell(navigationShell: navigationShell),
    branches: [
      StatefulShellBranch(
        navigatorKey: _feedNavigatorKey,
        routes: [
          GoRoute(
            path: RoutePaths.feed,
            builder: (context, state) => const FeedScreen(),
          ),
        ],
      ),
      StatefulShellBranch(
        navigatorKey: _mapNavigatorKey,
        routes: [
          GoRoute(
            path: RoutePaths.map,
            builder: (context, state) => const MapScreen(),
          ),
        ],
      ),
      StatefulShellBranch(
        navigatorKey: _reelsNavigatorKey,
        routes: [
          GoRoute(
            path: RoutePaths.reels,
            builder: (context, state) => const ReelsScreen(),
          ),
        ],
      ),
      StatefulShellBranch(
        navigatorKey: _inboxNavigatorKey,
        routes: [
          GoRoute(
            path: RoutePaths.inbox,
            builder: (context, state) => const InboxScreen(),
          ),
        ],
      ),
      StatefulShellBranch(
        navigatorKey: _profileNavigatorKey,
        routes: [
          GoRoute(
            path: RoutePaths.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RoutePaths.feed,
    redirect: (context, state) {
      final uri = state.uri;
      if (uri.scheme == 'locallens') {
        // Legacy deep links to social destinations that are not yet built
        // (Talk / Representative / Win / Notice details). Redirect straight
        // to the feed instead of dead-ending on a placeholder.
        final legacyHost =
            uri.host == 'talk' || uri.host == 'rep' || uri.host == 'win' || uri.host == 'notice';
        if (legacyHost) {
          return RoutePaths.feed;
        }
        final path = uri.host.isNotEmpty ? '/${uri.host}${uri.path}' : uri.path;
        return path;
      }

      // Path-form legacy deep links (e.g. /talk/45) to destinations that are
      // not yet built redirect to the feed as well.
      if (uri.path.startsWith('/talk/') ||
          uri.path.startsWith('/rep/') ||
          uri.path.startsWith('/win/') ||
          uri.path.startsWith('/notice/')) {
        return RoutePaths.feed;
      }

      final store = ref.read(localStoreProvider);
      final session = ref.read(sessionProvider);

      if (session == null &&
          !store.hasCompletedOnboarding() &&
          state.matchedLocation != RoutePaths.onboarding) {
        return RoutePaths.onboarding;
      }
      final onAuthPage =
          state.matchedLocation == RoutePaths.signIn ||
          state.matchedLocation == RoutePaths.otp;
      final onOnboardingPage = state.matchedLocation == RoutePaths.onboarding;

      if (session == null && !onAuthPage && !onOnboardingPage) {
        return RoutePaths.signIn;
      }
      if (session != null &&
          !session.isGuest &&
          (onAuthPage || onOnboardingPage)) {
        return RoutePaths.feed;
      }
      return null;
    },
    routes: [
      shell,
      GoRoute(
        path: RoutePaths.onboarding,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RoutePaths.compose,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ComposeScreen(),
      ),
      GoRoute(
        path: RoutePaths.signIn,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: RoutePaths.otp,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => OtpScreen(
          args: state.extra is OtpRouteArgs
              ? state.extra as OtpRouteArgs
              : null,
        ),
      ),
      GoRoute(
        path: RoutePaths.notifications,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: RoutePaths.repDashboard,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const RepDashboardScreen(),
      ),
      GoRoute(
        path: RoutePaths.issueDetail,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final idStr = state.pathParameters['id'];
          final issueId = int.tryParse(idStr ?? '') ?? 0;
          return IssueDetailScreen(issueId: issueId);
        },
      ),
      GoRoute(
        path: RoutePaths.anonymityGuide,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AnonymityGuideScreen(),
      ),
      GoRoute(
        path: RoutePaths.search,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: RoutePaths.gamification,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const GamificationScreen(),
      ),
      GoRoute(
        path: RoutePaths.adminFlaggedQueue,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AdminFlaggedQueueScreen(),
      ),
      GoRoute(
        path: RoutePaths.wardDetail,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final slug = state.pathParameters['slug'] ?? '';
          return WardDetailScreen(wardSlug: slug);
        },
      ),
      GoRoute(
        path: RoutePaths.outbox,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const OutboxScreen(),
      ),
      GoRoute(
        path: RoutePaths.settings,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: RoutePaths.editProfile,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: RoutePaths.publicProfile,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final idStr = state.pathParameters['id'];
          final userId = int.tryParse(idStr ?? '') ?? 0;
          return PublicProfileScreen(userId: userId);
        },
      ),
    ],
  );

  ref.listen(sessionProvider, (_, _) => router.refresh());
  return router;
});

class _AppShell extends ConsumerStatefulWidget {
  const _AppShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<_AppShell> {
  bool _guestBannerDismissed = false;

  Future<void> _openCreateSheet(BuildContext context) async {
    final session = ref.read(sessionProvider);
    final isGuest = session == null || session.isGuest;
    final theme = Theme.of(context);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: theme.colorScheme.surface,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              _CreateActionTile(
                key: const Key('createSheetReportIssue'),
                icon: Icons.report_problem_outlined,
                color: AppColors.urgent,
                title: sheetContext.tr('action_create_issue'),
                subtitle: 'Report a pothole, leak or outage to your ward.',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.push(RoutePaths.compose);
                },
              ),
              const SizedBox(height: 10),
              _CreateActionTile(
                key: const Key('createSheetStartTalk'),
                icon: Icons.forum_outlined,
                color: AppColors.brand,
                title: sheetContext.tr('action_start_talk'),
                subtitle: 'Begin a discussion with neighbours in your ward.',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  if (isGuest) {
                    showDialog(
                      context: context,
                      builder: (_) => const GuestGuard(),
                    );
                    return;
                  }
                  LocalTalkComposeSheet.show(
                    context,
                    'ward-45-urban-central',
                    onPostSubmitted: () =>
                        ref.read(multiTypeFeedProvider.notifier).refresh(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final session = ref.watch(sessionProvider);
    final isGuest = session == null || session.isGuest;

    return Scaffold(
      body: Stack(
        children: [
          widget.navigationShell,
          if (isGuest && !_guestBannerDismissed)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: GuestSessionBar(
                onDismiss: () => setState(() => _guestBannerDismissed = true),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _SocialDock(
        currentIndex: widget.navigationShell.currentIndex,
        unreadCount: unreadCount,
        onSelect: (index) => widget.navigationShell.goBranch(
          index,
          initialLocation: index == widget.navigationShell.currentIndex,
        ),
        onCreate: () => _openCreateSheet(context),
      ),
    );
  }
}

/// Instagram-style bottom dock: 4 tabs + a floating central "Create" button.
class _SocialDock extends StatelessWidget {
  const _SocialDock({
    required this.currentIndex,
    required this.unreadCount,
    required this.onSelect,
    required this.onCreate,
  });

  final int currentIndex;
  final int unreadCount;
  final ValueChanged<int> onSelect;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget tab({
      required int index,
      required String label,
      required IconData icon,
      required IconData selectedIcon,
      int? badge,
    }) {
      final selected = currentIndex == index;
      final color = selected ? AppColors.brand : colorScheme.onSurfaceVariant;
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          label: label,
          child: InkWell(
            key: Key('dockTab$index'),
            onTap: () => onSelect(index),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.brand.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Badge(
                      isLabelVisible: badge != null && badge > 0,
                      label: badge != null && badge > 0 ? Text('$badge') : null,
                      child: Icon(
                        selected ? selectedIcon : icon,
                        color: color,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: SafeArea(
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            children: [
              tab(
                index: 0,
                label: context.tr('nav_home'),
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
              ),
              tab(
                index: 1,
                label: context.tr('nav_map'),
                icon: Icons.map_outlined,
                selectedIcon: Icons.map,
              ),
              tab(
                index: 2,
                label: 'Reels',
                icon: Icons.movie_filter_outlined,
                selectedIcon: Icons.movie_filter,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Semantics(
                  button: true,
                  label: context.tr('nav_create'),
                  child: GestureDetector(
                    key: const Key('createDockButton'),
                    onTap: onCreate,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.brand,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.brand.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
              tab(
                index: 3,
                label: context.tr('nav_inbox'),
                icon: Icons.inbox_outlined,
                selectedIcon: Icons.inbox,
                badge: unreadCount,
              ),
              tab(
                index: 4,
                label: context.tr('nav_profile'),
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateActionTile extends StatelessWidget {
  const _CreateActionTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
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
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GuestSessionBar extends StatelessWidget {
  const GuestSessionBar({super.key, this.onDismiss});

  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.tertiaryContainer,
      elevation: 2,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: theme.colorScheme.onTertiaryContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr('guest_session_active'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                key: const Key('guestSignInCta'),
                onPressed: () =>
                    GoRouter.of(context).pushReplacement(RoutePaths.signIn),
                child: Text(context.tr('sign_in_required')),
              ),
              if (onDismiss != null)
                IconButton(
                  iconSize: 18,
                  icon: const Icon(Icons.close),
                  onPressed: onDismiss,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
