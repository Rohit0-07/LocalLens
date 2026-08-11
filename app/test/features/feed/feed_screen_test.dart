import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lens/features/feed/presentation/feed_providers.dart';
import 'package:local_lens/features/feed/presentation/feed_screen.dart';

import '../../helpers.dart';

Widget wrap(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(home: FeedScreen()),
  );
}

void main() {
  testWidgets('shows issues returned by the repository', (tester) async {
    final repo = FakeFeedRepository(
      issues: [
        buildIssue(id: 1, title: 'Deep pothole near the bus stop'),
        buildIssue(id: 2, title: 'Streetlight flickering', status: 'resolved'),
      ],
    );
    final container = ProviderContainer(
      overrides: [feedRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(wrap(container));
    await tester.pumpAndSettle();

    expect(find.text('Deep pothole near the bus stop'), findsOneWidget);
    expect(find.text('Streetlight flickering'), findsOneWidget);
    expect(find.text('RESOLVED'), findsOneWidget);
    expect(repo.fetchCount, 1);
  });

  testWidgets('shows error state and retries', (tester) async {
    final repo = FakeFeedRepository(error: StateError('offline'));
    final container = ProviderContainer(
      overrides: [feedRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(wrap(container));
    await tester.pumpAndSettle();

    expect(find.text('Feed unavailable'), findsOneWidget);

    repo.error = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('All clear around here'), findsOneWidget);
    expect(repo.fetchCount, 2);
  });

  testWidgets('shows empty state when no issues', (tester) async {
    final container = ProviderContainer(
      overrides: [
        feedRepositoryProvider.overrideWithValue(FakeFeedRepository()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(wrap(container));
    await tester.pumpAndSettle();

    expect(find.text('All clear around here'), findsOneWidget);
  });
}
