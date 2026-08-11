import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lens/core/router/app_router.dart';
import 'package:local_lens/features/auth/domain/session.dart';
import 'package:local_lens/features/auth/presentation/auth_providers.dart';

class _TestSessionController extends SessionController {
  _TestSessionController(this.session);

  final Session? session;

  @override
  Session? build() => session;
}

void main() {
  testWidgets('Deep link locallens://issue/42 parses and resolves route',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        sessionProvider.overrideWith(
          () => _TestSessionController(
            const Session(accessToken: 't', userId: 1),
          ),
        ),
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

    router.go('locallens://issue/42');
    await tester.pumpAndSettle();

    expect(router.state.matchedLocation, '/issue/42');
  });

  testWidgets('Deep link locallens://ward/downtown parses and resolves route',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        sessionProvider.overrideWith(
          () => _TestSessionController(
            const Session(accessToken: 't', userId: 1),
          ),
        ),
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

    router.go('locallens://ward/downtown');
    await tester.pumpAndSettle();

    expect(router.state.matchedLocation, '/ward/downtown');
  });

  testWidgets('Deep link locallens://talk/100 parses and resolves route',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        sessionProvider.overrideWith(
          () => _TestSessionController(
            const Session(accessToken: 't', userId: 1),
          ),
        ),
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

    router.go('locallens://talk/100');
    await tester.pumpAndSettle();

    expect(router.state.matchedLocation, '/talk/100');
    expect(find.text('Talk #100'), findsOneWidget);
  });
}
