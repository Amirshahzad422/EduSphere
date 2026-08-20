import 'package:flutter/material.dart';

Widget createWebVideoPlayer({
  required String videoUrl,
  required String title,
  required int initialPositionSeconds,
  required int totalDurationSeconds,
  VoidCallback? onComplete,
  void Function(int seconds)? onPositionChanged,
}) {
  return const SizedBox.shrink();
}
