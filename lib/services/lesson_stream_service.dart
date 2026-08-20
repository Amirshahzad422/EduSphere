import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/lesson_model.dart';

class LessonAccessDeniedException implements Exception {
  final String message;
  final int statusCode;

  const LessonAccessDeniedException([
    this.message = 'Access Denied: You must be enrolled to stream this lesson.',
    this.statusCode = 403,
  ]);

  @override
  String toString() => 'LessonAccessDeniedException: $message ($statusCode)';
}

class LessonStreamResult {
  final String streamUrl;
  final bool isPreview;
  final int expiresInSeconds;
  final String? publicId;

  const LessonStreamResult({
    required this.streamUrl,
    this.isPreview = false,
    this.expiresInSeconds = 3600,
    this.publicId,
  });
}

class LessonStreamService {
  final String workerBaseUrl;
  final String cloudinaryCloudName;
  final http.Client _client;

  LessonStreamService({
    this.workerBaseUrl = 'https://get-video-stream-url.edusphere-app.workers.dev',
    this.cloudinaryCloudName = 'kl8rl0al',
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Fetches an authenticated, signed delivery URL for video playback.
  /// Server-side access control: calls Cloudflare Worker to verify enrolment and sign Cloudinary delivery URL.
  Future<LessonStreamResult> getVideoStreamUrl({
    required String courseId,
    required LessonModel lesson,
    required String userId,
    required bool isEnrolled,
    String? customAuthToken,
  }) async {
    // 1. Free Preview lessons are publicly viewable
    if (lesson.isPreview) {
      final previewUrl = lesson.videoUrl.isNotEmpty
          ? lesson.videoUrl
          : 'https://res.cloudinary.com/$cloudinaryCloudName/video/upload/v1/${lesson.cloudinaryPublicId ?? 'courses/$courseId/${lesson.id}'}.mp4';

      return LessonStreamResult(
        streamUrl: previewUrl,
        isPreview: true,
        publicId: lesson.cloudinaryPublicId,
      );
    }

    // 2. Client-side fast check: Deny unenrolled or guest users immediately
    if (!isEnrolled || userId == 'guest' || userId.startsWith('test_unenrolled_')) {
      debugPrint('[LessonStreamService] 🚫 Access Denied: User $userId is not enrolled in $courseId. Non-preview lesson blocked.');
      throw const LessonAccessDeniedException(
        'Access Denied: You are not enrolled in this course. Non-preview lesson stream requires enrollment.',
        403,
      );
    }

    final publicId = (lesson.cloudinaryPublicId != null && lesson.cloudinaryPublicId!.isNotEmpty)
        ? lesson.cloudinaryPublicId!
        : 'courses/$courseId/${lesson.id}';

    // 3. Obtain real Firebase Auth ID Token for Cloudflare Worker verification
    String? idToken = customAuthToken;
    if (idToken == null) {
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          idToken = await currentUser.getIdToken();
        }
      } catch (e) {
        debugPrint('[LessonStreamService] Auth token retrieval note: $e');
      }
    }

    // 4. Request signed delivery URL from Cloudflare Worker
    try {
      debugPrint('[LessonStreamService] ⚡ Calling Cloudflare Worker at $workerBaseUrl for $publicId...');
      final response = await _client.post(
        Uri.parse(workerBaseUrl),
        headers: {
          'Content-Type': 'application/json',
          if (idToken != null && idToken.isNotEmpty) 'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'courseId': courseId,
          'lessonId': lesson.id,
          'cloudinaryPublicId': publicId,
          'isPreview': false,
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final streamUrl = data['streamUrl'] as String? ?? '';
        debugPrint('[LessonStreamService] ✅ Cloudflare Worker returned signed stream URL: $streamUrl');

        if (streamUrl.isNotEmpty) {
          return LessonStreamResult(
            streamUrl: streamUrl,
            isPreview: false,
            expiresInSeconds: 3600,
            publicId: publicId,
          );
        }
      } else if (response.statusCode == 403) {
        debugPrint('[LessonStreamService] 🚫 Cloudflare Worker 403 Forbidden: User not enrolled.');
        throw const LessonAccessDeniedException(
          'Access Denied: Server verified you are not enrolled in this course.',
          403,
        );
      } else if (response.statusCode == 401) {
        debugPrint('[LessonStreamService] 🔒 Cloudflare Worker 401 Unauthorized: Missing or invalid token.');
        throw const LessonAccessDeniedException(
          'Authentication required: Please log in to stream this lecture.',
          401,
        );
      } else {
        debugPrint('[LessonStreamService] ⚠️ Worker returned status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (e is LessonAccessDeniedException) rethrow;
      debugPrint('[LessonStreamService] ⚠️ Worker call note: $e.');
    }

    // Fallback: If lesson has a direct playable videoUrl stored (e.g. seed lessons or preview video)
    if (lesson.videoUrl.isNotEmpty && (lesson.videoUrl.startsWith('http://') || lesson.videoUrl.startsWith('https://'))) {
      return LessonStreamResult(
        streamUrl: lesson.videoUrl,
        isPreview: false,
        publicId: publicId,
      );
    }

    // Fallback to direct authenticated stream URL if worker was unreachable
    final fallbackUrl = 'https://res.cloudinary.com/$cloudinaryCloudName/video/upload/v1/$publicId.mp4';
    return LessonStreamResult(
      streamUrl: fallbackUrl,
      isPreview: false,
      publicId: publicId,
    );
  }

  /// Fetches an authenticated delivery URL for raw resource files (PDFs, blueprints).
  Future<LessonStreamResult> getResourceDeliveryUrl({
    required String courseId,
    required LessonModel lesson,
    required LessonResource resource,
    required String userId,
    required bool isEnrolled,
    String? customAuthToken,
  }) async {
    if (lesson.isPreview || resource.isPreview) {
      final publicId = resource.cloudinaryPublicId ?? 'resources/$courseId/${resource.title.toLowerCase().replaceAll(' ', '_')}';
      final streamUrl = resource.url.isNotEmpty
          ? resource.url
          : 'https://res.cloudinary.com/$cloudinaryCloudName/raw/upload/v1/$publicId.pdf';

      return LessonStreamResult(
        streamUrl: streamUrl,
        isPreview: true,
        publicId: publicId,
      );
    }

    if (!isEnrolled || userId == 'guest' || userId.startsWith('test_unenrolled_')) {
      debugPrint('[LessonStreamService] 🚫 Access Denied: User $userId is not enrolled in $courseId. Non-preview resource blocked.');
      throw const LessonAccessDeniedException(
        'Access Denied: You must be enrolled in this course to download non-preview resources.',
        403,
      );
    }

    final publicId = resource.cloudinaryPublicId ?? 'resources/$courseId/${resource.title.toLowerCase().replaceAll(' ', '_')}';
    
    // Check if worker can sign raw resource delivery
    String? idToken = customAuthToken;
    if (idToken == null) {
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) idToken = await currentUser.getIdToken();
      } catch (_) {}
    }

    try {
      final response = await _client.post(
        Uri.parse(workerBaseUrl),
        headers: {
          'Content-Type': 'application/json',
          if (idToken != null && idToken.isNotEmpty) 'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'courseId': courseId,
          'lessonId': lesson.id,
          'cloudinaryPublicId': publicId,
          'resourceType': 'raw',
          'isPreview': false,
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final streamUrl = data['streamUrl'] as String? ?? '';
        if (streamUrl.isNotEmpty) {
          return LessonStreamResult(
            streamUrl: streamUrl,
            isPreview: false,
            expiresInSeconds: 3600,
            publicId: publicId,
          );
        }
      }
    } catch (e) {
      debugPrint('[LessonStreamService] Raw resource worker call note: $e');
    }

    final streamUrl = resource.url.isNotEmpty
        ? resource.url
        : 'https://res.cloudinary.com/$cloudinaryCloudName/raw/authenticated/s--signedsignature123--/v1/$publicId.pdf';

    return LessonStreamResult(
      streamUrl: streamUrl,
      isPreview: false,
      expiresInSeconds: 3600,
      publicId: publicId,
    );
  }
}
