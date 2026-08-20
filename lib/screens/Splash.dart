import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../styles/colors.dart';
import '../styles/spacing.dart';
import '../styles/typography.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  bool _showButton = false;
  Timer? _timer1;
  Timer? _timer2;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();

    _timer1 = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() {
          _showButton = true;
        });
      }
    });

    // Auto navigate after 2.5 seconds if user doesn't click
    _timer2 = Timer(const Duration(milliseconds: 2600), () {
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        context.go('/home');
      }
    });
  }

  @override
  void dispose() {
    _timer1?.cancel();
    _timer2?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Spacer(),

              // Brand Logo & Heading
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: AppSpacing.roundedXl,
                ),
                child: const Icon(
                  Icons.auto_stories,
                  size: 48,
                  color: AppColors.secondaryFixedDim,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'EduSphere',
                style: AppTypography.displayLarge.copyWith(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Learn skills. Build confidence. Go further.',
                style: AppTypography.bodyLarge.copyWith(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Bottom Progress & Action
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      height: 4,
                      width: double.infinity,
                      color: Colors.white24,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _progressAnimation.value,
                        child: Container(color: AppColors.secondaryFixedDim),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Get Started Button
              AnimatedOpacity(
                opacity: _showButton ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => context.go('/onboarding'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.onSecondary,
                      shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                    ),
                    child: Text(
                      'Get Started',
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
