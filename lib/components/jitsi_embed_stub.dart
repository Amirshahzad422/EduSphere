import 'package:flutter/material.dart';

Widget buildNativeCameraStream({
  required String streamKey,
  required bool isInstructor,
  required bool isMicOn,
  required bool isCameraOn,
  VoidCallback? onStreamStarted,
}) {
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
}) async {}

void toggleHardwareMediaTrack({required bool isAudio, required bool enabled}) {}

void stopHardwareMediaStream() {}

Future<bool> startHardwareScreenShare() async => false;

bool isJitsiEmbedSupported() => false;
bool isNativeMediaStreamSupported() => false;
