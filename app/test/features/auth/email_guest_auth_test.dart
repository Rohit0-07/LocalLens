import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_lens/features/auth/domain/auth_repository.dart';
import 'package:local_lens/features/auth/domain/session.dart';
import 'package:local_lens/features/auth/presentation/auth_providers.dart';
import 'package:local_lens/features/auth/presentation/screens/otp_screen.dart';
import 'package:local_lens/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:local_lens/features/auth/presentation/widgets/guest_guard.dart';

class MockEmailGuestAuthRepository implements AuthRepository {
  String? requestedPhone;
  String? requestedEmail;
  String? verifiedEmail;
  String? verifiedCode;
  bool guestLoggedIn = false;

  @override
  Future<void> requestOtp(String phone) async {
    requestedPhone = phone;
  }

  @override
  Future<Session> verifyOtp({required String phone, required String code}) async {
    if (code != '000000') throw StateError('bad code');
    return const Session(accessToken: 'test-token', userId: 42);
  }

  @override
  Future<void> requestEmailOtp(String email) async {
    requestedEmail = email;
  }

  @override
  Future<Session> verifyEmailOtp({required String email, required String code}) async {
    verifiedEmail = email;
    verifiedCode = code;
    if (code != '000000') throw StateError('bad code');
    return const Session(accessToken: 'email-token', userId: 101, isGuest: false);
  }

  @override
  Future<Session> loginAsGuest() async {
    guestLoggedIn = true;
    return const Session(
      accessToken: 'guest-token',
      userId: 'guest:1234',
      isGuest: true,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName;
    if (name == #requestEmailOtp) {
      requestedEmail = invocation.positionalArguments.first as String?;
      return Future.value();
    }
    if (name == #verifyEmailOtp) {
      final email = invocation.namedArguments[#email] as String?;
      final code = invocation.namedArguments[#code] as String?;
      verifiedEmail = email;
      verifiedCode = code;
      return Future.value(const Session(accessToken: 'email-token', userId: 101, isGuest: false));
    }
    if (name == #loginAsGuest || name == #guestLogin || name == #createGuestSession) {
      guestLoggedIn = true;
      return Future.value(const Session(accessToken: 'guest-token', userId: 'guest:1234', isGuest: true));
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  group('F-02 Email Auth & Guest Mode Tests', () {
    late MockEmailGuestAuthRepository mockAuthRepository;

    setUp(() {
      mockAuthRepository = MockEmailGuestAuthRepository();
    });

    Widget buildTestApp({Widget? home}) {
      return ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
        ],
        child: MaterialApp(
          home: home ?? const SignInScreen(),
        ),
      );
    }

    testWidgets('Mode switcher on SignInScreen switches between Phone and Email mode', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Look for Email mode switch option
      final emailTab = find.text('Email');
      expect(emailTab, findsOneWidget);

      final phoneTab = find.text('Phone');
      expect(phoneTab, findsOneWidget);

      // Tap on Email mode
      await tester.tap(emailTab);
      await tester.pumpAndSettle();

      // Verify email input field is present
      expect(
        find.byWidgetPredicate((widget) =>
            widget is TextField &&
            (widget.decoration?.labelText?.toLowerCase().contains('email') == true ||
                widget.decoration?.hintText?.toLowerCase().contains('email') == true)),
        findsOneWidget,
      );

      // Switch back to Phone mode
      await tester.tap(phoneTab);
      await tester.pumpAndSettle();

      // Verify phone input field is shown again
      expect(
        find.byWidgetPredicate((widget) =>
            widget is TextField &&
            (widget.decoration?.labelText?.toLowerCase().contains('phone') == true ||
                widget.decoration?.hintText?.contains('+91') == true)),
        findsOneWidget,
      );
    });

    testWidgets('Email field enforces RFC regex validation and displays error for invalid format', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Switch to Email mode
      await tester.tap(find.text('Email'));
      await tester.pumpAndSettle();

      final textField = find.byType(TextField).first;

      // Enter invalid email address
      await tester.enterText(textField, 'invalid-email-format');
      await tester.pump();

      // Tap submit / request OTP button
      final submitButton = find.byWidgetPredicate(
        (widget) =>
            (widget is ElevatedButton || widget is FilledButton) &&
            ((widget as dynamic).child is Text &&
                (((widget as dynamic).child as Text).data?.toLowerCase().contains('otp') == true ||
                    ((widget as dynamic).child as Text).data?.toLowerCase().contains('continue') == true)),
      );
      expect(submitButton, findsOneWidget);

      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Check for validation error message
      expect(
        find.textContaining(RegExp(r'valid email', caseSensitive: false)),
        findsOneWidget,
      );

      // Enter valid email address
      await tester.enterText(textField, 'citizen@example.com');
      await tester.pumpAndSettle();

      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Validation error should no longer be present
      expect(
        find.textContaining(RegExp(r'invalid email', caseSensitive: false)),
        findsNothing,
      );
    });

    testWidgets('60-second countdown timer runs on OTP screen and enables resend until 0s', (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: OtpScreen(
              args: OtpRouteArgs(
                identifier: 'user@example.com',
                mode: OtpMode.email,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify 60-second countdown timer text appears
      final timerFinder = find.textContaining(RegExp(r'Resend.*(60s|59s|\d+s)', caseSensitive: false));
      expect(timerFinder, findsOneWidget);

      // Advance timer by 30 seconds
      await tester.pump(const Duration(seconds: 30));
      expect(find.textContaining(RegExp(r'30s|29s', caseSensitive: false)), findsOneWidget);

      // Advance timer to completion (31 more seconds)
      await tester.pump(const Duration(seconds: 31));
      await tester.pumpAndSettle();

      // Timer finished; "Resend OTP" button should be enabled
      final resendButton = find.textContaining(RegExp(r'Resend OTP', caseSensitive: false));
      expect(resendButton, findsOneWidget);
    });

    testWidgets('Continue as Guest button triggers guest session creation', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final guestButton = find.widgetWithText(OutlinedButton, 'Continue as Guest');
      expect(guestButton, findsOneWidget);

      await tester.tap(guestButton);
      await tester.pumpAndSettle();

      expect(mockAuthRepository.guestLoggedIn, isTrue);
    });

    testWidgets('GuestGuard renders clean M3 dialog prompt with no emojis', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const GuestGuard(),
                  );
                },
                child: const Text('Trigger Action'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open GuestGuard dialog
      await tester.tap(find.text('Trigger Action'));
      await tester.pumpAndSettle();

      // Verify Title
      expect(find.text('Sign in required'), findsOneWidget);

      // Verify Body Text
      expect(
        find.text('Create an account or sign in to participate in civic reporting.'),
        findsOneWidget,
      );

      // Verify Buttons
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Verify no emojis are present in any visible text
      final emojiRegex = RegExp(r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]', unicode: true);
      final allTextWidgets = tester.widgetList<Text>(find.byType(Text));
      for (final textWidget in allTextWidgets) {
        if (textWidget.data != null) {
          expect(emojiRegex.hasMatch(textWidget.data!), isFalse, reason: 'Emoji found in UI text: ${textWidget.data}');
        }
      }

      // Tap Cancel to dismiss dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Sign in required'), findsNothing);
    });
  });
}
