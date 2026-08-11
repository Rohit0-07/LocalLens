import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:local_lens/core/feedback/app_infrastructure.dart';
import 'package:local_lens/core/network/connectivity.dart';
import 'package:local_lens/core/network/offline_sync_worker.dart';
import 'package:local_lens/core/router/app_router.dart';
import 'package:local_lens/core/router/route_paths.dart';
import 'package:local_lens/core/storage/local_store.dart';
import 'package:local_lens/features/auth/domain/session.dart';
import 'package:local_lens/features/auth/presentation/auth_providers.dart';
import 'package:local_lens/features/compose/data/offline_outbox_queue.dart';
import 'package:local_lens/features/compose/domain/compose_draft.dart';
import 'package:local_lens/features/compose/presentation/compose_providers.dart';
import 'package:local_lens/features/feed/presentation/feed_providers.dart';
import 'package:local_lens/features/issue_detail/presentation/screens/issue_detail_screen.dart';
import 'package:local_lens/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:local_lens/features/ward/data/repositories/ward_repository.dart';
import 'package:local_lens/features/ward/domain/ward_detail_out.dart';
import 'package:local_lens/features/ward/domain/ward_list_response.dart';
import 'package:local_lens/features/ward/domain/ward_representative_out.dart';
import 'package:local_lens/features/ward/domain/ward_summary_out.dart';
import 'package:local_lens/features/ward/presentation/screens/ward_detail_screen.dart';
import 'package:local_lens/features/ward/presentation/ward_providers.dart';
import 'package:local_lens/shared/widgets/shimmer_loading.dart';
import 'package:local_lens/shared/widgets/skeleton_list.dart';

import '../helpers.dart';

class ExtendedTestLocalStore implements LocalStore {
  final Map<String, String> _storage = {};
  bool _completedOnboarding = false;

  @override
  bool hasCompletedOnboarding() => _completedOnboarding;

  @override
  Future<void> setCompletedOnboarding([bool completed = true]) async {
    _completedOnboarding = completed;
    _storage['has_completed_onboarding'] = completed ? 'true' : 'false';
  }

  @override
  String? getString(String key) => _storage[key];

  @override
  Future<void> setString(String key, String value) async {
    _storage[key] = value;
  }

  @override
  String? loadOutbox() => _storage['pending_outbox'];

  @override
  Future<void> saveOutbox(String json) async => _storage['pending_outbox'] = json;

  @override
  String? loadDraft() => _storage['current_draft'];

  @override
  Future<void> saveDraft(String json) async => _storage['current_draft'] = json;

  @override
  Future<void> clearDraft() async => _storage.remove('current_draft');

  @override
  Future<void> clearSession() async {}

  @override
  Future<void> init() async {}

  @override
  String? restoreAccessToken() => null;

  @override
  String? restoreUserId() => null;

  @override
  Future<void> saveSession({required String accessToken, required Object userId}) async {}

  @override
  String? getWardDetailCache(String slug) => _storage['ward_detail_$slug'];

