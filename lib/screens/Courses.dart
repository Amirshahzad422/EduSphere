import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/course_provider.dart';
import '../providers/cart_provider.dart';
import '../styles/colors.dart';
import '../styles/spacing.dart';
import '../styles/typography.dart';
import '../components/CourseCard.dart';
import '../components/SearchBar.dart';
import '../components/Filters.dart';
import '../components/Loader.dart';
import '../components/Button.dart';
import '../utils/helpers.dart';
import '../utils/auth_gate.dart';

class CoursesScreen extends ConsumerStatefulWidget {
  const CoursesScreen({super.key});

  @override
  ConsumerState<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends ConsumerState<CoursesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final isInstructor = user?.role == UserRole.instructor;
    final allFilteredCoursesAsync = ref.watch(filteredCoursesProvider);
    final paginatedCoursesAsync = ref.watch(paginatedCoursesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final selectedLevel = ref.watch(selectedLevelProvider);
    final selectedPriceRange = ref.watch(selectedPriceRangeProvider);
    final selectedDuration = ref.watch(selectedDurationProvider);
    final selectedMinRating = ref.watch(selectedMinRatingProvider);
    final selectedLanguage = ref.watch(selectedLanguageProvider);
    final sortBy = ref.watch(sortByProvider);
    final isGridView = ref.watch(isCourseGridViewProvider);
    final currentPage = ref.watch(currentPageProvider);
    final itemsPerPage = ref.watch(itemsPerPageProvider);
    final activeFiltersCount = ref.watch(activeFiltersCountProvider);
    final wishlist = ref.watch(wishlistProvider);
    final isDesktop = AppHelpers.isDesktop(context);
    final homeTarget = isInstructor ? '/instructor' : '/home';

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
                onTap: () => context.go(homeTarget),
                borderRadius: AppSpacing.roundedMd,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 2.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back, size: 18, color: AppColors.secondary),
                      const SizedBox(width: 8),
                      Text(
                        isInstructor ? 'Back to Dashboard' : 'Back to Home',
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

              // Header
              Text(
                'Explore Courses',
                style: AppTypography.displayMedium.copyWith(
                  fontSize: isDesktop ? 32 : 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Discover top-tier programs taught by leading industry specialists.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 20),

              // Search Bar & Controls Row
              Row(
                children: [
                  Expanded(
                    child: AppSearchBar(
                      controller: _searchController,
                      onChanged: (val) {
                        ref.read(searchQueryProvider.notifier).state = val;
                        ref.read(currentPageProvider.notifier).state = 1;
                      },
                      onFilterTap: () => CourseFiltersModal.show(context),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Filter Modal Button with Active Count Badge
                  ElevatedButton.icon(
                    onPressed: () => CourseFiltersModal.show(context),
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.tune, size: 18, color: AppColors.primary),
                        if (activeFiltersCount > 0)
                          Positioned(
                            top: -6,
                            right: -6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.secondary,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$activeFiltersCount',
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    ),
                    label: Text(
                      'Filters',
                      style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSpacing.roundedMd,
                        side: const BorderSide(color: AppColors.surfaceContainerHigh),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Grid / List View Toggle
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppSpacing.roundedMd,
                      border: Border.all(color: AppColors.surfaceContainerHigh),
                    ),
                    child: IconButton(
                      icon: Icon(
                        isGridView ? Icons.view_list : Icons.grid_view,
                        color: AppColors.onSurfaceVariant,
                      ),
                      onPressed: () {
                        ref.read(isCourseGridViewProvider.notifier).state = !isGridView;
                      },
                      tooltip: isGridView ? 'Switch to List View' : 'Switch to Grid View',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Category Filter Chips
              CategoryFilterChips(
                selectedCategory: selectedCategory,
                onSelected: (cat) {
                  ref.read(selectedCategoryProvider.notifier).state = cat;
                  ref.read(currentPageProvider.notifier).state = 1;
                },
              ),
              const SizedBox(height: 14),

              // Sub-controls: Level Chips & Sort Dropdown
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Level filter
                  Flexible(
                    child: LevelFilterChips(
                      selectedLevel: selectedLevel,
                      onSelected: (lvl) {
                        ref.read(selectedLevelProvider.notifier).state = lvl;
                        ref.read(currentPageProvider.notifier).state = 1;
                      },
                    ),
                  ),

                  // Sort Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppSpacing.roundedMd,
                      border: Border.all(color: AppColors.surfaceContainerHigh),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: sortBy,
                        style: AppTypography.labelSmall.copyWith(color: AppColors.onSurface),
                        icon: const Icon(Icons.sort, size: 16, color: AppColors.onSurfaceVariant),
                        items: const [
                          DropdownMenuItem(value: 'Popular', child: Text('Most Popular')),
                          DropdownMenuItem(value: 'Rating', child: Text('Highest Rated')),
                          DropdownMenuItem(value: 'Newest', child: Text('Newest Releases')),
                          DropdownMenuItem(value: 'PriceLow', child: Text('Price: Low to High')),
                          DropdownMenuItem(value: 'PriceHigh', child: Text('Price: High to Low')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            ref.read(sortByProvider.notifier).state = val;
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),

              // Active Filters Bar (When filters are active)
              if (activeFiltersCount > 0) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('Active Filters:', style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w700)),
                    if (selectedCategory != 'All')
                      _activeTag(selectedCategory, () => ref.read(selectedCategoryProvider.notifier).state = 'All'),
                    if (selectedLevel != 'All Levels')
                      _activeTag(selectedLevel, () => ref.read(selectedLevelProvider.notifier).state = 'All Levels'),
                    if (selectedPriceRange != 'All')
                      _activeTag(selectedPriceRange, () => ref.read(selectedPriceRangeProvider.notifier).state = 'All'),
                    if (selectedDuration != 'All')
                      _activeTag(selectedDuration, () => ref.read(selectedDurationProvider.notifier).state = 'All'),
                    if (selectedMinRating > 0.0)
                      _activeTag('$selectedMinRating★+', () => ref.read(selectedMinRatingProvider.notifier).state = 0.0),
                    if (selectedLanguage != 'All')
                      _activeTag(selectedLanguage, () => ref.read(selectedLanguageProvider.notifier).state = 'All'),
                    TextButton(
                      onPressed: () => resetAllCourseFilters(ref),
                      child: const Text('Clear all', style: TextStyle(fontSize: 12, color: AppColors.error)),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),

              // Courses List / Grid
              paginatedCoursesAsync.when(
                data: (courses) {
                  final totalCoursesCount = allFilteredCoursesAsync.asData?.value.length ?? 0;

                  if (totalCoursesCount == 0) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 64.0),
                        child: Column(
                          children: [
                            const Icon(Icons.search_off, size: 64, color: AppColors.outline),
                            const SizedBox(height: 16),
                            Text('No matching courses found', style: AppTypography.titleLarge),
                            const SizedBox(height: 6),
                            Text(
                              'Try adjusting your search query or removing some filters.',
                              style: AppTypography.bodyMedium.copyWith(color: AppColors.outline),
                            ),
                            const SizedBox(height: 20),
                            AppButton(
                              label: 'Reset All Filters',
                              variant: ButtonVariant.primary,
                              onPressed: () => resetAllCourseFilters(ref),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final totalPages = (totalCoursesCount / itemsPerPage).ceil();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Course Count Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Showing ${courses.length} of $totalCoursesCount courses',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Grid vs List Render
                      if (isGridView)
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
                                    : (constraints.maxWidth > 500 ? 0.75 : 0.70),
                              ),
                              itemCount: courses.length,
                              itemBuilder: (context, index) {
                                final course = courses[index];
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
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: courses.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final course = courses[index];
                            final isWish = wishlist.any((c) => c.id == course.id);
                            return CourseListCard(
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
                        ),
                      const SizedBox(height: 32),

                      // Pagination Controls
                      if (totalPages > 1)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: currentPage > 1
                                  ? () => ref.read(currentPageProvider.notifier).state--
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            for (int p = 1; p <= totalPages; p++)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: InkWell(
                                  onTap: () => ref.read(currentPageProvider.notifier).state = p,
                                  borderRadius: AppSpacing.roundedMd,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: currentPage == p ? AppColors.primary : Colors.white,
                                      borderRadius: AppSpacing.roundedMd,
                                      border: Border.all(
                                        color: currentPage == p ? AppColors.primary : AppColors.surfaceContainerHigh,
                                      ),
                                    ),
                                    child: Text(
                                      '$p',
                                      style: TextStyle(
                                        color: currentPage == p ? Colors.white : AppColors.onSurface,
                                        fontWeight: currentPage == p ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: currentPage < totalPages
                                  ? () => ref.read(currentPageProvider.notifier).state++
                                  : null,
                            ),
                          ],
                        ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
                loading: () => isGridView
                    ? GridView.count(
                        crossAxisCount: isDesktop ? 3 : 2,
                        shrinkWrap: true,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.78,
                        children: const [
                          CourseCardSkeleton(),
                          CourseCardSkeleton(),
                          CourseCardSkeleton(),
                          CourseCardSkeleton(),
                        ],
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: 4,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (_, __) => const CourseListCardSkeleton(),
                      ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text('Error loading courses: $err'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _activeTag(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.secondaryFixedDim.withOpacity(0.25),
        borderRadius: AppSpacing.roundedFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: AppColors.secondary),
          ),
        ],
      ),
    );
  }
}
