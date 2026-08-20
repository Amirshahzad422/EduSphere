import 'package:flutter/material.dart';
import '../styles/colors.dart';
import '../styles/spacing.dart';

/// Spinner Indicator
class AppLoader extends StatelessWidget {
  final double size;
  final Color color;

  const AppLoader({
    super.key,
    this.size = 32.0,
    this.color = AppColors.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    );
  }
}

/// Generic Skeleton Box with pulsing animation
class SkeletonBox extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh.withOpacity(_animation.value),
            borderRadius: widget.borderRadius ?? AppSpacing.roundedMd,
          ),
        );
      },
    );
  }
}

/// Grid View Skeleton Card matching CourseCard dimensions
class CourseCardSkeleton extends StatelessWidget {
  const CourseCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 16:9 Thumbnail Skeleton
          AspectRatio(
            aspectRatio: 16 / 9,
            child: SkeletonBox(borderRadius: AppSpacing.roundedLg),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Instructor row
                Row(
                  children: [
                    SkeletonBox(width: 20, height: 20, borderRadius: AppSpacing.roundedFull),
                    const SizedBox(width: 8),
                    SkeletonBox(width: 80, height: 12),
                  ],
                ),
                const SizedBox(height: 10),
                // Title lines
                SkeletonBox(width: double.infinity, height: 16),
                const SizedBox(height: 6),
                SkeletonBox(width: 140, height: 16),
                const SizedBox(height: 12),
                // Rating & duration
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SkeletonBox(width: 60, height: 12),
                    SkeletonBox(width: 50, height: 12),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.surfaceContainerHigh),
                const SizedBox(height: 12),
                // Price & Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SkeletonBox(width: 70, height: 20),
                    SkeletonBox(width: 65, height: 28),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// List View Skeleton Card matching CourseListCard dimensions
class CourseListCardSkeleton extends StatelessWidget {
  const CourseListCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail box
          SkeletonBox(width: 140, height: 95, borderRadius: AppSpacing.roundedMd),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 100, height: 12),
                const SizedBox(height: 8),
                SkeletonBox(width: double.infinity, height: 16),
                const SizedBox(height: 6),
                SkeletonBox(width: 160, height: 14),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SkeletonBox(width: 90, height: 12),
                    SkeletonBox(width: 60, height: 18),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
