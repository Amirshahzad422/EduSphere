import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/live_class_model.dart';
import '../styles/colors.dart';
import '../styles/spacing.dart';
import '../styles/typography.dart';
import '../utils/helpers.dart';
import 'jitsi_embed.dart';

class LiveClassRoom extends StatefulWidget {
  final String roomTitle;
  final String instructorName;
  final String jitsiRoomId;
  final bool isInstructor;
  final String currentUserId;
  final String currentUserName;
  final List<LiveClassParticipantModel> participants;
  final bool isMicOn;
  final bool isCameraOn;
  final bool isHandRaised;
  final ValueChanged<bool>? onToggleMic;
  final ValueChanged<bool>? onToggleCamera;
  final ValueChanged<bool>? onToggleHandRaise;
  final VoidCallback? onToggleChat;
  final VoidCallback? onLeaveClass;

  const LiveClassRoom({
    super.key,
    this.roomTitle = 'CS401: Neural Networks & Deep Learning',
    this.instructorName = 'Dr. Sarah Chen',
    this.jitsiRoomId = '',
    this.isInstructor = false,
    this.currentUserId = '',
    this.currentUserName = 'Student',
    this.participants = const [],
    this.isMicOn = true,
    this.isCameraOn = true,
    this.isHandRaised = false,
    this.onToggleMic,
    this.onToggleCamera,
    this.onToggleHandRaise,
    this.onToggleChat,
    this.onLeaveClass,
  });

  @override
  State<LiveClassRoom> createState() => _LiveClassRoomState();
}

enum LiveStreamEngine { nativeWebRTC, jitsiEmbed }

class _LiveClassRoomState extends State<LiveClassRoom> {
  LiveStreamEngine _engine = LiveStreamEngine.nativeWebRTC;
  bool _isScreenSharing = false;

  @override
  void initState() {
    super.initState();
    // Default to native WebRTC stream for zero-moderator login experience
    _engine = isNativeMediaStreamSupported()
        ? LiveStreamEngine.nativeWebRTC
        : LiveStreamEngine.jitsiEmbed;
  }

  void _handleToggleMic() {
    final nextState = !widget.isMicOn;
    toggleHardwareMediaTrack(isAudio: true, enabled: nextState);
    widget.onToggleMic?.call(nextState);
  }

  void _handleToggleCamera() {
    final nextState = !widget.isCameraOn;
    toggleHardwareMediaTrack(isAudio: false, enabled: nextState);
    widget.onToggleCamera?.call(nextState);
  }

  Future<void> _handleScreenShare() async {
    final success = await startHardwareScreenShare();
    if (mounted) {
      setState(() => _isScreenSharing = success);
      if (success) {
        AppHelpers.showSnackBar(context, '🖥️ Screen sharing active.');
      }
    }
  }

