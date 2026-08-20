import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/enrolment_provider.dart';
import '../providers/course_provider.dart';
import '../providers/cart_provider.dart';
import '../models/course_model.dart';
import '../models/enrolment_model.dart';
import '../models/live_class_model.dart';
import '../providers/live_class_provider.dart';
import '../styles/colors.dart';
import '../styles/spacing.dart';
import '../styles/typography.dart';
import '../components/ProgressBar.dart';
import '../components/Button.dart';
import '../components/Loader.dart';
import '../utils/helpers.dart';

class MyLearningScreen extends ConsumerStatefulWidget {
  const MyLearningScreen({super.key});

  @override
  ConsumerState<MyLearningScreen> createState() => _MyLearningScreenState();
}

class _MyLearningScreenState extends ConsumerState<MyLearningScreen> {
  int _selectedTabIndex = 0; // 0: In Progress, 1: Completed, 2: Wishlist

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'mobile development':
      case 'web development':
        return Icons.code;
      case 'design':
      case 'ui/ux design':
        return Icons.brush;
      case 'ai & data':
      case 'data science':
        return Icons.data_object;
      case 'cloud & devops':
        return Icons.cloud_queue;
      default:
        return Icons.school_outlined;
    }
  }

  String _formatLastWatched(DateTime? date) {
    if (date == null) return 'Recently';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    final myEnrolledAsync = ref.watch(myEnrolledCoursesProvider);
    final allCoursesAsync = ref.watch(allCoursesProvider);
    final wishlist = ref.watch(wishlistProvider);
    final isDesktop = AppHelpers.isDesktop(context);
    final allLiveClasses = ref.watch(allLiveClassesStreamProvider).value ?? [];

    final activeEnrolledLiveClasses = allLiveClasses.where((lc) {
      if (!lc.isLive) return false;
      return ref.read(enrolmentProvider.notifier).isEnrolled(lc.courseId);
    }).toList();

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
                'My Learning',
                style: AppTypography.displayMedium.copyWith(
                  fontSize: isDesktop ? 34 : 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Track your enrolled courses, certifications, and active learning milestones.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 20),

              // Hero Live Session Banner (if an enrolled course has a live session right now)
              if (activeEnrolledLiveClasses.isNotEmpty) ...[
                _buildLiveHeroBanner(context, activeEnrolledLiveClasses.first),
                const SizedBox(height: 20),
              ],

              // Stitch Navigation Tabs (In Progress, Completed, Wishlist)
              Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.surfaceContainerHigh)),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _tabButton('In Progress', 0),
                      SizedBox(width: isDesktop ? 24 : 16),
                      _tabButton('Completed', 1),
                      SizedBox(width: isDesktop ? 24 : 16),
                      _tabButton('Wishlist (${wishlist.length})', 2),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Tab 0 & 1: Enrolled Courses (In Progress / Completed)
              if (_selectedTabIndex == 0 || _selectedTabIndex == 1)
                myEnrolledAsync.when(
                  data: (items) {
                    var filtered = items.where((item) {
                      final enrol = item['enrolment'] as EnrolmentModel;
                      if (_selectedTabIndex == 0) return enrol.progress < 1.0;
                      if (_selectedTabIndex == 1) return enrol.progress >= 1.0;
                      return true;
                    }).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 60.0),
                          child: Column(
                            children: [
                              Icon(
                                _selectedTabIndex == 1 ? Icons.emoji_events_outlined : Icons.school_outlined,
                                size: 64,
                                color: AppColors.outline,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _selectedTabIndex == 1 ? 'No completed courses yet' : 'No courses in progress',
                                style: AppTypography.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _selectedTabIndex == 1
                                    ? 'Keep learning to complete your courses and earn verifiable certificates!'
                                    : 'Explore our rich catalogue of top-tier courses and start learning today.',
                                style: AppTypography.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              AppButton(
                                label: 'Explore Catalogue',
                                variant: ButtonVariant.primary,
                                onPressed: () => context.go('/courses'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // Bento Grid Layout
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth > 900
                            ? 3
                            : (constraints.maxWidth > 600 ? 2 : 1);

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                            mainAxisExtent: 310,
                          ),
                          itemBuilder: (context, index) {
                            final course = filtered[index]['course'] as CourseModel;
                            final enrol = filtered[index]['enrolment'] as EnrolmentModel;
                            final isCompleted = enrol.progress >= 1.0;

                            // Determine resume lesson id
                            final resumeLessonId = enrol.lastLessonId ??
                                (course.syllabus.isNotEmpty && course.syllabus.first.lessons.isNotEmpty
                                    ? course.syllabus.first.lessons.first.id
                                    : '1');

                            final activeLiveForCourse = allLiveClasses.where((lc) => lc.courseId == course.id && lc.isLive).toList();
                            final hasLiveClass = activeLiveForCourse.isNotEmpty;
                            final activeLiveClass = hasLiveClass ? activeLiveForCourse.first : null;

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: AppSpacing.roundedLg,
                                border: Border.all(
                                  color: hasLiveClass ? AppColors.error : AppColors.surfaceContainerHigh,
                                  width: hasLiveClass ? 1.5 : 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: hasLiveClass ? AppColors.error.withOpacity(0.08) : AppColors.cardShadow,
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Stack(
                                children: [
                                  // Top Accent Color Line (Stitch UI)
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    right: 0,
                                    height: 4,
                                    child: Container(
                                      color: hasLiveClass
                                          ? AppColors.error
                                          : (isCompleted ? AppColors.success : AppColors.secondary),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        // Header Row: Icon & Level / Live Badge
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: hasLiveClass
                                                    ? AppColors.error.withOpacity(0.1)
                                                    : AppColors.surfaceContainerLow,
                                                borderRadius: AppSpacing.roundedMd,
                                              ),
                                              child: Icon(
                                                hasLiveClass ? Icons.videocam : _getCategoryIcon(course.category),
                                                color: hasLiveClass ? AppColors.error : AppColors.secondary,
                                                size: 24,
                                              ),
                                            ),
                                            if (hasLiveClass)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: AppColors.error,
                                                  borderRadius: AppSpacing.roundedFull,
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      width: 6,
                                                      height: 6,
                                                      decoration: const BoxDecoration(
                                                        color: Colors.white,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'LIVE NOW',
                                                      style: AppTypography.labelSmall.copyWith(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w900,
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            else
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: AppColors.secondary.withOpacity(0.12),
                                                  borderRadius: AppSpacing.roundedFull,
                                                ),
                                                child: Text(
                                                  course.level,
                                                  style: AppTypography.labelSmall.copyWith(
                                                    color: AppColors.secondary,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),

                                        // Course Title & Subtitle
                                        Text(
                                          course.title,
                                          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Instructor: ${course.instructor.name}',
                                          style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const Spacer(),

                                        // Progress Row & Bar
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${(enrol.progress * 100).round()}% complete',
                                              style: AppTypography.labelSmall.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: isCompleted ? AppColors.success : AppColors.secondary,
                                              ),
                                            ),
                                            Text(
                                              'Last watched: ${_formatLastWatched(enrol.lastAccessedAt)}',
                                              style: AppTypography.labelSmall.copyWith(color: AppColors.outline),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        AppProgressBar(
                                          progress: enrol.progress,
                                          showPercentage: false,
                                          height: 5,
                                        ),
                                        const SizedBox(height: 16),

                                        // Action Buttons
                                        if (hasLiveClass) ...[
                                          SizedBox(
                                            width: double.infinity,
                                            child: AppButton(
                                              label: '🔴 Join Live Class',
                                              variant: ButtonVariant.danger,
                                              size: ButtonSize.md,
                                              icon: Icons.videocam_rounded,
                                              onPressed: () {
                                                context.go('/live-class/${activeLiveClass!.id}');
                                              },
                                            ),
                                          ),
                                        ] else ...[
                                          Row(
                                            children: [
                                              Expanded(
                                                child: AppButton(
                                                  label: isCompleted ? 'Certificate 🎓' : 'Resume',
                                                  variant: isCompleted ? ButtonVariant.secondary : ButtonVariant.primary,
                                                  size: ButtonSize.md,
                                                  icon: isCompleted ? Icons.workspace_premium : Icons.play_arrow,
                                                  onPressed: () {
                                                    if (isCompleted) {
                                                      context.go('/certificates');
                                                    } else {
                                                      context.go('/lesson/${course.id}/$resumeLessonId');
                                                    }
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              if (isCompleted)
                                                IconButton(
                                                  icon: const Icon(Icons.play_circle_outline, color: AppColors.secondary),
                                                  tooltip: 'Review Lessons',
                                                  onPressed: () => context.go('/lesson/${course.id}/$resumeLessonId'),
                                                ),
                                              IconButton(
                                                icon: const Icon(Icons.star_rate_rounded, color: AppColors.star),
                                                tooltip: 'Rate & Review Course',
                                                onPressed: () => context.go('/course/${course.id}'),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: AppLoader()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                ),

              // Tab 2: Wishlist Courses
              if (_selectedTabIndex == 2)
                allCoursesAsync.when(
                  data: (allCourses) {
                    final wishlistedCourses = wishlist;

                    if (wishlistedCourses.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 60.0),
                          child: Column(
                            children: [
                              const Icon(Icons.favorite_border, size: 64, color: AppColors.outline),
                              const SizedBox(height: 16),
                              Text('Your wishlist is empty', style: AppTypography.titleLarge),
                              const SizedBox(height: 8),
                              Text('Explore courses and save ones you like to your wishlist.', style: AppTypography.bodyMedium),
                              const SizedBox(height: 16),
                              AppButton(
                                label: 'Explore Catalogue',
                                variant: ButtonVariant.primary,
                                onPressed: () => context.go('/courses'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: wishlistedCourses.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final course = wishlistedCourses[index];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppSpacing.roundedLg,
                            border: Border.all(color: AppColors.surfaceContainerHigh),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: AppSpacing.roundedMd,
                                child: SizedBox(
                                  width: 100,
                                  height: 70,
                                  child: AppHelpers.buildCachedImage(
                                    imageUrl: course.thumbnailUrl,
                                    width: 100,
                                    height: 70,
                                    fit: BoxFit.cover,
                                    memCacheWidth: 250,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(course.category, style: AppTypography.labelSmall.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w700)),
                                    Text(course.title, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800), maxLines: 1),
                                    Text('\$${course.price.toStringAsFixed(2)}', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                              AppButton(
                                label: 'View Details',
                                variant: ButtonVariant.primary,
                                size: ButtonSize.sm,
                                onPressed: () => context.go('/course/${course.id}'),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: AppLoader()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.secondary : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelLarge.copyWith(
            color: isSelected ? AppColors.secondary : AppColors.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLiveHeroBanner(BuildContext context, LiveClassModel liveClass) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.06),
        borderRadius: AppSpacing.roundedXl,
        border: Border.all(color: AppColors.error, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 480;

          final iconWidget = Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.videocam_rounded, color: AppColors.error, size: 24),
          );

          final detailsWidget = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: AppSpacing.roundedFull,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'LIVE NOW',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Live class in session for your enrolled curriculum!',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                liveClass.title,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );

          final joinButton = AppButton(
            label: 'Join Live Room',
            variant: ButtonVariant.danger,
            size: isCompact ? ButtonSize.sm : ButtonSize.md,
            isFullWidth: isCompact,
            icon: Icons.play_arrow_rounded,
            onPressed: () => context.go('/live-class/${liveClass.id}'),
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    iconWidget,
                    const SizedBox(width: 10),
                    Expanded(child: detailsWidget),
                  ],
                ),
                const SizedBox(height: 12),
                joinButton,
              ],
            );
          }

          return Row(
            children: [
              iconWidget,
              const SizedBox(width: 14),
              Expanded(child: detailsWidget),
              const SizedBox(width: 14),
              joinButton,
            ],
          );
        },
      ),
    );
  }
}
