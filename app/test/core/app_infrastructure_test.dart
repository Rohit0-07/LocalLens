import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lens/core/feedback/app_infrastructure.dart';
import 'package:local_lens/core/feedback/app_messenger.dart';
import 'package:local_lens/core/feedback/error_boundary.dart';
import 'package:local_lens/core/feedback/toast_overlay.dart';
import 'package:local_lens/core/network/connectivity.dart';

class SilenceConnectivitySource implements ConnectivitySource {
  final _controller = StreamController<NetworkStatus>.broadcast();

  @override
  Stream<NetworkStatus> get statuses => _controller.stream;

  Future<void> close() => _controller.close();
}

class ThrowingWidget extends StatelessWidget {
  const ThrowingWidget({super.key});

  @override
  Widget build(BuildContext context) => throw StateError('build exploded');
}

void main() {
  ProviderContainer makeContainer() {
    final source = SilenceConnectivitySource();
    addTearDown(source.close);
    return ProviderContainer(
      overrides: [
        connectivitySourceProvider.overrideWithValue(source),
        appMessengerProvider.overrideWith(AppMessenger.new),
      ],
    );
  }

  testWidgets('error boundary is wired inside the app overlay', (tester) async {
    final container = makeContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: AppInfrastructure(child: ThrowingWidget())),
        ),
      ),
    );
    tester.takeException();

    expect(find.byType(SafeFallback), findsOneWidget);
    expect(find.text('Something went wrong'), findsOneWidget);
  });

  testWidgets('offline banner and toasts both render via the overlay', (
    tester,
  ) async {
    final container = makeContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: AppInfrastructure(child: SizedBox())),
        ),
      ),
    );

    container.read(appMessengerProvider.notifier).show('syncing failed');
    await tester.pump();

    expect(find.text('syncing failed'), findsOneWidget);
    expect(find.byType(ToastOverlay), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    expect(find.text('syncing failed'), findsNothing);
  });
}
