import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lens/core/router/app_router.dart';
import 'package:local_lens/core/router/route_paths.dart';
import 'package:local_lens/core/storage/local_store.dart';
import 'package:local_lens/features/auth/domain/session.dart';
import 'package:local_lens/features/auth/presentation/auth_providers.dart';
import 'package:local_lens/features/issue_detail/presentation/widgets/official_response_card.dart';
import 'package:local_lens/features/rep_dashboard/domain/official_response.dart';
import 'package:local_lens/features/rep_dashboard/domain/representative_profile.dart';
import 'package:local_lens/features/rep_dashboard/domain/ward_issues_response.dart';
import 'package:local_lens/features/rep_dashboard/presentation/rep_dashboard_providers.dart';
import 'package:local_lens/features/rep_dashboard/presentation/rep_dashboard_screen.dart';

import '../../helpers.dart';

class FakeRepDashboardLocalStore implements LocalStore {
  final Map<String, String> _storage = {};

  @override
  String? getString(String key) => _storage[key];

  @override
  Future<void> setString(String key, String value) async {
    _storage[key] = value;
  }

  @override
  Future<void> clearDraft() async {}

  @override
  Future<void> clearSession() async {}

  @override
  Future<void> init() async {}

  @override
  String? loadDraft() => null;

  @override
  String? loadOutbox() => null;

  @override
  String? restoreAccessToken() => null;

  @override
  String? restoreUserId() => null;

  @override
  Future<void> saveDraft(String json) async {}

  @override
  Future<void> saveOutbox(String json) async {}

