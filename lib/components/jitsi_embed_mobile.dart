import 'package:flutter/material.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';

final JitsiMeet _jitsiMeet = JitsiMeet();
bool _isInJitsiMeeting = false;

Widget buildNativeCameraStream({
  required String streamKey,
  required bool isInstructor,
  required bool isMicOn,
  required bool isCameraOn,
  VoidCallback? onStreamStarted,
}) {
  // On mobile, Jitsi SDK manages the full native WebRTC stream
  return const SizedBox.shrink();
}

Widget buildJitsiEmbed({
  required String jitsiRoomId,
  required String displayName,
  required bool isInstructor,
  required bool isMicOn,
  required bool isCameraOn,
  String? jwtToken,
  String? jaasAppId,
  String? serverURL,
}) {
  return const SizedBox.shrink();
}

Future<void> launchMobileJitsiMeeting({
  required String jitsiRoomId,
  required String displayName,
  required String email,
  required String? avatarUrl,
  required String roomTitle,
  required bool isMicOn,
  required bool isCameraOn,
  String? jwtToken,
  String? jaasAppId,
  String? serverURL,
  VoidCallback? onTerminated,
}) async {
  final cleanRoom = jitsiRoomId.isNotEmpty ? jitsiRoomId : 'edusphere_live_session';
  final appId = (jaasAppId != null && jaasAppId.isNotEmpty)
      ? jaasAppId
      : 'vpaas-magic-cookie-5c5675ce628e421aafac215917f37316';
  final hasJwt = jwtToken != null && jwtToken.isNotEmpty;
  final server = hasJwt ? (serverURL ?? '8x8.vc') : 'meet.jit.si';
  final targetRoom = hasJwt ? '$appId/$cleanRoom' : cleanRoom;

  try {
    final options = JitsiMeetConferenceOptions(
      serverURL: 'https://$server',
      room: targetRoom,
      token: jwtToken,
      configOverrides: {
        'startWithAudioMuted': !isMicOn,
        'startWithVideoMuted': !isCameraOn,
        'subject': roomTitle,
        'prejoinConfig.enabled': false,
        'prejoinPageEnabled': false,
      },
      featureFlags: {
        'unsaferoomwarning.enabled': false,
        'prejoinpage.enabled': false,
        'welcomepage.enabled': false,
        'pip.enabled': true,
        'invite.enabled': false,
      },
      userInfo: JitsiMeetUserInfo(
        displayName: displayName,
        email: email.isNotEmpty ? email : 'student@edusphere.io',
        avatar: avatarUrl,
      ),
    );

    debugPrint('[JitsiMobile] 🚀 Connecting to server: https://$server, room: $targetRoom, hasToken: $hasJwt, tokenLength: ${jwtToken?.length ?? 0}');

    final listener = JitsiMeetEventListener(
      conferenceJoined: (url) {
        _isInJitsiMeeting = true;
        debugPrint('[JitsiMobile] ✅ Joined Jitsi conference: $url');
      },
      conferenceTerminated: (url, error) {
        _isInJitsiMeeting = false;
        debugPrint('[JitsiMobile] ⏹️ Conference terminated: $url, error: $error');
        onTerminated?.call();
      },
      conferenceWillJoin: (url) {
        debugPrint('[JitsiMobile] ⏳ Joining conference: $url');
      },
      readyToClose: () {
        _isInJitsiMeeting = false;
        debugPrint('[JitsiMobile] 🚪 Ready to close');
      },
    );

    await _jitsiMeet.join(options, listener);
  } catch (e) {
    debugPrint('[JitsiMobile] ⚠️ Jitsi SDK join note: $e');
  }
}

void toggleHardwareMediaTrack({required bool isAudio, required bool enabled}) {
  try {
    if (isAudio) {
      _jitsiMeet.setAudioMuted(!enabled);
    } else {
      _jitsiMeet.setVideoMuted(!enabled);
    }
  } catch (e) {
    debugPrint('[JitsiMobile] Media toggle error: $e');
  }
}

void stopHardwareMediaStream() {
  try {
    if (_isInJitsiMeeting) {
      _jitsiMeet.hangUp();
      _isInJitsiMeeting = false;
    }
  } catch (e) {
    debugPrint('[JitsiMobile] Stop stream note: $e');
  }
}

Future<bool> startHardwareScreenShare() async => false;

bool isJitsiEmbedSupported() => false;
bool isNativeMediaStreamSupported() => false;
