import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course_model.dart';
import '../utils/constants.dart';
import 'firebase_service.dart';
import 'seed_service.dart';

class CourseService {
  static final List<CourseModel> _locallyCreatedCourses = [];
  static final Map<String, int> _additionalEnrolments = {};
  static final Map<String, List<double>> _additionalRatings = {};
  static List<CourseModel> _baseCourses = [];
  static bool _isSyncingWithFirestore = false;

  /// Returns all available courses from in-memory cache / Firestore / Seed Catalogue
  Future<List<CourseModel>> getCourses() async {
    // 1. If we already have base courses cached in memory, return combined list instantly (0ms delay)
    if (_baseCourses.isNotEmpty) {
      _triggerBackgroundFirestoreSync();
      return _buildCombinedList(_baseCourses);
    }

    // 2. Initial load: Load seed catalogue
    final seedCourses = await SeedService.loadSeedData();
    _baseCourses = seedCourses;

    // 3. Query Firestore if connected
    if (FirebaseService.isInitialized) {
      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection(AppConstants.coursesCollection)
            .get()
            .timeout(const Duration(milliseconds: 1500));

        if (querySnapshot.docs.isNotEmpty) {
          _baseCourses = querySnapshot.docs
              .map((doc) => CourseModel.fromJson(doc.data()))
              .toList();
        } else {
          debugPrint('[CourseService] Firestore courses collection empty, auto-seeding ${seedCourses.length} courses.');
          SeedService.syncToFirestore(seedCourses).catchError((e) {
            debugPrint('[CourseService] Sync to Firestore note: $e');
          });
        }
      } catch (e) {
        debugPrint('[CourseService] Firestore get note: $e. Using verified catalogue.');
      }
    }

    return _buildCombinedList(_baseCourses);
  }

  /// Recomputes merged list from base courses + local courses + dynamic metrics
  static List<CourseModel> _buildCombinedList(List<CourseModel> baseCourses) {
    final combined = <String, CourseModel>{};
    for (final c in _locallyCreatedCourses) {
      combined[c.id] = c;
    }
    for (final c in baseCourses) {
      combined.putIfAbsent(c.id, () => c);
    }

    final result = <CourseModel>[];
    for (final course in combined.values) {
      final extraEnrols = _additionalEnrolments[course.id] ?? 0;
      final ratingsList = _additionalRatings[course.id] ?? [];

      double computedRating = course.rating;
      int computedReviewCount = course.reviewCount;

      if (ratingsList.isNotEmpty) {
        final sumRatings = (course.rating * course.reviewCount) + ratingsList.fold<double>(0.0, (s, r) => s + r);
        computedReviewCount = course.reviewCount + ratingsList.length;
        computedRating = double.parse((sumRatings / computedReviewCount).toStringAsFixed(2));
      }

      final updatedCourse = course.copyWith(
        enrolmentCount: course.enrolmentCount + extraEnrols,
        rating: computedRating,
        reviewCount: computedReviewCount,
      );
      result.add(updatedCourse);
    }
    return result;
  }

  /// Syncs latest Firestore documents in the background without blocking the UI
  void _triggerBackgroundFirestoreSync() {
    if (!FirebaseService.isInitialized || _isSyncingWithFirestore) return;
    _isSyncingWithFirestore = true;

    FirebaseFirestore.instance
        .collection(AppConstants.coursesCollection)
        .get()
        .then((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        _baseCourses = querySnapshot.docs
            .map((doc) => CourseModel.fromJson(doc.data()))
            .toList();
      }
    }).catchError((_) {}).whenComplete(() {
      _isSyncingWithFirestore = false;
    });
  }

  /// Records student enrollment dynamically and syncs with Firestore
  Future<void> recordEnrolment(String courseId) async {
    _additionalEnrolments[courseId] = (_additionalEnrolments[courseId] ?? 0) + 1;
    debugPrint('[CourseService] Recorded enrollment for course $courseId. Total new enrollments: ${_additionalEnrolments[courseId]}');

    if (FirebaseService.isInitialized) {
      try {
        await FirebaseFirestore.instance
            .collection(AppConstants.coursesCollection)
            .doc(courseId)
            .update({'enrolmentCount': FieldValue.increment(1)});
      } catch (e) {
        debugPrint('[CourseService] Firestore enrolment increment note: $e');
      }
    }
  }

  /// Records student course rating dynamically and syncs with Firestore
  Future<void> recordCourseRating(String courseId, double rating) async {
    final list = _additionalRatings.putIfAbsent(courseId, () => []);
    list.add(rating);
    debugPrint('[CourseService] Recorded rating of $rating for course $courseId.');

    if (FirebaseService.isInitialized) {
      try {
        await FirebaseFirestore.instance
            .collection(AppConstants.coursesCollection)
            .doc(courseId)
            .update({
          'reviewCount': FieldValue.increment(1),
        });
      } catch (e) {
        debugPrint('[CourseService] Firestore rating update note: $e');
      }
    }
  }

  /// Publishes a new course to Firestore and memory so all students can immediately enroll
  Future<void> publishCourse(CourseModel course) async {
    _locallyCreatedCourses.removeWhere((c) => c.id == course.id);
    _locallyCreatedCourses.insert(0, course);

    if (FirebaseService.isInitialized) {
      try {
        await FirebaseFirestore.instance
            .collection(AppConstants.coursesCollection)
            .doc(course.id)
            .set(course.toJson());
        debugPrint('[CourseService] Course "${course.title}" (${course.id}) successfully published to Firestore!');
      } catch (e) {
        debugPrint('[CourseService] Firestore course publish note: $e');
      }
    }
  }

  /// Updates an existing course in Firestore and in-memory cache
  Future<void> updateCourse(CourseModel course) async {
    final existingIndex = _locallyCreatedCourses.indexWhere((c) => c.id == course.id);
    if (existingIndex != -1) {
      _locallyCreatedCourses[existingIndex] = course;
    } else {
      _locallyCreatedCourses.insert(0, course);
    }

    if (FirebaseService.isInitialized) {
      try {
        await FirebaseFirestore.instance
            .collection(AppConstants.coursesCollection)
            .doc(course.id)
            .set(course.toJson(), SetOptions(merge: true));
        debugPrint('[CourseService] Course "${course.title}" (${course.id}) successfully updated in Firestore!');
      } catch (e) {
        debugPrint('[CourseService] Firestore course update note: $e');
      }
    }
  }

  Future<CourseModel?> getCourseById(String courseId) async {
    final allCourses = await getCourses();
    try {
      return allCourses.firstWhere((c) => c.id == courseId);
    } catch (_) {
      return null;
    }
  }

  Future<List<CourseModel>> getFeaturedCourses() async {
    final all = await getCourses();
    return all.where((c) => c.isFeatured).toList();
  }

  Future<List<CourseModel>> getTrendingCourses() async {
    final all = await getCourses();
    return all.where((c) => c.isTrending).toList();
  }
}
