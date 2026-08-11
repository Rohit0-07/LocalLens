import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:local_lens/core/router/route_paths.dart';
import 'package:local_lens/features/auth/domain/session.dart';
import 'package:local_lens/features/auth/presentation/auth_providers.dart';
import 'package:local_lens/features/auth/presentation/screens/otp_screen.dart';

import '../../helpers.dart';

class _TrackingAuthRepository extends FakeAuthRepository {
  String? verifiedPhone;
  String? verifiedEmail;

  @override
  Future<Session> verifyOtp({
    required String phone,
    required String code,
  }) async {
    verifiedPhone = phone;
    return super.verifyOtp(phone: phone, code: code);
  }

  @override
  Future<Session> verifyEmailOtp({
    required String email,
    required String code,
  }) async {
    verifiedEmail = email;
    return super.verifyEmailOtp(email: email, code: code);
  }
}

void main() {
  Future<void> pumpOtpScreen(
    WidgetTester tester, {
    required _TrackingAuthRepository repo,
    required OtpRouteArgs args,
  }) async {
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: RoutePaths.otp,
      routes: [
        GoRoute(
          path: RoutePaths.otp,
          builder: (_, _) => OtpScreen(args: args),
        ),
        GoRoute(
          path: RoutePaths.feed,
          builder: (_, _) => const Scaffold(body: Text('feed landing')),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('phone OTP dispatches to verifyOtp', (tester) async {
    final repo = _TrackingAuthRepository();
    await pumpOtpScreen(
      tester,
      repo: repo,
      args: const OtpRouteArgs(
        identifier: '+919876543210',
        mode: OtpMode.phone,
      ),
    );

    expect(find.text('Verify your number'), findsOneWidget);

    final boxes = find.byType(TextField);
    expect(boxes, findsNWidgets(6));
    for (var i = 0; i < 6; i++) {
      await tester.enterText(boxes.at(i), '0');
    }
    await tester.pumpAndSettle();

    expect(repo.verifiedPhone, '+919876543210');
    expect(repo.verifiedEmail, isNull);
  });

  testWidgets('email OTP dispatches to verifyEmailOtp', (tester) async {
    final repo = _TrackingAuthRepository();
    await pumpOtpScreen(
      tester,
      repo: repo,
      args: const OtpRouteArgs(
        identifier: 'citizen@example.com',
        mode: OtpMode.email,
      ),
    );

    expect(find.text('Verify your email'), findsOneWidget);

    final boxes = find.byType(TextField);
    expect(boxes, findsNWidgets(6));
    for (var i = 0; i < 6; i++) {
      await tester.enterText(boxes.at(i), '0');
    }
    await tester.pumpAndSettle();

    expect(repo.verifiedEmail, 'citizen@example.com');
    expect(repo.verifiedPhone, isNull);
  });
}
