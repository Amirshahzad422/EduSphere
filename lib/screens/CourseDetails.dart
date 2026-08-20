import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../models/live_class_model.dart';
import '../providers/course_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/enrolment_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/live_class_provider.dart';
import '../models/course_model.dart';
import '../styles/colors.dart';
import '../styles/spacing.dart';
import '../styles/typography.dart';
import '../components/Button.dart';
import '../components/LessonList.dart';
import '../components/Loader.dart';
import '../components/CourseCard.dart';
import '../utils/formatters.dart';
import '../utils/helpers.dart';

class CourseDetailsScreen extends ConsumerWidget {
  final String courseId;

  const CourseDetailsScreen({
    super.key,
    required this.courseId,
  });

  void _showRatingModal(BuildContext context, WidgetRef ref, CourseModel course) {
    double selectedRating = 5.0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
          title: Text('Rate & Review Course', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(course.title, style: AppTypography.bodySmall.copyWith(color: AppColors.outline), maxLines: 1),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starVal = index + 1.0;
                  return IconButton(
                    icon: Icon(
                      starVal <= selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
                      color: AppColors.star,
                      size: 32,
                    ),
                    onPressed: () => setState(() => selectedRating = starVal),
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Share your feedback about this course...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            AppButton(
              label: 'Submit Review',
              variant: ButtonVariant.primary,
              size: ButtonSize.sm,
              onPressed: () async {
                Navigator.pop(ctx);
                await ref.read(courseServiceProvider).recordCourseRating(course.id, selectedRating);
                ref.read(courseRefreshCounterProvider.notifier).state++;
                if (context.mounted) {
                  AppHelpers.showSnackBar(context, 'Thank you! Your ${selectedRating.round()}★ review has been submitted.');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(allCoursesProvider);
    final isDesktop = AppHelpers.isDesktop(context);
    final user = ref.watch(authProvider);
    final isInstructorUser = user?.role == UserRole.instructor;
    final isEnrolled = ref.watch(enrolmentProvider.notifier).isEnrolled(courseId);
    final isInCart = ref.watch(cartProvider.notifier).isInCart(courseId);
    final isWishlisted = ref.watch(wishlistProvider.notifier).isInWishlist(courseId);
    final upcomingLiveAsync = ref.watch(courseUpcomingLiveClassProvider(courseId));

    return coursesAsync.when(
      data: (courses) {
        final course = courses.firstWhere(
          (c) => c.id == courseId,
          orElse: () => courses.first,
        );

        final isOwnInstructorCourse = isInstructorUser || (user != null && course.instructorId == user.id);
        final backTarget = isOwnInstructorCourse ? '/instructor' : '/courses';
        final backLabel = isOwnInstructorCourse ? 'Back to Instructor Dashboard' : 'Back to Explore Courses';

        final similarCourses = courses
            .where((c) => c.id != course.id && (c.category == course.category || c.level == course.level))
            .take(3)
            .toList();

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
                  // Back Navigation Breadcrumb (Role & Ownership Aware)
                  InkWell(
                    onTap: () => context.go(backTarget),
                    borderRadius: AppSpacing.roundedMd,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 2.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_back, size: 18, color: AppColors.secondary),
                          const SizedBox(width: 8),
                          Text(
                            backLabel,
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

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Main Column
                      Expanded(
                        flex: 8,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Live Class Banner (If active or upcoming)
                            upcomingLiveAsync.maybeWhen(
                              data: (liveClass) {
                                if (liveClass == null || liveClass.isEnded) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 20.0),
                                  child: _buildLiveClassBanner(
                                    context,
                                    liveClass,
                                    isEnrolled: isEnrolled,
                                    isInstructor: isOwnInstructorCourse,
                                  ),
                                );
                              },
                              orElse: () => const SizedBox.shrink(),
                            ),

                            // Preview Video / Thumbnail
                            _buildHeroPreview(context, course),
                            const SizedBox(height: 24),

                            // Mobile Pricing Card (Rendered under Hero on Mobile)
                            if (!isDesktop) ...[
                              _buildPricingSidebar(
                                context,
                                ref,
                                course,
                                isEnrolled,
                                isInCart,
                                isOwnInstructorCourse,
                                user?.id ?? 'user_demo_01',
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Badges & Wishlist Header
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryFixedDim.withOpacity(0.25),
                                    borderRadius: AppSpacing.roundedSm,
                                  ),
                                  child: Text(
                                    course.category,
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainerHigh,
                                    borderRadius: AppSpacing.roundedSm,
                                  ),
                                  child: Text(
                                    course.level,
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (isOwnInstructorCourse) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: AppSpacing.roundedSm,
                                    ),
                                    child: Text(
                                      'YOUR COURSE',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                                const Spacer(),
                                // Wishlist Toggle
                                if (!isOwnInstructorCourse)
                                  IconButton(
                                    icon: Icon(
                                      isWishlisted ? Icons.favorite : Icons.favorite_border,
                                      color: isWishlisted ? AppColors.error : AppColors.outline,
                                    ),
                                    onPressed: () {
                                      ref.read(wishlistProvider.notifier).toggleWishlist(course);
                                      AppHelpers.showSnackBar(
                                        context,
                                        isWishlisted ? 'Removed from wishlist' : 'Saved to wishlist!',
                                      );
                                    },
                                    tooltip: 'Save to Wishlist',
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Title & Subtitle
                            Text(
                              course.title,
                              style: AppTypography.displayMedium.copyWith(
                                fontSize: isDesktop ? 30 : 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              course.subtitle.isNotEmpty ? course.subtitle : 'Complete industry-grade curriculum and hands-on portfolio projects.',
                              style: AppTypography.bodyLarge.copyWith(color: AppColors.onSurfaceVariant),
                            ),
                            const SizedBox(height: 16),

                            // Metadata stats row
                            _buildStatsRow(course),
                            const SizedBox(height: 24),

                            // Instructor Bio Card
                            _buildInstructorCard(course),
                            const SizedBox(height: 28),

                            // What You'll Learn
                            if (course.whatYouWillLearn.isNotEmpty) ...[
                              _buildWhatYouWillLearn(course),
                              const SizedBox(height: 28),
                            ],

                            // Curriculum / Syllabus Accordion
                            _buildCurriculum(context, course),
                            const SizedBox(height: 28),

                            // Requirements
                            if (course.requirements.isNotEmpty) ...[
                              _buildRequirements(course),
                              const SizedBox(height: 28),
                            ],

                            // Student Reviews Breakdown with Write Review Action
                            _buildStudentReviews(context, ref, course, isEnrolled),
                            const SizedBox(height: 36),

                            // Similar Courses (Shown for students)
                            if (similarCourses.isNotEmpty && !isOwnInstructorCourse) ...[
                              _buildSimilarCourses(context, ref, similarCourses),
                              const SizedBox(height: 32),
                            ],
                          ],
                        ),
                      ),

                      // Right Column / Sticky Pricing Sidebar (Desktop)
                      if (isDesktop) ...[
                        const SizedBox(width: 32),
                        Expanded(
                          flex: 4,
                          child: _buildPricingSidebar(
                            context,
                            ref,
                            course,
                            isEnrolled,
                            isInCart,
                            isOwnInstructorCourse,
                            user?.id ?? 'user_demo_01',
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(60.0), child: AppLoader())),
      error: (err, _) => Center(child: Text('Error loading course details: $err')),
    );
  }

  Widget _buildHeroPreview(BuildContext context, CourseModel course) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: AppSpacing.roundedLg,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              course.thumbnailUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.surfaceContainerHigh,
                child: const Center(child: Icon(Icons.image, size: 50, color: AppColors.outline)),
              ),
            ),
          ),
          Container(
            color: Colors.black.withOpacity(0.35),
            child: Center(
              child: InkWell(
                onTap: () {
                  final firstLesson = course.syllabus.isNotEmpty && course.syllabus.first.lessons.isNotEmpty
                      ? course.syllabus.first.lessons.first.id
                      : '1';
                  context.go('/lesson/${course.id}/$firstLesson');
                },
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black45, blurRadius: 16, offset: Offset(0, 4)),
                    ],
                  ),
                  child: const Icon(Icons.play_arrow, size: 36, color: Colors.white),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: AppSpacing.roundedSm,
              ),
              child: Text(
                'Preview Course',
                style: AppTypography.labelSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(CourseModel course) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, size: 18, color: AppColors.star),
            const SizedBox(width: 4),
            Text(
              course.rating.toStringAsFixed(1),
              style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 4),
            Text('(${course.reviewCount} reviews)', style: AppTypography.bodySmall.copyWith(color: AppColors.outline)),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_outline, size: 16, color: AppColors.outline),
            const SizedBox(width: 4),
            Text(
              '${AppFormatters.formatCount(course.enrolmentCount)} students',
              style: AppTypography.bodySmall,
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language, size: 16, color: AppColors.outline),
            const SizedBox(width: 4),
            Text(course.language, style: AppTypography.bodySmall),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.update, size: 16, color: AppColors.outline),
            const SizedBox(width: 4),
            Text('Updated 2026', style: AppTypography.bodySmall),
          ],
        ),
      ],
    );
  }

  Widget _buildInstructorCard(CourseModel course) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Instructor', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: NetworkImage(course.instructor.avatarUrl),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.instructor.name,
                      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      course.instructor.title,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.outline),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: AppColors.star),
                        const SizedBox(width: 2),
                        Text('${course.instructor.rating} Rating', style: AppTypography.labelSmall),
                        const SizedBox(width: 10),
                        const Icon(Icons.people_outline, size: 14, color: AppColors.outline),
                        const SizedBox(width: 2),
                        Text('${AppFormatters.formatCount(course.instructor.studentsCount)} Students', style: AppTypography.labelSmall),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            course.instructor.bio,
            style: AppTypography.bodySmall.copyWith(height: 1.5, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatYouWillLearn(CourseModel course) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppSpacing.roundedLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("What you'll learn", style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          ...course.whatYouWillLearn.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle, size: 18, color: AppColors.secondary),
                  const SizedBox(width: 10),
                  Expanded(child: Text(item, style: AppTypography.bodyMedium)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurriculum(BuildContext context, CourseModel course) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Course Curriculum', style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w800)),
            Text(
              '${course.syllabus.length} modules • ${course.totalLessons} lessons',
              style: AppTypography.labelSmall.copyWith(color: AppColors.outline),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LessonList(
          syllabus: course.syllabus,
          onLessonSelected: (lesson) {
            context.go('/lesson/${course.id}/${lesson.id}');
          },
        ),
      ],
    );
  }

  Widget _buildRequirements(CourseModel course) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Requirements', style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        ...course.requirements.map(
          (req) => Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Expanded(child: Text(req, style: AppTypography.bodyMedium)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentReviews(BuildContext context, WidgetRef ref, CourseModel course, bool isEnrolled) {
    final reviews = [
      {
        'name': 'Sophia Martinez',
        'avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
        'rating': 5,
        'date': '2 weeks ago',
        'comment': 'Exceptional course. The real-world production projects made everything click immediately.',
      },
      {
        'name': 'James Miller',
        'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
        'rating': 5,
        'date': '1 month ago',
        'comment': 'Clear explanations, zero fluff, and great instructor response time in the forum.',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Student Feedback', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800)),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: AppColors.star, size: 20),
                  const SizedBox(width: 4),
                  Text('${course.rating.toStringAsFixed(1)} course rating', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Rating CTA Button
          Row(
            children: [
              Text('${course.reviewCount} total reviews', style: AppTypography.bodySmall.copyWith(color: AppColors.outline)),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.rate_review_outlined, size: 16, color: AppColors.secondary),
                label: const Text('Write a Review', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 12)),
                onPressed: () => _showRatingModal(context, ref, course),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ...reviews.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(radius: 16, backgroundImage: NetworkImage(r['avatar'] as String)),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r['name'] as String, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700)),
                            Text(r['date'] as String, style: AppTypography.labelSmall.copyWith(color: AppColors.outline, fontSize: 10)),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          children: List.generate(
                            r['rating'] as int,
                            (i) => const Icon(Icons.star_rounded, size: 14, color: AppColors.star),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(r['comment'] as String, style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: AppColors.surfaceContainerHigh),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSimilarCourses(BuildContext context, WidgetRef ref, List<CourseModel> similar) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Students also viewed', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final count = constraints.maxWidth >= 700 ? 3 : 1;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: count,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.76,
              ),
              itemCount: similar.length,
              itemBuilder: (context, index) {
                final c = similar[index];
                return CourseCard(
                  course: c,
                  onTap: () => context.go('/course/${c.id}'),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildPricingSidebar(
    BuildContext context,
    WidgetRef ref,
    CourseModel course,
    bool isEnrolled,
    bool isInCart,
    bool isOwnInstructorCourse,
    String userId,
  ) {
    final isFree = course.price == 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: AppColors.surfaceContainerHigh),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pricing
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                isFree ? 'Free' : AppFormatters.formatCurrency(course.price),
                style: AppTypography.displayMedium.copyWith(fontWeight: FontWeight.w800),
              ),
              if (course.originalPrice != null && !isFree) ...[
                const SizedBox(width: 8),
                Text(
                  AppFormatters.formatCurrency(course.originalPrice!),
                  style: AppTypography.bodyMedium.copyWith(
                    decoration: TextDecoration.lineThrough,
                    color: AppColors.outline,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),

          // Action Buttons based on Role and Ownership
          if (isOwnInstructorCourse) ...[
            // INSTRUCTOR VIEW: Edit in builder or view dashboard
            AppButton(
              label: 'Edit in Course Builder',
              variant: ButtonVariant.primary,
              isFullWidth: true,
              icon: Icons.edit,
              onPressed: () => context.go('/builder'),
            ),
            const SizedBox(height: 10),
            AppButton(
              label: 'Instructor Dashboard',
              variant: ButtonVariant.outline,
              isFullWidth: true,
              icon: Icons.dashboard,
              onPressed: () => context.go('/instructor'),
            ),
          ] else if (isEnrolled) ...[
            AppButton(
              label: 'Resume Learning',
              variant: ButtonVariant.secondary,
              isFullWidth: true,
              icon: Icons.play_arrow,
              onPressed: () {
                final firstLessonId = course.syllabus.isNotEmpty && course.syllabus.first.lessons.isNotEmpty
                    ? course.syllabus.first.lessons.first.id
                    : '1';
                context.go('/lesson/${course.id}/$firstLessonId');
              },
            ),
          ] else if (isFree) ...[
            // Free 1-Click Instant Enrollment
            AppButton(
              label: 'Enroll for Free',
              variant: ButtonVariant.primary,
              isFullWidth: true,
              icon: Icons.school,
              onPressed: () async {
                await ref.read(enrolmentProvider.notifier).enroll(course.id, userId);
                if (context.mounted) {
                  AppHelpers.showSnackBar(context, 'Successfully enrolled in ${course.title}!');
                  context.go('/my-learning');
                }
              },
            ),
          ] else ...[
            // Paid Course: Buy Now & Add to Cart
            AppButton(
              label: 'Buy Now',
              variant: ButtonVariant.primary,
              isFullWidth: true,
              icon: Icons.bolt,
              onPressed: () {
                if (!isInCart) {
                  ref.read(cartProvider.notifier).addToCart(course);
                }
                context.go('/checkout');
              },
            ),
            const SizedBox(height: 10),
            AppButton(
              label: isInCart ? 'View in Cart' : 'Add to Cart',
              variant: ButtonVariant.outline,
              isFullWidth: true,
              icon: Icons.shopping_bag_outlined,
              onPressed: () {
                if (!isInCart) {
                  ref.read(cartProvider.notifier).addToCart(course);
                  AppHelpers.showSnackBar(context, 'Added to shopping cart!');
                }
                context.go('/cart');
              },
            ),
          ],
          const SizedBox(height: 24),

          // Course checklist
          Text('This course includes:', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _checklistRow(Icons.ondemand_video, '${course.duration} on-demand video'),
          _checklistRow(Icons.insert_drive_file, 'Full lifetime access & syllabus resources'),
          _checklistRow(Icons.devices, 'Access on mobile, tablet & desktop'),
          _checklistRow(Icons.workspace_premium, 'Certificate of completion'),
        ],
      ),
    );
  }

  Widget _checklistRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.outline),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppTypography.bodySmall)),
        ],
      ),
    );
  }

  Widget _buildLiveClassBanner(
    BuildContext context,
    LiveClassModel liveClass, {
    required bool isEnrolled,
    required bool isInstructor,
  }) {
    final isLive = liveClass.isLive;
    final canJoin = isEnrolled || isInstructor;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isLive ? AppColors.error.withOpacity(0.06) : AppColors.secondaryFixedDim.withOpacity(0.15),
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(
          color: isLive ? AppColors.error : AppColors.secondary,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isLive ? AppColors.error : AppColors.secondary,
                  borderRadius: AppSpacing.roundedFull,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isLive ? 'LIVE NOW' : 'UPCOMING LIVE CLASS',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isLive
                      ? 'Live interactive class is active right now!'
                      : 'Scheduled for ${DateFormat('MMM dd • hh:mm a').format(liveClass.scheduledAt)}',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isLive ? AppColors.error : AppColors.secondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            liveClass.title,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          if (liveClass.description != null && liveClass.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              liveClass.description!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 14),

          // Join button / Enroll CTA
          Row(
            children: [
              if (canJoin)
                AppButton(
                  label: isLive ? 'Join Live Class' : 'Live Class Scheduled',
                  variant: isLive ? ButtonVariant.danger : ButtonVariant.secondary,
                  size: ButtonSize.sm,
                  icon: isLive ? Icons.videocam : Icons.event,
                  onPressed: isLive || isInstructor
                      ? () => context.go('/live-class/${liveClass.id}')
                      : null,
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: AppSpacing.roundedSm,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_outline, size: 16, color: AppColors.outline),
                      const SizedBox(width: 6),
                      Text(
                        'Enroll in this course to join live interactive sessions',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.outline),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
