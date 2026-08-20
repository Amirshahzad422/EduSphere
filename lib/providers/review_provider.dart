import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/course_model.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';
import '../services/firebase_service.dart';
import '../utils/constants.dart';

final reviewServiceProvider = Provider<ReviewService>((ref) {
  return ReviewService();
});

/// Real-time stream of all reviews for a specific course
final courseReviewsStreamProvider = StreamProvider.family<List<ReviewModel>, String>((ref, courseId) {
  final service = ref.watch(reviewServiceProvider);
  return service.getCourseReviewsStream(courseId);
});

/// Real-time stream of all reviews for an instructor across multiple course IDs
final instructorReviewsStreamProvider = StreamProvider.family<List<ReviewModel>, List<String>>((ref, courseIds) {
  final service = ref.watch(reviewServiceProvider);
  return service.getInstructorReviewsStream(courseIds);
});

/// Real-time stream of courses owned by an instructor for instant KPI reflection
final instructorCoursesRealtimeStreamProvider = StreamProvider.family<List<CourseModel>, String>((ref, instructorId) {
  if (!FirebaseService.isInitialized || Firebase.apps.isEmpty || instructorId.isEmpty) {
    return Stream.value([]);
  }

  return FirebaseFirestore.instance
      .collection(AppConstants.coursesCollection)
      .where('instructorId', isEqualTo: instructorId)
      .snapshots()
      .map((snap) {
    return snap.docs.map((d) => CourseModel.fromJson(d.data())).toList();
  });
});
