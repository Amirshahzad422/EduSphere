import 'dart:async';
import 'package:flutter/material.dart';
import '../models/quiz_model.dart';
import '../services/quiz_service.dart';
import '../styles/colors.dart';
import '../styles/spacing.dart';
import '../styles/typography.dart';
import 'Button.dart';

class QuizWidget extends StatefulWidget {
  final QuizModel quiz;
  final String userId;
  final void Function(QuizAttemptModel attempt)? onQuizCompleted;

  const QuizWidget({
    super.key,
    required this.quiz,
    this.userId = 'guest',
    this.onQuizCompleted,
  });

  @override
  State<QuizWidget> createState() => _QuizWidgetState();
}

class _QuizWidgetState extends State<QuizWidget> {
  int _currentQuestionIndex = 0;
  final Map<String, String> _userAnswers = {};
  final Map<String, TextEditingController> _shortAnswerControllers = {};
  bool _isSubmitted = false;
  QuizAttemptModel? _attemptResult;
  late int _remainingSeconds;
  Timer? _timer;

  final QuizService _quizService = QuizService();

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.quiz.timeLimitMinutes * 60;
    for (final q in widget.quiz.questions) {
      if (q.type == QuestionType.shortAnswer) {
        _shortAnswerControllers[q.id] = TextEditingController();
      }
    }
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        _submit();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _shortAnswerControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _selectOption(String questionId, String value) {
    if (_isSubmitted) return;
    setState(() {
      _userAnswers[questionId] = value;
    });
  }

