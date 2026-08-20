import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/quiz_service.dart';

final quizServiceProvider = Provider<QuizService>((ref) {
  return QuizService();
});

class QuizState {
  final Map<String, String> selectedAnswers;
  final bool isSubmitted;
  final int score;
  final bool passed;

  const QuizState({
    this.selectedAnswers = const {},
    this.isSubmitted = false,
    this.score = 0,
    this.passed = false,
  });

  QuizState copyWith({
    Map<String, String>? selectedAnswers,
    bool? isSubmitted,
    int? score,
    bool? passed,
  }) {
    return QuizState(
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      score: score ?? this.score,
      passed: passed ?? this.passed,
    );
  }
}

class QuizStateNotifier extends StateNotifier<QuizState> {
  QuizStateNotifier() : super(const QuizState());

  void selectOption(String questionId, String optionId) {
    if (state.isSubmitted) return;
    final updated = Map<String, String>.from(state.selectedAnswers);
    updated[questionId] = optionId;
    state = state.copyWith(selectedAnswers: updated);
  }

  void submitQuiz(int score, bool passed) {
    state = state.copyWith(
      isSubmitted: true,
      score: score,
      passed: passed,
    );
  }

  void reset() {
    state = const QuizState();
  }
}

final quizStateProvider = StateNotifierProvider.autoDispose<QuizStateNotifier, QuizState>((ref) {
  return QuizStateNotifier();
});
