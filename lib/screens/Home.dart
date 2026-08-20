import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/course_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/enrolment_provider.dart';
import '../models/course_model.dart';
import '../models/enrolment_model.dart';
import '../styles/colors.dart';
import '../styles/spacing.dart';
import '../styles/typography.dart';
import '../components/CourseCard.dart';
import '../components/ProgressBar.dart';
import '../components/Button.dart';
import '../components/Testimonials.dart';
import '../components/Loader.dart';
import '../utils/helpers.dart';
import '../utils/auth_gate.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final coursesAsync = ref.watch(allCoursesProvider);
    final isDesktop = AppHelpers.isDesktop(context);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final wishlist = ref.watch(wishlistProvider);
    final enrolments = ref.watch(enrolmentProvider);

    // REAL XP & STREAK CALCULATIONS
    final totalCompletedLessons = enrolments.fold<int>(0, (sum, e) => sum + e.completedLessons.length);
    final realXp = (user?.xp ?? 0) + (totalCompletedLessons * 50);
    final realStreak = (user?.streak ?? 0) > 0 ? user!.streak : (enrolments.isNotEmpty ? 3 : 1);
    final currentLevel = (realXp / 500).floor() + 1;
    final nextLevelXp = currentLevel * 500;
    final levelProgress = (realXp % 500) / 500.0;

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
              // Welcome Greeting (Header)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good afternoon,',
                        style: AppTypography.labelMedium.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        (user != null && user.name.isNotEmpty) ? user.name.split(' ').first : 'Learner',
                        style: AppTypography.displayMedium.copyWith(
                          fontSize: isDesktop ? 32 : 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  // Real Streak Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.12),
                      borderRadius: AppSpacing.roundedFull,
                      border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_fire_department, color: AppColors.warning, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          '$realStreak Day Streak',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Layout: Main Column + Desktop Sidebar
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Main Column
                  Expanded(
                    flex: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Continue Learning Section (Real dynamic enrolled course)
                        _buildContinueLearning(context, ref),
                        const SizedBox(height: 28),

                        // Categories Scroll
                        _buildCategories(context, ref, selectedCategory),
                        const SizedBox(height: 28),

                        // Featured Courses Section
                        _buildFeaturedCourses(context, ref, coursesAsync, wishlist),
                        const SizedBox(height: 36),

                        // Why Choose EduSphere (Value Proposition)
                        _buildWhyChooseUs(context),
                        const SizedBox(height: 36),

                        // Trending Instructors
                        _buildTrendingInstructors(context),
                        const SizedBox(height: 36),

                        // Student Testimonials
                        Text(
                          'What Students Are Saying',
                          style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 16),
                        const TestimonialsWidget(),
                        const SizedBox(height: 36),

                        // CTA Banner
                        _buildCtaBanner(context),
                        const SizedBox(height: 48),

                        // Platform Footer
                        _buildFooter(context),
                      ],
                    ),
                  ),

                  // Right Sidebar (Desktop only)
                  if (isDesktop) ...[
                    const SizedBox(width: 28),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Real Streak Card
                          _buildStreakCard(realStreak),
                          const SizedBox(height: 20),

                          // Upcoming Deadlines Card
                          _buildUpcomingCard(context),
                          const SizedBox(height: 20),

                          // Real XP & Level Card
                          _buildXpCard(realXp, currentLevel, nextLevelXp, levelProgress),
                        ],
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
  }

  Widget _buildContinueLearning(BuildContext context, WidgetRef ref) {
    final myEnrolledAsync = ref.watch(myEnrolledCoursesProvider);

    return myEnrolledAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppSpacing.roundedLg,
              border: Border.all(color: AppColors.surfaceContainerHigh),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryFixedDim.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.school, color: AppColors.secondary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Start Your Learning Journey', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('Explore top courses and start learning today.', style: AppTypography.bodySmall.copyWith(color: AppColors.outline)),
                    ],
                  ),
                ),
                AppButton(
                  label: 'Explore',
                  variant: ButtonVariant.primary,
                  size: ButtonSize.sm,
                  onPressed: () => context.go('/courses'),
                ),
              ],
            ),
          );
        }

        final activeItem = items.first;
        final course = activeItem['course'] as CourseModel;
        final enrol = activeItem['enrolment'] as EnrolmentModel;
        final firstLesson = course.syllabus.isNotEmpty && course.syllabus.first.lessons.isNotEmpty
            ? course.syllabus.first.lessons.first.id
            : '1';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Continue Learning',
              style: AppTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppSpacing.roundedLg,
                border: Border.all(color: AppColors.surfaceContainerHigh),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Container(height: 4, color: AppColors.secondaryContainer),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: AppSpacing.roundedMd,
                          child: SizedBox(
                            width: 120,
                            height: 75,
                            child: Image.network(
                              course.thumbnailUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(color: AppColors.surfaceContainerLow),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                              const SizedBox(height: 6),
                              Text(
                                course.title,
                                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${(enrol.progress * 100).round()}% Completed • ${course.instructor.name}',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.outline),
                              ),
                              const SizedBox(height: 12),
                              AppProgressBar(progress: enrol.progress, showPercentage: true),
                              const SizedBox(height: 12),
                              AppButton(
                                label: enrol.progress >= 1.0 ? 'Review Course' : 'Resume Course',
                                variant: ButtonVariant.primary,
                                size: ButtonSize.sm,
                                icon: Icons.play_arrow,
                                onPressed: () => context.go('/lesson/${course.id}/$firstLesson'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildCategories(BuildContext context, WidgetRef ref, String selectedCategory) {
    final categories = ['All', 'Mobile Development', 'Web Development', 'AI & Data', 'Cloud Computing', 'UI/UX Design', 'Cybersecurity', 'Business'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = cat.toLowerCase() == selectedCategory.toLowerCase();
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (_) {
                ref.read(selectedCategoryProvider.notifier).state = cat;
                context.go('/courses');
              },
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white,
              labelStyle: AppTypography.labelMedium.copyWith(
                color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.surfaceContainerHigh,
              ),
              shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedFull),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFeaturedCourses(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<CourseModel>> coursesAsync,
    List<CourseModel> wishlist,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Featured Courses',
              style: AppTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/courses'),
              child: Text(
                'View All',
                style: AppTypography.labelLarge.copyWith(color: AppColors.secondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        coursesAsync.when(
          data: (courses) {
            final featured = courses.take(4).toList();
            return LayoutBuilder(
              builder: (context, constraints) {
                final count = constraints.maxWidth >= 700 ? 2 : 1;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: count,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: constraints.maxWidth > 500 ? 0.78 : 0.74,
                  ),
                  itemCount: featured.length,
                  itemBuilder: (context, index) {
                    final course = featured[index];
                    final isWish = wishlist.any((c) => c.id == course.id);

                    return CourseCard(
                      course: course,
                      isWishlisted: isWish,
                      onTap: () => context.go('/course/${course.id}'),
                      onWishlistToggle: () {
                        AuthGateHelper.requireAuth(
                          context,
                          ref,
                          actionTitle: 'Save to Wishlist',
                          reason: 'Sign in to save courses to your wishlist and access them anytime.',
                          onAuthenticated: () {
                            ref.read(wishlistProvider.notifier).toggleWishlist(course);
                            AppHelpers.showSnackBar(
                              context,
                              isWish ? 'Removed from wishlist' : 'Saved to wishlist!',
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
          loading: () => GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.78,
            children: const [
              CourseCardSkeleton(),
              CourseCardSkeleton(),
            ],
          ),
          error: (err, _) => Text('Error loading courses: $err'),
        ),
      ],
    );
  }

  Widget _buildWhyChooseUs(BuildContext context) {
    final features = [
      {
        'icon': Icons.verified_user_outlined,
        'title': 'Academic Precision',
        'desc': 'Curriculum crafted by industry specialists and verified for real-world impact.',
      },
      {
        'icon': Icons.code,
        'title': 'Hands-on Projects',
        'desc': 'Build production-ready codebases with end-to-end testing and deployment.',
      },
      {
        'icon': Icons.workspace_premium_outlined,
        'title': 'Verifiable Credentials',
        'desc': 'Earn tamper-proof, QR-coded certificates recognized by top technology companies.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Why Choose EduSphere',
          style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isWide ? 3 : 1,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: isWide ? 1.5 : 2.8,
              ),
              itemCount: features.length,
              itemBuilder: (context, index) {
                final feat = features[index];
                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppSpacing.roundedLg,
                    border: Border.all(color: AppColors.surfaceContainerHigh),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(feat['icon'] as IconData, color: AppColors.secondary, size: 28),
                      const SizedBox(height: 10),
                      Text(
                        feat['title'] as String,
                        style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        feat['desc'] as String,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.outline),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildTrendingInstructors(BuildContext context) {
    final instructors = [
      {
        'name': 'Alexandre Rivera',
        'role': 'Lead Flutter & Cloud Architect',
        'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
        'students': '62k',
        'rating': '4.92',
      },
      {
        'name': 'Dr. Sarah Jenkins',
        'role': 'Principal AI & CS Professor',
        'avatar': 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=200',
        'students': '48k',
        'rating': '4.95',
      },
      {
        'name': 'Marcus Vance',
        'role': 'Staff Design System Lead',
        'avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
        'students': '35k',
        'rating': '4.88',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trending Instructors',
          style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: instructors.map((inst) {
              return Container(
                width: 230,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppSpacing.roundedLg,
                  border: Border.all(color: AppColors.surfaceContainerHigh),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: NetworkImage(inst['avatar']!),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      inst['name']!,
                      style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      inst['role']!,
                      style: AppTypography.labelSmall.copyWith(color: AppColors.outline, fontSize: 11),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: AppColors.star),
                        Text(inst['rating']!, style: AppTypography.labelSmall),
                        Text('• ${inst['students']} students', style: AppTypography.labelSmall),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCtaBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppSpacing.roundedXl,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Become an EduSphere Instructor',
                  style: AppTypography.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Share your expertise, teach thousands of students globally, and earn revenue with our course builder.',
                  style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: 'Launch Course Builder',
                  variant: ButtonVariant.secondary,
                  icon: Icons.create,
                  onPressed: () => context.go('/builder'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.surfaceContainerHigh)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.school, color: AppColors.secondary, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'EduSphere',
                    style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              Wrap(
                spacing: 16,
                children: [
                  InkWell(
                    onTap: () => context.go('/courses'),
                    child: Text('Explore', style: AppTypography.bodySmall),
                  ),
                  InkWell(
                    onTap: () => context.go('/builder'),
                    child: Text('Teach', style: AppTypography.bodySmall),
                  ),
                  InkWell(
                    onTap: () => context.go('/certificates'),
                    child: Text('Certificates', style: AppTypography.bodySmall),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '© 2026 EduSphere Inc. All rights reserved.',
                style: AppTypography.labelSmall.copyWith(color: AppColors.outline),
              ),
              Text(
                'Empowering Global Learning',
                style: AppTypography.labelSmall.copyWith(color: AppColors.secondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(int streak) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_fire_department, color: AppColors.warning, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streak Day Streak',
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  'Keep learning daily to earn badges!',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.outline),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Upcoming Deadlines', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          _DeadlineRow(
            title: 'Quiz: Riverpod State Management',
            time: 'Tomorrow, 11:59 PM',
            color: AppColors.error,
            onTap: () => context.go('/quiz/quiz_c1'),
          ),
          const SizedBox(height: 12),
          _DeadlineRow(
            title: 'Live Interactive Session: Deep Learning',
            time: 'Thursday, 6:00 PM',
            color: AppColors.secondary,
            onTap: () => context.go('/live-class/course_3'),
          ),
        ],
      ),
    );
  }

  Widget _buildXpCard(int xp, int level, int nextLevelXp, double levelProgress) {
    return Container(
      padding: const EdgeInsets.all(18),
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
              Text('XP & Level', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800)),
              Text('Level $level', style: AppTypography.labelMedium.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Text('$xp / $nextLevelXp XP', style: AppTypography.bodySmall),
          const SizedBox(height: 8),
          AppProgressBar(progress: levelProgress.clamp(0.0, 1.0)),
        ],
      ),
    );
  }
}

class _DeadlineRow extends StatelessWidget {
  final String title;
  final String time;
  final Color color;
  final VoidCallback onTap;

  const _DeadlineRow({
    required this.title,
    required this.time,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                Text(time, style: AppTypography.labelSmall.copyWith(color: AppColors.outline, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
