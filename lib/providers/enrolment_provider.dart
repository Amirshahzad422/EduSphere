import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/course_model.dart';
import '../models/enrolment_model.dart';
import '../services/course_service.dart';
import '../services/certificate_service.dart';
import 'auth_provider.dart';
import 'course_provider.dart';

class EnrolmentNotifier extends StateNotifier<List<EnrolmentModel>> {
  final Ref? _ref;
  final CourseService _courseService;

  EnrolmentNotifier([this._ref, CourseService? courseService])
      : _courseService = courseService ?? CourseService(),
        super([]);

  StreamSubscription<QuerySnapshot>? _firestoreSubscription;

  @override
  void dispose() {
    _firestoreSubscription?.cancel();
    super.dispose();
  }

  /// Fetches real Firestore enrolments for the active user and listens in real-time
  Future<void> fetchUserEnrolments(String userId) async {
    if (userId.isEmpty || userId == 'guest') return;
    try {
      if (Firebase.apps.isNotEmpty) {
        // 1. Immediate fetch
        final querySnapshot = await FirebaseFirestore.instance
            .collection('enrolments')
            .where('userId', isEqualTo: userId)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final fetched = querySnapshot.docs
              .map((doc) => EnrolmentModel.fromJson(doc.data()))
              .toList();

          final currentMap = {for (final e in state) e.courseId: e};
          for (final f in fetched) {
            currentMap[f.courseId] = f;
          }
          state = currentMap.values.toList();
          debugPrint('[EnrolmentService] ✅ Loaded ${fetched.length} enrolments from Firestore for user $userId');
        }

        // 2. Real-time live Firestore stream
        _firestoreSubscription?.cancel();
        _firestoreSubscription = FirebaseFirestore.instance
            .collection('enrolments')
            .where('userId', isEqualTo: userId)
            .snapshots()
            .listen((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final fetched = snapshot.docs
                .map((doc) => EnrolmentModel.fromJson(doc.data()))
                .toList();

            final currentMap = {for (final e in state) e.courseId: e};
            for (final f in fetched) {
              currentMap[f.courseId] = f;
            }
            state = currentMap.values.toList();
          }
        }, onError: (e) {
          debugPrint('[EnrolmentService] Firestore realtime stream note: $e');
        });
      }
    } catch (e) {
      debugPrint('[EnrolmentService] Firestore enrolment fetch note: $e');
    }
  }

  Future<EnrolmentModel> enroll(String courseId, String userId, {String? paymentId}) async {
    final existing = state.where((e) => e.courseId == courseId).toList();
    if (existing.isNotEmpty) {
      return existing.first;
    }

    final deterministicId = '${userId}_$courseId';
    final newEnrolment = EnrolmentModel(
      id: deterministicId,
      userId: userId,
      courseId: courseId,
      progress: 0.0,
      completedLessons: const [],
      lastPlayedPositions: const {},
      lessonNotes: const {},
      paymentId: paymentId ?? 'free_enrolment',
      enrolledAt: DateTime.now(),
      lastAccessedAt: DateTime.now(),
    );

    state = [...state, newEnrolment];

    // Record enrollment in CourseService so instructor revenue, student count, and catalogue stats update live
    await _courseService.recordEnrolment(courseId);
    if (_ref != null) {
      Future.microtask(() {
        try {
          _ref.read(courseRefreshCounterProvider.notifier).state++;
        } catch (_) {}
      });
    }

    // Persist to Cloud Firestore if connected
    try {
      if (Firebase.apps.isNotEmpty) {
        final firestore = FirebaseFirestore.instance;
        await firestore.collection('enrolments').doc(deterministicId).set(newEnrolment.toJson());
        debugPrint('[EnrolmentService] Persisted enrollment $deterministicId for user $userId to Firestore.');
      }
    } catch (e) {
      debugPrint('[EnrolmentService] Local enrolment mode (Firestore sync error: $e)');
    }

    return newEnrolment;
  }

  bool isEnrolled(String courseId) {
    return state.any((e) => e.courseId == courseId);
  }

  /// Saves the exact video playback position (in seconds) for seamless resume across sessions
  void savePlaybackPosition(String courseId, String lessonId, int positionSeconds) {
    state = state.map((enrol) {
      if (enrol.courseId == courseId) {
        final updatedPositions = Map<String, int>.from(enrol.lastPlayedPositions);
        updatedPositions[lessonId] = positionSeconds;

        final updatedEnrol = enrol.copyWith(
          lastLessonId: lessonId,
          lastPlayedPositions: updatedPositions,
          lastAccessedAt: DateTime.now(),
        );

        // Async sync to Firestore
        _syncEnrolmentToFirestore(updatedEnrol);
        return updatedEnrol;
      }
      return enrol;
    }).toList();
  }

  /// Persists student personal lesson notes
  void saveLessonNote(String courseId, String lessonId, String noteText) {
    state = state.map((enrol) {
      if (enrol.courseId == courseId) {
        final updatedNotes = Map<String, String>.from(enrol.lessonNotes);
        updatedNotes[lessonId] = noteText;

        final updatedEnrol = enrol.copyWith(
          lessonNotes: updatedNotes,
          lastAccessedAt: DateTime.now(),
        );

        _syncEnrolmentToFirestore(updatedEnrol);
        return updatedEnrol;
      }
      return enrol;
    }).toList();
  }

  bool completeLesson(String courseId, String lessonId, int totalLessons, {String? courseTitle, String? instructorName}) {
    bool isNewlyCompleted = false;
    bool courseNewlyFinished = false;

    final updatedState = <EnrolmentModel>[];
    for (final enrol in state) {
      if (enrol.courseId == courseId) {
        final currentCompleted = List<String>.from(enrol.completedLessons);
        final wasNotCompleted = !currentCompleted.contains(lessonId);

        if (wasNotCompleted) {
          currentCompleted.add(lessonId);
          isNewlyCompleted = true;
        }

        final newProgress = totalLessons > 0 ? (currentCompleted.length / totalLessons).clamp(0.0, 1.0) : 0.0;
        final willBeCompleted = newProgress >= 1.0;

        if (willBeCompleted && !enrol.isCompleted && enrol.progress < 1.0) {
          courseNewlyFinished = true;
        }

        final updatedEnrol = enrol.copyWith(
          completedLessons: currentCompleted,
          progress: newProgress,
          isCompleted: enrol.isCompleted || willBeCompleted,
          lastLessonId: lessonId,
          lastAccessedAt: DateTime.now(),
        );

        _syncEnrolmentToFirestore(updatedEnrol);
        updatedState.add(updatedEnrol);
      } else {
        updatedState.add(enrol);
      }
    }
    state = updatedState;

    // Award XP and badges strictly once outside the iteration
    if (isNewlyCompleted) {
      _ref?.read(authProvider.notifier).addXp(50);
    }
    if (courseNewlyFinished) {
      _ref?.read(authProvider.notifier).addXp(500);
      _ref?.read(authProvider.notifier).awardBadge('Mastery Graduate');
      final user = _ref?.read(authProvider);
      if (user != null) {
        _courseService.recordCourseRating(courseId, 5.0).catchError((_) {});
        try {
          final certService = _ref?.read(certificateServiceProvider);
          if (certService != null) {
            unawaited(
              certService.generateCertificate(
                userId: user.id,
                userName: user.name,
                courseId: courseId,
                courseTitle: courseTitle ?? 'Masterclass Course',
                instructorName: instructorName ?? 'EduSphere Instructor',
              ).then((_) {}).catchError((err) {
                debugPrint('[EnrolmentNotifier] Auto-certificate generation error: $err');
              }),
            );
          }
        } catch (e) {
          debugPrint('[EnrolmentNotifier] Could not trigger certificate generation: $e');
        }
      }
    }

    return isNewlyCompleted;
  }

  void _syncEnrolmentToFirestore(EnrolmentModel enrolment) {
    try {
      if (Firebase.apps.isNotEmpty) {
        FirebaseFirestore.instance
            .collection('enrolments')
            .doc(enrolment.id)
            .set(enrolment.toJson(), SetOptions(merge: true));
      }
    } catch (_) {}
  }
}

