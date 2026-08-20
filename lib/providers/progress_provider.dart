import 'package:flutter_riverpod/flutter_riverpod.dart';

// Tracks current video playback position / active lesson id
final activeLessonIdProvider = StateProvider<String?>((ref) => null);
final videoPlaybackSpeedProvider = StateProvider<double>((ref) => 1.0);
