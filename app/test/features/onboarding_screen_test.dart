import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lens/features/onboarding/presentation/screens/onboarding_screen.dart';

void main() {
  testWidgets('OnboardingScreen renders 5 pages and controls with required keys',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: OnboardingScreen(),
        ),
      ),
    );

    expect(find.byKey(const Key('skipOnboardingButton')), findsOneWidget);
    expect(find.byKey(const Key('onboardingNextButton')), findsOneWidget);
    expect(find.byKey(const Key('onboardingPageIndicator')), findsOneWidget);

    expect(find.text("See what's wrong"), findsOneWidget);

    // Tap next to cycle through pages
    await tester.tap(find.byKey(const Key('onboardingNextButton')));
    await tester.pumpAndSettle();
    expect(find.text('Your upvotes are civic signals'), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboardingNextButton')));
    await tester.pumpAndSettle();
    expect(find.text("We can't reveal you, even if we tried"), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboardingNextButton')));
    await tester.pumpAndSettle();
    expect(find.text('Street Check'), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboardingNextButton')));
    await tester.pumpAndSettle();
    expect(find.text('Every fix is celebrated'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
