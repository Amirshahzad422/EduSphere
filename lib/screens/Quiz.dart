import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/course_provider.dart';
import '../providers/auth_provider.dart';
import '../models/quiz_model.dart';
import '../services/quiz_service.dart';
import '../styles/colors.dart';
import '../styles/spacing.dart';
import '../styles/typography.dart';
import '../components/QuizWidget.dart';
import '../components/Button.dart';
import '../components/Loader.dart';
import '../utils/helpers.dart';
import '../utils/auth_gate.dart';

class QuizScreen extends ConsumerWidget {
  final String quizId;

  const QuizScreen({
    super.key,
    required this.quizId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(allCoursesProvider);
    final authUser = ref.watch(authProvider);
    final isDesktop = AppHelpers.isDesktop(context);

    return coursesAsync.when(
      data: (courses) {
        QuizModel? targetQuiz;
        String? relatedCourseId;

        for (final course in courses) {
          for (final q in course.quizzes) {
            if (q.id == quizId) {
              targetQuiz = q;
              relatedCourseId = course.id;
            }
          }
        }

        targetQuiz ??= courses.isNotEmpty && courses.first.quizzes.isNotEmpty
            ? courses.first.quizzes.first
            : null;
        relatedCourseId ??= courses.isNotEmpty ? courses.first.id : '1';

        if (targetQuiz == null) {
          return const Center(child: Text('Quiz not found.'));
        }

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? AppSpacing.marginDesktop : AppSpacing.marginMobile,
            vertical: AppSpacing.lg,
          ),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Navigation Breadcrumb
                  InkWell(
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/course/$relatedCourseId');
                      }
                    },
                    borderRadius: AppSpacing.roundedMd,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 2.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_back, size: 18, color: AppColors.secondary),
                          const SizedBox(width: 8),
                          Text(
                            'Back to Course',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    targetQuiz.title,
                    style: AppTypography.displayMedium.copyWith(
                      fontSize: isDesktop ? 30 : 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    targetQuiz.description.isNotEmpty
                        ? targetQuiz.description
                        : 'Test your mastery with this structured module assessment. Complete all questions to earn course credit.',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),

                  // Interactive Quiz Card or Guest Sign In Card
                  if (authUser == null)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppSpacing.roundedLg,
                        border: Border.all(color: AppColors.surfaceContainerHigh),
                        boxShadow: const [
                          BoxShadow(color: AppColors.cardShadow, blurRadius: 12, offset: Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.quiz_outlined, size: 48, color: AppColors.primary),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Sign In to Take Assessment',
                            style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Log in or create a free account to take this module quiz, submit your answers, and earn XP towards your verified certificate.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                          const SizedBox(height: 24),
                          AppButton(
                            label: 'Sign In to Start Quiz',
                            variant: ButtonVariant.primary,
                            icon: Icons.login,
                            onPressed: () {
                              AuthGateHelper.requireAuth(
                                context,
                                ref,
                                actionTitle: 'Start Quiz Assessment',
                                reason: 'Sign in to record your quiz score and track module completion.',
                                onAuthenticated: () {},
                              );
                            },
                          ),
                        ],
                      ),
                    )
                  else
                    QuizWidget(
                      quiz: targetQuiz,
                      userId: authUser.id,
                      onQuizCompleted: (attempt) async {
                        // Persist to Cloud Firestore quizAttempts collection
                        final quizService = QuizService();
                        await quizService.recordAttempt(attempt);

                        if (context.mounted) {
                          AppHelpers.showSnackBar(
                            context,
                            attempt.passed
                                ? '🏆 Assessment Passed! Score: ${attempt.score}% (Saved to profile)'
                                : 'Assessment recorded. Score: ${attempt.score}%. You can review explanations and retry.',
                            isError: !attempt.passed,
                          );
                        }
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: AppLoader()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }
}
