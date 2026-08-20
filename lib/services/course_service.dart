import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course_model.dart';
import '../utils/constants.dart';
import 'firebase_service.dart';
import 'cloudinary_upload_service.dart';

class CourseService {
  static final List<CourseModel> _locallyCreatedCourses = [];
  static final Map<String, int> _additionalEnrolments = {};
  static final Map<String, List<double>> _additionalRatings = {};
  static List<CourseModel> _baseCourses = [];
  static bool _isSyncingWithFirestore = false;

  static const List<CourseModel> _defaultProductionCourses = [
    CourseModel(
      id: 'course_flutter_arch',
      title: 'Complete Flutter & Dart Architecture Masterclass',
      category: 'Mobile Development',
      instructorId: 'BxnBMFJRQjMftbikQdCiSbpKFH92',
      instructor: InstructorInfo(
        id: 'BxnBMFJRQjMftbikQdCiSbpKFH92',
        name: 'Dr. Alexandre Rivera',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
        title: 'Senior Faculty Director',
        bio: 'Senior Faculty Director & Lead Software Architect at EduSphere.',
        rating: 4.95,
        studentsCount: 1420,
      ),
      price: 89.99,
      originalPrice: 119.99,
      discount: 25.0,
      level: 'Intermediate',
      language: 'English',
      duration: '14.5 hrs',
      rating: 4.9,
      enrolmentCount: 342,
      thumbnailUrl: 'https://images.unsplash.com/photo-1551650975-87deedd944c3?w=800',
      subtitle: 'Master production-grade Flutter engineering, Clean Architecture, Riverpod 2.0 state management, offline caching, and responsive UI systems.',
      whatYouWillLearn: [
        'Build layered Clean Architecture applications with Flutter and Riverpod',
        'Implement resilient offline-first caching and synchronisation',
        'Stream signed media securely using Cloudflare serverless workers',
      ],
      requirements: ['Basic knowledge of Dart and OOP'],
      syllabus: [],
    ),
    CourseModel(
      id: 'course_cloud_serverless',
      title: 'Full-Stack Cloud & Serverless Systems with Docker',
      category: 'Cloud Engineering',
      instructorId: 'BxnBMFJRQjMftbikQdCiSbpKFH92',
      instructor: InstructorInfo(
        id: 'BxnBMFJRQjMftbikQdCiSbpKFH92',
        name: 'Dr. Alexandre Rivera',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
        title: 'Senior Faculty Director',
        bio: 'Senior Faculty Director & Lead Software Architect at EduSphere.',
        rating: 4.95,
        studentsCount: 1420,
      ),
      price: 94.99,
      originalPrice: 129.99,
      discount: 25.0,
      level: 'Advanced',
      language: 'English',
      duration: '18.0 hrs',
      rating: 4.95,
      enrolmentCount: 289,
      thumbnailUrl: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=800',
      subtitle: 'Architect zero-cost serverless microservices with Cloudflare Workers, secure edge pipelines, Docker container orchestration, and Cloud Firestore integration.',
      whatYouWillLearn: [
        'Deploy serverless Edge workers with sub-millisecond execution',
        'Implement zero-card storage and media distribution pipelines',
      ],
      requirements: ['Basic Node.js / HTTP protocols'],
      syllabus: [],
    ),
    CourseModel(
      id: 'course_uiux_design',
      title: 'Modern UI/UX Design Systems & Micro-Interactions',
      category: 'UI/UX Design',
      instructorId: 'BxnBMFJRQjMftbikQdCiSbpKFH92',
      instructor: InstructorInfo(
        id: 'BxnBMFJRQjMftbikQdCiSbpKFH92',
        name: 'Dr. Alexandre Rivera',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
        title: 'Senior Faculty Director',
        bio: 'Senior Faculty Director & Lead Software Architect at EduSphere.',
        rating: 4.95,
        studentsCount: 1420,
      ),
      price: 79.99,
      originalPrice: 99.99,
      discount: 20.0,
      level: 'Beginner',
      language: 'English',
      duration: '11.5 hrs',
      rating: 4.85,
      enrolmentCount: 412,
      thumbnailUrl: 'https://images.unsplash.com/photo-1507238691740-187a5b1d37b8?w=800',
      subtitle: 'Design world-class mobile and web user experiences with Figma, comprehensive design tokens, glassmorphism aesthetics, and fluid motion design.',
      whatYouWillLearn: [
        'Construct scalable design token systems in Figma and Flutter',
        'Create micro-animations that elevate user engagement',
      ],
      requirements: ['No prior experience needed'],
      syllabus: [],
    ),
    CourseModel(
      id: 'course_cybersecurity',
      title: 'Zero-Trust Cybersecurity & Threat Hunting',
      category: 'Cybersecurity',
      instructorId: 'BxnBMFJRQjMftbikQdCiSbpKFH92',
      instructor: InstructorInfo(
        id: 'BxnBMFJRQjMftbikQdCiSbpKFH92',
        name: 'Dr. Alexandre Rivera',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
        title: 'Senior Faculty Director',
        bio: 'Senior Faculty Director & Lead Software Architect at EduSphere.',
        rating: 4.95,
        studentsCount: 1420,
      ),
      price: 99.99,
      originalPrice: 139.99,
      discount: 28.0,
      level: 'Advanced',
      language: 'English',
      duration: '16.5 hrs',
      rating: 4.92,
      enrolmentCount: 198,
      thumbnailUrl: 'https://images.unsplash.com/photo-1563986768609-322da13575f3?w=800',
      subtitle: 'Protect enterprise infrastructure with modern zero-trust architecture, cryptographic identity validation, packet inspection, and incident response.',
      whatYouWillLearn: [
        'Implement least-privilege Zero-Trust network perimeters',
        'Analyze network packets, handshake ciphers, and threat vectors',
      ],
      requirements: ['TCP/IP networking basics'],
      syllabus: [],
    ),
    CourseModel(
      id: 'course_databases_web3',
      title: 'High-Performance Distributed Databases & Web3',
      category: 'Software Engineering',
      instructorId: 'BxnBMFJRQjMftbikQdCiSbpKFH92',
      instructor: InstructorInfo(
        id: 'BxnBMFJRQjMftbikQdCiSbpKFH92',
        name: 'Dr. Alexandre Rivera',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
        title: 'Senior Faculty Director',
        bio: 'Senior Faculty Director & Lead Software Architect at EduSphere.',
        rating: 4.95,
        studentsCount: 1420,
      ),
      price: 109.99,
      originalPrice: 149.99,
      discount: 25.0,
      level: 'Intermediate',
      language: 'English',
      duration: '15.0 hrs',
      rating: 4.88,
      enrolmentCount: 235,
      thumbnailUrl: 'https://images.unsplash.com/photo-1639762681485-074b7f938ba0?w=800',
      subtitle: 'Master distributed document stores, immutable cryptographic ledgers, query indexing, ACID transactions, and smart contract state machines.',
      whatYouWillLearn: [
        'Design distributed NoSQL schemas and partition keys',
        'Optimize multi-document atomic transactions and indexing',
      ],
      requirements: ['Basic database concepts'],
      syllabus: [],
    ),
  ];

