import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/course_provider.dart';
import '../styles/colors.dart';
import '../styles/spacing.dart';
import '../styles/typography.dart';
import '../components/Button.dart';
import '../components/Loader.dart';
import '../utils/formatters.dart';
import '../utils/helpers.dart';

class InstructorDashboardScreen extends ConsumerWidget {
  const InstructorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final coursesAsync = ref.watch(allCoursesProvider);
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
              // Header with Switch to Student View and Create Course
              if (isDesktop)
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Instructor Dashboard',
                              style: AppTypography.displayMedium.copyWith(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryFixedDim.withOpacity(0.3),
                                borderRadius: AppSpacing.roundedSm,
                                border: Border.all(color: AppColors.secondary),
                              ),
                              child: Text(
                                'INSTRUCTOR MODE',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Welcome back, ${user?.name ?? 'Instructor'}. Manage your published curriculum, analytics & payouts.',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.videocam, size: 18),
                          label: const Text('Live Classes'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.outlineVariant),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                          ),
                          onPressed: () => context.go('/instructor/live-classes'),
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.school, size: 18),
                          label: const Text('Student View'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.outlineVariant),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                          ),
                          onPressed: () {
                            ref.read(authProvider.notifier).switchRole(UserRole.student);
                            AppHelpers.showSnackBar(context, 'Switched to Student View');
                            context.go('/home');
                          },
                        ),
                        AppButton(
                          label: 'Create Course',
                          variant: ButtonVariant.secondary,
                          icon: Icons.add,
                          onPressed: () => context.go('/builder'),
                        ),
                      ],
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Instructor Dashboard',
                            style: AppTypography.displayMedium.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryFixedDim.withOpacity(0.3),
                            borderRadius: AppSpacing.roundedSm,
                            border: Border.all(color: AppColors.secondary),
                          ),
                          child: Text(
                            'INSTRUCTOR',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Welcome back, ${user?.name ?? 'Instructor'}.',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.videocam, size: 16),
                          label: const Text('Live Classes'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.outlineVariant),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                          onPressed: () => context.go('/instructor/live-classes'),
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.school, size: 16),
                          label: const Text('Student View'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.outlineVariant),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                          onPressed: () {
                            ref.read(authProvider.notifier).switchRole(UserRole.student);
                            AppHelpers.showSnackBar(context, 'Switched to Student View');
                            context.go('/home');
                          },
                        ),
                        AppButton(
                          label: 'Create Course',
                          variant: ButtonVariant.secondary,
                          size: ButtonSize.sm,
                          icon: Icons.add,
                          onPressed: () => context.go('/builder'),
                        ),
                      ],
                    ),
                  ],
                ),
              const SizedBox(height: 24),

              coursesAsync.when(
                data: (allCourses) {
                  // Filter strictly to courses created by this instructor
                  final myCourses = allCourses.where((c) {
                    if (user == null) return false;
                    final matchId = c.instructorId == user.id;
                    final matchName = c.instructor.name.toLowerCase().trim() == user.name.toLowerCase().trim();
                    return matchId || matchName;
                  }).toList();

                  // REAL DATA CALCULATIONS - NO FAKE FALLBACK FIGURES
                  final totalStudents = myCourses.fold<int>(0, (sum, c) => sum + c.enrolmentCount);
                  final totalRevenue = myCourses.fold<double>(0, (sum, c) => sum + (c.enrolmentCount * c.price * 0.85));
                  final avgRating = myCourses.isNotEmpty
                      ? (myCourses.fold<double>(0, (sum, c) => sum + c.rating) / myCourses.length)
                      : 0.0;

                  final kpiCards = [
                    _KpiCard(
                      title: 'Total Earnings',
                      value: AppFormatters.formatCurrency(totalRevenue),
                      icon: Icons.monetization_on,
                      iconColor: AppColors.success,
                      trend: myCourses.isNotEmpty ? '${myCourses.length} active courses' : '0 published courses',
                      onTap: () => context.go('/earnings'),
                    ),
                    _KpiCard(
                      title: 'Total Students',
                      value: AppFormatters.formatCount(totalStudents),
                      icon: Icons.people,
                      iconColor: AppColors.secondary,
                      trend: myCourses.isNotEmpty ? 'Enrolled in your courses' : 'No students yet',
                    ),
                    _KpiCard(
                      title: 'Average Rating',
                      value: myCourses.isNotEmpty ? '${avgRating.toStringAsFixed(1)} ★' : '0.0 ★',
                      icon: Icons.star,
                      iconColor: AppColors.star,
                      trend: myCourses.isNotEmpty ? 'Based on student ratings' : 'No ratings yet',
                    ),
                  ];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Responsive KPI Metric Cards
                      if (isDesktop)
                        Row(
                          children: kpiCards
                              .map((card) => Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 16.0),
                                      child: card,
                                    ),
                                  ))
                              .toList(),
                        )
                      else
                        Column(
                          children: kpiCards
                              .map((card) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12.0),
                                    child: card,
                                  ))
                              .toList(),
                        ),
                      const SizedBox(height: 32),

                      // My Published Courses List
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'My Published Courses (${myCourses.length})',
                            style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w800),
                          ),
                          if (myCourses.isNotEmpty)
                            TextButton.icon(
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add Course'),
                              onPressed: () => context.go('/builder'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (myCourses.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppSpacing.roundedLg,
                            border: Border.all(color: AppColors.surfaceContainerHigh),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryFixedDim.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.school_outlined, size: 48, color: AppColors.secondary),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'You haven’t published any courses yet',
                                style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 480),
                                child: Text(
                                  'Create your curriculum, set your price, and start teaching students globally.',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
                                ),
                              ),
                              const SizedBox(height: 20),
                              AppButton(
                                label: 'Launch Course Builder',
                                variant: ButtonVariant.secondary,
                                icon: Icons.rocket_launch,
                                onPressed: () => context.go('/builder'),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppSpacing.roundedLg,
                            border: Border.all(color: AppColors.surfaceContainerHigh),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: myCourses.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.surfaceContainerHigh),
                            itemBuilder: (context, index) {
                              final course = myCourses[index];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                leading: ClipRRect(
                                  borderRadius: AppSpacing.roundedSm,
                                  child: Image.network(
                                    course.thumbnailUrl,
                                    width: 64,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(width: 64, height: 44, color: AppColors.surfaceContainerLow),
                                  ),
                                ),
                                title: Text(
                                  course.title,
                                  style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  '${course.category} • ${AppFormatters.formatCount(course.enrolmentCount)} students • ${AppFormatters.formatCurrency(course.price)}',
                                  style: AppTypography.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.secondary),
                                      tooltip: 'Edit in Builder',
                                      onPressed: () => context.go('/builder?courseId=${course.id}'),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.visibility_outlined, size: 20, color: AppColors.outline),
                                      tooltip: 'View Course Page',
                                      onPressed: () => context.go('/course/${course.id}'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  );
                },
                loading: () => const Center(child: AppLoader()),
                error: (err, _) => Center(child: Text('Error loading dashboard: $err')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final String trend;
  final VoidCallback? onTap;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.trend,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.roundedLg,
      child: Container(
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
                Text(title, style: AppTypography.labelMedium.copyWith(color: AppColors.outline)),
                Icon(icon, color: iconColor, size: 22),
              ],
            ),
            const SizedBox(height: 10),
            Text(value, style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(trend, style: AppTypography.labelSmall.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
