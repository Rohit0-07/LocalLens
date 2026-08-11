import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:local_lens/core/router/route_paths.dart';
import 'package:local_lens/features/auth/presentation/auth_providers.dart';
import 'package:local_lens/features/auth/presentation/screens/otp_screen.dart';
import 'package:local_lens/features/auth/presentation/screens/sign_in_screen.dart';

import '../../helpers.dart';

void main() {
  testWidgets('shows validation error for an invalid phone', (tester) async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SignInScreen()),
      ),
    );

    await tester.enterText(find.byType(TextField), '123');
    await tester.tap(find.text('Send OTP'));
    await tester.pumpAndSettle();

    expect(find.textContaining('valid phone number'), findsOneWidget);
  });

  testWidgets('valid phone requests an OTP and navigates', (tester) async {
    final repo = FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: RoutePaths.signIn,
      routes: [
        GoRoute(
          path: RoutePaths.signIn,
          builder: (_, _) => const SignInScreen(),
        ),
        GoRoute(path: RoutePaths.otp, builder: (_, _) => const OtpScreen()),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.enterText(find.byType(TextField), '+919876543210');
    await tester.tap(find.text('Send OTP'));
    await tester.pumpAndSettle();

    expect(repo.requestedPhone, '+919876543210');
    expect(find.text('Verify your number'), findsOneWidget);
  });

  testWidgets('foreign phone number with own country code is not mangled', (tester) async {
    final repo = FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: RoutePaths.signIn,
      routes: [
        GoRoute(
          path: RoutePaths.signIn,
          builder: (_, _) => const SignInScreen(),
        ),
        GoRoute(
          path: RoutePaths.otp,
          builder: (_, state) => OtpScreen(
            args: state.extra is OtpRouteArgs ? state.extra as OtpRouteArgs : null,
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.enterText(find.byType(TextField), '+1 555 123 4567');
    await tester.tap(find.text('Send OTP'));
    await tester.pumpAndSettle();

    expect(repo.requestedPhone, '+15551234567');
    expect(find.text('Verify your number'), findsOneWidget);
  });

  testWidgets('Indian number without prefix gets +91', (tester) async {
    final repo = FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: RoutePaths.signIn,
      routes: [
        GoRoute(
          path: RoutePaths.signIn,
          builder: (_, _) => const SignInScreen(),
        ),
        GoRoute(
          path: RoutePaths.otp,
          builder: (_, state) => OtpScreen(
            args: state.extra is OtpRouteArgs ? state.extra as OtpRouteArgs : null,
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.enterText(find.byType(TextField), '98765 43210');
    await tester.tap(find.text('Send OTP'));
    await tester.pumpAndSettle();

    expect(repo.requestedPhone, '+919876543210');
    expect(find.text('Verify your number'), findsOneWidget);
  });
}
