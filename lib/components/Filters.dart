import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/course_provider.dart';
import '../styles/colors.dart';
import '../styles/spacing.dart';
import '../styles/typography.dart';
import 'Button.dart';

/// Top horizontal Category scroll chips
class CategoryFilterChips extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  const CategoryFilterChips({
    super.key,
    required this.selectedCategory,
    required this.onSelected,
  });

  static const List<String> categories = [
    'All',
    'Mobile Development',
    'Web Development',
    'AI & Data',
    'Cloud Computing',
    'UI/UX Design',
    'Cybersecurity',
    'Business',
  ];

  @override
  Widget build(BuildContext context) {
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
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white,
              labelStyle: AppTypography.labelMedium.copyWith(
                color: isSelected ? Colors.white : AppColors.onSurface,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: AppSpacing.roundedFull,
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.surfaceContainerHigh,
                ),
              ),
              showCheckmark: false,
              onSelected: (_) => onSelected(cat),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Level filter chips (All Levels, Beginner, Intermediate, Advanced)
class LevelFilterChips extends StatelessWidget {
  final String selectedLevel;
  final ValueChanged<String> onSelected;

  const LevelFilterChips({
    super.key,
    required this.selectedLevel,
    required this.onSelected,
  });

  static const List<String> levels = ['All Levels', 'Beginner', 'Intermediate', 'Advanced'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: levels.map((lvl) {
          final isSelected = lvl.toLowerCase() == selectedLevel.toLowerCase();
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(lvl),
              selected: isSelected,
              selectedColor: AppColors.secondaryFixedDim.withOpacity(0.3),
              backgroundColor: Colors.white,
              labelStyle: AppTypography.labelSmall.copyWith(
                color: isSelected ? AppColors.secondary : AppColors.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: AppSpacing.roundedFull,
                side: BorderSide(
                  color: isSelected ? AppColors.secondary : AppColors.surfaceContainerHigh,
                ),
              ),
              showCheckmark: false,
              onSelected: (_) => onSelected(lvl),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Comprehensive Filter Bottom Sheet / Modal
class CourseFiltersModal extends ConsumerWidget {
  const CourseFiltersModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const CourseFiltersModal(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final selectedLevel = ref.watch(selectedLevelProvider);
    final selectedPriceRange = ref.watch(selectedPriceRangeProvider);
    final selectedDuration = ref.watch(selectedDurationProvider);
    final selectedMinRating = ref.watch(selectedMinRatingProvider);
    final selectedLanguage = ref.watch(selectedLanguageProvider);
    final activeCount = ref.watch(activeFiltersCountProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Filter Courses',
                        style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800),
                      ),
                      if (activeCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: AppSpacing.roundedFull,
                          ),
                          child: Text(
                            '$activeCount',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24, color: AppColors.surfaceContainerHigh),

              // Filter Body
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Category
                    _buildSectionHeader('Category'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: CategoryFilterChips.categories.map((cat) {
                        final sel = cat.toLowerCase() == selectedCategory.toLowerCase();
                        return _filterChip(
                          label: cat,
                          isSelected: sel,
                          onSelected: () => ref.read(selectedCategoryProvider.notifier).state = cat,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Level
                    _buildSectionHeader('Difficulty Level'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: LevelFilterChips.levels.map((lvl) {
                        final sel = lvl.toLowerCase() == selectedLevel.toLowerCase();
                        return _filterChip(
                          label: lvl,
                          isSelected: sel,
                          onSelected: () => ref.read(selectedLevelProvider.notifier).state = lvl,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Price Range
                    _buildSectionHeader('Price'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['All', 'Free', 'Under \$30', '\$30 - \$60', '\$60+'].map((p) {
                        final sel = p == selectedPriceRange;
                        return _filterChip(
                          label: p,
                          isSelected: sel,
                          onSelected: () => ref.read(selectedPriceRangeProvider.notifier).state = p,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Duration
                    _buildSectionHeader('Duration'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['All', '< 3 Hours', '3 - 6 Hours', '6+ Hours'].map((d) {
                        final sel = d == selectedDuration;
                        return _filterChip(
                          label: d,
                          isSelected: sel,
                          onSelected: () => ref.read(selectedDurationProvider.notifier).state = d,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Minimum Rating
                    _buildSectionHeader('Minimum Rating'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        {'label': 'All Ratings', 'val': 0.0},
                        {'label': '4.5 ★ & above', 'val': 4.5},
                        {'label': '4.0 ★ & above', 'val': 4.0},
                        {'label': '3.5 ★ & above', 'val': 3.5},
                      ].map((item) {
                        final val = item['val'] as double;
                        final sel = selectedMinRating == val;
                        return _filterChip(
                          label: item['label'] as String,
                          isSelected: sel,
                          onSelected: () => ref.read(selectedMinRatingProvider.notifier).state = val,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Language
                    _buildSectionHeader('Language'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['All', 'English', 'Spanish', 'German', 'French'].map((lang) {
                        final sel = lang.toLowerCase() == selectedLanguage.toLowerCase();
                        return _filterChip(
                          label: lang,
                          isSelected: sel,
                          onSelected: () => ref.read(selectedLanguageProvider.notifier).state = lang,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // Bottom Action Buttons
              const Divider(height: 20, color: AppColors.surfaceContainerHigh),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Reset All',
                      variant: ButtonVariant.outline,
                      onPressed: () {
                        resetAllCourseFilters(ref);
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: AppButton(
                      label: 'Apply Filters',
                      variant: ButtonVariant.primary,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return InkWell(
      onTap: onSelected,
      borderRadius: AppSpacing.roundedFull,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: AppSpacing.roundedFull,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceContainerHigh,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: isSelected ? Colors.white : AppColors.onSurface,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
