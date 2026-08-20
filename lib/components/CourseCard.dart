import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../styles/colors.dart';
import '../styles/spacing.dart';
import '../styles/typography.dart';
import '../utils/formatters.dart';
import '../utils/helpers.dart';

/// Standard Grid Course Card matching Stitch designs & AGENTS.md requirements
class CourseCard extends StatelessWidget {
  final CourseModel course;
  final VoidCallback? onTap;
  final VoidCallback? onWishlistToggle;
  final bool isWishlisted;

  const CourseCard({
    super.key,
    required this.course,
    this.onTap,
    this.onWishlistToggle,
    this.isWishlisted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: AppColors.surfaceContainerHigh),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thumbnail Stack with badges and wishlist button
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: AppHelpers.buildCachedImage(
                    imageUrl: course.thumbnailUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: 600,
                  ),
                ),
                // Category Chip (Top Left)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: AppSpacing.roundedSm,
                    ),
                    child: Text(
                      course.category,
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                // Discount Badge
                if (course.discount > 0)
                  Positioned(
                    top: 10,
                    right: 48,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: AppSpacing.roundedSm,
                      ),
                      child: Text(
                        '${course.discount.round()}% OFF',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                // Wishlist Icon (Top Right)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Material(
                    color: Colors.white.withOpacity(0.9),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onWishlistToggle,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          isWishlisted ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: isWishlisted ? AppColors.error : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Course Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Instructor Row + Level Badge
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundImage: NetworkImage(course.instructor.avatarUrl),
                        backgroundColor: AppColors.surfaceContainerHigh,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          course.instructor.name,
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppColors.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Level Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          borderRadius: AppSpacing.roundedSm,
                        ),
                        child: Text(
                          course.level,
                          style: AppTypography.labelSmall.copyWith(
                            fontSize: 10,
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Title
                  Text(
                    course.title,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Metadata Row: Rating, Enrolments, Duration
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 16, color: AppColors.star),
                      const SizedBox(width: 3),
                      Text(
                        course.rating.toStringAsFixed(1),
                        style: AppTypography.labelSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${AppFormatters.formatCount(course.enrolmentCount)})',
                        style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.outline),
                      ),
                      const Spacer(),
                      const Icon(Icons.schedule, size: 13, color: AppColors.outline),
                      const SizedBox(width: 3),
                      Text(
                        course.duration,
                        style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Divider
                  const Divider(height: 1, color: AppColors.surfaceContainerHigh),
                  const SizedBox(height: 10),

                  // Price & View Details Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (course.originalPrice != null)
                            Text(
                              AppFormatters.formatCurrency(course.originalPrice!),
                              style: AppTypography.bodySmall.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: AppColors.outline,
                                fontSize: 11,
                              ),
                            ),
                          Text(
                            course.price == 0 ? 'Free' : AppFormatters.formatCurrency(course.price),
                            style: AppTypography.titleLarge.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: onTap,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          backgroundColor: AppColors.surfaceContainerLow,
                          shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Details',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward, size: 13, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ],
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

/// Horizontal List View Course Card matching Stitch Explore List View
class CourseListCard extends StatelessWidget {
  final CourseModel course;
  final VoidCallback? onTap;
  final VoidCallback? onWishlistToggle;
  final bool isWishlisted;

  const CourseListCard({
    super.key,
    required this.course,
    this.onTap,
    this.onWishlistToggle,
    this.isWishlisted = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 450;
    final thumbWidth = isMobile ? 110.0 : 140.0;
    final thumbHeight = isMobile ? 80.0 : 95.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: AppColors.surfaceContainerHigh),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail with Category & Discount badge
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: AppSpacing.roundedMd,
                    child: SizedBox(
                      width: thumbWidth,
                      height: thumbHeight,
                      child: AppHelpers.buildCachedImage(
                        imageUrl: course.thumbnailUrl,
                        width: thumbWidth,
                        height: thumbHeight,
                        fit: BoxFit.cover,
                        memCacheWidth: 350,
                      ),
                    ),
                  ),
                  if (course.discount > 0)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: AppSpacing.roundedSm,
                        ),
                        child: Text(
                          '${course.discount.round()}% OFF',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // Main Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category & Level
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            course.category,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('•', style: TextStyle(color: AppColors.outline, fontSize: 10)),
                        const SizedBox(width: 6),
                        Text(
                          course.level,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        // Wishlist button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: onWishlistToggle,
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                isWishlisted ? Icons.favorite : Icons.favorite_border,
                                size: 18,
                                color: isWishlisted ? AppColors.error : AppColors.outline,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Title
                    Text(
                      course.title,
                      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800, fontSize: isMobile ? 13.5 : 15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Instructor name
                    Text(
                      'By ${course.instructor.name} • ${course.duration}',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.outline, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Rating & Price row
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 15, color: AppColors.star),
                            const SizedBox(width: 2),
                            Text(
                              course.rating.toStringAsFixed(1),
                              style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${AppFormatters.formatCount(course.enrolmentCount)})',
                              style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.outline),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (course.originalPrice != null) ...[
                              Text(
                                AppFormatters.formatCurrency(course.originalPrice!),
                                style: AppTypography.bodySmall.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  color: AppColors.outline,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              course.price == 0 ? 'Free' : AppFormatters.formatCurrency(course.price),
                              style: AppTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ],
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
