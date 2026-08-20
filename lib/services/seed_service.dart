import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course_model.dart';
import '../utils/constants.dart';
import 'firebase_service.dart';

class SeedService {
  static List<CourseModel> _cachedCourses = [];
  static List<InstructorInfo> _cachedInstructors = [];

  static List<CourseModel> get cachedCourses => List.unmodifiable(_cachedCourses);
  static List<InstructorInfo> get cachedInstructors => List.unmodifiable(_cachedInstructors);

  /// Loads mock courses from course_seed.json and seeds Firestore if connected
  static Future<List<CourseModel>> loadSeedData() async {
    if (_cachedCourses.isNotEmpty) return _cachedCourses;

    try {
      final jsonString = await rootBundle.loadString(AppConstants.courseSeedAssetPath);
      final Map<String, dynamic> data = jsonDecode(jsonString);

      if (data.containsKey('instructors')) {
        final List<dynamic> instList = data['instructors'];
        _cachedInstructors = instList.map((e) => InstructorInfo.fromJson(e as Map<String, dynamic>)).toList();
      }

      if (data.containsKey('courses')) {
        final List<dynamic> courseList = data['courses'];
        _cachedCourses = courseList.map((e) => CourseModel.fromJson(e as Map<String, dynamic>)).toList();
      }

      debugPrint('[SeedService] Loaded ${_cachedCourses.length} seed courses and ${_cachedInstructors.length} instructors.');

      // If Firebase Firestore is active, trigger sync to Firestore non-blocking
      if (FirebaseService.isInitialized) {
        syncToFirestore(_cachedCourses).timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            debugPrint('[SeedService] Firestore sync timed out. Proceeding with local seed data.');
          },
        ).catchError((e) {
          debugPrint('[SeedService] Firestore sync error: $e');
        });
      }
    } catch (e) {
      debugPrint('[SeedService] Error loading course seed data: $e');
    }

    return _cachedCourses;
  }

  static Future<void> syncToFirestore(List<CourseModel> courses) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final collection = firestore.collection(AppConstants.coursesCollection);
      final snapshot = await collection.limit(1).get();

      if (snapshot.docs.isEmpty) {
        debugPrint('[SeedService] Seeding Firestore collection "${AppConstants.coursesCollection}" with mock data...');
        for (final course in courses) {
          await collection.doc(course.id).set(course.toJson());
        }
        debugPrint('[SeedService] Firestore successfully seeded with ${courses.length} courses.');
      } else {
        debugPrint('[SeedService] Firestore collection "${AppConstants.coursesCollection}" already has documents.');
      }
    } catch (e) {
      debugPrint('[SeedService] Firestore sync skipped or failed (test mode): $e');
    }
  }
}
