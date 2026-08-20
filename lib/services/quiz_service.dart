import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/quiz_model.dart';
import 'course_service.dart';

class QuizService {
  final CourseService _courseService = CourseService();
  final List<QuizAttemptModel> _localAttempts = [];

  List<QuizAttemptModel> get localAttempts => List.unmodifiable(_localAttempts);

  Future<QuizModel?> getQuiz(String courseId, String quizId) async {
    final course = await _courseService.getCourseById(courseId);
    if (course == null) return null;

    try {
      return course.quizzes.firstWhere((q) => q.id == quizId);
    } catch (_) {
      if (course.quizzes.isNotEmpty) return course.quizzes.first;
      return null;
    }
  }

  /// Auto-grades MCQ and True/False questions while extracting Short Answer submissions for instructor review
  QuizAttemptModel evaluateQuiz({
    required QuizModel quiz,
    required String userId,
    required Map<String, String> userAnswers,
  }) {
    int autoCount = 0;
    int correctCount = 0;
    int shortAnswerCount = 0;

    for (final q in quiz.questions) {
      if (q.type == QuestionType.shortAnswer) {
        shortAnswerCount++;
      } else {
        autoCount++;
        final selectedId = userAnswers[q.id];
        final correctOption = q.options.firstWhere(
          (opt) => opt.isCorrect,
          orElse: () => q.options.first,
        );

        final isCorrect = selectedId != null &&
            (selectedId == correctOption.id || selectedId == correctOption.text);
        if (isCorrect) correctCount++;
      }
    }

    final score = autoCount > 0 ? ((correctCount / autoCount) * 100).round() : 100;
    final passed = score >= quiz.passingScore;

    return QuizAttemptModel(
      id: 'attempt_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      quizId: quiz.id,
      courseId: quiz.courseId,
      score: score,
      passed: passed,
      shortAnswerCount: shortAnswerCount,
      answers: userAnswers,
      completedAt: DateTime.now(),
    );
  }

  /// Records quiz attempt and persists to Firestore collection 'quizAttempts'
  Future<QuizAttemptModel> recordAttempt(QuizAttemptModel attempt) async {
    _localAttempts.add(attempt);

    // Persist to Cloud Firestore
    try {
      if (Firebase.apps.isNotEmpty) {
        final firestore = FirebaseFirestore.instance;
        await firestore.collection('quizAttempts').doc(attempt.id).set(attempt.toJson());
        debugPrint('[QuizService] 📝 Persisted quiz attempt ${attempt.id} (Score: ${attempt.score}%) to Firestore.');
      }
    } catch (e) {
      debugPrint('[QuizService] Local quiz attempt saved (Firestore sync: $e)');
    }

    return attempt;
  }

  Future<List<QuizAttemptModel>> getAttemptsForUser(String userId) async {
    return _localAttempts.where((a) => a.userId == userId).toList();
  }

  /// Persists or updates a quiz definition in Cloud Firestore collection 'quizzes'
  Future<QuizModel> saveOrUpdateQuiz(QuizModel quiz) async {
    try {
      if (Firebase.apps.isNotEmpty) {
        final firestore = FirebaseFirestore.instance;
        await firestore.collection('quizzes').doc(quiz.id).set(quiz.toJson(), SetOptions(merge: true));
        debugPrint('[QuizService] 💾 Persisted quiz ${quiz.id} ("${quiz.title}") to Firestore.');
      }
    } catch (e) {
      debugPrint('[QuizService] Local quiz mode (Firestore sync: $e)');
    }
    return quiz;
  }

  /// Deletes a quiz definition from Cloud Firestore collection 'quizzes'
  Future<void> deleteQuiz(String quizId) async {
    try {
      if (Firebase.apps.isNotEmpty) {
        final firestore = FirebaseFirestore.instance;
        await firestore.collection('quizzes').doc(quizId).delete();
        debugPrint('[QuizService] 🗑️ Deleted quiz $quizId from Firestore.');
      }
    } catch (e) {
      debugPrint('[QuizService] Delete quiz note (Firestore sync: $e)');
    }
  }
}
