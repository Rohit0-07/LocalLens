import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../auth/presentation/auth_providers.dart';

class OnboardingPageData {
  const OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
}

const List<OnboardingPageData> _onboardingPages = [
  OnboardingPageData(
    title: "See what's wrong",
    subtitle: 'Value Proposition',
    description:
        'Discover real-time civic issues in your neighborhood, from dangerous potholes to failing streetlights.',
    icon: Icons.location_on_rounded,
    color: Colors.indigo,
  ),
  OnboardingPageData(
    title: 'Your upvotes are civic signals',
    subtitle: 'Civic Impact',
    description:
        'Vote on local issues that matter most to your community. Upvoted issues demand faster municipal response.',
    icon: Icons.thumb_up_alt_rounded,
    color: Colors.teal,
  ),
  OnboardingPageData(
    title: "We can't reveal you, even if we tried",
    subtitle: 'Anonymity Promise',
    description:
        'Report concerns safely with zero-knowledge obfuscation, fuzzy location shielding, and complete privacy.',
    icon: Icons.shield_rounded,
    color: Colors.deepPurple,
  ),
  OnboardingPageData(
    title: 'Street Check',
    subtitle: 'Daily Ritual',
    description:
        'Make civic awareness a habit. Check nearby updates on your daily commute and stay informed.',
    icon: Icons.today_rounded,
    color: Colors.amber,
  ),
  OnboardingPageData(
    title: 'Every fix is celebrated',
    subtitle: 'Win-Loop',
    description:
        'Track issue resolution from dispatch to repair, earning badges as your neighborhood improves.',
    icon: Icons.emoji_events_rounded,
    color: Colors.orange,
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final localStore = ref.read(localStoreProvider);
    await localStore.setCompletedOnboarding(true);
    if (!mounted) return;

    final session = ref.read(sessionProvider);
    if (session != null && !session.isGuest) {
      context.go(RoutePaths.feed);
    } else {
      context.go(RoutePaths.signIn);
    }
  }

  void _onNextPressed() {
    if (_currentPage < _onboardingPages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLastPage = _currentPage == _onboardingPages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Skip button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  key: const Key('skipOnboardingButton'),
                  onPressed: _completeOnboarding,
                  child: const Text('Skip'),
                ),
              ),
            ),

            // PageView Carousel
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _onboardingPages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final page = _onboardingPages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: page.color.withAlpha(30),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            page.icon,
                            size: 72,
                            color: page.color,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          page.subtitle.toUpperCase(),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: page.color,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.description,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation Controls
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page indicators
                  Row(
                    key: const Key('onboardingPageIndicator'),
                    children: List.generate(
                      _onboardingPages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(right: 6),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  // Next / Get Started button
                  FilledButton(
                    key: const Key('onboardingNextButton'),
                    onPressed: _onNextPressed,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(isLastPage ? 'Get Started' : 'Next'),
                        const SizedBox(width: 4),
                        Icon(
                          isLastPage
                              ? Icons.check_circle_outline
                              : Icons.arrow_forward_rounded,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
