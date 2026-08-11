import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:local_lens/core/router/app_router.dart';
import 'package:local_lens/features/auth/domain/session.dart';
import 'package:local_lens/features/auth/presentation/auth_providers.dart';

class _FixedSessionController extends SessionController {
  _FixedSessionController(this.session);

  final Session? session;

  @override
  Session? build() => session;
}

Future<GoRouter> pumpRouter(
  WidgetTester tester, {
  required Session? session,
}) async {
  final container = ProviderContainer(
    overrides: [
      sessionProvider.overrideWith(() => _FixedSessionController(session)),
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
  return router;
}

void main() {
  testWidgets('router redirects to sign-in when signed out', (tester) async {
    final router = await pumpRouter(tester, session: null);
    expect(router.state.matchedLocation, '/sign-in');
  });

  testWidgets('router allows feed when signed in', (tester) async {
    final router = await pumpRouter(
      tester,
      session: Session(accessToken: 't', userId: 1),
    );
    expect(router.state.matchedLocation, '/feed');
  });
}
