import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/course_provider.dart';
import '../providers/enrolment_provider.dart';
import '../providers/auth_provider.dart';
import '../models/course_model.dart';
import '../models/lesson_model.dart';
import '../models/user_model.dart';
import '../models/enrolment_model.dart';
import '../services/lesson_stream_service.dart';
import '../styles/colors.dart';
import '../styles/spacing.dart';
import '../styles/typography.dart';
import '../components/VideoPlayer.dart';
import '../components/LessonList.dart';
import '../components/Button.dart';
import '../components/Loader.dart';
import '../components/AuthGateModal.dart';
import '../utils/helpers.dart';
import '../utils/auth_gate.dart';

final lessonStreamServiceProvider = Provider<LessonStreamService>((ref) {
  return LessonStreamService();
});

class LessonScreen extends ConsumerStatefulWidget {
  final String courseId;
  final String lessonId;

  const LessonScreen({
    super.key,
    required this.courseId,
    required this.lessonId,
  });

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _currentLessonId;
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _discussionController = TextEditingController();

  final List<Map<String, String>> _discussionMessages = [
    {
      'user': 'Alexandre Rivera (Instructor)',
      'message': 'Welcome to this module! Check the resources tab for the architecture blueprint PDF.',
      'time': '2 hours ago',
    },
    {
      'user': 'David K.',
      'message': 'Does the repository pattern handle stream caching automatically in this setup?',
      'time': '45 mins ago',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _currentLessonId = widget.lessonId;
  }

  Future<LessonStreamResult>? _streamFuture;
  String? _cachedLessonId;
  String? _cachedUserId;
  bool? _cachedIsEnrolled;

  Future<LessonStreamResult> _getStreamFuture(
    LessonStreamService streamService, {
    required String courseId,
    required LessonModel lesson,
    required String userId,
    required bool isEnrolled,
  }) {
    if (_streamFuture == null ||
        _cachedLessonId != lesson.id ||
        _cachedUserId != userId ||
        _cachedIsEnrolled != isEnrolled) {
      _cachedLessonId = lesson.id;
      _cachedUserId = userId;
      _cachedIsEnrolled = isEnrolled;
      _streamFuture = streamService.getVideoStreamUrl(
        courseId: courseId,
        lesson: lesson,
        userId: userId,
        isEnrolled: isEnrolled,
      );
    }
    return _streamFuture!;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    _discussionController.dispose();
    super.dispose();
  }

  void _postQuestion() {
    final text = _discussionController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _discussionMessages.add({
        'user': 'You',
        'message': text,
        'time': 'Just now',
      });
      _discussionController.clear();
    });
    AppHelpers.showSnackBar(context, 'Question posted to discussion forum!');
  }

  int _parseDurationSeconds(String durationStr) {
    try {
      if (durationStr.contains(':')) {
        final parts = durationStr.split(':');
        if (parts.length == 2) {
          return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
        } else if (parts.length == 3) {
          return (int.tryParse(parts[0]) ?? 0) * 3600 + (int.tryParse(parts[1]) ?? 0) * 60 + (int.tryParse(parts[2]) ?? 0);
        }
      } else if (durationStr.endsWith('m')) {
        return (int.tryParse(durationStr.replaceAll('m', '')) ?? 10) * 60;
      }
    } catch (_) {}
    return 600;
  }

  Future<void> _handleOpenResource({
    required BuildContext context,
    required CourseModel course,
    required LessonModel lesson,
    required LessonResource resource,
    required bool isEnrolled,
    required bool isAuthor,
    required UserModel? authUser,
    required LessonStreamService streamService,
    required bool isDownload,
  }) async {
    final canAccess = isEnrolled || isAuthor || lesson.isPreview || resource.isPreview;

    if (!canAccess) {
      if (authUser == null) {
        AuthGateModal.show(
          context,
          actionTitle: 'Unlock Lesson Resource',
          reason: 'Sign in to access and download "${resource.title}".',
          onAuthenticated: () {},
        );
      } else {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
            title: Row(
              children: [
                const Icon(Icons.lock_outline, color: AppColors.secondary),
                const SizedBox(width: 10),
                const Text('Course Enrollment Required', style: TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'The resource "${resource.title}" is exclusive to enrolled students.',
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  'Enroll in "${course.title}" to unlock all lecture videos, downloadable PDFs, blueprints, quizzes, and earn an official verifiable certificate.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              AppButton(
                label: course.price == 0 ? 'Enroll for Free' : 'Enroll Now (\$${course.price.toStringAsFixed(2)})',
                variant: ButtonVariant.secondary,
                size: ButtonSize.sm,
                onPressed: () {
                  Navigator.pop(ctx);
                  if (course.price == 0) {
                    ref.read(enrolmentProvider.notifier).enroll(course.id, authUser.id);
                    AppHelpers.showSnackBar(context, '🎉 Successfully enrolled! Resource unlocked.');
                  } else {
                    context.push('/checkout/${course.id}');
                  }
                },
              ),
            ],
          ),
        );
      }
      return;
    }

    try {
      AppHelpers.showSnackBar(
        context,
        isDownload
            ? 'Fetching secure download link for ${resource.title}...'
            : 'Opening ${resource.title}...',
      );

      final result = await streamService.getResourceDeliveryUrl(
        courseId: course.id,
        lesson: lesson,
        resource: resource,
        userId: authUser?.id ?? 'guest',
        isEnrolled: isEnrolled || isAuthor,
      );

      final url = result.streamUrl;
      if (url.isEmpty) {
        if (context.mounted) {
          AppHelpers.showSnackBar(context, 'Unable to generate delivery URL for this resource.', isError: true);
        }
        return;
      }

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }

      if (context.mounted) {
        AppHelpers.showSnackBar(
          context,
          isDownload
              ? '📥 Downloading ${resource.title}'
              : '📄 Viewing ${resource.title}',
        );
      }
    } on LessonAccessDeniedException catch (e) {
      if (context.mounted) {
        AppHelpers.showSnackBar(context, '🔒 ${e.message}', isError: true);
      }
    } catch (e) {
      if (context.mounted) {
        AppHelpers.showSnackBar(context, 'Failed to open resource: $e', isError: true);
      }
    }
  }

  Widget _buildResourceCard({
    required BuildContext context,
    required CourseModel course,
    required LessonModel lesson,
    required LessonResource resource,
    required bool isEnrolled,
    required bool isAuthor,
    required UserModel? authUser,
    required LessonStreamService streamService,
    String? lessonContextTitle,
  }) {
    final canAccess = isEnrolled || isAuthor || lesson.isPreview || resource.isPreview;
    final isPdf = resource.type.toLowerCase() == 'pdf';
    final isZip = resource.type.toLowerCase() == 'zip';
    final isDoc = resource.type.toLowerCase().startsWith('doc');
    final isCode = resource.type.toLowerCase() == 'code' || resource.type.toLowerCase() == 'json' || resource.type.toLowerCase() == 'dart';

    final IconData fileIcon = isPdf
        ? Icons.picture_as_pdf
        : (isZip
            ? Icons.folder_zip
            : (isDoc
                ? Icons.description
                : (isCode ? Icons.code : Icons.insert_drive_file_outlined)));

    final Color iconColor = isPdf
        ? AppColors.error
        : (isZip
            ? Colors.orange
            : (isDoc
                ? AppColors.secondary
                : (isCode ? Colors.teal : AppColors.outline)));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(
          color: canAccess ? AppColors.surfaceContainerHigh : AppColors.outlineVariant.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, cardConstraints) {
          final isNarrow = cardConstraints.maxWidth < 450;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.12),
                      borderRadius: AppSpacing.roundedSm,
                    ),
                    child: Icon(fileIcon, color: iconColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resource.title,
                          style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (lessonContextTitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Lesson: $lessonContextTitle',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.outline, fontSize: 11),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: canAccess
                                    ? (resource.isPreview || lesson.isPreview
                                        ? AppColors.secondaryContainer
                                        : AppColors.success.withOpacity(0.12))
                                    : AppColors.error.withOpacity(0.1),
                                borderRadius: AppSpacing.roundedSm,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    canAccess ? Icons.check_circle_outline : Icons.lock_outline,
                                    size: 11,
                                    color: canAccess
                                        ? (resource.isPreview || lesson.isPreview
                                            ? AppColors.onSecondaryContainer
                                            : AppColors.success)
                                        : AppColors.error,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    canAccess
                                        ? (resource.isPreview || lesson.isPreview
                                            ? 'Free Preview'
                                            : 'Enrolled Access')
                                        : '🔒 Enrolled Only',
                                    style: AppTypography.labelSmall.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: canAccess
                                        ? (resource.isPreview || lesson.isPreview
                                            ? AppColors.onSecondaryContainer
                                            : AppColors.success)
                                        : AppColors.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLow,
                                borderRadius: AppSpacing.roundedSm,
                              ),
                              child: Text(
                                '${resource.type.toUpperCase()} File',
                                style: AppTypography.labelSmall.copyWith(fontSize: 10, color: AppColors.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isNarrow) ...[
                    const SizedBox(width: 12),
                    // Action buttons (Desktop / Wide)
                    if (canAccess) ...[
                      AppButton(
                        label: 'View',
                        icon: Icons.visibility_outlined,
                        variant: ButtonVariant.outline,
                        size: ButtonSize.sm,
                        onPressed: () => _handleOpenResource(
                          context: context,
                          course: course,
                          lesson: lesson,
                          resource: resource,
                          isEnrolled: isEnrolled,
                          isAuthor: isAuthor,
                          authUser: authUser,
                          streamService: streamService,
                          isDownload: false,
                        ),
                      ),
                      const SizedBox(width: 6),
                      AppButton(
                        label: 'Download',
                        icon: Icons.download_outlined,
                        variant: ButtonVariant.secondary,
                        size: ButtonSize.sm,
                        onPressed: () => _handleOpenResource(
                          context: context,
                          course: course,
                          lesson: lesson,
                          resource: resource,
                          isEnrolled: isEnrolled,
                          isAuthor: isAuthor,
                          authUser: authUser,
                          streamService: streamService,
                          isDownload: true,
                        ),
                      ),
                    ] else ...[
                      AppButton(
                        label: 'Unlock File',
                        icon: Icons.lock_outline,
                        variant: ButtonVariant.outline,
                        size: ButtonSize.sm,
                        onPressed: () => _handleOpenResource(
                          context: context,
                          course: course,
                          lesson: lesson,
                          resource: resource,
                          isEnrolled: isEnrolled,
                          isAuthor: isAuthor,
                          authUser: authUser,
                          streamService: streamService,
                          isDownload: false,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
              // Action buttons (Narrow / Mobile)
              if (isNarrow) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (canAccess) ...[
                      AppButton(
                        label: 'View',
                        icon: Icons.visibility_outlined,
                        variant: ButtonVariant.outline,
                        size: ButtonSize.sm,
                        onPressed: () => _handleOpenResource(
                          context: context,
                          course: course,
                          lesson: lesson,
                          resource: resource,
                          isEnrolled: isEnrolled,
                          isAuthor: isAuthor,
                          authUser: authUser,
                          streamService: streamService,
                          isDownload: false,
                        ),
                      ),
                      AppButton(
                        label: 'Download',
                        icon: Icons.download_outlined,
                        variant: ButtonVariant.secondary,
                        size: ButtonSize.sm,
                        onPressed: () => _handleOpenResource(
                          context: context,
                          course: course,
                          lesson: lesson,
                          resource: resource,
                          isEnrolled: isEnrolled,
                          isAuthor: isAuthor,
                          authUser: authUser,
                          streamService: streamService,
                          isDownload: true,
                        ),
                      ),
                    ] else ...[
                      AppButton(
                        label: 'Unlock File',
                        icon: Icons.lock_outline,
                        variant: ButtonVariant.outline,
                        size: ButtonSize.sm,
                        onPressed: () => _handleOpenResource(
                          context: context,
                          course: course,
                          lesson: lesson,
                          resource: resource,
                          isEnrolled: isEnrolled,
                          isAuthor: isAuthor,
                          authUser: authUser,
                          streamService: streamService,
                          isDownload: false,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(allCoursesProvider);
    final enrolments = ref.watch(enrolmentProvider);
    final authUser = ref.watch(authProvider);
    final streamService = ref.watch(lessonStreamServiceProvider);
    final isDesktop = AppHelpers.isDesktop(context);

    return coursesAsync.when(
      data: (courses) {
        final course = courses.firstWhere(
          (c) => c.id == widget.courseId,
          orElse: () => courses.first,
        );

        // Find all lessons flattened for navigation
        final allLessons = <LessonModel>[];
        for (final m in course.syllabus) {
          allLessons.addAll(m.lessons);
        }

        LessonModel? activeLesson;
        for (final l in allLessons) {
          if (l.id == _currentLessonId) activeLesson = l;
        }
        final LessonModel currentLesson = activeLesson ??
            (allLessons.isNotEmpty
                ? allLessons.first
                : const LessonModel(id: '1', courseId: '1', title: 'Course Overview', videoUrl: '', order: 1));

        final currentIndex = allLessons.indexWhere((l) => l.id == currentLesson.id);
        final hasPrevious = currentIndex > 0;
        final hasNext = currentIndex >= 0 && currentIndex < allLessons.length - 1;

        final isAuthor = authUser != null && (course.instructorId == authUser.id || course.instructor.id == authUser.id);
        final isEnrolled = isAuthor || enrolments.any((e) => e.courseId == course.id);
        final currentEnrolment = enrolments.firstWhere(
          (e) => e.courseId == course.id,
          orElse: () => EnrolmentModel(
            id: 'enr_preview',
            userId: authUser?.id ?? 'guest',
            courseId: course.id,
            progress: 0.0,
            completedLessons: [],
            lastPlayedPositions: const {},
            lessonNotes: const {},
            enrolledAt: DateTime.now(),
          ),
        );

        // Load existing note into controller if empty
        final savedNote = currentEnrolment.lessonNotes[currentLesson.id] ?? '';
        if (_noteController.text.isEmpty && savedNote.isNotEmpty) {
          _noteController.text = savedNote;
        }

        final initialPosition = currentEnrolment.lastPlayedPositions[currentLesson.id] ?? 0;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? AppSpacing.marginDesktop : AppSpacing.marginMobile,
            vertical: AppSpacing.lg,
          ),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Navigation Breadcrumb
                  InkWell(
                    onTap: () => context.go('/my-learning'),
                    borderRadius: AppSpacing.roundedMd,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 2.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_back, size: 18, color: AppColors.secondary),
                          const SizedBox(width: 8),
                          Text(
                            'Back to My Learning',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Main Video & Content Column
                      Expanded(
                        flex: 8,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Video Player / Server-Side Access Control Lock
                            FutureBuilder<LessonStreamResult>(
                              future: _getStreamFuture(
                                streamService,
                                courseId: course.id,
                                lesson: currentLesson,
                                userId: authUser?.id ?? 'guest',
                                isEnrolled: isEnrolled,
                              ),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return AspectRatio(
                                    aspectRatio: 16 / 9,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: AppSpacing.roundedLg,
                                      ),
                                      child: const Center(child: AppLoader(color: AppColors.secondary)),
                                    ),
                                  );
                                }

                                if (snapshot.hasError) {
                                  final err = snapshot.error;
                                  final isAccessDenied = err is LessonAccessDeniedException;

                                  return AspectRatio(
                                    aspectRatio: 16 / 9,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F172A),
                                        borderRadius: AppSpacing.roundedLg,
                                        border: Border.all(
                                          color: isAccessDenied
                                              ? AppColors.error.withOpacity(0.4)
                                              : AppColors.secondary.withOpacity(0.4),
                                        ),
                                      ),
                                      child: Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(24.0),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isAccessDenied ? Icons.lock_person_outlined : Icons.videocam_off_outlined,
                                                size: 56,
                                                color: isAccessDenied ? AppColors.secondaryFixed : AppColors.error,
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                isAccessDenied ? 'Lesson Locked' : 'Unable to Stream Video',
                                                style: AppTypography.headlineSmall.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                isAccessDenied
                                                    ? 'This lecture requires active enrollment. Enroll now to stream the full course.'
                                                    : 'Failed to connect to video streaming server: ${err.toString()}',
                                                style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 16),
                                              AppButton(
                                                label: isAccessDenied
                                                    ? (authUser == null ? 'Sign In to Unlock' : 'Enroll to Unlock')
                                                    : 'Retry Stream',
                                                variant: ButtonVariant.secondary,
                                                size: ButtonSize.sm,
                                                icon: isAccessDenied
                                                    ? (authUser == null ? Icons.login : Icons.shopping_cart_outlined)
                                                    : Icons.refresh,
                                                onPressed: isAccessDenied
                                                    ? (authUser == null
                                                        ? () {
                                                            AuthGateHelper.requireAuth(
                                                              context,
                                                              ref,
                                                              actionTitle: 'Watch Full Lesson',
                                                              reason: 'Sign in to access your enrolled courses and resume video lessons.',
                                                              onAuthenticated: () {
                                                                setState(() {
                                                                  _streamFuture = null;
                                                                });
                                                              },
                                                            );
                                                          }
                                                        : () => context.go('/course/${course.id}'))
                                                    : () => setState(() {
                                                          _streamFuture = null;
                                                        }),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                final streamResult = snapshot.data!;
                                final parsedDuration = _parseDurationSeconds(currentLesson.duration);
                                return CustomVideoPlayer(
                                  key: ValueKey('player_${currentLesson.id}'),
                                  videoUrl: streamResult.streamUrl,
                                  title: currentLesson.title,
                                  initialPositionSeconds: initialPosition,
                                  totalDurationSeconds: parsedDuration,
                                  onPositionChanged: (seconds) {
                                    ref.read(enrolmentProvider.notifier).savePlaybackPosition(
                                          course.id,
                                          currentLesson.id,
                                          seconds,
                                        );
                                  },
                                  onComplete: () {
                                    _handleCompleteLesson(course, currentLesson);
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 20),

                            // Title & Complete Button Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.secondary.withOpacity(0.12),
                                          borderRadius: AppSpacing.roundedFull,
                                        ),
                                        child: Text(
                                          'Lesson ${currentLesson.order} · ${course.category}',
                                          style: AppTypography.labelSmall.copyWith(
                                            color: AppColors.secondary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        currentLesson.title,
                                        style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w800),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Instructor: ${course.instructor.name}',
                                        style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                AppButton(
                                  label: currentEnrolment.completedLessons.contains(currentLesson.id)
                                      ? 'Completed'
                                      : 'Mark as Complete',
                                  variant: currentEnrolment.completedLessons.contains(currentLesson.id)
                                      ? ButtonVariant.secondary
                                      : ButtonVariant.outline,
                                  size: ButtonSize.sm,
                                  icon: Icons.check_circle,
                                  onPressed: () {
                                    final isAlreadyCompleted = currentEnrolment.completedLessons.contains(currentLesson.id);
                                    if (isAlreadyCompleted) {
                                      AppHelpers.showSnackBar(context, 'This lesson is already completed.');
                                      return;
                                    }
                                    _handleCompleteLesson(course, currentLesson);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Mobile Lesson Playlist Accordion
                            if (!isDesktop) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: AppSpacing.roundedLg,
                                  border: Border.all(color: AppColors.surfaceContainerHigh),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Course Playlist', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800)),
                                    const SizedBox(height: 12),
                                    LessonList(
                                      syllabus: course.syllabus,
                                      activeLessonId: _currentLessonId,
                                      completedLessonIds: currentEnrolment.completedLessons,
                                      onLessonSelected: (lesson) {
                                        setState(() {
                                          _currentLessonId = lesson.id;
                                          _streamFuture = null;
                                          _noteController.text = currentEnrolment.lessonNotes[lesson.id] ?? '';
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Tabs: Overview, Notes, Resources, Discussion
                            TabBar(
                              controller: _tabController,
                              labelColor: AppColors.primary,
                              unselectedLabelColor: AppColors.outline,
                              indicatorColor: AppColors.secondary,
                              indicatorWeight: 3,
                              tabs: const [
                                Tab(text: 'Overview'),
                                Tab(text: 'My Notes'),
                                Tab(text: 'Resources'),
                                Tab(text: 'Discussion'),
                              ],
                            ),
                            const SizedBox(height: 16),

                            SizedBox(
                              height: 320,
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  // Tab 1: Overview
                                  SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'About this Lesson',
                                          style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'In this lesson, you will master the foundational architectural patterns and data models required to build scalable enterprise web and mobile applications. Review the code blueprints in the resources tab and complete the quiz assessment upon finishing the video lecture.',
                                          style: AppTypography.bodyLarge.copyWith(height: 1.6),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Tab 2: Notes
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        alignment: WrapAlignment.spaceBetween,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: [
                                          Text(
                                            'Personal Lesson Notes',
                                            style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                                          ),
                                          TextButton.icon(
                                            style: TextButton.styleFrom(
                                              visualDensity: VisualDensity.compact,
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            ),
                                            icon: const Icon(Icons.save_outlined, size: 16, color: AppColors.secondary),
                                            label: const Text('Save Note', style: TextStyle(color: AppColors.secondary, fontSize: 12)),
                                            onPressed: () {
                                              ref.read(enrolmentProvider.notifier).saveLessonNote(
                                                    course.id,
                                                    currentLesson.id,
                                                    _noteController.text,
                                                  );
                                              AppHelpers.showSnackBar(context, 'Notes saved to your cloud profile!');
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Expanded(
                                        child: TextField(
                                          controller: _noteController,
                                          maxLines: null,
                                          expands: true,
                                          textAlignVertical: TextAlignVertical.top,
                                          decoration: InputDecoration(
                                            hintText: 'Type your notes for this lecture here...',
                                            hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.outline),
                                            contentPadding: const EdgeInsets.all(14),
                                            fillColor: AppColors.surfaceContainerLowest,
                                            filled: true,
                                            border: OutlineInputBorder(
                                              borderRadius: AppSpacing.roundedMd,
                                              borderSide: const BorderSide(color: AppColors.surfaceContainerHigh),
                                            ),
                                          ),
                                          onChanged: (val) {
                                            ref.read(enrolmentProvider.notifier).saveLessonNote(
                                                  course.id,
                                                  currentLesson.id,
                                                  val,
                                                );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Tab 3: Resources (Authenticated Cloudinary Raw Files & PDFs)
                                  Builder(
                                    builder: (context) {
                                      // Collect all other course resources
                                      final otherResources = <Map<String, dynamic>>[];
                                      for (final m in course.syllabus) {
                                        for (final l in m.lessons) {
                                          if (l.id != currentLesson.id) {
                                            for (final r in l.resources) {
                                              otherResources.add({
                                                'lesson': l,
                                                'resource': r,
                                              });
                                            }
                                          }
                                        }
                                      }

                                      return SingleChildScrollView(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Header Banner
                                            Container(
                                              padding: const EdgeInsets.all(14),
                                              margin: const EdgeInsets.only(bottom: 16),
                                              decoration: BoxDecoration(
                                                color: AppColors.surfaceContainerLow,
                                                borderRadius: AppSpacing.roundedMd,
                                                border: Border.all(color: AppColors.outlineVariant),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    isEnrolled || isAuthor ? Icons.folder_shared : Icons.lock_person_outlined,
                                                    color: isEnrolled || isAuthor ? AppColors.secondary : AppColors.outline,
                                                    size: 24,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          isEnrolled || isAuthor
                                                              ? 'Enrolled Scholar Access'
                                                              : (currentLesson.isPreview ? 'Free Preview Access' : 'Exclusive Course Resources'),
                                                          style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          isEnrolled || isAuthor
                                                              ? 'You have unlimited access to view and download all PDFs, blueprints, and assets.'
                                                              : 'Free preview files can be downloaded by everyone. Paid course assets require active enrollment.',
                                                          style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant, fontSize: 11),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // 1. Current Lesson Resources
                                            Text(
                                              'Resources for this Lecture',
                                              style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w800),
                                            ),
                                            const SizedBox(height: 8),

                                            if (currentLesson.resources.isNotEmpty)
                                              ...currentLesson.resources.map((res) {
                                                return _buildResourceCard(
                                                  context: context,
                                                  course: course,
                                                  lesson: currentLesson,
                                                  resource: res,
                                                  isEnrolled: isEnrolled,
                                                  isAuthor: isAuthor,
                                                  authUser: authUser,
                                                  streamService: streamService,
                                                );
                                              })
                                            else ...[
                                              // Fallback sample resources if none explicitly attached to this lesson
                                              _buildResourceCard(
                                                context: context,
                                                course: course,
                                                lesson: currentLesson,
                                                resource: LessonResource(
                                                  title: '${currentLesson.title} — Blueprint & Notes (PDF)',
                                                  cloudinaryPublicId: 'resources/${course.id}/${currentLesson.id}_blueprint',
                                                  type: 'pdf',
                                                  isPreview: currentLesson.isPreview,
                                                ),
                                                isEnrolled: isEnrolled,
                                                isAuthor: isAuthor,
                                                authUser: authUser,
                                                streamService: streamService,
                                              ),
                                              _buildResourceCard(
                                                context: context,
                                                course: course,
                                                lesson: currentLesson,
                                                resource: const LessonResource(
                                                  title: 'Starter Code & Schema Definitions (ZIP)',
                                                  cloudinaryPublicId: 'resources/demo/starter_code',
                                                  type: 'zip',
                                                  isPreview: true,
                                                ),
                                                isEnrolled: isEnrolled,
                                                isAuthor: isAuthor,
                                                authUser: authUser,
                                                streamService: streamService,
                                              ),
                                            ],

                                            // 2. Other Course Resources
                                            if (otherResources.isNotEmpty) ...[
                                              const SizedBox(height: 16),
                                              Text(
                                                'Other Course Files & Blueprints (${otherResources.length})',
                                                style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w800),
                                              ),
                                              const SizedBox(height: 8),
                                              ...otherResources.map((item) {
                                                final otherLesson = item['lesson'] as LessonModel;
                                                final otherRes = item['resource'] as LessonResource;
                                                return _buildResourceCard(
                                                  context: context,
                                                  course: course,
                                                  lesson: otherLesson,
                                                  resource: otherRes,
                                                  isEnrolled: isEnrolled,
                                                  isAuthor: isAuthor,
                                                  authUser: authUser,
                                                  streamService: streamService,
                                                  lessonContextTitle: otherLesson.title,
                                                );
                                              }),
                                            ],
                                          ],
                                        ),
                                      );
                                    },
                                  ),

                                  // Tab 4: Discussion
                                  Column(
                                    children: [
                                      Expanded(
                                        child: ListView.separated(
                                          itemCount: _discussionMessages.length,
                                          separatorBuilder: (_, __) => const Divider(height: 16),
                                          itemBuilder: (context, idx) {
                                            final msg = _discussionMessages[idx];
                                            return ListTile(
                                              contentPadding: EdgeInsets.zero,
                                              leading: CircleAvatar(
                                                backgroundColor: AppColors.secondary.withOpacity(0.2),
                                                child: Text(
                                                  msg['user']!.substring(0, 1),
                                                  style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              title: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(msg['user']!, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold)),
                                                  Text(msg['time']!, style: AppTypography.labelSmall.copyWith(color: AppColors.outline)),
                                                ],
                                              ),
                                              subtitle: Padding(
                                                padding: const EdgeInsets.only(top: 4.0),
                                                child: Text(msg['message']!, style: AppTypography.bodySmall),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _discussionController,
                                              decoration: InputDecoration(
                                                hintText: 'Ask a question about this lesson...',
                                                hintStyle: AppTypography.bodySmall,
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                                border: OutlineInputBorder(
                                                  borderRadius: AppSpacing.roundedFull,
                                                  borderSide: const BorderSide(color: AppColors.surfaceContainerHigh),
                                                ),
                                              ),
                                              onSubmitted: (_) => _postQuestion(),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(Icons.send, color: AppColors.secondary),
                                            onPressed: _postQuestion,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Right Sidebar: Desktop Sticky Playlist
                      if (isDesktop) ...[
                        const SizedBox(width: 28),
                        Expanded(
                          flex: 4,
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: AppSpacing.roundedLg,
                              border: Border.all(color: AppColors.surfaceContainerHigh),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Course Syllabus',
                                      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
                                    ),
                                    Text(
                                      '${(currentEnrolment.progress * 100).round()}%',
                                      style: AppTypography.labelMedium.copyWith(
                                        color: AppColors.secondary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: AppSpacing.roundedFull,
                                  child: LinearProgressIndicator(
                                    value: currentEnrolment.progress,
                                    minHeight: 6,
                                    backgroundColor: AppColors.surfaceContainerHigh,
                                    valueColor: const AlwaysStoppedAnimation(AppColors.secondary),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                LessonList(
                                  syllabus: course.syllabus,
                                  activeLessonId: _currentLessonId,
                                  completedLessonIds: currentEnrolment.completedLessons,
                                  onLessonSelected: (lesson) {
                                    setState(() {
                                      _currentLessonId = lesson.id;
                                      _noteController.text = currentEnrolment.lessonNotes[lesson.id] ?? '';
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Bottom Action Bar: Previous & Next Lesson Navigation
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppSpacing.roundedLg,
                      border: Border.all(color: AppColors.surfaceContainerHigh),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'Previous',
                            variant: ButtonVariant.outline,
                            size: ButtonSize.sm,
                            icon: Icons.arrow_back,
                            onPressed: hasPrevious
                                ? () {
                                    final prevLesson = allLessons[currentIndex - 1];
                                    setState(() {
                                      _currentLessonId = prevLesson.id;
                                      _noteController.text = currentEnrolment.lessonNotes[prevLesson.id] ?? '';
                                    });
                                  }
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppButton(
                            label: 'Next Lesson',
                            variant: ButtonVariant.primary,
                            size: ButtonSize.sm,
                            icon: Icons.arrow_forward,
                            onPressed: hasNext
                                ? () {
                                    final nextLesson = allLessons[currentIndex + 1];
                                    setState(() {
                                      _currentLessonId = nextLesson.id;
                                      _noteController.text = currentEnrolment.lessonNotes[nextLesson.id] ?? '';
                                    });
                                  }
                                : () {
                                    // Completed last lesson -> route to quiz or certificates
                                    if (course.quizzes.isNotEmpty) {
                                      context.go('/quiz/${course.quizzes.first.id}');
                                    } else {
                                      _handleCompleteLesson(course, allLessons[currentIndex]);
                                      context.go('/my-learning');
                                    }
                                  },
                          ),
                        ),
                      ],
                    ),
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

  void _handleCompleteLesson(CourseModel course, LessonModel lesson) {
    final isNew = ref.read(enrolmentProvider.notifier).completeLesson(
      course.id,
      lesson.id,
      course.totalLessons,
      courseTitle: course.title,
      instructorName: course.instructor.name,
    );

    if (isNew && mounted) {
      final enrolments = ref.read(enrolmentProvider);
      final enrol = enrolments.firstWhere(
        (e) => e.courseId == course.id,
        orElse: () => EnrolmentModel(
          id: 'temp',
          userId: 'user',
          courseId: course.id,
          completedLessons: [lesson.id],
          progress: 1.0,
          enrolledAt: DateTime.now(),
        ),
      );

      if (enrol.isCompleted || enrol.progress >= 1.0) {
        _showCourseCompletionCelebrationModal(context, course);
      } else {
        AppHelpers.showSnackBar(context, 'Lesson complete! +50 XP awarded 🎯');
      }
    }
  }

  void _showCourseCompletionCelebrationModal(BuildContext context, CourseModel course) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedXl),
        backgroundColor: Colors.white,
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium_rounded, size: 48, color: AppColors.secondary),
            ),
            const SizedBox(height: 16),
            Text(
              '🎉 Course Completed!',
              style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Congratulations! You have completed 100% of "${course.title}". Your verified certificate of completion is now issued and accredited!',
              style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'View Verified Certificate 🎓',
              variant: ButtonVariant.secondary,
              isFullWidth: true,
              icon: Icons.workspace_premium,
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/certificates');
              },
            ),
            const SizedBox(height: 8),
            AppButton(
              label: 'Go to My Learning',
              variant: ButtonVariant.outline,
              isFullWidth: true,
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/my-learning');
              },
            ),
          ],
        ),
      ),
    );
  }
}
