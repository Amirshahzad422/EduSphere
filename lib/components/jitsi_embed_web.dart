// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

final Set<String> _registeredViews = {};
html.IFrameElement? _activeIframe;

Widget buildNativeCameraStream({
  required String streamKey,
  required bool isInstructor,
  required bool isMicOn,
  required bool isCameraOn,
  VoidCallback? onStreamStarted,
}) {
  // Always route to shared Jitsi conference on web
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
  final cleanRoomId = jitsiRoomId.isNotEmpty ? jitsiRoomId : 'edusphere_live_session';
  final appId = (jaasAppId != null && jaasAppId.isNotEmpty)
      ? jaasAppId
      : 'vpaas-magic-cookie-5c5675ce628e421aafac215917f37316';
  final server = (serverURL != null && serverURL.isNotEmpty) ? serverURL : '8x8.vc';
  final viewId = 'jitsi-frame-$cleanRoomId-${jwtToken?.hashCode ?? 0}';

  if (!_registeredViews.contains(viewId)) {
    ui_web.platformViewRegistry.registerViewFactory(viewId, (int id) {
      // JaaS (8x8.vc) Standard Configuration
      final configParams = [
        'config.prejoinConfig.enabled=false',
        'config.prejoinPageEnabled=false',
        'config.startWithAudioMuted=${!isMicOn}',
        'config.startWithVideoMuted=${!isCameraOn}',
        'userInfo.displayName=${Uri.encodeComponent(displayName)}',
      ].join('&');

      final jwtQuery = (jwtToken != null && jwtToken.isNotEmpty)
          ? 'jwt=${Uri.encodeComponent(jwtToken)}&'
          : '';

      final targetUrl = (jwtToken != null && jwtToken.isNotEmpty)
          ? 'https://$server/$appId/$cleanRoomId?$jwtQuery#$configParams'
          : 'https://meet.jit.si/$cleanRoomId#$configParams';

      final iframe = html.IFrameElement()
        ..src = targetUrl
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.backgroundColor = '#0F172A'
        ..allow = 'camera; microphone; display-capture; autoplay; clipboard-write; fullscreen'
        ..setAttribute('allowfullscreen', 'true');

      _activeIframe = iframe;
      return iframe;
    });
    _registeredViews.add(viewId);
  }

  return HtmlElementView(viewType: viewId);
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
  // On web, embed is used directly in-canvas
}

void toggleHardwareMediaTrack({required bool isAudio, required bool enabled}) {
  try {
    if (_activeIframe != null && _activeIframe!.contentWindow != null) {
      // Send postMessage to Jitsi Iframe if API listener is active
      _activeIframe!.contentWindow!.postMessage({
        'type': isAudio ? 'toggleAudio' : 'toggleVideo',
        'enabled': enabled,
      }, '*');
    }
  } catch (e) {
    debugPrint('[JitsiWeb] PostMessage note: $e');
  }
}

void stopHardwareMediaStream() {
  _activeIframe = null;
}

Future<bool> startHardwareScreenShare() async => false;

bool isJitsiEmbedSupported() => true;
bool isNativeMediaStreamSupported() => false;