  void _submit() {
    _timer?.cancel();

    // Pull short answer values
    for (final entry in _shortAnswerControllers.entries) {
      _userAnswers[entry.key] = entry.value.text.trim();
    }

    final attempt = _quizService.evaluateQuiz(
      quiz: widget.quiz,
      userId: widget.userId,
      userAnswers: _userAnswers,
    );

    setState(() {
      _isSubmitted = true;
      _attemptResult = attempt;
    });

    widget.onQuizCompleted?.call(attempt);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.quiz.questions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('No quiz questions configured.', style: AppTypography.bodyMedium),
        ),
      );
    }

    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    final timeFormatted = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    // RESULT / SCORE FEEDBACK VIEW
    if (_isSubmitted && _attemptResult != null) {
      final attempt = _attemptResult!;
      final passed = attempt.passed;

      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppSpacing.roundedLg,
          border: Border.all(color: AppColors.surfaceContainerHigh),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Result Header Card
            Center(
              child: Column(
                children: [
                  Icon(
                    passed ? Icons.check_circle_rounded : Icons.info_outline,
                    size: 64,
                    color: passed ? AppColors.success : AppColors.warning,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    passed ? 'Quiz Passed! 🏆' : 'Quiz Completed',
                    style: AppTypography.headlineSmall.copyWith(
                      color: passed ? AppColors.success : AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Auto-Graded Score: ${attempt.score}% (Passing: ${widget.quiz.passingScore}%)',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (attempt.shortAnswerCount > 0) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.12),
                        borderRadius: AppSpacing.roundedFull,
                      ),
                      child: Text(
                        'ℹ️ ${attempt.shortAnswerCount} Short Answer response(s) submitted for Instructor Review',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Detailed Question Review & Explanations
            Text(
              'Detailed Review & Explanations',
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.quiz.questions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, idx) {
                final q = widget.quiz.questions[idx];
                final answer = _userAnswers[q.id] ?? 'No answer provided';
                final isShortAnswer = q.type == QuestionType.shortAnswer;

                bool isCorrect = false;
                if (!isShortAnswer) {
                  final correctOpt = q.options.firstWhere(
                    (opt) => opt.isCorrect,
                    orElse: () => q.options.first,
                  );
                  isCorrect = answer == correctOpt.id || answer == correctOpt.text;
                }

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: AppSpacing.roundedMd,
                    border: Border.all(
                      color: isShortAnswer
                          ? AppColors.secondary.withOpacity(0.4)
                          : (isCorrect ? AppColors.success.withOpacity(0.4) : AppColors.error.withOpacity(0.4)),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isShortAnswer
                                ? Icons.pending_actions
                                : (isCorrect ? Icons.check_circle : Icons.cancel),
                            size: 20,
                            color: isShortAnswer
                                ? AppColors.secondary
                                : (isCorrect ? AppColors.success : AppColors.error),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${idx + 1}. ${q.question}',
                              style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your Answer: $answer',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isShortAnswer
                              ? AppColors.primary
                              : (isCorrect ? AppColors.success : AppColors.error),
                        ),
                      ),
                      if (q.explanation.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: AppSpacing.roundedSm,
                          ),
                          child: Text(
                            '💡 Explanation: ${q.explanation}',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton(
                  label: 'Retake Assessment',
                  variant: ButtonVariant.outline,
                  size: ButtonSize.sm,
                  icon: Icons.refresh,
                  onPressed: () {
                    setState(() {
                      _isSubmitted = false;
                      _attemptResult = null;
                      _currentQuestionIndex = 0;
                      _userAnswers.clear();
                      for (final c in _shortAnswerControllers.values) {
                        c.clear();
                      }
                      _remainingSeconds = widget.quiz.timeLimitMinutes * 60;
                    });
                    _startTimer();
                  },
                ),
              ],
            ),
          ],
        ),
      );
    }

    // ACTIVE QUESTION VIEW
    final currentQuestion = widget.quiz.questions[_currentQuestionIndex];
    final totalQuestions = widget.quiz.questions.length;
    final progress = (totalQuestions > 0) ? (_currentQuestionIndex + 1) / totalQuestions : 1.0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: AppColors.surfaceContainerHigh),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Distraction-Free Header: Question Counter & Timer Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Question ${_currentQuestionIndex + 1} of $totalQuestions',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.quiz.title,
                    style: AppTypography.labelSmall.copyWith(color: AppColors.outline),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _remainingSeconds < 120
                      ? AppColors.error.withOpacity(0.12)
                      : AppColors.surfaceContainerLow,
                  borderRadius: AppSpacing.roundedFull,
                  border: Border.all(
                    color: _remainingSeconds < 120 ? AppColors.error : AppColors.surfaceContainerHigh,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: _remainingSeconds < 120 ? AppColors.error : AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timeFormatted,
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: _remainingSeconds < 120 ? AppColors.error : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress Bar
          ClipRRect(
            borderRadius: AppSpacing.roundedFull,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: AppColors.surfaceContainerHigh,
              valueColor: const AlwaysStoppedAnimation(AppColors.secondary),
            ),
          ),
          const SizedBox(height: 20),

          // Question Type Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: AppSpacing.roundedSm,
            ),
            child: Text(
              currentQuestion.type == QuestionType.multipleChoice
                  ? 'Multiple Choice'
                  : (currentQuestion.type == QuestionType.trueFalse ? 'True / False' : 'Short Answer'),
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Question Title
          Text(
            currentQuestion.question,
            style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 20),

          // Question Options: MCQ / True-False / Short Answer
          if (currentQuestion.type == QuestionType.multipleChoice || currentQuestion.type == QuestionType.trueFalse)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: currentQuestion.options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, optIndex) {
                final option = currentQuestion.options[optIndex];
                final isSelected = _userAnswers[currentQuestion.id] == option.id;

                return InkWell(
                  onTap: () => _selectOption(currentQuestion.id, option.id),
                  borderRadius: AppSpacing.roundedMd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.secondary.withOpacity(0.08)
                          : AppColors.surfaceContainerLowest,
                      borderRadius: AppSpacing.roundedMd,
                      border: Border.all(
                        color: isSelected ? AppColors.secondary : AppColors.surfaceContainerHigh,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? AppColors.secondary : Colors.transparent,
                            border: Border.all(
                              color: isSelected ? AppColors.secondary : AppColors.outlineVariant,
                              width: 1.5,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, size: 14, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            option.text,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? AppColors.primary : AppColors.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          else
            // Short Answer Text Input Field
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _shortAnswerControllers[currentQuestion.id],
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Type your concise answer here...',
                    hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.outline),
                    contentPadding: const EdgeInsets.all(14),
                    fillColor: AppColors.surfaceContainerLowest,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: AppSpacing.roundedMd,
                      borderSide: const BorderSide(color: AppColors.surfaceContainerHigh),
                    ),
                  ),
                  onChanged: (val) => _userAnswers[currentQuestion.id] = val,
                ),
                const SizedBox(height: 8),
                Text(
                  'Note: Short answer responses are flagged for instructor evaluation.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.outline),
                ),
              ],
            ),

          const SizedBox(height: 28),

          // Navigation Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentQuestionIndex > 0)
                AppButton(
                  label: 'Previous',
                  variant: ButtonVariant.outline,
                  size: ButtonSize.sm,
                  icon: Icons.arrow_back,
                  onPressed: () {
                    setState(() {
                      _currentQuestionIndex--;
                    });
                  },
                )
              else
                const SizedBox.shrink(),

              if (_currentQuestionIndex < totalQuestions - 1)
                AppButton(
                  label: 'Next Question',
                  variant: ButtonVariant.primary,
                  size: ButtonSize.sm,
                  icon: Icons.arrow_forward,
                  onPressed: () {
                    setState(() {
                      _currentQuestionIndex++;
                    });
                  },
                )
              else
                AppButton(
                  label: 'Submit Assessment',
                  variant: ButtonVariant.secondary,
                  size: ButtonSize.sm,
                  icon: Icons.send,
                  onPressed: _submit,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
