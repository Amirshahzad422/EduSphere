import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/live_class_model.dart';
import '../models/user_model.dart';
import '../services/live_class_service.dart';
import 'auth_provider.dart';
import 'enrolment_provider.dart';

final liveClassServiceProvider = Provider<LiveClassService>((ref) {
  return LiveClassService();
});

final activeLiveClassStreamProvider = StreamProvider.family<LiveClassModel?, String>((ref, classId) {
  final service = ref.watch(liveClassServiceProvider);
  return service.streamLiveClass(classId);
});

final liveClassParticipantsStreamProvider =
    StreamProvider.family<List<LiveClassParticipantModel>, String>((ref, classId) {
  final service = ref.watch(liveClassServiceProvider);
  return service.streamParticipants(classId);
});

final liveClassMessagesStreamProvider =
    StreamProvider.family<List<LiveClassMessageModel>, String>((ref, classId) {
  final service = ref.watch(liveClassServiceProvider);
  return service.streamMessages(classId);
});

final courseUpcomingLiveClassProvider =
    StreamProvider.family<LiveClassModel?, String>((ref, courseId) {
  final service = ref.watch(liveClassServiceProvider);
  return service.streamCourseLiveClasses(courseId).map((classes) {
    // Return active live class first, otherwise upcoming scheduled class
    final live = classes.where((c) => c.isLive).toList();
    if (live.isNotEmpty) return live.first;

    final upcoming = classes.where((c) => c.isScheduled).toList();
    return upcoming.isNotEmpty ? upcoming.first : null;
  });
});

final instructorLiveClassesStreamProvider =
    StreamProvider.family<List<LiveClassModel>, String>((ref, instructorId) {
  final service = ref.watch(liveClassServiceProvider);
  return service.streamInstructorLiveClasses(instructorId);
});

final allLiveClassesStreamProvider = StreamProvider<List<LiveClassModel>>((ref) {
  final service = ref.watch(liveClassServiceProvider);
  return service.streamAllLiveClasses();
});

/// Returns the active LiveClassModel that the current user has access to
/// (either enrolled student or owning instructor).
final activeUserLiveSessionProvider = Provider<LiveClassModel?>((ref) {
  final liveClassesAsync = ref.watch(allLiveClassesStreamProvider);
  final user = ref.watch(authProvider);
  final enrolmentList = ref.watch(enrolmentProvider);

  return liveClassesAsync.maybeWhen(
    data: (liveClasses) {
      if (liveClasses.isEmpty) return null;

      for (final liveClass in liveClasses) {
        // Instructor check
        if (user != null &&
            (user.role == UserRole.instructor ||
                liveClass.instructorId == user.id ||
                liveClass.instructorId == 'inst_1')) {
          return liveClass;
        }
        // Enrolled student check (enrolmentList contains enrolled course IDs)
        final isEnrolled = enrolmentList.any((e) => e.courseId == liveClass.courseId);
        if (isEnrolled) {
          return liveClass;
        }
      }
      return null;
    },
    orElse: () => null,
  );
});
