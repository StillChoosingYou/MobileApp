import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/route_names.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';

/// App-level onboarding carousel shown on first launch (before role selection).
/// 3-4 slides introducing key app capabilities, with "Get Started" → role select.
class AppOnboardingCarousel extends StatefulWidget {
  const AppOnboardingCarousel({super.key});

  @override
  State<AppOnboardingCarousel> createState() => _AppOnboardingCarouselState();
}

class _AppOnboardingCarouselState extends State<AppOnboardingCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;

  static const List<_OnboardingSlide> _slides = [
    _OnboardingSlide(
      title: 'Welcome to PGPC Campus',
      description:
          'Your all-in-one portal for grades, enrollment, payments, and campus life at Pangasinan Polytechnic College.',
      illustration: Icons.school_rounded,
      backgroundColor: Color(0xFF102A6D),
      accentColor: Color(0xFFDABD64),
    ),
    _OnboardingSlide(
      title: 'Stay on Top of Academics',
      description:
          'View your class schedule, check grades in real time, track enrollment status, and access course materials — all in one place.',
      illustration: Icons.menu_book_rounded,
      backgroundColor: Color(0xFF1B3A8C),
      accentColor: Color(0xFFDABD64),
    ),
    _OnboardingSlide(
      title: 'Pay Tuition Securely',
      description:
          'Pay via GCash, bank transfer, or at the cashier window. Get instant digital receipts and track your payment history anytime.',
      illustration: Icons.payment_rounded,
      backgroundColor: Color(0xFF2646A8),
      accentColor: Color(0xFFDABD64),
    ),
    _OnboardingSlide(
      title: 'Your Digital Campus ID',
      description:
          'Generate a QR-based ID for gate entry, library access, and event check-ins. Works offline — no internet required.',
      illustration: Icons.qr_code_2_rounded,
      backgroundColor: Color(0xFF0D4A6B),
      accentColor: Color(0xFFDABD64),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    if (!mounted) return;
    context.go(Routes.roleSelect);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isCompact = Responsive.isCompactHeight(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button (top-right)
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.all(isCompact ? 12 : 16),
                child: TextButton(
                  onPressed: _skipOnboarding,
                  style: TextButton.styleFrom(
                    foregroundColor: scheme.onSurfaceVariant,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: const Size(48, 48),
                  ),
                  child: Text(
                    'Skip',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ),
            ),

            // Slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return _SlideView(
                    slide: slide,
                    index: index,
                    isLast: index == _slides.length - 1,
                    onNext: _nextPage,
                    compact: isCompact,
                  );
                },
              ),
            ),

            // Page indicators + Get Started button
            Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                0,
                24,
                isCompact ? 24 : 32,
              ),
              child: Column(
                children: [
                  // Page indicator dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.goldSeed
                              : scheme.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: isCompact ? 16 : 24),

                  // Next / Get Started button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      icon: _currentPage == _slides.length - 1
                          ? const Icon(Icons.arrow_forward_rounded, size: 20)
                          : const Icon(Icons.arrow_forward_rounded, size: 20),
                      label: Text(
                        _currentPage == _slides.length - 1
                            ? 'Get Started'
                            : 'Next',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      onPressed: _nextPage,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.goldSeed,
                        foregroundColor: AppColors.royalBlueSeed,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
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

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.title,
    required this.description,
    required this.illustration,
    required this.backgroundColor,
    required this.accentColor,
  });

  final String title;
  final String description;
  final IconData illustration;
  final Color backgroundColor;
  final Color accentColor;
}

class _SlideView extends StatelessWidget {
  const _SlideView({
    required this.slide,
    required this.index,
    required this.isLast,
    required this.onNext,
    required this.compact,
  });

  final _OnboardingSlide slide;
  final int index;
  final bool isLast;
  final VoidCallback onNext;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 20 : 32,
        vertical: compact ? 16 : 24,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration container
          Container(
            width: compact ? 140 : 180,
            height: compact ? 140 : 180,
            decoration: BoxDecoration(
              color: slide.accentColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                slide.illustration,
                size: compact ? 64 : 80,
                color: slide.accentColor,
              ),
            ),
          ),
          SizedBox(height: compact ? 24 : 32),

          // Title
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
              height: 1.2,
            ),
          ),
          SizedBox(height: compact ? 12 : 16),

          // Description
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}