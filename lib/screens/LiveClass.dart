import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../styles/colors.dart';
import '../styles/spacing.dart';
import '../styles/typography.dart';
import '../components/LiveClassRoom.dart';
import '../components/ChatBubble.dart';
import '../components/Button.dart';
import '../services/notification_service.dart';
import '../utils/helpers.dart';

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

  final List<Map<String, dynamic>> _messages = [
    {
      'sender': 'Dr. Sarah Chen (Instructor)',
      'message': 'Welcome everyone! Today we are discussing Neural Networks & Deep Learning architectures.',
      'time': '10:02 AM',
      'isUser': false,
      'avatar': 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=100',
    },
    {
      'sender': 'Alexandre Rivera',
      'message': 'Excited for this! Can we ask about backpropagation math later in the Q&A?',
      'time': '10:03 AM',
      'isUser': false,
      'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
    },
    {
      'sender': 'You',
      'message': 'Hello Dr. Chen! Ready to learn.',
      'time': '10:04 AM',
      'isUser': true,
      'avatar': null,
    },
  ];

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'sender': 'You',
        'message': text,
        'time': '10:05 AM',
        'isUser': true,
        'avatar': null,
      });
      _chatController.clear();
    });
  }

  void _showLeaveConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Live Class?'),
        content: const Text('You can rejoin this active lecture at any time from My Learning.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Stay in Class'),
          ),
          AppButton(
            label: 'Leave',
            variant: ButtonVariant.danger,
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
    final notifService = ref.watch(notificationServiceProvider);

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
                  TextButton.icon(
                    icon: const Icon(Icons.notifications_active, size: 18, color: AppColors.secondary),
                    label: const Text('Test FCM Push Alert', style: TextStyle(color: AppColors.secondary)),
                    onPressed: () {
                      notifService.sendLiveClassNotification(
                        classId: widget.classId,
                        courseTitle: 'CS401: Neural Networks',
                        instructorName: 'Dr. Sarah Chen',
                        minutesUntilStart: 5,
                      );
                      AppHelpers.showSnackBar(
                        context,
                        '📲 [FCM] Notification sent: Live class starting in 5 minutes!',
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Live Video Stream
                  Expanded(
                    flex: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LiveClassRoom(
                          roomTitle: 'CS401: Neural Networks & Deep Learning',
                          instructorName: 'Dr. Sarah Chen (Stanford AI Faculty)',
                          participantCount: 28,
                          onToggleChat: () {
                            setState(() {
                              _isChatOpenMobile = !_isChatOpenMobile;
                            });
                          },
                          onLeaveClass: _showLeaveConfirmation,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Live Interactive Session: Neural Networks & Deep Architectures',
                          style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Interactive live stream powered by Jitsi Meet. Live Q&A, code reviews, and architectural deep-dives.',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),

                  // Right Live Chat & Participants Sidebar (Desktop)
                  if (isDesktop || _isChatOpenMobile) ...[
                    const SizedBox(width: 28),
                    Expanded(
                      flex: 4,
                      child: Container(
                        height: 520,
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
                          children: [
                            // Chat Header
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: const BoxDecoration(
                                border: Border(bottom: BorderSide(color: AppColors.surfaceContainerHigh)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Live Discussion Forum',
                                    style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary.withOpacity(0.15),
                                      borderRadius: AppSpacing.roundedSm,
                                    ),
                                    child: Text(
                                      '28 Active',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.secondary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Message List
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                itemCount: _messages.length,
                                itemBuilder: (context, index) {
                                  final msg = _messages[index];
                                  return ChatBubble(
                                    senderName: msg['sender'],
                                    message: msg['message'],
                                    timestamp: msg['time'],
                                    isCurrentUser: msg['isUser'],
                                    avatarUrl: msg['avatar'],
                                  );
                                },
                              ),
                            ),

                            // Input Box
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
                                        hintText: 'Ask instructor a question...',
                                        hintStyle: AppTypography.bodySmall,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        border: OutlineInputBorder(
                                          borderRadius: AppSpacing.roundedFull,
                                          borderSide: const BorderSide(color: AppColors.surfaceContainerHigh),
                                        ),
                                      ),
                                      onSubmitted: (_) => _sendMessage(),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.send, color: AppColors.secondary, size: 20),
                                    onPressed: _sendMessage,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