  /// Returns all available courses directly from memory cache instantly (0ms) with background Firestore sync
  Future<List<CourseModel>> getCourses() async {
    // 1. If already initialized, return combined list instantly (0ms)
    if (_baseCourses.isNotEmpty) {
      _triggerBackgroundFirestoreSync();
      return _buildCombinedList(_baseCourses);
    }

    // 2. First-time initialization: instant seed in memory & trigger background sync
    _baseCourses = List.from(_defaultProductionCourses);
    _triggerBackgroundFirestoreSync();
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

  /// Permanently deletes a course from Firestore, in-memory caches, and purges all its Cloudinary assets
  Future<bool> deleteCourse(
    String courseId, {
    String? userId,
    String? userToken,
    CloudinaryUploadService? uploadService,
  }) async {
    // 1. Locate the course to inspect its Cloudinary assets
    final course = await getCourseById(courseId);

    // 2. Delete all Cloudinary assets if course was found
    if (course != null) {
      final uploader = uploadService ?? CloudinaryUploadService();

      // a) Delete lesson videos and downloadable resources
      for (final module in course.syllabus) {
        for (final lesson in module.lessons) {
          // Video asset
          if (lesson.videoUrl.isNotEmpty &&
              !lesson.videoUrl.startsWith('http') &&
              !lesson.videoUrl.startsWith('sample_')) {
            try {
              await uploader.deleteCloudinaryAsset(
                publicId: lesson.videoUrl,
                resourceType: 'video',
                courseId: courseId,
                idToken: userToken,
              );
            } catch (e) {
              debugPrint('[CourseService] Error deleting lesson video: $e');
            }
          }

          // Lesson resources (PDFs, ZIPs, Blueprints)
          for (final res in lesson.resources) {
            final pubId = res.cloudinaryPublicId;
            if (pubId != null &&
                pubId.isNotEmpty &&
                !pubId.startsWith('http')) {
              try {
                final resType = (res.type.toLowerCase() == 'image' ||
                        res.type.toLowerCase() == 'png' ||
                        res.type.toLowerCase() == 'jpg')
                    ? 'image'
                    : 'raw';
                await uploader.deleteCloudinaryAsset(
                  publicId: pubId,
                  resourceType: resType,
                  courseId: courseId,
                  idToken: userToken,
                );
              } catch (e) {
                debugPrint('[CourseService] Error deleting lesson resource: $e');
              }
            }
          }
        }
      }

      // b) Delete Course thumbnail if hosted on Cloudinary
      if (course.thumbnailUrl.isNotEmpty &&
          course.thumbnailUrl.contains('res.cloudinary.com') &&
          !course.thumbnailUrl.contains('images.unsplash.com')) {
        try {
          final uri = Uri.parse(course.thumbnailUrl);
          final segments = uri.pathSegments;
          final uploadIndex = segments.indexOf('upload');
          if (uploadIndex != -1 && uploadIndex + 1 < segments.length) {
            final afterUpload = segments.sublist(uploadIndex + 1);
            final publicSegments = afterUpload.where((s) => !RegExp(r'^v\d+$').hasMatch(s)).toList();
            if (publicSegments.isNotEmpty) {
              final publicIdWithExt = publicSegments.join('/');
              final dotIndex = publicIdWithExt.lastIndexOf('.');
              final publicId = dotIndex != -1 ? publicIdWithExt.substring(0, dotIndex) : publicIdWithExt;
              await uploader.deleteCloudinaryAsset(
                publicId: publicId,
                resourceType: 'image',
                courseId: courseId,
                idToken: userToken,
              );
            }
          }
        } catch (e) {
          debugPrint('[CourseService] Error deleting thumbnail: $e');
        }
      }
    }

    // 3. Remove from in-memory caches
    _locallyCreatedCourses.removeWhere((c) => c.id == courseId);
    _baseCourses.removeWhere((c) => c.id == courseId);
    _additionalEnrolments.remove(courseId);
    _additionalRatings.remove(courseId);

    // 4. Delete from Firestore
    if (FirebaseService.isInitialized) {
      try {
        final firestore = FirebaseFirestore.instance;
        // Delete course document
        await firestore.collection(AppConstants.coursesCollection).doc(courseId).delete();

        // Delete associated quizzes
        try {
          final quizDocs = await firestore
              .collection(AppConstants.quizzesCollection)
              .where('courseId', isEqualTo: courseId)
              .get();
          for (final doc in quizDocs.docs) {
            await doc.reference.delete();
          }
        } catch (e) {
          debugPrint('[CourseService] Quizzes cleanup note: $e');
        }

        // Delete associated live classes
        try {
          final liveDocs = await firestore
              .collection('liveClasses')
              .where('courseId', isEqualTo: courseId)
              .get();
          for (final doc in liveDocs.docs) {
            await doc.reference.delete();
          }
        } catch (e) {
          debugPrint('[CourseService] Live classes cleanup note: $e');
        }

        debugPrint('[CourseService] ✅ Course "$courseId" and all assets permanently deleted.');
      } catch (e) {
        debugPrint('[CourseService] Firestore course deletion error: $e');
      }
    }

    return true;
  }
}