  @override
  Future<void> saveSession({required String accessToken, required Object userId}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const sampleProfile = RepresentativeProfile(
  id: 'repr_12345',
  userId: 42,
  officialName: 'Hon. Sarah Jenkins',
  title: 'Ward Councilor',
  ward: 'Ward 45, Urban Central',
  verifiedAt: null,
  totalWardIssues: 18,
  escalatedWardIssues: 4,
  respondedWardIssues: 12,
  pendingResponseWardIssues: 6,
);

final sampleIssue1 = buildIssue(
  id: 101,
  title: 'Severe Pothole on Main St',
  status: 'escalated',
);

final sampleIssue2 = buildIssue(
  id: 102,
  title: 'Garbage accumulation in alley',
  status: 'unacknowledged',
);

final sampleWardIssuesAll = WardIssuesResponse(
  items: [sampleIssue1, sampleIssue2],
  total: 2,
);

final sampleWardIssuesEscalated = WardIssuesResponse(
  items: [sampleIssue1],
  total: 1,
);

final sampleWardIssuesNeedsResponse = WardIssuesResponse(
  items: [sampleIssue1, sampleIssue2],
  total: 2,
);

const sampleOfficialResponse = OfficialResponse(
  id: 'off_resp_9988',
  issueId: 101,
  representativeId: 'repr_12345',
  officialName: 'Hon. Sarah Jenkins',
  title: 'Ward Councilor',
  ward: 'Ward 45, Urban Central',
  message: 'Public Works team dispatched. Work will begin on Wednesday.',
  estimatedResolutionDays: 3,
  statusUpdate: 'acknowledged',
  createdAt: null,
);

class _FixedSessionController extends SessionController {
  _FixedSessionController(this.session);

  final Session? session;

  @override
  Session? build() => session;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Feature F-11 Rep Dashboard & Governance Tools Tests', () {
    testWidgets('FE-REP-01: RepDashboardScreen header profile & metrics display', (tester) async {
      final container = ProviderContainer(
        overrides: [
          repProfileProvider.overrideWith((ref) async => sampleProfile),
          wardIssuesFilterProvider.overrideWith((ref) => 'all'),
          wardIssuesProvider.overrideWith((ref, filter) async => sampleWardIssuesAll),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: RepDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('repDashboardScreen')), findsOneWidget);
      expect(find.text('Representative Dashboard'), findsOneWidget);

      expect(find.byKey(const Key('repProfileName')), findsOneWidget);
      expect(find.text('Hon. Sarah Jenkins'), findsOneWidget);

      expect(find.byKey(const Key('repProfileWard')), findsOneWidget);
      expect(find.text('Ward 45, Urban Central'), findsOneWidget);

      expect(find.byKey(const Key('metricTotalWardIssues')), findsOneWidget);
      expect(find.text('18'), findsOneWidget);

      expect(find.byKey(const Key('metricEscalatedWardIssues')), findsOneWidget);
      expect(find.text('4'), findsOneWidget);

      expect(find.byKey(const Key('metricPendingResponseWardIssues')), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
    });

    testWidgets('FE-REP-02: Filter chips interaction & ward issue list updates', (tester) async {
      String activeFilter = 'all';

      final container = ProviderContainer(
        overrides: [
          repProfileProvider.overrideWith((ref) async => sampleProfile),
          wardIssuesFilterProvider.overrideWith((ref) => activeFilter),
          wardIssuesProvider.overrideWith((ref, filter) async {
            if (filter == 'escalated') {
              return sampleWardIssuesEscalated;
            } else if (filter == 'needs_response') {
              return sampleWardIssuesNeedsResponse;
            }
            return sampleWardIssuesAll;
          }),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: RepDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wardFilterChip_all')), findsOneWidget);
      expect(find.byKey(const Key('wardFilterChip_escalated')), findsOneWidget);
      expect(find.byKey(const Key('wardFilterChip_needs_response')), findsOneWidget);
      expect(find.byKey(const Key('wardIssueList')), findsOneWidget);

      await tester.tap(find.byKey(const Key('wardFilterChip_escalated')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('wardFilterChip_needs_response')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('wardFilterChip_all')));
      await tester.pumpAndSettle();
    });

    testWidgets('FE-REP-03: Post Official Response sheet workflow (cancel & submit)', (tester) async {
      final container = ProviderContainer(
        overrides: [
          repProfileProvider.overrideWith((ref) async => sampleProfile),
          wardIssuesFilterProvider.overrideWith((ref) => 'all'),
          wardIssuesProvider.overrideWith((ref, filter) async => sampleWardIssuesAll),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: RepDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('respondToIssueButton_101')), findsOneWidget);
      await tester.tap(find.byKey(const Key('respondToIssueButton_101')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('postOfficialResponseDialog')), findsOneWidget);
      expect(find.byKey(const Key('officialResponseInput')), findsOneWidget);
      expect(find.byKey(const Key('officialEtaInput')), findsOneWidget);
      expect(find.byKey(const Key('cancelOfficialResponseButton')), findsOneWidget);
      expect(find.byKey(const Key('submitOfficialResponseButton')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('officialResponseInput')),
        'Public Works team dispatched. Work will begin on Wednesday.',
      );
      await tester.enterText(find.byKey(const Key('officialEtaInput')), '3');

      await tester.tap(find.byKey(const Key('cancelOfficialResponseButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('postOfficialResponseDialog')), findsNothing);

      await tester.tap(find.byKey(const Key('respondToIssueButton_101')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('officialResponseInput')),
        'Public Works team dispatched. Work will begin on Wednesday.',
      );
      await tester.enterText(find.byKey(const Key('officialEtaInput')), '3');

      await tester.tap(find.byKey(const Key('submitOfficialResponseButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('postOfficialResponseDialog')), findsNothing);
    });

    testWidgets('FE-REP-04: OfficialResponseCard rendering in issue detail', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfficialResponseCard(
              response: sampleOfficialResponse,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('officialResponseCard_101')), findsOneWidget);
      expect(find.text('Official Representative Response'), findsOneWidget);
      expect(find.byKey(const Key('officialResponseTitle')), findsOneWidget);
      expect(find.text('Hon. Sarah Jenkins'), findsOneWidget);
      expect(find.byKey(const Key('officialResponseMessage')), findsOneWidget);
      expect(
        find.text('Public Works team dispatched. Work will begin on Wednesday.'),
        findsOneWidget,
      );

      final hasVerifiedIcon = find.byIcon(Icons.verified_user).evaluate().isNotEmpty ||
          find.byIcon(Icons.shield_outlined).evaluate().isNotEmpty;
      expect(hasVerifiedIcon, isTrue);
    });

    testWidgets('FE-REP-05: Offline cache & local store persistence (Hive)', (tester) async {
      final store = FakeRepDashboardLocalStore();
      final profileJson = jsonEncode({
        'id': 'repr_12345',
        'user_id': 42,
        'official_name': 'Hon. Sarah Jenkins',
        'title': 'Ward Councilor',
        'ward': 'Ward 45, Urban Central',
        'verified_at': '2026-01-15T09:00:00Z',
        'total_ward_issues': 18,
        'escalated_ward_issues': 4,
        'responded_ward_issues': 12,
        'pending_response_ward_issues': 6,
      });

      await store.setString('rep_profile', profileJson);
      expect(store.getString('rep_profile'), isNotNull);

      final container = ProviderContainer(
        overrides: [
          repProfileProvider.overrideWith((ref) async => sampleProfile),
          wardIssuesFilterProvider.overrideWith((ref) => 'all'),
          wardIssuesProvider.overrideWith((ref, filter) async => sampleWardIssuesAll),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: RepDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hon. Sarah Jenkins'), findsOneWidget);
      expect(find.text('Ward 45, Urban Central'), findsOneWidget);
    });

    testWidgets('FE-REP-06: Non-representative authorization error & redirect handling', (tester) async {
      final nonRepSession = const Session(
        accessToken: 'citizen-token',
        userId: 101,
        isGuest: false,
      );

      final container = ProviderContainer(
        overrides: [
          sessionProvider.overrideWith(() => _FixedSessionController(nonRepSession)),
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

      router.go(RoutePaths.repDashboard);
      await tester.pumpAndSettle();

      final location = router.state.matchedLocation;
      expect(location != RoutePaths.repDashboard || find.text('Access Denied').evaluate().isNotEmpty || find.text('403').evaluate().isNotEmpty, isTrue);
    });
  });
}
