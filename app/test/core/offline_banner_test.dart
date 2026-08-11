import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lens/core/feedback/offline_banner.dart';
import 'package:local_lens/core/network/connectivity.dart';

class FakeConnectivitySource implements ConnectivitySource {
  final _controller = StreamController<NetworkStatus>.broadcast();

  @override
  Stream<NetworkStatus> get statuses => _controller.stream;

  void emit(NetworkStatus status) => _controller.add(status);

  Future<void> close() => _controller.close();
}

const offlineText =
    "You're offline. Changes will upload when you're back online.";

void main() {
  Future<void> pumpBanner(WidgetTester tester, FakeConnectivitySource source) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [connectivitySourceProvider.overrideWithValue(source)],
        child: const MaterialApp(home: Scaffold(body: OfflineBanner())),
      ),
    );
  }

  testWidgets('shows a banner when offline', (tester) async {
    final source = FakeConnectivitySource();
    addTearDown(source.close);

    await pumpBanner(tester, source);
    source.emit(NetworkStatus.offline);
    await tester.pump();

    expect(find.text(offlineText), findsOneWidget);
  });

  testWidgets('hides the banner when back online', (tester) async {
    final source = FakeConnectivitySource();
    addTearDown(source.close);

    await pumpBanner(tester, source);
    source.emit(NetworkStatus.online);
    await tester.pumpAndSettle();

    expect(find.text(offlineText), findsNothing);
  });

  testWidgets('appears while offline and disappears once online', (
    tester,
  ) async {
    final source = FakeConnectivitySource();
    addTearDown(source.close);

    await pumpBanner(tester, source);
    source.emit(NetworkStatus.offline);
    await tester.pumpAndSettle();
    expect(find.text(offlineText), findsOneWidget);

    source.emit(NetworkStatus.online);
    await tester.pumpAndSettle();
    expect(find.text(offlineText), findsNothing);
  });
}
