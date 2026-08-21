import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/course_model.dart';
import '../models/live_class_model.dart';
import '../providers/auth_provider.dart';
import '../providers/course_provider.dart';
import '../providers/live_class_provider.dart';
import '../services/notification_service.dart';
import '../styles/colors.dart';
import '../styles/spacing.dart';
import '../styles/typography.dart';
import '../components/Button.dart';
import '../components/Loader.dart';
import '../utils/helpers.dart';

class LiveClassManagementScreen extends ConsumerStatefulWidget {
  const LiveClassManagementScreen({super.key});

  @override
  ConsumerState<LiveClassManagementScreen> createState() => _LiveClassManagementScreenState();
}

class _LiveClassManagementScreenState extends ConsumerState<LiveClassManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _durationController = TextEditingController(text: '60');
  final _descriptionController = TextEditingController();

  String? _selectedCourseId;
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _handleGoLiveNowDialog(List<CourseModel> instructorCourses) async {
    if (instructorCourses.isEmpty) {
      AppHelpers.showSnackBar(context, 'You must create and publish a course first before going live.', isError: true);
      return;
    }

    String selectedCourseId = _selectedCourseId ?? instructorCourses.first.id;
    final titleCtrl = TextEditingController(
      text: '${instructorCourses.firstWhere((c) => c.id == selectedCourseId).title} - Live Stream',
    );

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
          insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
          contentPadding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.sensors, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Go Live Now', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Start an instant live broadcast for your enrolled students immediately with zero advance scheduling.'),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCourseId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Select Course *'),
                  items: instructorCourses.map((c) {
                    return DropdownMenuItem(
                      value: c.id,
                      child: Text(
                        c.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() {
                        selectedCourseId = val;
                        final course = instructorCourses.firstWhere((c) => c.id == val);
                        titleCtrl.text = '${course.title} - Live Stream';
                      });
                    }
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Live Session Title *'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            AppButton(
              label: '🔴 Broadcast Now',
              variant: ButtonVariant.danger,
              size: ButtonSize.sm,
              onPressed: () async {
                final user = ref.read(authProvider);
                if (user == null) return;
                Navigator.pop(dialogCtx);

                try {
                  final liveClass = await ref.read(liveClassServiceProvider).goLiveNow(
                    courseId: selectedCourseId,
                    instructorId: user.id,
                    title: titleCtrl.text.trim(),
                  );
                  if (mounted) {
                    AppHelpers.showSnackBar(context, '🔴 Going live now on "${liveClass.title}"!');
                    context.go('/live-class/${liveClass.id}');
                  }
                } catch (e) {
                  if (mounted) {
                    AppHelpers.showSnackBar(context, 'Error starting live stream: $e', isError: true);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleScheduleClass(List<CourseModel> instructorCourses) async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCourseId == null || _selectedCourseId!.isEmpty) {
      AppHelpers.showSnackBar(context, 'Please select a course to schedule this live class for.', isError: true);
      return;
    }

    // Verify strict ownership
    final user = ref.read(authProvider);
    final isOwner = instructorCourses.any((c) => c.id == _selectedCourseId);
    if (!isOwner || user == null) {
      AppHelpers.showSnackBar(context, 'Security check failed: You can only schedule classes for your own courses.', isError: true);
      return;
    }

    final selectedCourse = instructorCourses.firstWhere((c) => c.id == _selectedCourseId);

    setState(() => _isSubmitting = true);

    try {
      final scheduledDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final duration = int.tryParse(_durationController.text.trim()) ?? 60;
      final liveService = ref.read(liveClassServiceProvider);

      final created = await liveService.scheduleLiveClass(
        courseId: _selectedCourseId!,
        instructorId: user.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
        scheduledAt: scheduledDateTime,
        durationMinutes: duration,
      );

      // Trigger FCM notification dispatch
      NotificationService().sendLiveClassNotification(
        classId: created.id,
        courseTitle: selectedCourse.title,
        instructorName: user.name.isNotEmpty ? user.name : 'Course Instructor',
        minutesUntilStart: scheduledDateTime.difference(DateTime.now()).inMinutes.clamp(0, 1440),
      );

      if (mounted) {
        AppHelpers.showSnackBar(context, '✅ Live Class "${created.title}" scheduled successfully!');
        _titleController.clear();
        _descriptionController.clear();
        _durationController.text = '60';
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Failed to schedule live class: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = AppHelpers.isDesktop(context);
    final user = ref.watch(authProvider);
    final coursesAsync = ref.watch(allCoursesProvider);
    final liveClassesAsync = ref.watch(instructorLiveClassesStreamProvider(user?.id ?? 'inst_1'));

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
              // Top Breadcrumb Navigation
              InkWell(
                onTap: () => context.go('/instructor'),
                borderRadius: AppSpacing.roundedMd,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 2.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back, size: 18, color: AppColors.secondary),
                      const SizedBox(width: 8),
                      Text(
                        'Back to Instructor Dashboard',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header Title Area with Go Live Now
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
                        'Live Class Management',
                        style: AppTypography.displayMedium.copyWith(
                          fontSize: isDesktop ? 32 : 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Schedule future sessions or broadcast live instantly to your enrolled students.',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                  coursesAsync.maybeWhen(
                    data: (allCourses) {
                      final instructorCourses = allCourses.where((c) {
                        if (user == null) return false;
                        final matchId = c.instructorId == user.id;
                        final matchName = c.instructor.name.toLowerCase().trim() == user.name.toLowerCase().trim();
                        return matchId || matchName;
                      }).toList();

                      return AppButton(
                        label: '🔴 Go Live Now',
                        variant: ButtonVariant.danger,
                        size: ButtonSize.md,
                        icon: Icons.sensors,
                        onPressed: () => _handleGoLiveNowDialog(instructorCourses),
                      );
                    },
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Main Responsive Layout
              coursesAsync.when(
                loading: () => const Center(child: AppLoader()),
                error: (e, _) => Center(child: Text('Error loading courses: $e')),
                data: (allCourses) {
                  // Filter courses STRICTLY owned by this authenticated instructor
                  final instructorCourses = allCourses.where((c) {
                    if (user == null) return false;
                    final matchId = c.instructorId == user.id;
                    final matchName = c.instructor.name.toLowerCase().trim() == user.name.toLowerCase().trim();
                    return matchId || matchName;
                  }).toList();

                  if (instructorCourses.isNotEmpty) {
                    if (_selectedCourseId == null || !instructorCourses.any((c) => c.id == _selectedCourseId)) {
                      _selectedCourseId = instructorCourses.first.id;
                    }
                  } else {
                    _selectedCourseId = null;
                  }

                  return liveClassesAsync.when(
                    loading: () => const Center(child: AppLoader()),
                    error: (e, _) => Center(child: Text('Error loading sessions: $e')),
                    data: (liveClasses) {
                      final upcomingClasses = liveClasses.where((c) => !c.isEnded).toList();
                      final completedClasses = liveClasses.where((c) => c.isEnded).toList();

                      if (isDesktop) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Column: Schedule Form Area (flex 7)
                            Expanded(
                              flex: 7,
                              child: _buildScheduleForm(instructorCourses),
                            ),
                            const SizedBox(width: 24),

                            // Right Column: Sessions List Area (flex 5)
                            Expanded(
                              flex: 5,
                              child: _buildSessionsSidebar(
                                upcomingClasses: upcomingClasses,
                                completedClasses: completedClasses,
                                allCourses: allCourses,
                              ),
                            ),
                          ],
                        );
                      } else {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildScheduleForm(instructorCourses),
                            const SizedBox(height: 24),
                            _buildSessionsSidebar(
                              upcomingClasses: upcomingClasses,
                              completedClasses: completedClasses,
                              allCourses: allCourses,
                            ),
                          ],
                        );
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // Schedule Form Area (Left)
  // =========================================================================
  Widget _buildScheduleForm(List<CourseModel> instructorCourses) {
    if (instructorCourses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: AppSpacing.roundedXl,
          border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondaryFixedDim.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.school_outlined, size: 40, color: AppColors.secondary),
            ),
            const SizedBox(height: 16),
            Text(
              'No Published Courses Found',
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'You can only schedule and conduct live classes for courses you own. Create and publish a course first.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Launch Course Builder',
              variant: ButtonVariant.secondary,
              icon: Icons.rocket_launch,
              onPressed: () => context.go('/builder'),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppSpacing.roundedXl,
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryFixedDim.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.videocam_rounded, color: AppColors.secondary, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  'Schedule New Class',
                  style: AppTypography.headlineMedium.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1, color: AppColors.surfaceContainerHigh),

            // Class Title
            Text('Class Title', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'e.g., Deep Learning Architecture & Calculus',
                border: OutlineInputBorder(borderRadius: AppSpacing.roundedMd),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a title for the session' : null,
            ),
            const SizedBox(height: 16),

            // Course Dropdown & Date Picker
            Row(
              children: [
                // Course Dropdown
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Course', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _selectedCourseId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: AppSpacing.roundedMd),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        items: instructorCourses.map((c) {
                          return DropdownMenuItem<String>(
                            value: c.id,
                            child: Text(
                              c.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedCourseId = val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Date Picker
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Date', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: AppSpacing.roundedMd,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.outlineVariant),
                            borderRadius: AppSpacing.roundedMd,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('MMM dd, yyyy').format(_selectedDate),
                                style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const Icon(Icons.calendar_today, size: 18, color: AppColors.secondary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Start Time & Duration
            Row(
              children: [
                // Start Time Picker
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Start Time', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _pickTime,
                        borderRadius: AppSpacing.roundedMd,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.outlineVariant),
                            borderRadius: AppSpacing.roundedMd,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedTime.format(context),
                                style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const Icon(Icons.schedule, size: 18, color: AppColors.secondary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Duration Input
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Duration (mins)', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _durationController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '60',
                          border: OutlineInputBorder(borderRadius: AppSpacing.roundedMd),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n <= 0) return 'Enter valid minutes';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description Area
            Text('Description (Optional)', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Brief summary of concepts, prerequisites, or topics covered...',
                border: OutlineInputBorder(borderRadius: AppSpacing.roundedMd),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'Schedule Class',
                variant: ButtonVariant.primary,
                size: ButtonSize.lg,
                icon: Icons.calendar_month,
                isLoading: _isSubmitting,
                onPressed: () => _handleScheduleClass(instructorCourses),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // Sessions List Area (Right Sidebar)
  // =========================================================================
  Widget _buildSessionsSidebar({
    required List<LiveClassModel> upcomingClasses,
    required List<LiveClassModel> completedClasses,
    required List<CourseModel> allCourses,
  }) {
    return Column(
      children: [
        // Upcoming Classes Card
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: AppSpacing.roundedXl,
            border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Upcoming Classes',
                    style: AppTypography.headlineMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      borderRadius: AppSpacing.roundedFull,
                    ),
                    child: Text(
                      '${upcomingClasses.length}',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.onSecondaryContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20, thickness: 1, color: AppColors.surfaceContainerHigh),

              if (upcomingClasses.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(
                    child: Text(
                      'No upcoming live sessions scheduled.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.outline),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: upcomingClasses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = upcomingClasses[index];
                    final course = allCourses.firstWhere(
                      (c) => c.id == item.courseId,
                      orElse: () => allCourses.first,
                    );
                    return _buildUpcomingSessionCard(item, course);
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Completed Classes Card
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: AppSpacing.roundedXl,
            border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Completed Sessions',
                style: AppTypography.headlineMedium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const Divider(height: 20, thickness: 1, color: AppColors.surfaceContainerHigh),

              if (completedClasses.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: Text(
                      'No past completed sessions yet.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.outline),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: completedClasses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = completedClasses[index];
                    return Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: AppSpacing.roundedMd,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: AppTypography.labelMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.lineThrough,
                                    color: AppColors.outline,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('MMM dd, yyyy • hh:mm a').format(item.scheduledAt),
                                  style: AppTypography.labelSmall.copyWith(color: AppColors.outline),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.outlineVariant.withOpacity(0.4),
                              borderRadius: AppSpacing.roundedSm,
                            ),
                            child: Text(
                              'Ended',
                              style: AppTypography.labelSmall.copyWith(color: AppColors.outline),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  // Session Card Item with Top Accent Line
  Widget _buildUpcomingSessionCard(LiveClassModel session, CourseModel course) {
    final isLiveNow = session.isLive;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(
          color: isLiveNow ? AppColors.error : AppColors.outlineVariant.withOpacity(0.4),
          width: isLiveNow ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isLiveNow ? AppColors.error.withOpacity(0.08) : Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Accent Color Line (matching Stitch)
          Container(
            height: 3,
            color: isLiveNow ? AppColors.error : AppColors.secondary,
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        session.title,
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isLiveNow)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: AppSpacing.roundedFull,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'LIVE',
                              style: AppTypography.labelSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  course.title,
                  style: AppTypography.labelSmall.copyWith(color: AppColors.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Date & Time metadata
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: AppColors.outline),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM dd').format(session.scheduledAt),
                      style: AppTypography.labelSmall.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.schedule, size: 14, color: AppColors.outline),
                    const SizedBox(width: 4),
                    Text(
                      '${DateFormat('hh:mm a').format(session.scheduledAt)} (${session.durationMinutes}m)',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Start Class / End Class CTA
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: isLiveNow ? 'Enter Live Room' : 'Start Class',
                        variant: isLiveNow ? ButtonVariant.danger : ButtonVariant.secondary,
                        size: ButtonSize.sm,
                        icon: isLiveNow ? Icons.videocam : Icons.play_arrow_rounded,
                        onPressed: () async {
                          if (!isLiveNow) {
                            await ref.read(liveClassServiceProvider).startLiveClass(session.id);
                            if (!mounted) return;
                            AppHelpers.showSnackBar(context, '🔴 Live Class started!');
                          }
                          if (!mounted) return;
                          context.go('/live-class/${session.id}');
                        },
                      ),
                    ),
                    if (isLiveNow) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'End Class',
                        icon: const Icon(Icons.stop_circle_outlined, color: AppColors.error),
                        onPressed: () async {
                          final user = ref.read(authProvider);
                          await ref.read(liveClassServiceProvider).endLiveClass(session.id);
                          ref.invalidate(allLiveClassesStreamProvider);
                          if (user != null) {
                            ref.invalidate(instructorLiveClassesStreamProvider(user.id));
                          }
                          if (!mounted) return;
                          AppHelpers.showSnackBar(context, 'Live class ended.');
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
