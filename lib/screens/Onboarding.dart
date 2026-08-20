import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../styles/colors.dart';
import '../styles/spacing.dart';
import '../styles/typography.dart';
import '../components/Button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<Map<String, String>> _slides = [
    {
      'title': 'Discover courses from expert instructors.',
      'description': 'Elevate your skills with premium content curated by industry leaders. Learn at your own pace, anywhere, anytime.',
      'image': 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=800',
    },
    {
      'title': 'Interactive live classes & real-time collaboration.',
      'description': 'Join hands-on live sessions, ask questions, take real-time quizzes, and connect with fellow peers around the globe.',
      'image': 'https://images.unsplash.com/photo-1531403009284-440f080d1e12?w=800',
    },
    {
      'title': 'Earn verifiable certificates & level up your career.',
      'description': 'Showcase verifiable credentials with unique verification IDs and QR codes directly on your resume and LinkedIn.',
      'image': 'https://images.unsplash.com/photo-1523240795612-9a054b0db644?w=800',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentIndex < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceBright,
      body: SafeArea(
        child: Column(
          children: [
            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Illustration / Image Container
                        Container(
                          constraints: const BoxConstraints(maxHeight: 280, maxWidth: 440),
                          decoration: BoxDecoration(
                            borderRadius: AppSpacing.roundedXl,
                            border: Border.all(color: AppColors.surfaceContainerHigh),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.cardShadow,
                                blurRadius: 16,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.network(
                            slide['image']!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.surfaceContainerLow,
                              child: const Icon(Icons.school, size: 64, color: AppColors.secondary),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Title
                        Text(
                          slide['title']!,
                          style: AppTypography.headlineLarge.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: AppColors.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),

                        // Description
                        Text(
                          slide['description']!,
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.onSurfaceVariant,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation Controls
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Skip
                  TextButton(
                    onPressed: () => context.go('/home'),
                    child: Text(
                      'Skip',
                      style: AppTypography.labelLarge.copyWith(color: AppColors.secondary),
                    ),
                  ),

                  // Progress Dots
                  Row(
                    children: List.generate(_slides.length, (dotIndex) {
                      final isActive = dotIndex == _currentIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.secondary : AppColors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  // Next / Get Started Button
                  AppButton(
                    label: _currentIndex == _slides.length - 1 ? 'Start' : 'Next',
                    variant: ButtonVariant.primary,
                    size: ButtonSize.sm,
                    icon: Icons.arrow_forward,
                    onPressed: _onNext,
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