final enrolmentProvider = StateNotifierProvider<EnrolmentNotifier, List<EnrolmentModel>>((ref) {
  final courseService = ref.watch(courseServiceProvider);
  final notifier = EnrolmentNotifier(ref, courseService);

  final authUser = ref.watch(authProvider);
  if (authUser != null && authUser.id.isNotEmpty && authUser.id != 'guest') {
    notifier.fetchUserEnrolments(authUser.id);
  }

  return notifier;
});

final myEnrolledCoursesProvider = Provider<AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final enrolments = ref.watch(enrolmentProvider);
  final allCoursesAsync = ref.watch(allCoursesProvider);

  return allCoursesAsync.whenData((courses) {
    final result = <Map<String, dynamic>>[];
    for (final enrol in enrolments) {
      try {
        final course = courses.firstWhere((c) => c.id == enrol.courseId);
        result.add({
          'course': course,
          'enrolment': enrol,
        });
      } catch (_) {
        // Fallback placeholder if course document is still synchronizing from remote Firestore
        final fallback = CourseModel(
          id: enrol.courseId,
          title: 'Course: ${enrol.courseId}',
          subtitle: 'Active Enrolment',
          category: 'Development',
          instructorId: 'inst_default',
          instructor: const InstructorInfo(
            id: 'inst_default',
            name: 'EduSphere Instructor',
            title: 'Senior Faculty',
            avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
            bio: 'Expert instructor at EduSphere.',
          ),
          price: 0.0,
          discount: 0,
          level: 'All Levels',
          language: 'English',
          duration: '3.5 Hours',
          rating: 4.9,
          reviewCount: 1,
          enrolmentCount: 1,
          thumbnailUrl: 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=800',
          syllabus: const [],
          requirements: const [],
          whatYouWillLearn: const [],
        );
        result.add({
          'course': fallback,
          'enrolment': enrol,
        });
      }
    }
    return result;
  });
});