  Future<void> _openExternalJitsi() async {
    final cleanRoom = widget.jitsiRoomId.isNotEmpty ? widget.jitsiRoomId : 'edusphere_live_session';
    final url = Uri.parse(
      'https://meet.jit.si/$cleanRoom#config.prejoinConfig.enabled=false&config.prejoinPageEnabled=false&config.requireDisplayName=false&config.disableDeepLinking=true&config.startWithAudioMuted=${!widget.isMicOn}&config.startWithVideoMuted=${!widget.isCameraOn}&userInfo.displayName=${Uri.encodeComponent(widget.currentUserName)}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeParticipantCount = widget.participants.isNotEmpty ? widget.participants.length : 1;
    final isNativeSupported = isNativeMediaStreamSupported();
    final isJitsiSupported = isJitsiEmbedSupported();

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: AppSpacing.roundedLg,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Main Live Video Feed Canvas
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              children: [
                // 1. Native In-App WebRTC Stream Engine (Zero Moderator Login required!)
                if (_engine == LiveStreamEngine.nativeWebRTC && isNativeSupported)
                  Positioned.fill(
                    child: buildNativeCameraStream(
                      streamKey: '${widget.jitsiRoomId}_${widget.currentUserId}',
                      isInstructor: widget.isInstructor,
                      isMicOn: widget.isMicOn,
                      isCameraOn: widget.isCameraOn,
                    ),
                  )
                // 2. Jitsi Meet Embed Option (with prejoin bypass)
                else if (_engine == LiveStreamEngine.jitsiEmbed && isJitsiSupported && widget.jitsiRoomId.isNotEmpty)
                  Positioned.fill(
                    child: buildJitsiEmbed(
                      jitsiRoomId: widget.jitsiRoomId,
                      displayName: widget.isInstructor
                          ? '${widget.instructorName} (Instructor)'
                          : widget.currentUserName,
                      isInstructor: widget.isInstructor,
                      isMicOn: widget.isMicOn,
                      isCameraOn: widget.isCameraOn,
                    ),
                  )
                // 3. Fallback Theater Canvas
                else
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
                              border: Border.all(
                                color: widget.isCameraOn ? AppColors.secondary : AppColors.error,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (widget.isCameraOn ? AppColors.secondary : AppColors.error).withOpacity(0.4),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              backgroundColor: const Color(0xFF334155),
                              child: Icon(
                                widget.isCameraOn ? Icons.videocam : Icons.videocam_off,
                                size: 44,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.isInstructor
                                ? '${widget.instructorName} (You - Broadcasting)'
                                : widget.instructorName,
                            style: AppTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Room: ${widget.jitsiRoomId} • WebRTC In-App Stream',
                            style: AppTypography.labelSmall.copyWith(color: AppColors.secondaryFixedDim),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Top Header Overlay: LIVE Badge, Engine Toggle, Standalone button
                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: AppSpacing.roundedFull,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
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
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: AppSpacing.roundedSm,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.people, size: 12, color: Colors.white70),
                                const SizedBox(width: 4),
                                Text(
                                  '$activeParticipantCount',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (isNativeSupported)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: AppSpacing.roundedSm,
                                border: Border.all(color: AppColors.secondary.withOpacity(0.5)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.verified_user, size: 12, color: AppColors.secondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'EduSphere WebRTC',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(width: 6),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.all(4),
                            tooltip: 'Open Standalone Jitsi Link',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black.withOpacity(0.7),
                            ),
                            icon: const Icon(Icons.open_in_new, size: 16, color: Colors.white),
                            onPressed: _openExternalJitsi,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Bottom Overlay: Participant Carousel
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: SizedBox(
                    height: 84,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.participants.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, idx) {
                        final p = widget.participants[idx];
                        final isSelf = p.userId == widget.currentUserId;
                        final hasHand = isSelf ? widget.isHandRaised : p.isHandRaised;
                        final micOn = isSelf ? widget.isMicOn : p.isMicOn;

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
                              p.avatar != null && p.avatar!.isNotEmpty
                                  ? Image.network(
                                      p.avatar!,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white),
                                    )
                                  : Center(
                                      child: Text(
                                        p.name.isNotEmpty
                                            ? p.name.substring(0, p.name.length > 2 ? 2 : p.name.length).toUpperCase()
                                            : 'ST',
                                        style: AppTypography.labelMedium
                                            .copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                                      ),
                                    ),

                              if (isSelf)
                                Positioned(
                                  top: 4,
                                  left: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary,
                                      borderRadius: AppSpacing.roundedSm,
                                    ),
                                    child: Text(
                                      'YOU',
                                      style: AppTypography.labelSmall.copyWith(
                                        fontSize: 8,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),

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
                    // Mic Toggle
                    IconButton(
                      icon: Icon(widget.isMicOn ? Icons.mic : Icons.mic_off, color: Colors.white),
                      onPressed: _handleToggleMic,
                      style: IconButton.styleFrom(
                        backgroundColor: widget.isMicOn ? AppColors.secondary : AppColors.error,
                      ),
                      tooltip: widget.isMicOn ? 'Mute Microphone' : 'Unmute Microphone',
                    ),
                    const SizedBox(width: 8),

                    // Camera Toggle
                    IconButton(
                      icon: Icon(widget.isCameraOn ? Icons.videocam : Icons.videocam_off, color: Colors.white),
                      onPressed: _handleToggleCamera,
                      style: IconButton.styleFrom(
                        backgroundColor: widget.isCameraOn ? AppColors.secondary : AppColors.error,
                      ),
                      tooltip: widget.isCameraOn ? 'Turn Off Camera' : 'Turn On Camera',
                    ),
                    const SizedBox(width: 8),

                    // Screen Share
                    IconButton(
                      icon: Icon(
                        _isScreenSharing ? Icons.screen_share : Icons.screen_share_outlined,
                        color: _isScreenSharing ? AppColors.secondaryFixed : Colors.white,
                      ),
                      onPressed: _handleScreenShare,
                      style: IconButton.styleFrom(
                        backgroundColor: _isScreenSharing ? AppColors.secondary.withOpacity(0.5) : Colors.white12,
                      ),
                      tooltip: 'Share Screen',
                    ),
                    const SizedBox(width: 8),

                    // Raise Hand
                    if (!widget.isInstructor)
                      IconButton(
                        icon: Icon(
                          Icons.front_hand,
                          color: widget.isHandRaised ? AppColors.secondaryFixed : Colors.white,
                        ),
                        onPressed: widget.onToggleHandRaise != null
                            ? () => widget.onToggleHandRaise!(!widget.isHandRaised)
                            : null,
                        style: IconButton.styleFrom(
                          backgroundColor: widget.isHandRaised ? AppColors.secondary.withOpacity(0.5) : Colors.white12,
                        ),
                        tooltip: widget.isHandRaised ? 'Lower Hand' : 'Raise Hand',
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
                      tooltip: 'Live Class Chat',
                    ),
                    const SizedBox(width: 12),

                    // End / Leave Call
                    IconButton(
                      icon: const Icon(Icons.call_end, color: Colors.white),
                      onPressed: widget.onLeaveClass,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.error,
                      ),
                      tooltip: widget.isInstructor ? 'End Class for All' : 'Leave Class',
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
