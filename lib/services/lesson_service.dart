import '../models/lesson_model.dart';
import 'course_service.dart';

class LessonService {
  final CourseService _courseService = CourseService();

  Future<LessonModel?> getLesson(String courseId, String lessonId) async {
    final course = await _courseService.getCourseById(courseId);
    if (course == null) return null;

    for (final module in course.syllabus) {
      for (final lesson in module.lessons) {
        if (lesson.id == lessonId) return lesson;
      }
    }
    return null;
  }
}
