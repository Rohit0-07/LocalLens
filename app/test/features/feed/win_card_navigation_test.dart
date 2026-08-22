import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:local_lens/core/router/route_paths.dart';
import 'package:local_lens/features/feed/domain/win.dart';
import 'package:local_lens/features/feed/presentation/feed_providers.dart';
import 'package:local_lens/features/feed/presentation/widgets/win_card.dart';

import '../../helpers.dart';

WinItem _createWin({int id = 3, int issueId = 77}) {
  return WinItem(
    id: id,
    issueId: issueId,
    title: 'Water tanker schedule fixed',
    description: 'Two tankers dispatched on morning and evening shifts',
    category: 'water',
    ward: 'Ward 45, Urban Central',
    latitude: 19.1136,
    longitude: 72.8697,
    contributorCredits: const ['Verified Citizen'],
    createdAt: DateTime.utc(2026, 8, 20, 9),
  );
}

Widget _wrapCard(Widget card) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(body: card),
      ),
      GoRoute(
        path: RoutePaths.issueDetail,
        builder: (context, state) =>
            Scaffold(body: Text('ISSUE_DETAIL_${state.pathParameters['id']}')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [feedRepositoryProvider.overrideWithValue(FakeFeedRepository())],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets(
    'tapping a community win card opens the underlying issue detail',
    (tester) async {
      await tester.pumpWidget(_wrapCard(WinCard(win: _createWin())));
      await tester.pumpAndSettle();

      expect(find.text('ISSUE_DETAIL_77'), findsNothing);

      await tester.tap(find.text('Water tanker schedule fixed'));
      await tester.pumpAndSettle();

      expect(find.text('ISSUE_DETAIL_77'), findsOneWidget);
    },
  );

  testWidgets('tapping the share button does not navigate away', (
    tester,
  ) async {
    await tester.pumpWidget(_wrapCard(WinCard(win: _createWin())));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.share_outlined));
    await tester.pumpAndSettle();

    expect(find.text('ISSUE_DETAIL_77'), findsNothing);
  });
}
