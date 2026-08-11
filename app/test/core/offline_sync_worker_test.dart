import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lens/core/feedback/app_infrastructure.dart';
import 'package:local_lens/core/network/connectivity.dart';

class TestConnectivitySource implements ConnectivitySource {
  final _controller = StreamController<NetworkStatus>.broadcast();

  @override
  Stream<NetworkStatus> get statuses => _controller.stream;

  void emit(NetworkStatus status) {
    _controller.add(status);
  }

  Future<void> close() => _controller.close();
}

void main() {
  testWidgets(
      'OfflineSyncWorker triggers toast when transitioning from offline to online',
      (tester) async {
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
            body: AppInfrastructure(child: Text('Main Content')),
          ),
        ),
      ),
    );

    // Initial state: offline
    connectivitySource.emit(NetworkStatus.offline);
    await tester.pump(Duration.zero);
    await tester.pump();

    // Transition to online
    connectivitySource.emit(NetworkStatus.online);
    await tester.pump(Duration.zero);
    await tester.pump();

    expect(
      find.text('Back online — synchronizing outbox queue'),
      findsOneWidget,
    );

    // Clean up toast timer
    await tester.pump(const Duration(seconds: 5));
  });
}
