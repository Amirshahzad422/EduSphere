import 'package:flutter/material.dart';
import '../styles/colors.dart';
import '../styles/spacing.dart';
import '../styles/typography.dart';

class LiveClassRoom extends StatefulWidget {
  final String roomTitle;
  final String instructorName;
  final int participantCount;
  final VoidCallback? onToggleChat;
  final VoidCallback? onLeaveClass;

  const LiveClassRoom({
    super.key,
    this.roomTitle = 'CS401: Neural Networks & Deep Learning',
    this.instructorName = 'Dr. Sarah Chen',
    this.participantCount = 28,
    this.onToggleChat,
    this.onLeaveClass,
  });

  @override
  State<LiveClassRoom> createState() => _LiveClassRoomState();
}

class _LiveClassRoomState extends State<LiveClassRoom> {
  bool _isMicOn = true;
  bool _isCameraOn = true;
  bool _isHandRaised = false;

  final List<Map<String, dynamic>> _participants = [
    {
      'name': 'You (Student)',
      'isSelf': true,
      'isMicOn': true,
      'isHandRaised': false,
      'avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=120',
    },
    {
      'name': 'Alexandre Rivera',
      'isSelf': false,
      'isMicOn': true,
      'isHandRaised': true,
      'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=120',
    },
    {
      'name': 'James Miller',
      'isSelf': false,
      'isMicOn': false,
      'isHandRaised': false,
      'initials': 'JM',
    },
    {
      'name': 'Elena Rostova',
      'isSelf': false,
      'isMicOn': false,
      'isHandRaised': true,
      'avatar': 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=120',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: AppSpacing.roundedLg,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Main Live Video Feed
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              children: [
                // Live Stream Video Canvas / Instructor Visual
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.secondary, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.secondary.withOpacity(0.4),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const CircleAvatar(
                            backgroundColor: Color(0xFF334155),
                            child: Icon(Icons.videocam, size: 44, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.instructorName,
                          style: AppTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Broadcasting via Jitsi Meet Live Stream',
                          style: AppTypography.labelSmall.copyWith(color: AppColors.secondaryFixedDim),
                        ),
                      ],
                    ),
                  ),
                ),

                // Top Header Overlay: LIVE Badge, Timer, Title
                Positioned(
                  top: 14,
                  left: 14,
                  right: 14,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: AppSpacing.roundedFull,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'LIVE',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: AppSpacing.roundedFull,
                            ),
                            child: Text(
                              '45:12',
                              style: AppTypography.labelSmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: AppSpacing.roundedFull,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.group, size: 14, color: Colors.white70),
                            const SizedBox(width: 6),
                            Text(
                              '${widget.participantCount} in Room',
                              style: AppTypography.labelSmall.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Participant Overlay Horizontal Carousel
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: SizedBox(
                    height: 84,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _participants.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, idx) {
                        if (idx == _participants.length) {
                          return Container(
                            width: 64,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: AppSpacing.roundedMd,
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Center(
                              child: Text(
                                '+${widget.participantCount - _participants.length}',
                                style: AppTypography.labelMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                              ),
                            ),
                          );
                        }

                        final p = _participants[idx];
                        final isSelf = p['isSelf'] == true;
                        final hasHand = isSelf ? _isHandRaised : (p['isHandRaised'] == true);
                        final micOn = isSelf ? _isMicOn : (p['isMicOn'] == true);

                        return Container(
                          width: 68,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: AppSpacing.roundedMd,
                            border: Border.all(
                              color: isSelf ? AppColors.secondary : Colors.white24,
                              width: isSelf ? 2 : 1,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            children: [
                              p['avatar'] != null
                                  ? Image.network(
                                      p['avatar'],
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white),
                                    )
                                  : Center(
                                      child: Text(
                                        p['initials'] ?? 'ST',
                                        style: AppTypography.labelMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                                      ),
                                    ),
                              // Hand raise badge
                              if (hasHand)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: AppColors.secondary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.front_hand, size: 10, color: Colors.white),
                                  ),
                                ),
                              // Mic state badge
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: micOn ? Colors.black54 : AppColors.error,
                                    borderRadius: AppSpacing.roundedSm,
                                  ),
                                  child: Icon(
                                    micOn ? Icons.mic : Icons.mic_off,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Meeting Controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // Mic
                    IconButton(
                      icon: Icon(_isMicOn ? Icons.mic : Icons.mic_off, color: Colors.white),
                      onPressed: () => setState(() => _isMicOn = !_isMicOn),
                      style: IconButton.styleFrom(
                        backgroundColor: _isMicOn ? Colors.white12 : AppColors.error,
                      ),
                      tooltip: 'Toggle Mic',
                    ),
                    const SizedBox(width: 8),
                    // Camera
                    IconButton(
                      icon: Icon(_isCameraOn ? Icons.videocam : Icons.videocam_off, color: Colors.white),
                      onPressed: () => setState(() => _isCameraOn = !_isCameraOn),
                      style: IconButton.styleFrom(
                        backgroundColor: _isCameraOn ? Colors.white12 : AppColors.error,
                      ),
                      tooltip: 'Toggle Camera',
                    ),
                    const SizedBox(width: 8),
                    // Raise Hand
                    IconButton(
                      icon: Icon(
                        Icons.front_hand,
                        color: _isHandRaised ? AppColors.secondaryFixed : Colors.white,
                      ),
                      onPressed: () {
                        setState(() => _isHandRaised = !_isHandRaised);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_isHandRaised ? 'Hand raised to instructor ✋' : 'Hand lowered'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: _isHandRaised ? AppColors.secondary.withOpacity(0.5) : Colors.white12,
                      ),
                      tooltip: 'Raise Hand',
                    ),
                  ],
                ),

                Row(
                  children: [
                    // Chat Toggle
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                      onPressed: widget.onToggleChat,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white12,
                      ),
                      tooltip: 'Open Live Discussion',
                    ),
                    const SizedBox(width: 12),
                    // End / Leave Call
                    IconButton(
                      icon: const Icon(Icons.call_end, color: Colors.white),
                      onPressed: widget.onLeaveClass,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.error,
                      ),
                      tooltip: 'Leave Class',
                    ),
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
