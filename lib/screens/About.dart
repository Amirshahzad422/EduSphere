import 'package:flutter/material.dart';
import '../styles/colors.dart';
import '../styles/spacing.dart';
import '../styles/typography.dart';
import '../utils/helpers.dart';

// Note: No Stitch reference found for About screen — used consistent styling matching lib/styles/
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = AppHelpers.isDesktop(context);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppSpacing.marginDesktop : AppSpacing.marginMobile,
        vertical: AppSpacing.lg,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'About EduSphere',
                style: AppTypography.displayMedium.copyWith(
                  fontSize: isDesktop ? 32 : 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'EduSphere is an advanced architectural e-learning platform created to bridge the gap between academic theory and high-level industry practice.',
                style: AppTypography.bodyLarge.copyWith(height: 1.6),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppSpacing.roundedLg,
                  border: Border.all(color: AppColors.surfaceContainerHigh),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Our Mission', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    Text(
                      'To democratize access to elite technical education, providing developers, designers, and innovators with masterclasses taught by senior specialists and verified with immutable credentials.',
                      style: AppTypography.bodyMedium.copyWith(height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
