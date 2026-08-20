import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/live_class_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/enrolment_provider.dart';
import '../providers/course_provider.dart';
import '../providers/live_class_provider.dart';
import '../styles/colors.dart';
import '../styles/spacing.dart';
import '../styles/typography.dart';
import '../components/LiveClassRoom.dart';
import '../components/ChatBubble.dart';
import '../components/Button.dart';
import '../components/Loader.dart';
import '../components/jitsi_embed.dart';
import '../services/notification_service.dart';
import '../utils/helpers.dart';
import '../utils/auth_gate.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class LiveClassScreen extends ConsumerStatefulWidget {
  final String classId;

  const LiveClassScreen({
    super.key,
    required this.classId,
  });

  @override
  ConsumerState<LiveClassScreen> createState() => _LiveClassScreenState();
}

class _LiveClassScreenState extends ConsumerState<LiveClassScreen> {
  final TextEditingController _chatController = TextEditingController();
  bool _isChatOpenMobile = false;
  bool _isMicOn = true;
  bool _isCameraOn = true;
  bool _isHandRaised = false;
  bool _hasJoined = false;
  bool _hasShownEndedDialog = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _joinSession();
    });
  }

  @override
  void dispose() {
    _chatController.dispose();
    stopHardwareMediaStream();
    final user = ref.read(authProvider);
    if (user != null) {
      ref.read(liveClassServiceProvider).leaveLiveClass(widget.classId, user.id);
    }
    super.dispose();
  }

  void _joinSession() {
    final user = ref.read(authProvider);
    if (user != null && !_hasJoined) {
      ref.read(liveClassServiceProvider).joinLiveClass(
            widget.classId,
            user,
            isMicOn: _isMicOn,
            isCameraOn: _isCameraOn,
          );
      _hasJoined = true;
    }
  }

  void _toggleMic(bool val) {
    setState(() => _isMicOn = val);
    final user = ref.read(authProvider);
    if (user != null) {
      ref.read(liveClassServiceProvider).updateParticipantMedia(widget.classId, user.id, isMicOn: val);
    }
  }

  void _toggleCamera(bool val) {
    setState(() => _isCameraOn = val);
    final user = ref.read(authProvider);
    if (user != null) {
      ref.read(liveClassServiceProvider).updateParticipantMedia(widget.classId, user.id, isCameraOn: val);
    }
  }

  void _toggleHandRaise(bool val) {
    setState(() => _isHandRaised = val);
    final user = ref.read(authProvider);
    if (user != null) {
      ref.read(liveClassServiceProvider).updateParticipantMedia(widget.classId, user.id, isHandRaised: val);
      AppHelpers.showSnackBar(
        context,
        val ? '✋ Hand raised to instructor' : 'Hand lowered',
      );
    }
  }

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(authProvider) ??
        const UserModel(
          id: 'user_guest',
          name: 'Student',
          email: 'student@edusphere.com',
          role: UserRole.student,
        );

    ref.read(liveClassServiceProvider).sendMessage(widget.classId, user, text);
    _chatController.clear();
  }

  void _showLeaveOrEndConfirmation(bool isInstructor) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
        title: Text(isInstructor ? 'End Live Class for All?' : 'Leave Live Class?'),
        content: Text(
          isInstructor
              ? 'Ending this class will disconnect all connected students and archive the live stream session.'
              : 'You can rejoin this active lecture at any time from My Learning while it remains live.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Stay in Class'),
          ),
          AppButton(
            label: isInstructor ? 'End Class' : 'Leave',
            variant: ButtonVariant.danger,
            size: ButtonSize.sm,
            onPressed: () async {
              Navigator.pop(ctx);
              stopHardwareMediaStream();
              if (isInstructor) {
                await ref.read(liveClassServiceProvider).endLiveClass(widget.classId);
                ref.invalidate(allLiveClassesStreamProvider);
                ref.invalidate(activeLiveClassStreamProvider(widget.classId));
                if (mounted) context.go('/instructor/live-classes');
              } else {
                final user = ref.read(authProvider);
                if (user != null) {
                  await ref.read(liveClassServiceProvider).leaveLiveClass(widget.classId, user.id);
                }
                ref.invalidate(allLiveClassesStreamProvider);
                ref.invalidate(activeLiveClassStreamProvider(widget.classId));
                if (mounted) context.go('/my-learning');
              }
            },
          ),
        ],
      ),
    );
  }

  void _showClassEndedModal() {
    if (_hasShownEndedDialog) return;
    _hasShownEndedDialog = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.secondary),
            const SizedBox(width: 8),
            const Text('Live Class Ended'),
          ],
        ),
        content: const Text(
          'The instructor has ended this live class. Thank you for participating!',
        ),
        actions: [
          AppButton(
            label: 'Back to My Learning',
            variant: ButtonVariant.primary,
            size: ButtonSize.sm,
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/my-learning');
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = AppHelpers.isDesktop(context);
    final user = ref.watch(authProvider);
    final liveClassAsync = ref.watch(activeLiveClassStreamProvider(widget.classId));
    final participantsAsync = ref.watch(liveClassParticipantsStreamProvider(widget.classId));
    final messagesAsync = ref.watch(liveClassMessagesStreamProvider(widget.classId));
    final coursesAsync = ref.watch(allCoursesProvider);

    return liveClassAsync.when(
      loading: () => const Scaffold(body: Center(child: AppLoader())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error loading live class: $e'))),
      data: (liveClass) {
        if (liveClass == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.videocam_off, size: 48, color: AppColors.outline),
                  const SizedBox(height: 12),
                  Text('Live Class Not Found', style: AppTypography.titleLarge),
                  const SizedBox(height: 12),
                  AppButton(label: 'Back to Home', onPressed: () => context.go('/home')),
                ],
              ),
            ),
          );
        }

        // Automatic graceful transition when session is ended
        if (liveClass.isEnded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showClassEndedModal();
          });
        }

        // Find associated course for title and instructor info
        final allCourses = coursesAsync.value ?? [];
        final matchingCourses = allCourses.where((c) => c.id == liveClass.courseId).toList();
        final course = matchingCourses.isNotEmpty ? matchingCourses.first : null;

        final isInstructor = (user != null &&
            (user.role == UserRole.instructor ||
                user.id == liveClass.instructorId ||
                (course != null && course.instructorId == user.id)));

        // Strict Enrollment Guard
        final isEnrolled = ref.watch(enrolmentProvider.notifier).isEnrolled(liveClass.courseId);
        final hasAccess = isInstructor || isEnrolled;

        if (!hasAccess) {
          return Scaffold(
            body: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480),
                padding: const EdgeInsets.all(AppSpacing.xl),
                margin: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: AppSpacing.roundedXl,
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_rounded, size: 40, color: AppColors.error),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Access Restricted',
                      style: AppTypography.headlineMedium.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user == null
                          ? 'Sign in with your enrolled student account to join this live interactive class.'
                          : 'You must be enrolled in "${course?.title ?? 'this course'}" to join this live interactive class.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 24),
                    if (user == null)
                      AppButton(
                        label: 'Sign In to Join Class',
                        variant: ButtonVariant.primary,
                        isFullWidth: true,
                        icon: Icons.login,
                        onPressed: () {
                          AuthGateHelper.requireAuth(
                            context,
                            ref,
                            actionTitle: 'Join Live Class',
                            reason: 'Sign in to access interactive live sessions and real-time chat.',
                            onAuthenticated: () {
                              _joinSession();
                            },
                          );
                        },
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => context.go('/courses'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                              ),
                              child: const Text('Browse Courses'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppButton(
                              label: 'View Course',
                              variant: ButtonVariant.primary,
                              size: ButtonSize.md,
                              onPressed: () => context.go('/course/${liveClass.courseId}'),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          );
        }

        final participants = participantsAsync.value ?? [];
        final messages = messagesAsync.value ?? [];

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
                  // Top Breadcrumb & Notification Trigger Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => context.go(isInstructor ? '/instructor/live-classes' : '/my-learning'),
                        borderRadius: AppSpacing.roundedMd,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 2.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.arrow_back, size: 18, color: AppColors.secondary),
                              const SizedBox(width: 8),
                              Text(
                                isInstructor ? 'Back to Live Management' : 'Back to My Learning',
                                style: AppTypography.labelMedium.copyWith(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.notifications_active, size: 18, color: AppColors.secondary),
                        label: const Text('Test FCM Push Alert', style: TextStyle(color: AppColors.secondary)),
                        onPressed: () {
                          NotificationService().sendLiveClassNotification(
                            classId: widget.classId,
                            courseTitle: course?.title ?? liveClass.title,
                            instructorName: course?.instructor.name ?? 'Dr. Sarah Chen',
                            minutesUntilStart: 5,
                          );
                          AppHelpers.showSnackBar(
                            context,
                            '📲 [FCM] Notification dispatched: Live class starting in 5 minutes!',
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Main Video Player + Real-time Chat Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left: Live Stream Canvas & Controls (flex 8)
                      Expanded(
                        flex: 8,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LiveClassRoom(
                              roomTitle: liveClass.title,
                              instructorName: course?.instructor.name ?? 'Dr. Sarah Chen',
                              jitsiRoomId: liveClass.jitsiRoomId,
                              isInstructor: isInstructor,
                              currentUserId: user?.id ?? '',
                              currentUserName: user?.name ?? (isInstructor ? 'Instructor' : 'Student'),
                              participants: participants,
                              isMicOn: _isMicOn,
                              isCameraOn: _isCameraOn,
                              isHandRaised: _isHandRaised,
                              onToggleMic: _toggleMic,
                              onToggleCamera: _toggleCamera,
                              onToggleHandRaise: _toggleHandRaise,
                              onToggleChat: () {
                                setState(() => _isChatOpenMobile = !_isChatOpenMobile);
                              },
                              onLeaveClass: () => _showLeaveOrEndConfirmation(isInstructor),
                            ),
                            const SizedBox(height: 20),

                            // Mobile Chat Section (when toggled on mobile)
                            if (!isDesktop && _isChatOpenMobile) ...[
                              _buildChatPanel(messages),
                              const SizedBox(height: 20),
                            ],

                            // Class Description Card
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLowest,
                                borderRadius: AppSpacing.roundedXl,
                                border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.secondaryFixedDim.withOpacity(0.25),
                                          borderRadius: AppSpacing.roundedSm,
                                        ),
                                        child: Text(
                                          course?.category ?? 'Live Interactive Session',
                                          style: AppTypography.labelSmall.copyWith(
                                            color: AppColors.secondary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Room: ${liveClass.jitsiRoomId}',
                                        style: AppTypography.labelSmall.copyWith(color: AppColors.outline),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    liveClass.title,
                                    style: AppTypography.headlineMedium.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    liveClass.description ??
                                        'Welcome to this live interactive broadcast. Ask questions via the live chat or use the Raise Hand feature to request speaking permissions.',
                                    style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Right: Desktop Sticky Live Chat (flex 4)
                      if (isDesktop) ...[
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 4,
                          child: _buildChatPanel(messages),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // =========================================================================
  // In-Class Real-Time Chat Panel
  // =========================================================================
  Widget _buildChatPanel(List<LiveClassMessageModel> messages) {
    return Container(
      height: 520,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppSpacing.roundedXl,
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Chat Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.surfaceContainerHigh)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.forum_outlined, size: 20, color: AppColors.secondary),
                    const SizedBox(width: 8),
                    Text(
                      'Live Class Q&A',
                      style: AppTypography.headlineMedium.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: AppSpacing.roundedFull,
                  ),
                  child: Text(
                    '${messages.length} msgs',
                    style: AppTypography.labelSmall.copyWith(color: AppColors.onSurfaceVariant, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),

          // Messages List Stream
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Text(
                      'No messages yet. Be the first to say hello!',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.outline),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg.senderId == (ref.read(authProvider)?.id ?? '');

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: ChatBubble(
                          message: msg.message,
                          senderName: msg.senderName,
                          timestamp: '${msg.sentAt.hour.toString().padLeft(2, '0')}:${msg.sentAt.minute.toString().padLeft(2, '0')}',
                          isCurrentUser: isMe,
                          avatarUrl: msg.senderAvatar,
                        ),
                      );
                    },
                  ),
          ),

          // Message Input Field
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.surfaceContainerHigh)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    decoration: InputDecoration(
                      hintText: 'Ask a question in class...',
                      hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.outline),
                      border: OutlineInputBorder(
                        borderRadius: AppSpacing.roundedMd,
                        borderSide: BorderSide(color: AppColors.outlineVariant.withOpacity(0.5)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                  onPressed: _sendMessage,
                  tooltip: 'Send Message',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
