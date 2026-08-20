import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../models/course_model.dart';
import '../models/lesson_model.dart';
import '../models/quiz_model.dart';
import '../providers/auth_provider.dart';
import '../providers/course_provider.dart';
import '../services/quiz_service.dart';
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
  List<LessonResource> resources;

  _DraftLesson({
    required this.id,
    required this.title,
    required this.duration,
    this.cloudinaryPublicId = '',
    this.videoUrl = '',
    this.isPreview = false,
    List<LessonResource>? resources,
  }) : resources = resources ?? [];
}

class _DraftModule {
  String id;
  String title;
  String description;
  List<_DraftLesson> lessons;

  _DraftModule({
    required this.id,
    required this.title,
    this.description = '',
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
  final _quizService = QuizService();

  final List<_DraftModule> _modules = [
    _DraftModule(
      id: 'mod_1',
      title: 'Module 1: Architecture & Setup',
      description: 'Foundations of clean architecture, environment configuration, and state setup.',
      lessons: [
        _DraftLesson(
          id: 'les_1_1',
          title: 'Welcome & Curriculum Overview',
          duration: '10m',
          cloudinaryPublicId: 'courses/demo/intro_teaser',
          videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
          isPreview: true,
          resources: [
            const LessonResource(
              title: 'Curriculum Roadmap (PDF)',
              cloudinaryPublicId: 'resources/demo/curriculum_roadmap',
              type: 'pdf',
              isPreview: true,
            ),
          ],
        ),
        _DraftLesson(
          id: 'les_1_2',
          title: 'Zero-Card Cloud Architecture with Cloudinary',
          duration: '22m',
          cloudinaryPublicId: 'courses/demo/c1_arch_deep_dive',
          videoUrl: '',
          isPreview: false,
          resources: [],
        ),
      ],
    ),
  ];

  final List<QuizModel> _quizzes = [];

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
              description: m.description,
              lessons: m.lessons
                  .map((l) => _DraftLesson(
                        id: l.id,
                        title: l.title,
                        duration: l.duration,
                        cloudinaryPublicId: l.cloudinaryPublicId ?? '',
                        videoUrl: l.videoUrl,
                        isPreview: l.isPreview,
                        resources: List<LessonResource>.from(l.resources),
                      ))
                  .toList(),
            ),
          );
        }
        _quizzes.clear();
        _quizzes.addAll(course.quizzes);
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

  /// Opens dialog to create a new module or edit/rename an existing module
  Future<void> _showModuleDialog({int? editIndex}) async {
    final isEditing = editIndex != null;
    final existingMod = isEditing ? _modules[editIndex] : null;

    final titleCtrl = TextEditingController(
      text: existingMod != null ? existingMod.title : 'Module ${_modules.length + 1}: ',
    );
    final descCtrl = TextEditingController(
      text: existingMod != null ? existingMod.description : '',
    );

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
          title: Row(
            children: [
              Icon(isEditing ? Icons.edit_note : Icons.create_new_folder_outlined, color: AppColors.secondary),
              const SizedBox(width: 10),
              Text(
                isEditing ? 'Edit Module Details' : 'Add Curriculum Module',
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Module Title *',
                    hintText: 'e.g. Module 2: State Management & Architecture',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Module Summary / Description',
                    hintText: 'Brief summary of concepts taught in this module...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            AppButton(
              label: isEditing ? 'Save Changes' : 'Create Module',
              variant: ButtonVariant.secondary,
              size: ButtonSize.sm,
              onPressed: () {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) {
                  AppHelpers.showSnackBar(context, 'Please enter a module title', isError: true);
                  return;
                }

                setState(() {
                  if (isEditing) {
                    existingMod!.title = title;
                    existingMod.description = descCtrl.text.trim();
                  } else {
                    final nextId = 'mod_${DateTime.now().millisecondsSinceEpoch}';
                    _modules.add(
                      _DraftModule(
                        id: nextId,
                        title: title,
                        description: descCtrl.text.trim(),
                        lessons: [],
                      ),
                    );
                  }
                });

                Navigator.pop(ctx);
                if (isEditing) {
                  AppHelpers.showSnackBar(context, 'Module updated successfully');
                }
              },
            ),
          ],
        );
      },
    );
  }

  /// Removes a lesson and cleans up orphaned Cloudinary asset from remote storage
  Future<void> _removeLesson(int modIdx, int lesIdx) async {
    final lesson = _modules[modIdx].lessons[lesIdx];
    final publicId = lesson.cloudinaryPublicId;

    // Delete remote resources
    for (final res in lesson.resources) {
      if (res.cloudinaryPublicId != null && res.cloudinaryPublicId!.isNotEmpty) {
        await _uploadService.deleteCloudinaryAsset(
          publicId: res.cloudinaryPublicId!,
          courseId: widget.courseId,
          resourceType: 'raw',
        );
      }
    }

    setState(() {
      _modules[modIdx].lessons.removeAt(lesIdx);
    });

    if (publicId.isNotEmpty) {
      debugPrint('[CourseBuilder] 🗑️ Deleting removed lesson asset from Cloudinary: $publicId');
      await _uploadService.deleteCloudinaryAsset(
        publicId: publicId,
        courseId: widget.courseId,
        resourceType: 'video',
      );
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Lesson removed & remote storage cleaned up');
      }
    }
  }

  /// Modal for adding/editing a lesson with real Video and Resource Uploader
  Future<void> _showAddOrEditLessonModal(int moduleIndex, {int? lessonIndex}) async {
    final isEditing = lessonIndex != null;
    final existingLes = isEditing ? _modules[moduleIndex].lessons[lessonIndex] : null;

    final lessonTitleCtrl = TextEditingController(text: existingLes?.title ?? 'New Lecture Video');
    final durationCtrl = TextEditingController(text: existingLes?.duration ?? '15m');
    bool isPreview = existingLes?.isPreview ?? false;
    bool isUploadingVideo = false;
    double videoProgress = 0.0;
    String videoStatusText = '';
    String uploadedPublicId = existingLes?.cloudinaryPublicId ?? '';
    String uploadedSecureUrl = existingLes?.videoUrl ?? '';
    final String oldPublicId = existingLes?.cloudinaryPublicId ?? '';
    String? selectedVideoFileName;
    int? selectedVideoFileSize;
    String? videoUploadErrorMessage;

    // Downloadable Resources state
    final List<LessonResource> draftResources = List<LessonResource>.from(existingLes?.resources ?? []);
    bool isUploadingResource = false;
    double resourceProgress = 0.0;
    String resourceStatusText = '';
    String? resourceUploadErrorMessage;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final canSaveLesson = uploadedPublicId.isNotEmpty && !isUploadingVideo && !isUploadingResource;

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
              title: Row(
                children: [
                  Icon(isEditing ? Icons.video_settings : Icons.video_library, color: AppColors.secondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isEditing ? 'Edit Lesson & Content' : 'Add Lesson & Upload Content',
                      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 580,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Lesson Basic Info
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
                        onChanged: isUploadingVideo
                            ? null
                            : (val) {
                                setDialogState(() {
                                  isPreview = val;
                                  if (uploadedPublicId.isNotEmpty && uploadedPublicId != oldPublicId) {
                                    uploadedPublicId = '';
                                    uploadedSecureUrl = '';
                                    selectedVideoFileName = null;
                                    selectedVideoFileSize = null;
                                  }
                                });
                              },
                      ),
                      const SizedBox(height: 16),

                      // 1. Lecture Video Upload Card
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
                                Expanded(
                                  child: Text(
                                    isEditing ? 'Lecture Video Stream' : 'Cloudinary Video Upload',
                                    style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
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
                            if (uploadedPublicId.isNotEmpty && selectedVideoFileName == null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle_outline, size: 16, color: AppColors.secondary),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Current Asset: $uploadedPublicId',
                                        style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w600),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (selectedVideoFileName != null && uploadedPublicId.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    const Icon(Icons.movie_outlined, size: 16, color: AppColors.secondary),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '$selectedVideoFileName (${((selectedVideoFileSize ?? 0) / (1024 * 1024)).toStringAsFixed(1)} MB)',
                                        style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w600),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (isUploadingVideo) ...[
                              LinearProgressIndicator(
                                value: videoProgress > 0 ? videoProgress : null,
                                color: AppColors.secondary,
                                backgroundColor: AppColors.surfaceContainerHigh,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                videoStatusText.isNotEmpty
                                    ? videoStatusText
                                    : 'Uploading: ${(videoProgress * 100).toStringAsFixed(0)}%',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
                              ),
                            ] else
                              AppButton(
                                label: videoUploadErrorMessage != null
                                    ? 'Retry Video Upload'
                                    : (uploadedPublicId.isNotEmpty ? 'Replace Video File' : 'Pick & Upload Video File'),
                                variant: ButtonVariant.outline,
                                size: ButtonSize.sm,
                                icon: Icons.upload_file,
                                isLoading: isUploadingVideo,
                                onPressed: () async {
                                  setDialogState(() {
                                    videoUploadErrorMessage = null;
                                  });

                                  try {
                                    final pickResult = await FilePicker.platform.pickFiles(
                                      type: FileType.video,
                                      withData: true,
                                    );

                                    if (pickResult == null || pickResult.files.isEmpty) return;

                                    final pickedFile = pickResult.files.first;
                                    final fileBytes = pickedFile.bytes;
                                    final fileSize = pickedFile.size;
                                    final fileName = pickedFile.name;

                                    if (fileSize > CloudinaryUploadService.maxFileSizeBytes) {
                                      final sizeMb = (fileSize / (1024 * 1024)).toStringAsFixed(1);
                                      final err = 'Video file size ($sizeMb MB) exceeds the 100MB Cloudinary free tier limit.';
                                      setDialogState(() {
                                        selectedVideoFileName = null;
                                        selectedVideoFileSize = null;
                                        videoUploadErrorMessage = err;
                                      });
                                      if (mounted) AppHelpers.showSnackBar(context, err, isError: true);
                                      return;
                                    }

                                    if (fileBytes == null) {
                                      throw Exception('Unable to read video file bytes.');
                                    }

                                    setDialogState(() {
                                      selectedVideoFileName = fileName;
                                      selectedVideoFileSize = fileSize;
                                      isUploadingVideo = true;
                                      videoProgress = 0.05;
                                      videoStatusText = 'Initiating upload to Cloudinary...';
                                    });

                                    final courseId = widget.courseId ?? 'course_${DateTime.now().millisecondsSinceEpoch}';
                                    final lessonId = existingLes?.id ?? 'les_${DateTime.now().millisecondsSinceEpoch}';

                                    final uploadResult = await _uploadService.uploadLessonVideo(
                                      courseId: courseId,
                                      lessonId: lessonId,
                                      fileName: fileName,
                                      fileBytes: fileBytes,
                                      isPreview: isPreview,
                                      onProgress: (progress, sent, total) {
                                        setDialogState(() {
                                          videoProgress = progress;
                                          final sentMb = (sent / (1024 * 1024)).toStringAsFixed(1);
                                          final totalMb = (total / (1024 * 1024)).toStringAsFixed(1);
                                          videoStatusText = 'Uploading: ${(progress * 100).toStringAsFixed(0)}% ($sentMb MB / $totalMb MB)';
                                        });
                                      },
                                    );

                                    setDialogState(() {
                                      isUploadingVideo = false;
                                      uploadedPublicId = uploadResult.publicId;
                                      uploadedSecureUrl = uploadResult.secureUrl;
                                      if (uploadResult.durationSeconds > 0) {
                                        final m = uploadResult.durationSeconds ~/ 60;
                                        final s = uploadResult.durationSeconds % 60;
                                        final autoDuration = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
                                        durationCtrl.text = autoDuration;
                                        videoStatusText = 'Video upload completed! ($autoDuration)';
                                      } else {
                                        videoStatusText = 'Video upload completed!';
                                      }
                                    });
                                  } catch (e) {
                                    setDialogState(() {
                                      isUploadingVideo = false;
                                      videoProgress = 0.0;
                                      selectedVideoFileName = null;
                                      selectedVideoFileSize = null;
                                      videoUploadErrorMessage = e.toString();
                                    });
                                    if (mounted) AppHelpers.showSnackBar(context, 'Upload failed: $e', isError: true);
                                  }
                                },
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. Downloadable Resources & PDFs Section
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: AppSpacing.roundedMd,
                          border: Border.all(color: AppColors.surfaceContainerHigh),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.attachment_rounded, color: AppColors.secondary, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Attached Lesson Resources',
                                      style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${draftResources.length} files',
                                  style: AppTypography.labelSmall.copyWith(color: AppColors.outline),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Students can view and download these files directly under the Resources tab.',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant, fontSize: 11),
                            ),
                            const SizedBox(height: 12),

                            // List of attached resources
                            if (draftResources.isNotEmpty)
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: draftResources.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (_, resIdx) {
                                  final res = draftResources[resIdx];
                                  final isPdf = res.type.toLowerCase() == 'pdf';
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: AppSpacing.roundedSm,
                                      border: Border.all(color: AppColors.outlineVariant),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isPdf ? Icons.picture_as_pdf : Icons.insert_drive_file_outlined,
                                          size: 20,
                                          color: isPdf ? AppColors.error : AppColors.secondary,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                res.title,
                                                style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                res.isPreview ? 'Free Preview Access · Cloudinary Raw' : 'Enrolled Students Only · Signed Raw',
                                                style: AppTypography.bodySmall.copyWith(fontSize: 10, color: res.isPreview ? AppColors.success : AppColors.primary),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                                          tooltip: 'Remove Resource',
                                          onPressed: () async {
                                            if (res.cloudinaryPublicId != null && res.cloudinaryPublicId!.isNotEmpty) {
                                              _uploadService.deleteCloudinaryAsset(
                                                publicId: res.cloudinaryPublicId!,
                                                courseId: widget.courseId,
                                                resourceType: 'raw',
                                              );
                                            }
                                            setDialogState(() {
                                              draftResources.removeAt(resIdx);
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Text(
                                  'No resource files attached to this lesson yet.',
                                  style: AppTypography.bodySmall.copyWith(color: AppColors.outline, fontSize: 11),
                                ),
                              ),
                            const SizedBox(height: 12),

                            // Upload Resource Button & Progress
                            if (isUploadingResource) ...[
                              LinearProgressIndicator(
                                value: resourceProgress > 0 ? resourceProgress : null,
                                color: AppColors.secondary,
                                backgroundColor: AppColors.surfaceContainerHigh,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                resourceStatusText,
                                style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant, fontSize: 11),
                              ),
                            ] else
                              AppButton(
                                label: resourceUploadErrorMessage != null ? 'Retry Resource Upload' : 'Upload PDF / Resource File',
                                variant: ButtonVariant.outline,
                                size: ButtonSize.sm,
                                icon: Icons.upload_file_outlined,
                                onPressed: () async {
                                  setDialogState(() {
                                    resourceUploadErrorMessage = null;
                                  });
                                  try {
                                    final pickResult = await FilePicker.platform.pickFiles(
                                      type: FileType.custom,
                                      allowedExtensions: ['pdf', 'zip', 'doc', 'docx', 'png', 'jpg', 'txt', 'epub'],
                                      withData: true,
                                    );

                                    if (pickResult == null || pickResult.files.isEmpty) return;
                                    final pickedFile = pickResult.files.first;
                                    final fileBytes = pickedFile.bytes;
                                    final fileName = pickedFile.name;
                                    final extension = pickedFile.extension ?? 'pdf';

                                    if (fileBytes == null) throw Exception('Unable to read resource file bytes.');

                                    setDialogState(() {
                                      isUploadingResource = true;
                                      resourceProgress = 0.05;
                                      resourceStatusText = 'Uploading $fileName to Cloudinary Raw Storage...';
                                    });

                                    final courseId = widget.courseId ?? 'course_${DateTime.now().millisecondsSinceEpoch}';
                                    final resourceId = 'res_${DateTime.now().millisecondsSinceEpoch}';

                                    final uploadResult = await _uploadService.uploadLessonResource(
                                      courseId: courseId,
                                      resourceId: resourceId,
                                      fileName: fileName,
                                      fileBytes: fileBytes,
                                      isPreview: isPreview,
                                      onProgress: (progress, sent, total) {
                                        setDialogState(() {
                                          resourceProgress = progress;
                                          final sentMb = (sent / (1024 * 1024)).toStringAsFixed(1);
                                          final totalMb = (total / (1024 * 1024)).toStringAsFixed(1);
                                          resourceStatusText = 'Uploading: ${(progress * 100).toStringAsFixed(0)}% ($sentMb MB / $totalMb MB)';
                                        });
                                      },
                                    );

                                    setDialogState(() {
                                      isUploadingResource = false;
                                      draftResources.add(
                                        LessonResource(
                                          title: fileName,
                                          url: uploadResult.secureUrl,
                                          type: extension,
                                          cloudinaryPublicId: uploadResult.publicId,
                                          isPreview: isPreview,
                                        ),
                                      );
                                      resourceStatusText = 'Resource uploaded successfully!';
                                    });
                                  } catch (e) {
                                    setDialogState(() {
                                      isUploadingResource = false;
                                      resourceUploadErrorMessage = e.toString();
                                    });
                                    if (mounted) AppHelpers.showSnackBar(context, 'Resource upload failed: $e', isError: true);
                                  }
                                },
                              ),
                            if (resourceUploadErrorMessage != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                resourceUploadErrorMessage!,
                                style: AppTypography.bodySmall.copyWith(color: AppColors.error, fontSize: 11),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: (isUploadingVideo || isUploadingResource) ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                AppButton(
                  label: isEditing ? 'Save Lesson' : 'Add to Module',
                  variant: ButtonVariant.primary,
                  size: ButtonSize.sm,
                  onPressed: canSaveLesson
                      ? () async {
                          if (lessonTitleCtrl.text.trim().isEmpty) return;

                          if (oldPublicId.isNotEmpty && oldPublicId != uploadedPublicId) {
                            debugPrint('[CourseBuilder] 🔄 Purging replaced video from Cloudinary: $oldPublicId');
                            _uploadService.deleteCloudinaryAsset(
                              publicId: oldPublicId,
                              courseId: widget.courseId,
                              resourceType: 'video',
                            );
                          }

                          setState(() {
                            if (isEditing) {
                              existingLes!.title = lessonTitleCtrl.text.trim();
                              existingLes.duration = durationCtrl.text.trim().isEmpty ? '15m' : durationCtrl.text.trim();
                              existingLes.cloudinaryPublicId = uploadedPublicId;
                              existingLes.videoUrl = isPreview ? uploadedSecureUrl : '';
                              existingLes.isPreview = isPreview;
                              existingLes.resources = draftResources;
                            } else {
                              final lessonId = 'les_${DateTime.now().millisecondsSinceEpoch}';
                              _modules[moduleIndex].lessons.add(
                                _DraftLesson(
                                  id: lessonId,
                                  title: lessonTitleCtrl.text.trim(),
                                  duration: durationCtrl.text.trim().isEmpty ? '15m' : durationCtrl.text.trim(),
                                  cloudinaryPublicId: uploadedPublicId,
                                  videoUrl: isPreview ? uploadedSecureUrl : '',
                                  isPreview: isPreview,
                                  resources: draftResources,
                                ),
                              );
                            }
                          });
                          Navigator.pop(ctx);
                        }
                      : () {
                          AppHelpers.showSnackBar(
                            context,
                            'Please upload a lecture video before saving this lesson.',
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

  /// Interactive Question Editor Dialog for MCQ and True/False
  Future<void> _showQuestionEditorDialog({
    required BuildContext parentContext,
    QuizQuestion? existingQuestion,
    required ValueChanged<QuizQuestion> onQuestionSaved,
  }) async {
    final isEditing = existingQuestion != null;
    final promptCtrl = TextEditingController(text: existingQuestion?.question ?? '');
    final explanationCtrl = TextEditingController(text: existingQuestion?.explanation ?? '');
    QuestionType selectedType = existingQuestion?.type ?? QuestionType.multipleChoice;

    // Options controllers
    List<TextEditingController> optionControllers = [];
    int correctIndex = 0;

    if (isEditing && existingQuestion.options.isNotEmpty) {
      optionControllers = existingQuestion.options.map((o) => TextEditingController(text: o.text)).toList();
      final idx = existingQuestion.options.indexWhere((o) => o.isCorrect);
      if (idx >= 0) correctIndex = idx;
    } else {
      if (selectedType == QuestionType.trueFalse) {
        optionControllers = [
          TextEditingController(text: 'True'),
          TextEditingController(text: 'False'),
        ];
      } else {
        optionControllers = [
          TextEditingController(text: 'Option A'),
          TextEditingController(text: 'Option B'),
          TextEditingController(text: 'Option C'),
          TextEditingController(text: 'Option D'),
        ];
      }
    }

    await showDialog(
      context: parentContext,
      builder: (qCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setQState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
              title: Row(
                children: [
                  Icon(isEditing ? Icons.edit_note : Icons.help_outline, color: AppColors.secondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isEditing ? 'Edit Quiz Question' : 'Add Question',
                      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question Prompt
                      TextField(
                        controller: promptCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Question Prompt *',
                          hintText: 'e.g. Which Cloudflare Worker route signs authenticated video stream URLs?',
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Question Type Selector
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('Type: ', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                          ChoiceChip(
                            label: const Text('Multiple Choice'),
                            selected: selectedType == QuestionType.multipleChoice,
                            onSelected: (val) {
                              if (val) {
                                setQState(() {
                                  selectedType = QuestionType.multipleChoice;
                                  optionControllers = [
                                    TextEditingController(text: 'Option A'),
                                    TextEditingController(text: 'Option B'),
                                    TextEditingController(text: 'Option C'),
                                    TextEditingController(text: 'Option D'),
                                  ];
                                  correctIndex = 0;
                                });
                              }
                            },
                          ),
                          ChoiceChip(
                            label: const Text('True / False'),
                            selected: selectedType == QuestionType.trueFalse,
                            onSelected: (val) {
                              if (val) {
                                setQState(() {
                                  selectedType = QuestionType.trueFalse;
                                  optionControllers = [
                                    TextEditingController(text: 'True'),
                                    TextEditingController(text: 'False'),
                                  ];
                                  correctIndex = 0;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'Answers & Correct Choice (Select the radio of correct option):',
                        style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),

                      // Options Editor
                      ...List.generate(optionControllers.length, (optIdx) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Radio<int>(
                                value: optIdx,
                                groupValue: correctIndex,
                                activeColor: AppColors.success,
                                onChanged: (val) {
                                  if (val != null) {
                                    setQState(() => correctIndex = val);
                                  }
                                },
                              ),
                              Expanded(
                                child: TextField(
                                  controller: optionControllers[optIdx],
                                  decoration: InputDecoration(
                                    labelText: 'Option ${optIdx + 1}',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ),
                              if (selectedType == QuestionType.multipleChoice && optionControllers.length > 2)
                                IconButton(
                                  icon: const Icon(Icons.close, size: 16, color: AppColors.error),
                                  tooltip: 'Remove Option',
                                  onPressed: () {
                                    setQState(() {
                                      optionControllers.removeAt(optIdx);
                                      if (correctIndex >= optionControllers.length) {
                                        correctIndex = 0;
                                      }
                                    });
                                  },
                                ),
                            ],
                          ),
                        );
                      }),

                      if (selectedType == QuestionType.multipleChoice && optionControllers.length < 6)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            icon: const Icon(Icons.add, size: 16, color: AppColors.secondary),
                            label: const Text('Add Option', style: TextStyle(color: AppColors.secondary)),
                            onPressed: () {
                              setQState(() {
                                optionControllers.add(TextEditingController(text: 'Option ${optionControllers.length + 1}'));
                              });
                            },
                          ),
                        ),
                      const SizedBox(height: 12),

                      // Explanation / Feedback
                      TextField(
                        controller: explanationCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Explanation & Student Feedback (Optional)',
                          hintText: 'Explains why the answer is correct upon quiz grading...',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(qCtx),
                  child: const Text('Cancel'),
                ),
                AppButton(
                  label: isEditing ? 'Update Question' : 'Add Question',
                  variant: ButtonVariant.secondary,
                  size: ButtonSize.sm,
                  onPressed: () {
                    final prompt = promptCtrl.text.trim();
                    if (prompt.isEmpty) {
                      AppHelpers.showSnackBar(parentContext, 'Please enter question text', isError: true);
                      return;
                    }

                    final options = optionControllers.asMap().entries.map((entry) {
                      return QuizOption(
                        id: 'opt_${entry.key + 1}',
                        text: entry.value.text.trim(),
                        isCorrect: entry.key == correctIndex,
                      );
                    }).toList();

                    final newQuestion = QuizQuestion(
                      id: existingQuestion?.id ?? 'q_${DateTime.now().millisecondsSinceEpoch}',
                      question: prompt,
                      explanation: explanationCtrl.text.trim(),
                      type: selectedType,
                      options: options,
                    );

                    onQuestionSaved(newQuestion);
                    Navigator.pop(qCtx);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Modal for creating or editing a full curriculum quiz
  Future<void> _showAddOrEditQuizModal({QuizModel? existingQuiz, int? quizIndex}) async {
    final isEditing = existingQuiz != null && quizIndex != null;

    final titleCtrl = TextEditingController(text: existingQuiz?.title ?? 'Module 1 Assessment Quiz');
    final descCtrl = TextEditingController(text: existingQuiz?.description ?? 'Test your knowledge on curriculum concepts');
    final passingScoreCtrl = TextEditingController(text: (existingQuiz?.passingScore ?? 80).toString());
    final timeLimitCtrl = TextEditingController(text: (existingQuiz?.timeLimitMinutes ?? 15).toString());

    final List<QuizQuestion> draftQuestions = List<QuizQuestion>.from(existingQuiz?.questions ?? [
      const QuizQuestion(
        id: 'q_sample_1',
        question: 'Which service provides signed video URLs in this application?',
        explanation: 'Cloudflare Workers generate short-lived signed delivery URLs using the Cloudinary API secret.',
        type: QuestionType.multipleChoice,
        options: [
          QuizOption(id: 'opt_1', text: 'Cloudflare Workers', isCorrect: true),
          QuizOption(id: 'opt_2', text: 'Firebase Cloud Functions', isCorrect: false),
          QuizOption(id: 'opt_3', text: 'Direct Client App', isCorrect: false),
          QuizOption(id: 'opt_4', text: 'Jitsi Meet Bridge', isCorrect: false),
        ],
      ),
    ]);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setQuizState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
              title: Row(
                children: [
                  Icon(isEditing ? Icons.quiz : Icons.add_task, color: AppColors.secondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isEditing ? 'Edit Quiz & Assessment' : 'Create New Course Quiz',
                      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 620,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Quiz Settings
                      TextField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(labelText: 'Quiz Title *'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descCtrl,
                        decoration: const InputDecoration(labelText: 'Description / Instructions'),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: passingScoreCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Passing Score (%)',
                                suffixText: '%',
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: timeLimitCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Time Limit (Mins)',
                                suffixText: 'mins',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Questions Management Header
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Text(
                            'Questions (${draftQuestions.length})',
                            style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w800),
                          ),
                          AppButton(
                            label: 'Add Question',
                            variant: ButtonVariant.outline,
                            size: ButtonSize.sm,
                            icon: Icons.add,
                            onPressed: () {
                              _showQuestionEditorDialog(
                                parentContext: context,
                                onQuestionSaved: (newQ) {
                                  setQuizState(() {
                                    draftQuestions.add(newQ);
                                  });
                                },
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Questions List Preview
                      if (draftQuestions.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: AppSpacing.roundedMd,
                          ),
                          child: const Center(
                            child: Text('No questions added yet. Click "Add Question" above.'),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: draftQuestions.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, qIdx) {
                            final q = draftQuestions[qIdx];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLowest,
                                borderRadius: AppSpacing.roundedSm,
                                border: Border.all(color: AppColors.surfaceContainerHigh),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.secondary.withOpacity(0.12),
                                          borderRadius: AppSpacing.roundedSm,
                                        ),
                                        child: Text(
                                          'Q${qIdx + 1}',
                                          style: AppTypography.labelSmall.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          q.question,
                                          style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.secondary),
                                        tooltip: 'Edit Question',
                                        onPressed: () {
                                          _showQuestionEditorDialog(
                                            parentContext: context,
                                            existingQuestion: q,
                                            onQuestionSaved: (updatedQ) {
                                              setQuizState(() {
                                                draftQuestions[qIdx] = updatedQ;
                                              });
                                            },
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                                        tooltip: 'Delete Question',
                                        onPressed: () {
                                          setQuizState(() {
                                            draftQuestions.removeAt(qIdx);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  // Preview options
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: q.options.map((opt) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: opt.isCorrect ? AppColors.success.withOpacity(0.12) : AppColors.surfaceContainerLow,
                                          borderRadius: AppSpacing.roundedSm,
                                          border: Border.all(
                                            color: opt.isCorrect ? AppColors.success.withOpacity(0.4) : AppColors.outlineVariant,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (opt.isCorrect) ...[
                                              const Icon(Icons.check_circle, size: 12, color: AppColors.success),
                                              const SizedBox(width: 4),
                                            ],
                                            Flexible(
                                              child: Text(
                                                opt.text,
                                                style: AppTypography.bodySmall.copyWith(
                                                  fontSize: 11,
                                                  fontWeight: opt.isCorrect ? FontWeight.w700 : FontWeight.normal,
                                                  color: opt.isCorrect ? AppColors.success : AppColors.onSurface,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
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
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                AppButton(
                  label: isEditing ? 'Save Quiz Changes' : 'Create Quiz',
                  variant: ButtonVariant.primary,
                  size: ButtonSize.sm,
                  onPressed: () {
                    final title = titleCtrl.text.trim();
                    if (title.isEmpty) {
                      AppHelpers.showSnackBar(context, 'Please enter a quiz title', isError: true);
                      return;
                    }
                    if (draftQuestions.isEmpty) {
                      AppHelpers.showSnackBar(context, 'Please add at least 1 question to the quiz', isError: true);
                      return;
                    }

                    final passingScore = int.tryParse(passingScoreCtrl.text.trim()) ?? 80;
                    final timeLimit = int.tryParse(timeLimitCtrl.text.trim()) ?? 15;
                    final courseId = widget.courseId ?? 'course_${DateTime.now().millisecondsSinceEpoch}';

                    final quiz = QuizModel(
                      id: existingQuiz?.id ?? 'quiz_${DateTime.now().millisecondsSinceEpoch}',
                      courseId: courseId,
                      title: title,
                      description: descCtrl.text.trim(),
                      passingScore: passingScore,
                      timeLimitMinutes: timeLimit,
                      questions: draftQuestions,
                    );

                    setState(() {
                      if (isEditing) {
                        _quizzes[quizIndex] = quiz;
                      } else {
                        _quizzes.add(quiz);
                      }
                    });

                    Navigator.pop(ctx);
                    AppHelpers.showSnackBar(context, isEditing ? 'Quiz updated successfully!' : 'Quiz added to course!');
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
          description: mod.description.isNotEmpty ? mod.description : '${mod.title} description.',
          lessons: mod.lessons.asMap().entries.map((lesEntry) {
            final les = lesEntry.value;
            return LessonModel(
              id: les.id,
              courseId: courseId,
              title: les.title,
              duration: les.duration,
              videoUrl: les.videoUrl,
              cloudinaryPublicId: les.cloudinaryPublicId,
              order: lesEntry.key + 1,
              isPreview: les.isPreview,
              resources: les.resources,
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
        quizzes: _quizzes,
        isFeatured: true,
        isTrending: true,
      );

      // Sync quizzes to Firestore quizzes collection
      for (final q in _quizzes) {
        await _quizService.saveOrUpdateQuiz(q);
      }

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

  /// Handles double-confirmed deletion of the entire course and all Cloudinary assets
  Future<void> _handleDeleteCourse() async {
    final courseId = widget.courseId;
    if (courseId == null || courseId.isEmpty) return;

    final courseTitle = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : 'this course';

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.12),
                borderRadius: AppSpacing.roundedSm,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Delete Course Permanently?',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurface),
                children: [
                  const TextSpan(text: 'Are you sure you want to permanently delete '),
                  TextSpan(
                    text: '"$courseTitle"',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const TextSpan(text: '?'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: AppSpacing.roundedMd,
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚠️ This action is permanent and irreversible:',
                    style: AppTypography.labelMedium.copyWith(color: AppColors.error, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '• All video lessons will be purged from Cloudinary storage console.\n'
                    '• All downloadable PDFs, blueprints & resources will be deleted.\n'
                    '• Quizzes, reviews, and live class schedules will be erased.\n'
                    '• Course will be permanently removed from database and search.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant, fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedSm),
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Delete Course Forever', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      AppHelpers.showSnackBar(context, 'Deleting course and purging Cloudinary console assets...');
      final user = ref.read(authProvider);
      await ref.read(courseServiceProvider).deleteCourse(courseId, userId: user?.id);

      // Clean all quizzes for this course
      for (final q in _quizzes) {
        await _quizService.deleteQuiz(q.id);
      }

      ref.read(courseRefreshCounterProvider.notifier).state++;
      ref.invalidate(allCoursesProvider);
      ref.invalidate(courseByIdProvider(courseId));

      if (mounted) {
        AppHelpers.showSnackBar(context, '✅ Course and all Cloudinary assets permanently deleted.');
        context.go('/instructor');
      }
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
                            ? 'Update curriculum, downloadable resources, and quizzes'
                            : 'Build curriculum, upload videos/resources to Cloudinary, and create assessments',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (_isEditMode) ...[
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedSm),
                          ),
                          icon: const Icon(Icons.delete_forever, size: 18),
                          label: const Text('Delete Course', style: TextStyle(fontWeight: FontWeight.w700)),
                          onPressed: _handleDeleteCourse,
                        ),
                      ],
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
                    if (isDesktop)
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
                      )
                    else ...[
                      TextFormField(
                        controller: _categoryController,
                        decoration: const InputDecoration(labelText: 'Category'),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              decoration: const InputDecoration(labelText: 'Price (\$USD) *', prefixText: '\$ '),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: _levelController,
                              decoration: const InputDecoration(labelText: 'Level'),
                            ),
                          ),
                        ],
                      ),
                    ],
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
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Text('Curriculum Modules', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800)),
                        AppButton(
                          label: 'Add Module',
                          variant: ButtonVariant.outline,
                          size: ButtonSize.sm,
                          icon: Icons.add,
                          onPressed: () => _showModuleDialog(),
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
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  ConstrainedBox(
                                    constraints: BoxConstraints(maxWidth: isDesktop ? 600 : 180),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.folder_outlined, size: 20, color: AppColors.secondary),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                mod.title,
                                                style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (mod.description.isNotEmpty)
                                                Text(
                                                  mod.description,
                                                  style: AppTypography.bodySmall.copyWith(color: AppColors.outline, fontSize: 11),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                        icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.secondary),
                                        tooltip: 'Rename / Edit Module',
                                        onPressed: () => _showModuleDialog(editIndex: modIdx),
                                      ),
                                      AppButton(
                                        label: 'Add Lesson',
                                        variant: ButtonVariant.outline,
                                        size: ButtonSize.sm,
                                        icon: Icons.video_call,
                                        onPressed: () => _showAddOrEditLessonModal(modIdx),
                                      ),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                        icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                        tooltip: 'Delete Module',
                                        onPressed: () {
                                          if (_modules.length > 1) {
                                            setState(() => _modules.removeAt(modIdx));
                                          } else {
                                            AppHelpers.showSnackBar(context, 'Course must have at least one curriculum module', isError: true);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (mod.lessons.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text(
                                    'No lessons added yet. Click "Add Lesson" to upload a video and resources.',
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
                                                const SizedBox(height: 4),
                                                Wrap(
                                                  spacing: 6,
                                                  runSpacing: 4,
                                                  crossAxisAlignment: WrapCrossAlignment.center,
                                                  children: [
                                                    Text(les.duration, style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: les.isPreview ? AppColors.secondaryContainer : AppColors.surfaceContainerHigh,
                                                        borderRadius: AppSpacing.roundedSm,
                                                      ),
                                                      child: Text(
                                                        les.isPreview
                                                            ? 'Free Preview'
                                                            : 'Authenticated Stream',
                                                        style: AppTypography.labelSmall.copyWith(
                                                          fontSize: 10,
                                                          color: les.isPreview ? AppColors.onSecondaryContainer : AppColors.onSurfaceVariant,
                                                        ),
                                                      ),
                                                    ),
                                                    if (les.resources.isNotEmpty)
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: AppColors.secondary.withOpacity(0.12),
                                                          borderRadius: AppSpacing.roundedSm,
                                                        ),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            const Icon(Icons.attachment, size: 10, color: AppColors.secondary),
                                                            const SizedBox(width: 2),
                                                            Flexible(
                                                              child: Text(
                                                                '${les.resources.length} file(s)',
                                                                style: AppTypography.labelSmall.copyWith(
                                                                  fontSize: 10,
                                                                  color: AppColors.secondary,
                                                                  fontWeight: FontWeight.w700,
                                                                ),
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                            icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.secondary),
                                            tooltip: 'Edit / Replace Video & Resources',
                                            onPressed: () => _showAddOrEditLessonModal(modIdx, lessonIndex: lesIdx),
                                          ),
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                            icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                                            tooltip: 'Delete Lesson & Clean Storage',
                                            onPressed: () => _removeLesson(modIdx, lesIdx),
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
              const SizedBox(height: 24),

              // Quizzes & Assessments Card
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
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          children: [
                            const Icon(Icons.quiz_outlined, color: AppColors.secondary, size: 22),
                            Text('Course Quizzes & Assessments', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800)),
                          ],
                        ),
                        AppButton(
                          label: 'Add Quiz',
                          variant: ButtonVariant.outline,
                          size: ButtonSize.sm,
                          icon: Icons.add_task,
                          onPressed: () => _showAddOrEditQuizModal(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Create assessments for students to evaluate their mastery and earn course certificates.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),

                    if (_quizzes.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: AppSpacing.roundedMd,
                          border: Border.all(color: AppColors.outlineVariant),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(Icons.help_outline, size: 36, color: AppColors.outline),
                              const SizedBox(height: 8),
                              Text(
                                'No assessments created yet for this course.',
                                style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
                              ),
                              const SizedBox(height: 10),
                              AppButton(
                                label: 'Create First Assessment Quiz',
                                variant: ButtonVariant.secondary,
                                size: ButtonSize.sm,
                                icon: Icons.add,
                                onPressed: () => _showAddOrEditQuizModal(),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _quizzes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, qIdx) {
                          final quiz = _quizzes[qIdx];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLowest,
                              borderRadius: AppSpacing.roundedMd,
                              border: Border.all(color: AppColors.surfaceContainerHigh),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.fact_check_outlined, color: AppColors.secondary, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        quiz.title,
                                        style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                                      ),
                                      if (quiz.description.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          quiz.description,
                                          style: AppTypography.bodySmall.copyWith(color: AppColors.outline, fontSize: 11),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 8,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.secondary.withOpacity(0.12),
                                              borderRadius: AppSpacing.roundedSm,
                                            ),
                                            child: Text(
                                              '${quiz.questions.length} Questions',
                                              style: AppTypography.labelSmall.copyWith(
                                                color: AppColors.secondary,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.success.withOpacity(0.12),
                                              borderRadius: AppSpacing.roundedSm,
                                            ),
                                            child: Text(
                                              '${quiz.passingScore}% Passing',
                                              style: AppTypography.labelSmall.copyWith(
                                                color: AppColors.success,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.surfaceContainerHigh,
                                              borderRadius: AppSpacing.roundedSm,
                                            ),
                                            child: Text(
                                              '${quiz.timeLimitMinutes} Mins',
                                              style: AppTypography.labelSmall.copyWith(
                                                color: AppColors.onSurfaceVariant,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.secondary),
                                  tooltip: 'Edit Quiz & Questions',
                                  onPressed: () => _showAddOrEditQuizModal(existingQuiz: quiz, quizIndex: qIdx),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                  tooltip: 'Delete Quiz',
                                  onPressed: () async {
                                    await _quizService.deleteQuiz(quiz.id);
                                    setState(() {
                                      _quizzes.removeAt(qIdx);
                                    });
                                    if (context.mounted) {
                                      AppHelpers.showSnackBar(context, 'Quiz removed from course');
                                    }
                                  },
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
