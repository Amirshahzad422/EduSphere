import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../styles/colors.dart';
import '../styles/spacing.dart';
import '../styles/typography.dart';
import '../components/Button.dart';

// Note: No Stitch reference found for NotFound screen — used consistent styling matching lib/styles/
class NotFoundScreen extends StatefulWidget {
  const NotFoundScreen({super.key});

  @override
  State<NotFoundScreen> createState() => _NotFoundScreenState();
}

class _NotFoundScreenState extends State<NotFoundScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 560),
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppSpacing.roundedXl,
              border: Border.all(color: AppColors.surfaceContainerHigh),
              boxShadow: const [
                BoxShadow(color: AppColors.cardShadow, blurRadius: 20, offset: Offset(0, 8)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryFixedDim.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.explore_off, size: 54, color: AppColors.secondary),
                ),
                const SizedBox(height: 20),
                Text(
                  '404',
                  style: AppTypography.displayLarge.copyWith(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    letterSpacing: -1,
                  ),
                ),
                Text(
                  'Page Not Found',
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'The resource or screen you requested might have been moved or does not exist.',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search for courses instead...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: AppSpacing.roundedMd,
                      borderSide: const BorderSide(color: AppColors.outlineVariant),
                    ),
                  ),
                  onSubmitted: (query) {
                    if (query.trim().isNotEmpty) {
                      context.go('/courses');
                    }
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Return to Home',
                        variant: ButtonVariant.primary,
                        icon: Icons.home,
                        onPressed: () => context.go('/home'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        label: 'Browse Courses',
                        variant: ButtonVariant.secondary,
                        icon: Icons.school,
                        onPressed: () => context.go('/courses'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