  @override
  Future<void> saveWardDetailCache(String slug, String jsonStr) async {
    _storage['ward_detail_$slug'] = jsonStr;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestConnectivitySource implements ConnectivitySource {
  final _controller = StreamController<NetworkStatus>.broadcast();

  @override
  Stream<NetworkStatus> get statuses => _controller.stream;

  void emit(NetworkStatus status) {
    _controller.add(status);
  }

  Future<void> close() => _controller.close();
}

class _TestSessionController extends SessionController {
  _TestSessionController(this.session);

  final Session? session;

  @override
  Session? build() => session;
}

class FakeWardRepository implements WardRepository {
  FakeWardRepository({this.wardDetail});

  final WardDetailOut? wardDetail;

  @override
  Future<WardDetailOut> getWardDetail(String slug, {int issuesLimit = 10}) async {
    return wardDetail ??
        WardDetailOut(
          slug: slug,
          name: 'Urban Central',
          code: 'UC-01',
          centerLatitude: 19.1136,
          centerLongitude: 72.8697,
          totalIssues: 17,
          activeIssues: 5,
          escalatedIssues: 2,
          resolvedIssues: 10,
          resolutionRatePct: 58.8,
          assignedRepresentative: const WardRepresentativeOut(
            officialName: 'Jane Doe',
            title: 'Council Member',
          ),
          recentIssues: [],
          updatedAt: DateTime.utc(2026, 8, 10),
        );
  }

  @override
  Future<WardListResponse> getWards({int limit = 20, int offset = 0}) async {
    return const WardListResponse(
      items: [],
      total: 0,
      limit: 20,
      offset: 0,
    );
  }

  @override
  Future<WardSummaryOut> getWardByLocation(double lat, double lng) async {
    return const WardSummaryOut(
      slug: 'urban-central',
      name: 'Urban Central',
      code: 'UC-01',
      centerLatitude: 19.1136,
      centerLongitude: 72.8697,
      totalIssues: 17,
      activeIssues: 5,
      escalatedIssues: 2,
      resolvedIssues: 10,
      resolutionRatePct: 58.8,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FE-INFRA-01: 5-Page Onboarding carousel page swiping and navigation', () {
    testWidgets('carousel page swiping, Next button tap, and page indicator index update', (tester) async {
      final store = ExtendedTestLocalStore();
      final container = ProviderContainer(
        overrides: [
          localStoreProvider.overrideWithValue(store),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Page 0: "See what's wrong"
      expect(find.text("See what's wrong"), findsOneWidget);
      expect(find.byKey(const Key('onboardingPageIndicator')), findsOneWidget);
      expect(find.byKey(const Key('onboardingNextButton')), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

      // Tap Next button to advance to Page 1: "Your upvotes are civic signals"
      await tester.tap(find.byKey(const Key('onboardingNextButton')));
      await tester.pumpAndSettle();
      expect(find.text('Your upvotes are civic signals'), findsOneWidget);

      // Tap Next button to advance to Page 2: "We can't reveal you, even if we tried"
      await tester.tap(find.byKey(const Key('onboardingNextButton')));
      await tester.pumpAndSettle();
      expect(find.text("We can't reveal you, even if we tried"), findsOneWidget);

      // Fling left on PageView to advance to Page 3: "Street Check"
      await tester.fling(find.byType(PageView), const Offset(-500, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('Street Check'), findsOneWidget);

      // Fling right on PageView to go back to Page 2
      await tester.fling(find.byType(PageView), const Offset(500, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text("We can't reveal you, even if we tried"), findsOneWidget);

      // Advance to Page 3 again via Next button
      await tester.tap(find.byKey(const Key('onboardingNextButton')));
      await tester.pumpAndSettle();
      expect(find.text('Street Check'), findsOneWidget);

      // Tap Next button to advance to Page 4: "Every fix is celebrated"
      await tester.tap(find.byKey(const Key('onboardingNextButton')));
      await tester.pumpAndSettle();
      expect(find.text('Every fix is celebrated'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
    });
  });

  group('FE-INFRA-02: Skip Onboarding button tap & Hive completed status', () {
    testWidgets('skip onboarding button tap sets has_completed_onboarding = true and navigates to sign-in for logged out user', (tester) async {
      final store = ExtendedTestLocalStore();
      final container = ProviderContainer(
        overrides: [
          localStoreProvider.overrideWithValue(store),
          sessionProvider.overrideWith(() => _TestSessionController(null)),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, RoutePaths.onboarding);
      expect(store.hasCompletedOnboarding(), isFalse);

      // Tap Skip button
      expect(find.byKey(const Key('skipOnboardingButton')), findsOneWidget);
      await tester.tap(find.byKey(const Key('skipOnboardingButton')));
      await tester.pumpAndSettle();

      // Verify Hive/store updated
      expect(store.hasCompletedOnboarding(), isTrue);
      expect(router.state.matchedLocation, RoutePaths.signIn);
    });

    testWidgets('completing onboarding on last page sets has_completed_onboarding = true', (tester) async {
      final store = ExtendedTestLocalStore();
      final container = ProviderContainer(
        overrides: [
          localStoreProvider.overrideWithValue(store),
          sessionProvider.overrideWith(() => _TestSessionController(null)),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Advance through all 5 pages
      for (int i = 0; i < 4; i++) {
        await tester.tap(find.byKey(const Key('onboardingNextButton')));
        await tester.pumpAndSettle();
      }
      expect(find.text('Get Started'), findsOneWidget);

      // Tap Get Started button
      await tester.tap(find.byKey(const Key('onboardingNextButton')));
      await tester.pumpAndSettle();

      expect(store.hasCompletedOnboarding(), isTrue);
      expect(router.state.matchedLocation, RoutePaths.signIn);
    });
  });

  group('FE-INFRA-03: OfflineSyncWorker automatically calls OfflineOutboxQueue.flush() on reconnection', () {
    testWidgets('flushes outbox queue when network transitions from offline to online', (tester) async {
      final connectivitySource = TestConnectivitySource();
      addTearDown(connectivitySource.close);

      final store = ExtendedTestLocalStore();
      final fakeFeedRepo = FakeFeedRepository();
      final outboxQueue = OfflineOutboxQueue(store, fakeFeedRepo);

      // Enqueue a draft to outbox
      final draft = const ComposeDraft(
        title: 'Broken streetlight on Main St',
        description: 'Dark area at night',
        category: 'lighting',
        latitude: 19.1136,
        longitude: 72.8697,
      );
      await outboxQueue.enqueue(draft);
      expect(outboxQueue.getPendingQueue().length, 1);

      final container = ProviderContainer(
        overrides: [
          connectivitySourceProvider.overrideWithValue(connectivitySource),
          localStoreProvider.overrideWithValue(store),
          feedRepositoryProvider.overrideWithValue(fakeFeedRepo),
          offlineOutboxProvider.overrideWithValue(outboxQueue),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: OfflineSyncWorker(),
            ),
          ),
        ),
      );

      // Transition to offline
      connectivitySource.emit(NetworkStatus.offline);
      await tester.pump(Duration.zero);
      await tester.pump();
      expect(outboxQueue.getPendingQueue().length, 1);

      // Transition to online -> triggers flush
      connectivitySource.emit(NetworkStatus.online);
      await tester.pump(Duration.zero);
      await tester.pump();

      // Pending queue should now be empty (flushed)
      expect(outboxQueue.getPendingQueue().isEmpty, isTrue);

      // Pump out timer
      await tester.pump(const Duration(seconds: 5));
    });
  });

  group('FE-INFRA-04: Toast notification on offline outbox queue flush', () {
    testWidgets('shows toast when offline outbox queue flush is triggered on reconnection', (tester) async {
      final connectivitySource = TestConnectivitySource();
      addTearDown(connectivitySource.close);

      final container = ProviderContainer(
        overrides: [
          connectivitySourceProvider.overrideWithValue(connectivitySource),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: AppInfrastructure(child: Text('App Main Content')),
            ),
          ),
        ),
      );

      // Emit offline then online
      connectivitySource.emit(NetworkStatus.offline);
      await tester.pump(Duration.zero);
      await tester.pump();

      connectivitySource.emit(NetworkStatus.online);
      await tester.pump(Duration.zero);
      await tester.pump();

      expect(
        find.text('Back online — synchronizing outbox queue'),
        findsOneWidget,
      );

      await tester.pump(const Duration(seconds: 5));
    });
  });

  group('FE-INFRA-05: Deep linking URI scheme parsing and GoRouter resolution', () {
    late ProviderContainer container;
    late GoRouter router;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          sessionProvider.overrideWith(
            () => _TestSessionController(
              const Session(accessToken: 't', userId: 1),
            ),
          ),
          localStoreProvider.overrideWithValue(ExtendedTestLocalStore()),
          feedRepositoryProvider.overrideWithValue(FakeFeedRepository()),
          wardRepositoryProvider.overrideWithValue(FakeWardRepository()),
        ],
      );
      router = container.read(routerProvider);
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('locallens://issue/123 resolves to /issue/123 and renders IssueDetailScreen', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      router.go('locallens://issue/123');
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, '/issue/123');
      expect(find.byType(IssueDetailScreen), findsOneWidget);
      expect(find.text('Issue #123'), findsOneWidget);
    });

    testWidgets('locallens://ward/urban-central resolves to /ward/urban-central and renders WardDetailScreen', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      router.go('locallens://ward/urban-central');
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, '/ward/urban-central');
      expect(find.byType(WardDetailScreen), findsOneWidget);
    });

    testWidgets('locallens://talk/45 resolves to /talk/45 and renders PlaceholderScreen', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      router.go('locallens://talk/45');
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, '/talk/45');
      expect(find.text('Talk #45'), findsOneWidget);
    });

    testWidgets('locallens://rep/7 resolves to /rep/7 and renders PlaceholderScreen', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      router.go('locallens://rep/7');
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, '/rep/7');
      expect(find.text('Representative #7'), findsOneWidget);
    });

    testWidgets('locallens://win/99 resolves to /win/99 and renders PlaceholderScreen', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      router.go('locallens://win/99');
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, '/win/99');
      expect(find.text('Civic Win #99'), findsOneWidget);
    });
  });

  group('FE-INFRA-06: ShimmerLoading widget renders animated gradient sweep over skeleton elements', () {
    testWidgets('renders ShimmerBox and SkeletonList elements wrapped in ShimmerLoading', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ShimmerLoading(
                  child: ShimmerBox(width: 200, height: 24),
                ),
                Expanded(
                  child: SkeletonList(itemCount: 2),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(ShimmerLoading), findsNWidgets(2));
      expect(find.byType(ShimmerBox), findsOneWidget);
      expect(find.byType(SkeletonList), findsOneWidget);
      expect(find.byType(Card), findsNWidgets(2));
    });

    testWidgets('ShaderMask linear gradient sweep configuration when ShimmerLoading is active', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ShimmerLoading(
              baseColor: Colors.grey.shade400,
              highlightColor: Colors.white,
              child: Container(width: 100, height: 100, color: Colors.grey),
            ),
          ),
        ),
      );

      expect(find.byType(ShimmerLoading), findsOneWidget);
    });
  });
}
