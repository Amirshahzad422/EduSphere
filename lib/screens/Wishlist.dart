import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/cart_provider.dart';
import '../styles/colors.dart';
import '../styles/spacing.dart';
import '../styles/typography.dart';
import '../components/CourseCard.dart';
import '../components/Button.dart';
import '../utils/helpers.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlist = ref.watch(wishlistProvider);
    final isDesktop = AppHelpers.isDesktop(context);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppSpacing.marginDesktop : AppSpacing.marginMobile,
        vertical: AppSpacing.lg,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Navigation Breadcrumb
              InkWell(
                onTap: () => context.go('/home'),
                borderRadius: AppSpacing.roundedMd,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 2.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back, size: 18, color: AppColors.secondary),
                      const SizedBox(width: 8),
                      Text(
                        'Back to Home',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Text(
                'My Wishlist',
                style: AppTypography.displayMedium.copyWith(
                  fontSize: isDesktop ? 32 : 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${wishlist.length} course${wishlist.length == 1 ? '' : 's'} saved for later',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 24),

              if (wishlist.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60.0),
                    child: Column(
                      children: [
                        const Icon(Icons.favorite_border, size: 64, color: AppColors.outline),
                        const SizedBox(height: 16),
                        Text('Your wishlist is empty', style: AppTypography.titleLarge),
                        const SizedBox(height: 8),
                        Text('Save courses you want to study later by clicking the heart icon.', style: AppTypography.bodyMedium),
                        const SizedBox(height: 20),
                        AppButton(
                          label: 'Explore Catalog',
                          variant: ButtonVariant.primary,
                          onPressed: () => context.go('/courses'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossCount = AppHelpers.getGridColumnCount(context);
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: isDesktop
                            ? 0.78
                            : (MediaQuery.sizeOf(context).width > 420 ? 0.75 : 0.70),
                      ),
                      itemCount: wishlist.length,
                      itemBuilder: (context, index) {
                        final course = wishlist[index];
                        return CourseCard(
                          course: course,
                          isWishlisted: true,
                          onTap: () => context.go('/course/${course.id}'),
                          onWishlistToggle: () =>
                              ref.read(wishlistProvider.notifier).toggleWishlist(course),
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
