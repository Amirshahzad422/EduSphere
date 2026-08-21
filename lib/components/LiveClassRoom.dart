import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/live_class_model.dart';
import '../services/live_class_service.dart';
import '../styles/colors.dart';
import '../styles/spacing.dart';
import '../styles/typography.dart';
import '../utils/helpers.dart';
import 'jitsi_embed.dart';

class LiveClassRoom extends StatefulWidget {
  final String classId;
  final String courseId;
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
    this.classId = '',
    this.courseId = '',
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

class _LiveClassRoomState extends State<LiveClassRoom> {
  bool _isScreenSharing = false;
  String? _jaasJwtToken;
  String? _jaasAppId;
  String? _jaasServerURL;

  @override
  void initState() {
    super.initState();
    _initJaaSAndMedia();
  }

  Future<void> _initJaaSAndMedia() async {
    // 1. Fetch authenticated JaaS token
    try {
      final tokenRes = await LiveClassService().getLiveClassToken(
        courseId: widget.courseId.isNotEmpty ? widget.courseId : 'course_1',
        classId: widget.classId.isNotEmpty ? widget.classId : 'live_1',
        roomName: widget.jitsiRoomId,
        userId: widget.currentUserId.isNotEmpty ? widget.currentUserId : 'student',
        userName: widget.isInstructor ? widget.instructorName : widget.currentUserName,
        isInstructor: widget.isInstructor,
      );
      debugPrint('[LiveClassRoom] 🔑 JaaS Token received: ${tokenRes.token != null}, server: ${tokenRes.serverURL}, appId: ${tokenRes.appId}');
      if (mounted) {
        setState(() {
          _jaasJwtToken = tokenRes.token;
          _jaasAppId = tokenRes.appId;
          _jaasServerURL = tokenRes.serverURL;
        });
      }
    } catch (e) {
      debugPrint('[LiveClassRoom] ⚠️ Token retrieval note: $e');
    }

    // 2. Request runtime camera & microphone permissions and auto-join on mobile
    final granted = await _requestHardwarePermissions(audio: true, video: true, isInitialPrompt: true);
    if (!kIsWeb && widget.jitsiRoomId.isNotEmpty && mounted && granted) {
      _handleJoinLiveStream();
    }
  }

  Future<bool> _requestHardwarePermissions({
    bool audio = true,
    bool video = true,
    bool isInitialPrompt = false,
  }) async {
    if (kIsWeb) return true;
    try {
      final permissionsToRequest = <Permission>[];
      if (audio) permissionsToRequest.add(Permission.microphone);
      if (video) permissionsToRequest.add(Permission.camera);

      final statuses = await permissionsToRequest.request();
      bool allGranted = true;

      for (final entry in statuses.entries) {
        debugPrint('[LiveClassRoom] Permission ${entry.key}: ${entry.value}');
        if (!entry.value.isGranted && !entry.value.isLimited) {
          allGranted = false;
        }
      }

      if (!allGranted && !isInitialPrompt && mounted) {
        AppHelpers.showSnackBar(
          context,
          '⚠️ Please allow Camera and Microphone permissions in App Settings to broadcast.',
          isError: true,
        );
      }
      return allGranted;
    } catch (e) {
      debugPrint('[LiveClassRoom] Permission request note: $e');
      return false;
    }
  }

  Future<void> _handleToggleMic() async {
    final nextState = !widget.isMicOn;
    if (nextState) {
      await _requestHardwarePermissions(audio: true, video: false);
    }
    toggleHardwareMediaTrack(isAudio: true, enabled: nextState);
    widget.onToggleMic?.call(nextState);
    if (mounted) {
      AppHelpers.showSnackBar(
        context,
        nextState ? '🎤 Microphone enabled / unmuted' : '🔇 Microphone muted',
      );
    }
  }

