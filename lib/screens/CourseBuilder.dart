import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../models/course_model.dart';
import '../models/lesson_model.dart';
import '../providers/auth_provider.dart';
import '../providers/course_provider.dart';
import '../styles/colors.dart';
import '../styles/spacing.dart';
import '../styles/typography.dart';
import '../components/Button.dart';
import '../components/Loader.dart';
import '../services/cloudinary_upload_service.dart';
import '../utils/helpers.dart';

class CourseBuilderScreen extends ConsumerStatefulWidget {
  final String? courseId;

  const CourseBuilderScreen({
    super.key,
    this.courseId,
  });

  @override
  ConsumerState<CourseBuilderScreen> createState() => _CourseBuilderScreenState();
}

class _DraftLesson {
  String id;
  String title;
  String duration;
  String cloudinaryPublicId;
  String videoUrl;
  bool isPreview;

  _DraftLesson({
    required this.id,
    required this.title,
    required this.duration,
    this.cloudinaryPublicId = '',
    this.videoUrl = '',
    this.isPreview = false,
  });
}

class _DraftModule {
  String id;
  String title;
  List<_DraftLesson> lessons;

  _DraftModule({
    required this.id,
    required this.title,
    required this.lessons,
  });
}

class _CourseBuilderScreenState extends ConsumerState<CourseBuilderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController(text: 'Production Flutter & Cloudflare Masterclass');
  final _categoryController = TextEditingController(text: 'Development');
  final _priceController = TextEditingController(text: '49.99');
  final _levelController = TextEditingController(text: 'Intermediate');
  final _thumbnailController = TextEditingController(
    text: 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=600',
  );
  final _descriptionController = TextEditingController(
    text: 'Learn how to build, secure, and deploy full-stack Flutter applications with Cloudinary and Cloudflare Workers.',
  );

  bool _isPublishing = false;
  bool _isLoadingCourse = false;
  bool _isEditMode = false;
  final _uploadService = CloudinaryUploadService();

  final List<_DraftModule> _modules = [
    _DraftModule(
      id: 'mod_1',
      title: 'Module 1: Architecture & Setup',
      lessons: [
        _DraftLesson(
          id: 'les_1_1',
          title: 'Welcome & Curriculum Overview',
          duration: '10m',
          cloudinaryPublicId: 'courses/demo/intro_teaser',
          videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
          isPreview: true,
        ),
        _DraftLesson(
          id: 'les_1_2',
          title: 'Zero-Card Cloud Architecture with Cloudinary',
          duration: '22m',
          cloudinaryPublicId: 'courses/demo/c1_arch_deep_dive',
          videoUrl: '', // Non-preview: NO playable raw URL stored
          isPreview: false,
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.courseId != null && widget.courseId!.isNotEmpty) {
      _isEditMode = true;
      _loadExistingCourse(widget.courseId!);
    }
  }

  Future<void> _loadExistingCourse(String courseId) async {
    setState(() => _isLoadingCourse = true);
    final course = await ref.read(courseServiceProvider).getCourseById(courseId);
    if (course != null && mounted) {
      setState(() {
        _titleController.text = course.title;
        _categoryController.text = course.category;
        _priceController.text = course.price.toStringAsFixed(2);
        _levelController.text = course.level;
        _thumbnailController.text = course.thumbnailUrl;
        _descriptionController.text = course.whatYouWillLearn.join('\n');
        _modules.clear();
        for (final m in course.syllabus) {
          _modules.add(
            _DraftModule(
              id: m.id,
              title: m.title,
              lessons: m.lessons
                  .map((l) => _DraftLesson(
                        id: l.id,
                        title: l.title,
                        duration: l.duration,
                        cloudinaryPublicId: l.cloudinaryPublicId ?? '',
                        videoUrl: l.videoUrl,
                        isPreview: l.isPreview,
                      ))
                  .toList(),
            ),
          );
        }
        _isLoadingCourse = false;
      });
    } else {
      if (mounted) setState(() => _isLoadingCourse = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _levelController.dispose();
    _thumbnailController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addModule() {
    setState(() {
      final nextIdx = _modules.length + 1;
      _modules.add(
        _DraftModule(
          id: 'mod_$nextIdx',
          title: 'Module $nextIdx: Core Implementation',
          lessons: [],
        ),
      );
    });
  }

  Future<void> _showAddLessonModal(int moduleIndex) async {
    final lessonTitleCtrl = TextEditingController(text: 'New Lecture Video');
    final durationCtrl = TextEditingController(text: '15m');
    bool isPreview = false;
    bool isUploading = false;
    double uploadProgress = 0.0;
    String uploadStatusText = '';
    String uploadedPublicId = '';
    String uploadedSecureUrl = '';
    String? selectedFileName;
    int? selectedFileSize;
    String? uploadErrorMessage;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final canAddToModule = uploadedPublicId.isNotEmpty && !isUploading;

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
              title: Row(
                children: [
                  const Icon(Icons.video_library, color: AppColors.secondary),
                  const SizedBox(width: 10),
                  Text('Add Lesson & Upload Video', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: lessonTitleCtrl,
                      decoration: const InputDecoration(labelText: 'Lesson Title *'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: durationCtrl,
                      decoration: const InputDecoration(labelText: 'Duration (e.g. 15m)'),
                    ),
                    const SizedBox(height: 14),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Free Preview Lesson'),
                      subtitle: const Text('Allow guests to watch without enrolling'),
                      value: isPreview,
                      activeColor: AppColors.secondary,
                      onChanged: isUploading
                          ? null
                          : (val) {
                              setDialogState(() {
                                isPreview = val;
                                // Reset upload if access preset changes
                                if (uploadedPublicId.isNotEmpty) {
                                  uploadedPublicId = '';
                                  uploadedSecureUrl = '';
                                  selectedFileName = null;
                                  selectedFileSize = null;
                                }
                              });
                            },
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: AppSpacing.roundedMd,
                        border: Border.all(color: AppColors.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.cloud_upload_outlined, color: AppColors.secondary, size: 20),
                              const SizedBox(width: 8),
                              Text('Cloudinary Video Upload', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isPreview
                                ? 'Preset: edusphere_public_preview (Locked: Public)'
                                : 'Preset: edusphere_authenticated (Locked: Authenticated)',
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isPreview ? AppColors.secondary : AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (selectedFileName != null && uploadedPublicId.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  const Icon(Icons.movie_outlined, size: 16, color: AppColors.secondary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '$selectedFileName (${((selectedFileSize ?? 0) / (1024 * 1024)).toStringAsFixed(1)} MB)',
                                      style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (isUploading) ...[
                            LinearProgressIndicator(
                              value: uploadProgress > 0 ? uploadProgress : null,
                              color: AppColors.secondary,
                              backgroundColor: AppColors.surfaceContainerHigh,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              uploadStatusText.isNotEmpty
                                  ? uploadStatusText
                                  : 'Uploading: ${(uploadProgress * 100).toStringAsFixed(0)}%',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
                            ),
                          ] else if (uploadedPublicId.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryContainer,
                                borderRadius: AppSpacing.roundedSm,
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: AppColors.secondary, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Upload Verified & Stored', style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w700)),
                                        Text('Public ID: $uploadedPublicId', style: AppTypography.bodySmall.copyWith(fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            AppButton(
                              label: uploadErrorMessage != null ? 'Retry Upload' : 'Pick & Upload Video File',
                              variant: ButtonVariant.outline,
                              size: ButtonSize.sm,
                              icon: Icons.upload_file,
                              isLoading: isUploading,
                              onPressed: () async {
                                setDialogState(() {
                                  uploadErrorMessage = null;
                                });

                                try {
                                  final pickResult = await FilePicker.platform.pickFiles(
                                    type: FileType.video,
                                    withData: true,
                                  );

                                  if (pickResult == null || pickResult.files.isEmpty) {
                                    return;
                                  }

                                  final pickedFile = pickResult.files.first;
                                  final fileBytes = pickedFile.bytes;
                                  final fileSize = pickedFile.size;
                                  final fileName = pickedFile.name;

                                  // Client-side 100MB hard limit check
                                  if (fileSize > CloudinaryUploadService.maxFileSizeBytes) {
                                    final sizeMb = (fileSize / (1024 * 1024)).toStringAsFixed(1);
                                    final err = 'Video file size ($sizeMb MB) exceeds the 100MB Cloudinary free tier limit. Please compress or trim the video.';
                                    setDialogState(() {
                                      selectedFileName = null;
                                      selectedFileSize = null;
                                      uploadedPublicId = '';
                                      uploadErrorMessage = err;
                                    });
                                    if (mounted) {
                                      AppHelpers.showSnackBar(context, err, isError: true);
                                    }
                                    return;
                                  }

                                  if (fileBytes == null) {
                                    throw Exception('Unable to read file bytes from device storage.');
                                  }

                                  setDialogState(() {
                                    selectedFileName = fileName;
                                    selectedFileSize = fileSize;
                                    isUploading = true;
                                    uploadProgress = 0.05;
                                    uploadStatusText = 'Initiating upload to Cloudinary...';
                                  });

                                  final courseId = widget.courseId ?? 'course_${DateTime.now().millisecondsSinceEpoch}';
                                  final lessonId = 'les_${DateTime.now().millisecondsSinceEpoch}';

                                  final uploadResult = await _uploadService.uploadLessonVideo(
                                    courseId: courseId,
                                    lessonId: lessonId,
                                    fileName: fileName,
                                    fileBytes: fileBytes,
                                    isPreview: isPreview,
                                    onProgress: (progress, sent, total) {
                                      setDialogState(() {
                                        uploadProgress = progress;
                                        final sentMb = (sent / (1024 * 1024)).toStringAsFixed(1);
                                        final totalMb = (total / (1024 * 1024)).toStringAsFixed(1);
                                        uploadStatusText = 'Uploading: ${(progress * 100).toStringAsFixed(0)}% ($sentMb MB / $totalMb MB)';
                                      });
                                    },
                                  );

                                  setDialogState(() {
                                    isUploading = false;
                                    uploadedPublicId = uploadResult.publicId;
                                    uploadedSecureUrl = uploadResult.secureUrl;
                                    if (uploadResult.durationSeconds > 0) {
                                      final m = uploadResult.durationSeconds ~/ 60;
                                      final s = uploadResult.durationSeconds % 60;
                                      final autoDuration = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
                                      durationCtrl.text = autoDuration;
                                      uploadStatusText = 'Upload completed! (Duration: $autoDuration)';
                                    } else {
                                      uploadStatusText = 'Upload completed!';
                                    }
                                  });
                                } catch (e) {
                                  // Clean up state on upload failure: remove file name and block add button
                                  setDialogState(() {
                                    isUploading = false;
                                    uploadProgress = 0.0;
                                    selectedFileName = null;
                                    selectedFileSize = null;
                                    uploadedPublicId = '';
                                    uploadedSecureUrl = '';
                                    uploadErrorMessage = e.toString();
                                  });
                                  if (mounted) {
                                    AppHelpers.showSnackBar(context, 'Upload failed: $e', isError: true);
                                  }
                                }
                              },
                            ),
                          if (uploadErrorMessage != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.08),
                                borderRadius: AppSpacing.roundedSm,
                                border: Border.all(color: AppColors.error.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, size: 18, color: AppColors.error),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      uploadErrorMessage!,
                                      style: AppTypography.bodySmall.copyWith(color: AppColors.error, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isUploading ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                AppButton(
                  label: 'Add to Module',
                  variant: ButtonVariant.primary,
                  size: ButtonSize.sm,
                  onPressed: canAddToModule
                      ? () {
                          if (lessonTitleCtrl.text.trim().isEmpty) return;
                          final lessonId = 'les_${DateTime.now().millisecondsSinceEpoch}';
                          setState(() {
                            _modules[moduleIndex].lessons.add(
                              _DraftLesson(
                                id: lessonId,
                                title: lessonTitleCtrl.text.trim(),
                                duration: durationCtrl.text.trim().isEmpty ? '15m' : durationCtrl.text.trim(),
                                cloudinaryPublicId: uploadedPublicId,
                                videoUrl: isPreview ? uploadedSecureUrl : '',
                                isPreview: isPreview,
                              ),
                            );
                          });
                          Navigator.pop(ctx);
                        }
                      : () {
                          AppHelpers.showSnackBar(
                            context,
                            'Please upload a video to Cloudinary before adding this lesson.',
                            isError: true,
                          );
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handlePublishCourse() async {
    if (_titleController.text.trim().isEmpty) {
      AppHelpers.showSnackBar(context, 'Please enter a valid course title', isError: true);
      return;
    }

    setState(() => _isPublishing = true);

    try {
      final user = ref.read(authProvider);
      final price = double.tryParse(_priceController.text.trim()) ?? 49.99;
      final courseId = (_isEditMode && widget.courseId != null && widget.courseId!.isNotEmpty)
          ? widget.courseId!
          : 'course_${DateTime.now().millisecondsSinceEpoch}';

      final syllabusModules = _modules.asMap().entries.map((modEntry) {
        final mod = modEntry.value;
        return ModuleModel(
          id: mod.id,
          title: mod.title,
          description: '${mod.title} description.',
          lessons: mod.lessons.asMap().entries.map((lesEntry) {
            final les = lesEntry.value;
            return LessonModel(
              id: les.id,
              courseId: courseId,
              title: les.title,
              duration: les.duration,
              videoUrl: les.videoUrl, // Only populated for preview lessons; empty for paid
              cloudinaryPublicId: les.cloudinaryPublicId,
              order: lesEntry.key + 1,
              isPreview: les.isPreview,
            );
          }).toList(),
        );
      }).toList();

      final course = CourseModel(
        id: courseId,
        title: _titleController.text.trim(),
        category: _categoryController.text.trim().isEmpty ? 'Development' : _categoryController.text.trim(),
        instructorId: user?.id ?? 'inst_me',
        instructor: InstructorInfo(
          id: user?.id ?? 'inst_me',
          name: user?.name.isNotEmpty == true ? user!.name : 'Lead Instructor',
          title: 'Senior Instructor & Subject Matter Expert',
          avatarUrl: user?.photoUrl ?? 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
          bio: user?.bio ?? 'Passionate educator and industry specialist.',
        ),
        price: price,
        originalPrice: (price * 1.25).roundToDouble(),
        discount: 20,
        level: _levelController.text.trim().isEmpty ? 'All Levels' : _levelController.text.trim(),
        language: 'English',
        duration: '12h 30m',
        rating: 5.0,
        enrolmentCount: 0,
        thumbnailUrl: _thumbnailController.text.trim().isEmpty
            ? 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=600'
            : _thumbnailController.text.trim(),
        previewVideoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        syllabus: syllabusModules,
        requirements: [
          'Basic understanding of programming fundamentals',
          'A computer with modern web browser or IDE installed',
        ],
        whatYouWillLearn: [
          'Master modern industry best practices and architectures',
          'Build end-to-end full stack mobile and web projects',
          'Deploy applications to production and handle scaling',
        ],
        isFeatured: true,
        isTrending: true,
      );

      if (_isEditMode) {
        await ref.read(courseServiceProvider).updateCourse(course);
        ref.invalidate(allCoursesProvider);
        ref.invalidate(courseByIdProvider(courseId));
        if (mounted) {
          AppHelpers.showSnackBar(context, '🎉 Course "${course.title}" updated successfully!');
          context.go('/instructor');
        }
      } else {
        await ref.read(courseServiceProvider).publishCourse(course);
        ref.invalidate(allCoursesProvider);
        if (mounted) {
          AppHelpers.showSnackBar(context, '🎉 Course "${course.title}" published! Available to all students.');
          context.go('/instructor');
        }
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Failed to save course: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = AppHelpers.isDesktop(context);

    if (_isLoadingCourse) {
      return const Scaffold(
        body: Center(child: AppLoader(color: AppColors.secondary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? AppSpacing.marginDesktop : AppSpacing.marginMobile,
          vertical: AppSpacing.xl,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Wrap(
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEditMode ? 'Edit Course' : 'Create New Course',
                        style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isEditMode
                            ? 'Update curriculum, pricing, and video lectures'
                            : 'Build your curriculum, upload videos to Cloudinary, and publish to students',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                  AppButton(
                    label: _isPublishing
                        ? 'Saving...'
                        : (_isEditMode ? 'Save Changes' : 'Publish Course'),
                    variant: ButtonVariant.secondary,
                    size: ButtonSize.md,
                    icon: _isEditMode ? Icons.save : Icons.rocket_launch,
                    isLoading: _isPublishing,
                    onPressed: _handlePublishCourse,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Basic Course Information Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppSpacing.roundedLg,
                  border: Border.all(color: AppColors.surfaceContainerHigh),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Course Details', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Course Title *'),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _categoryController,
                            decoration: const InputDecoration(labelText: 'Category'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            decoration: const InputDecoration(labelText: 'Price (\$USD) *', prefixText: '\$ '),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _levelController,
                            decoration: const InputDecoration(labelText: 'Level (e.g. Beginner, Advanced)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _thumbnailController,
                      decoration: const InputDecoration(
                        labelText: 'Thumbnail Image URL',
                        hintText: 'https://images.unsplash.com/...',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Course Description & Highlights'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Curriculum / Syllabus Modules Card
              Container(
                padding: const EdgeInsets.all(24),
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
                        Text('Curriculum Modules', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800)),
                        AppButton(
                          label: 'Add Module',
                          variant: ButtonVariant.outline,
                          size: ButtonSize.sm,
                          icon: Icons.add,
                          onPressed: _addModule,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _modules.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, modIdx) {
                        final mod = _modules[modIdx];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: AppSpacing.roundedMd,
                            border: Border.all(color: AppColors.outlineVariant),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.folder_outlined, size: 20, color: AppColors.secondary),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(mod.title, style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700)),
                                  ),
                                  AppButton(
                                    label: 'Add Lesson',
                                    variant: ButtonVariant.outline,
                                    size: ButtonSize.sm,
                                    icon: Icons.video_call,
                                    onPressed: () => _showAddLessonModal(modIdx),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                    onPressed: () {
                                      if (_modules.length > 1) {
                                        setState(() => _modules.removeAt(modIdx));
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (mod.lessons.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text(
                                    'No lessons added yet. Click "Add Lesson" to upload a video.',
                                    style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
                                  ),
                                )
                              else
                                Column(
                                  children: mod.lessons.asMap().entries.map((lesEntry) {
                                    final lesIdx = lesEntry.key;
                                    final les = lesEntry.value;
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: AppSpacing.roundedSm,
                                        border: Border.all(color: AppColors.surfaceContainerHigh),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            les.isPreview ? Icons.visibility : Icons.lock_outline,
                                            size: 18,
                                            color: les.isPreview ? AppColors.secondary : AppColors.outline,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(les.title, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600)),
                                                const SizedBox(height: 2),
                                                Row(
                                                  children: [
                                                    Text(les.duration, style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: les.isPreview ? AppColors.secondaryContainer : AppColors.surfaceContainerHigh,
                                                        borderRadius: AppSpacing.roundedSm,
                                                      ),
                                                      child: Text(
                                                        les.isPreview
                                                            ? 'Free Preview'
                                                            : 'Authenticated (Cloudinary: ${les.cloudinaryPublicId})',
                                                        style: AppTypography.labelSmall.copyWith(
                                                          fontSize: 10,
                                                          color: les.isPreview ? AppColors.onSecondaryContainer : AppColors.onSurfaceVariant,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.close, size: 16, color: AppColors.onSurfaceVariant),
                                            onPressed: () {
                                              setState(() => mod.lessons.removeAt(lesIdx));
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Bottom Publish / Save CTA
              Center(
                child: AppButton(
                  label: _isEditMode ? 'Save & Update Course' : 'Publish Course to Students',
                  variant: ButtonVariant.secondary,
                  size: ButtonSize.lg,
                  icon: _isEditMode ? Icons.save : Icons.rocket_launch,
                  isLoading: _isPublishing,
                  onPressed: _handlePublishCourse,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
