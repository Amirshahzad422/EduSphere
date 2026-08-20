import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';
import '../components/Button.dart';

// Note: No Stitch reference found for NotFound screen — used consistent styling matching lib/styles/
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 72, color: AppColors.outline),
              const SizedBox(height: 16),
              Text(
                '404 - Page Not Found',
                style: AppTypography.displayMedium.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'The page you are looking for does not exist or has been moved.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Return to Home',
                variant: ButtonVariant.primary,
                icon: Icons.home,
                onPressed: () => context.go('/home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