  Future<void> _handleToggleCamera() async {
    final nextState = !widget.isCameraOn;
    if (nextState) {
      await _requestHardwarePermissions(audio: false, video: true);
    }
    toggleHardwareMediaTrack(isAudio: false, enabled: nextState);
    widget.onToggleCamera?.call(nextState);
    if (mounted) {
      AppHelpers.showSnackBar(
        context,
        nextState ? '📷 Camera turned on' : '🚫 Camera turned off',
      );
    }
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

  Future<void> _handleJoinLiveStream() async {
    await _requestHardwarePermissions(audio: true, video: true);
    if (!kIsWeb) {
      await launchMobileJitsiMeeting(
        jitsiRoomId: widget.jitsiRoomId,
        displayName: widget.isInstructor
            ? '${widget.instructorName} (Instructor)'
            : widget.currentUserName,
        email: widget.currentUserId.isNotEmpty ? '${widget.currentUserId}@edusphere.io' : 'student@edusphere.io',
        avatarUrl: null,
        roomTitle: widget.roomTitle,
        isMicOn: widget.isMicOn,
        isCameraOn: widget.isCameraOn,
        jwtToken: _jaasJwtToken,
        jaasAppId: _jaasAppId,
        serverURL: _jaasServerURL,
      );
    }
    // On Web: The Jitsi room renders embedded 100% inside the App UI via HtmlElementView.
  }

  @override
  Widget build(BuildContext context) {
    final activeParticipantCount = widget.participants.isNotEmpty ? widget.participants.length : 1;
    final isJitsiSupported = isJitsiEmbedSupported();
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 480;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B0F19),
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: Colors.white12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Main Live Video Feed Stage (Adaptive Height with Zero Overflow)
          AspectRatio(
            aspectRatio: isCompact ? 16 / 10 : 16 / 9,
            child: Stack(
              children: [
                // Jitsi Meet / JaaS (8x8.vc) Embed Option (Web Direct IFrame)
                if (isJitsiSupported && widget.jitsiRoomId.isNotEmpty)
                  Positioned.fill(
                    child: buildJitsiEmbed(
                      jitsiRoomId: widget.jitsiRoomId,
                      displayName: widget.isInstructor
                          ? '${widget.instructorName} (Instructor)'
                          : widget.currentUserName,
                      isInstructor: widget.isInstructor,
                      isMicOn: widget.isMicOn,
                      isCameraOn: widget.isCameraOn,
                      jwtToken: _jaasJwtToken,
                      jaasAppId: _jaasAppId,
                      serverURL: _jaasServerURL,
                    ),
                  )
                // High-End Interactive Live Broadcast Theater (Mobile Native SDK)
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
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: screenWidth > 64 ? screenWidth - 32 : 300),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: isCompact ? 54 : 70,
                                  height: isCompact ? 54 : 70,
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
                                      size: isCompact ? 28 : 36,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  widget.isInstructor
                                      ? '${widget.instructorName} (Broadcasting)'
                                      : widget.instructorName,
                                  style: (isCompact ? AppTypography.titleSmall : AppTypography.titleMedium)
                                      .copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Room: ${widget.jitsiRoomId}',
                                  style: AppTypography.labelSmall.copyWith(color: AppColors.secondaryFixedDim, fontSize: 10),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.secondary,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isCompact ? 10 : 14,
                                      vertical: isCompact ? 4 : 6,
                                    ),
                                    shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedSm),
                                  ),
                                  icon: const Icon(Icons.videocam, size: 14),
                                  label: Text(
                                    widget.isInstructor ? 'Broadcast Live (Jitsi)' : 'Join Video Feed (Jitsi)',
                                    style: TextStyle(fontSize: isCompact ? 10.5 : 12, fontWeight: FontWeight.w800),
                                  ),
                                  onPressed: _handleJoinLiveStream,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Top Header Overlay: LIVE Badge, Participant Counter, External Button
                Positioned(
                  top: 8,
                  left: 8,
                  right: 8,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'LIVE',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 9.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: AppSpacing.roundedSm,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.people, size: 11, color: Colors.white70),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$activeParticipantCount',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!kIsWeb)
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                tooltip: 'Rejoin Live Conference',
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black.withOpacity(0.7),
                                ),
                                icon: const Icon(Icons.videocam, size: 14, color: Colors.white),
                                onPressed: _handleJoinLiveStream,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Participant Stream Strip (Dedicated Row - Zero Collision)
          if (widget.participants.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF131B2E),
                border: Border(
                  top: BorderSide(color: Colors.white12),
                  bottom: BorderSide(color: Colors.white12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Connected Attendees (${widget.participants.length})',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.secondaryFixedDim,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          widget.isInstructor ? 'Broadcasting Room' : 'Interactive Session',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white54,
                            fontSize: 9.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 56,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.participants.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, idx) {
                        final p = widget.participants[idx];
                        final isSelf = p.userId == widget.currentUserId;
                        final hasHand = isSelf ? widget.isHandRaised : p.isHandRaised;
                        final micOn = isSelf ? widget.isMicOn : p.isMicOn;

                        return Container(
                          width: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: AppSpacing.roundedSm,
                            border: Border.all(
                              color: isSelf ? AppColors.secondary : Colors.white24,
                              width: isSelf ? 1.5 : 1,
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
                                      errorBuilder: (_, __, ___) => Center(
                                        child: Text(
                                          p.name.isNotEmpty
                                              ? p.name.substring(0, p.name.length > 2 ? 2 : p.name.length).toUpperCase()
                                              : 'ST',
                                          style: AppTypography.labelSmall
                                              .copyWith(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        p.name.isNotEmpty
                                            ? p.name.substring(0, p.name.length > 2 ? 2 : p.name.length).toUpperCase()
                                            : 'ST',
                                        style: AppTypography.labelSmall
                                            .copyWith(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10),
                                      ),
                                    ),

                              if (isSelf)
                                Positioned(
                                  top: 2,
                                  left: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: const Text(
                                      'YOU',
                                      style: TextStyle(
                                        fontSize: 7,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),

                              if (hasHand)
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: Container(
                                    padding: const EdgeInsets.all(1.5),
                                    decoration: const BoxDecoration(
                                      color: AppColors.secondary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.front_hand, size: 8, color: Colors.white),
                                  ),
                                ),

                              Positioned(
                                bottom: 2,
                                right: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(1.5),
                                  decoration: BoxDecoration(
                                    color: micOn ? Colors.black87 : AppColors.error,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Icon(
                                    micOn ? Icons.mic : Icons.mic_off,
                                    size: 8,
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
                ],
              ),
            ),

          // 3. Bottom Meeting Controls (Responsive Fitted Container)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Mic Toggle
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        icon: Icon(widget.isMicOn ? Icons.mic : Icons.mic_off, color: Colors.white, size: 18),
                        onPressed: _handleToggleMic,
                        style: IconButton.styleFrom(
                          backgroundColor: widget.isMicOn ? AppColors.secondary : AppColors.error,
                        ),
                        tooltip: widget.isMicOn ? 'Mute Microphone' : 'Unmute Microphone',
                      ),
                      const SizedBox(width: 6),

                      // Camera Toggle
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        icon: Icon(widget.isCameraOn ? Icons.videocam : Icons.videocam_off, color: Colors.white, size: 18),
                        onPressed: _handleToggleCamera,
                        style: IconButton.styleFrom(
                          backgroundColor: widget.isCameraOn ? AppColors.secondary : AppColors.error,
                        ),
                        tooltip: widget.isCameraOn ? 'Turn Off Camera' : 'Turn On Camera',
                      ),
                      const SizedBox(width: 6),

                      // Screen Share
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        icon: Icon(
                          _isScreenSharing ? Icons.screen_share : Icons.screen_share_outlined,
                          color: _isScreenSharing ? AppColors.secondaryFixed : Colors.white,
                          size: 18,
                        ),
                        onPressed: _handleScreenShare,
                        style: IconButton.styleFrom(
                          backgroundColor: _isScreenSharing ? AppColors.secondary.withOpacity(0.5) : Colors.white12,
                        ),
                        tooltip: 'Share Screen',
                      ),

                      // Raise Hand
                      if (!widget.isInstructor) ...[
                        const SizedBox(width: 6),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          icon: Icon(
                            Icons.front_hand,
                            color: widget.isHandRaised ? AppColors.secondaryFixed : Colors.white,
                            size: 18,
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
                    ],
                  ),
                  const SizedBox(width: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Chat Toggle
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 18),
                        onPressed: widget.onToggleChat,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white12,
                        ),
                        tooltip: 'Live Class Chat',
                      ),
                      const SizedBox(width: 6),

                      // End / Leave Call
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        icon: const Icon(Icons.call_end, color: Colors.white, size: 18),
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
          ),
        ],
      ),
    );
  }
}
