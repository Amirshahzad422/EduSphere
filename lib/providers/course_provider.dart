import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/course_model.dart';
import '../services/course_service.dart';

final courseServiceProvider = Provider<CourseService>((ref) {
  return CourseService();
});

final courseRefreshCounterProvider = StateProvider<int>((ref) => 0);

final allCoursesProvider = FutureProvider<List<CourseModel>>((ref) async {
  ref.watch(courseRefreshCounterProvider);
  final service = ref.watch(courseServiceProvider);
  return await service.getCourses();
});

final courseByIdProvider = FutureProvider.family<CourseModel?, String>((ref, id) async {
  ref.watch(courseRefreshCounterProvider);
  final service = ref.watch(courseServiceProvider);
  return await service.getCourseById(id);
});

// Filter & Search State Providers
final selectedCategoryProvider = StateProvider<String>((ref) => 'All');
final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedLevelProvider = StateProvider<String>((ref) => 'All Levels');
final selectedPriceRangeProvider = StateProvider<String>((ref) => 'All'); // All, Free, Under $30, $30 - $60, $60+
final selectedDurationProvider = StateProvider<String>((ref) => 'All'); // All, < 3 Hours, 3 - 6 Hours, 6+ Hours
final selectedMinRatingProvider = StateProvider<double>((ref) => 0.0); // 0.0 (All), 4.5, 4.0, 3.5
final selectedLanguageProvider = StateProvider<String>((ref) => 'All'); // All, English, Spanish, German, French
final sortByProvider = StateProvider<String>((ref) => 'Popular'); // Popular, Rating, Newest, PriceLow, PriceHigh

// View Mode & Pagination State Providers
final isCourseGridViewProvider = StateProvider<bool>((ref) => true);
final currentPageProvider = StateProvider<int>((ref) => 1);
final itemsPerPageProvider = StateProvider<int>((ref) => 6);

/// Count of active non-default filters
final activeFiltersCountProvider = Provider<int>((ref) {
  int count = 0;
  if (ref.watch(selectedCategoryProvider) != 'All') count++;
  if (ref.watch(searchQueryProvider).trim().isNotEmpty) count++;
  if (ref.watch(selectedLevelProvider) != 'All Levels') count++;
  if (ref.watch(selectedPriceRangeProvider) != 'All') count++;
  if (ref.watch(selectedDurationProvider) != 'All') count++;
  if (ref.watch(selectedMinRatingProvider) > 0.0) count++;
  if (ref.watch(selectedLanguageProvider) != 'All') count++;
  return count;
});

/// Helper function to reset all filter values
void resetAllCourseFilters(WidgetRef ref) {
  ref.read(selectedCategoryProvider.notifier).state = 'All';
  ref.read(searchQueryProvider.notifier).state = '';
  ref.read(selectedLevelProvider.notifier).state = 'All Levels';
  ref.read(selectedPriceRangeProvider.notifier).state = 'All';
  ref.read(selectedDurationProvider.notifier).state = 'All';
  ref.read(selectedMinRatingProvider.notifier).state = 0.0;
  ref.read(selectedLanguageProvider.notifier).state = 'All';
  ref.read(sortByProvider.notifier).state = 'Popular';
  ref.read(currentPageProvider.notifier).state = 1;
}

/// Helper function to parse hours from duration strings like "12 hours", "2h 30m", "45 mins"
double _parseDurationHours(String durationStr) {
  final lower = durationStr.toLowerCase();
  final numMatch = RegExp(r'(\d+(\.\d+)?)').firstMatch(lower);
  if (numMatch == null) return 5.0; // default fallback

  final val = double.tryParse(numMatch.group(1) ?? '0') ?? 0.0;
  if (lower.contains('min')) {
    return val / 60.0;
  }
  return val;
}

final filteredCoursesProvider = Provider<AsyncValue<List<CourseModel>>>((ref) {
  final coursesAsync = ref.watch(allCoursesProvider);
  final category = ref.watch(selectedCategoryProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();
  final level = ref.watch(selectedLevelProvider);
  final priceRange = ref.watch(selectedPriceRangeProvider);
  final duration = ref.watch(selectedDurationProvider);
  final minRating = ref.watch(selectedMinRatingProvider);
  final language = ref.watch(selectedLanguageProvider);
  final sortBy = ref.watch(sortByProvider);

  return coursesAsync.whenData((courses) {
    var filtered = courses.where((course) {
      // Category filter
      final matchesCategory = category == 'All' ||
          course.category.toLowerCase() == category.toLowerCase();

      // Search query filter
      final matchesQuery = query.isEmpty ||
          course.title.toLowerCase().contains(query) ||
          course.instructor.name.toLowerCase().contains(query) ||
          course.category.toLowerCase().contains(query) ||
          course.subtitle.toLowerCase().contains(query);

      // Level filter
      final matchesLevel = level == 'All Levels' ||
          course.level.toLowerCase() == level.toLowerCase();

      // Price range filter
      bool matchesPrice = true;
      if (priceRange == 'Free') {
        matchesPrice = course.price == 0.0;
      } else if (priceRange == 'Under \$30') {
        matchesPrice = course.price > 0 && course.price < 30.0;
      } else if (priceRange == '\$30 - \$60') {
        matchesPrice = course.price >= 30.0 && course.price <= 60.0;
      } else if (priceRange == '\$60+') {
        matchesPrice = course.price > 60.0;
      }

      // Duration filter
      bool matchesDuration = true;
      final parsedHours = _parseDurationHours(course.duration);
      if (duration == '< 3 Hours') {
        matchesDuration = parsedHours < 3.0;
      } else if (duration == '3 - 6 Hours') {
        matchesDuration = parsedHours >= 3.0 && parsedHours <= 6.0;
      } else if (duration == '6+ Hours') {
        matchesDuration = parsedHours > 6.0;
      }

      // Rating filter
      final matchesRating = minRating == 0.0 || course.rating >= minRating;

      // Language filter
      final matchesLanguage = language == 'All' ||
          course.language.toLowerCase() == language.toLowerCase();

      return matchesCategory &&
          matchesQuery &&
          matchesLevel &&
          matchesPrice &&
          matchesDuration &&
          matchesRating &&
          matchesLanguage;
    }).toList();

    // Sorting
    switch (sortBy) {
      case 'PriceLow':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'PriceHigh':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Rating':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Newest':
        filtered.sort((a, b) {
          final aDate = a.updatedAt ?? DateTime(2025);
          final bDate = b.updatedAt ?? DateTime(2025);
          return bDate.compareTo(aDate);
        });
        break;
      case 'Popular':
      default:
        filtered.sort((a, b) => b.enrolmentCount.compareTo(a.enrolmentCount));
        break;
    }

    return filtered;
  });
});

/// Paginated slice of the filtered courses list
final paginatedCoursesProvider = Provider<AsyncValue<List<CourseModel>>>((ref) {
  final filteredAsync = ref.watch(filteredCoursesProvider);
  final currentPage = ref.watch(currentPageProvider);
  final itemsPerPage = ref.watch(itemsPerPageProvider);

  return filteredAsync.whenData((courses) {
    final startIndex = (currentPage - 1) * itemsPerPage;
    if (startIndex >= courses.length) {
      if (courses.isEmpty) return [];
      return courses.take(itemsPerPage).toList();
    }
    return courses.skip(startIndex).take(itemsPerPage).toList();
  });
});
