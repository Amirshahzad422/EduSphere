// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

final Set<String> _registeredViews = {};
html.MediaStream? _currentMediaStream;
html.VideoElement? _activeVideoElement;

Widget buildNativeCameraStream({
  required String streamKey,
  required bool isInstructor,
  required bool isMicOn,
  required bool isCameraOn,
  VoidCallback? onStreamStarted,
}) {
  final viewId = 'local-camera-stream-$streamKey';

  if (!_registeredViews.contains(viewId)) {
    ui_web.platformViewRegistry.registerViewFactory(viewId, (int id) {
      final video = html.VideoElement()
        ..autoplay = true
        ..muted = isInstructor // Mute local feedback for instructor
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.backgroundColor = '#0F172A'
        ..setAttribute('playsinline', 'true');

      _activeVideoElement = video;

      // Request browser hardware camera & microphone directly with ZERO external login
      html.window.navigator.mediaDevices?.getUserMedia({
        'video': {
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
          'facingMode': 'user',
        },
        'audio': true,
      }).then((stream) {
        _currentMediaStream = stream;
        video.srcObject = stream;
        
        // Sync initial track states
        for (final audioTrack in stream.getAudioTracks()) {
          audioTrack.enabled = isMicOn;
        }
        for (final videoTrack in stream.getVideoTracks()) {
          videoTrack.enabled = isCameraOn;
        }
        onStreamStarted?.call();
      }).catchError((err) {
        debugPrint('[LiveClass] Camera/Mic access prompt note: $err');
      });

      return video;
    });
    _registeredViews.add(viewId);
  }

  return HtmlElementView(viewType: viewId);
}

void toggleHardwareMediaTrack({required bool isAudio, required bool enabled}) {
  if (_currentMediaStream == null) return;

  if (isAudio) {
    for (final track in _currentMediaStream!.getAudioTracks()) {
      track.enabled = enabled;
    }
  } else {
    for (final track in _currentMediaStream!.getVideoTracks()) {
      track.enabled = enabled;
    }
  }
}

void stopHardwareMediaStream() {
  try {
    if (_currentMediaStream != null) {
      for (final track in _currentMediaStream!.getTracks()) {
        track.stop();
      }
      _currentMediaStream = null;
    }
    if (_activeVideoElement != null) {
      _activeVideoElement!.srcObject = null;
      _activeVideoElement = null;
    }
    debugPrint('[LiveClass] 🛑 Hardware camera and microphone stream released.');
  } catch (e) {
    debugPrint('[LiveClass] Error releasing media stream: $e');
  }
}

Future<bool> startHardwareScreenShare() async {
  try {
    final mediaDevices = html.window.navigator.mediaDevices as dynamic;
    final displayStream = await mediaDevices?.getDisplayMedia({
      'video': true,
      'audio': true,
    });
    if (displayStream != null && _activeVideoElement != null) {
      _currentMediaStream = displayStream;
      _activeVideoElement!.srcObject = displayStream;
      return true;
    }
  } catch (e) {
    debugPrint('[LiveClass] Screen share cancelled/error: $e');
  }
  return false;
}

Widget buildJitsiEmbed({
  required String jitsiRoomId,
  required String displayName,
  required bool isInstructor,
  required bool isMicOn,
  required bool isCameraOn,
}) {
  final cleanRoomId = jitsiRoomId.isNotEmpty ? jitsiRoomId : 'edusphere_live_session';
  final viewId = 'jitsi-frame-$cleanRoomId';

  if (!_registeredViews.contains(viewId)) {
    ui_web.platformViewRegistry.registerViewFactory(viewId, (int id) {
      // Configuration parameters bypassing pre-join & moderator waiting rooms
      final configParams = [
        'config.prejoinConfig.enabled=false',
        'config.prejoinPageEnabled=false',
        'config.requireDisplayName=false',
        'config.disableDeepLinking=true',
        'config.enableInsecureRoomNameAllowed=true',
        'config.startWithAudioMuted=${!isMicOn}',
        'config.startWithVideoMuted=${!isCameraOn}',
        'userInfo.displayName=${Uri.encodeComponent(displayName)}',
      ].join('&');

      final iframe = html.IFrameElement()
        ..src = 'https://meet.jit.si/$cleanRoomId#$configParams'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allow = 'camera; microphone; display-capture; autoplay; clipboard-write; fullscreen'
        ..setAttribute('allowfullscreen', 'true');
      return iframe;
    });
    _registeredViews.add(viewId);
  }

  return HtmlElementView(viewType: viewId);
}

bool isJitsiEmbedSupported() => true;
bool isNativeMediaStreamSupported() => true;
