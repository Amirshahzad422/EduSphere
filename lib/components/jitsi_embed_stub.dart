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
}) {
  return const SizedBox.shrink();
}

void toggleHardwareMediaTrack({required bool isAudio, required bool enabled}) {}

void stopHardwareMediaStream() {}

Future<bool> startHardwareScreenShare() async => false;

bool isJitsiEmbedSupported() => false;
bool isNativeMediaStreamSupported() => false;
