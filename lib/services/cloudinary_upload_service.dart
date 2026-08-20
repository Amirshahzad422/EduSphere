import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class CloudinaryUploadException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic errorDetails;

  const CloudinaryUploadException(
    this.message, {
    this.statusCode,
    this.errorDetails,
  });

  @override
  String toString() => 'CloudinaryUploadException: $message (status: $statusCode)';
}

class CloudinaryUploadResult {
  final String publicId;
  final String secureUrl;
  final String resourceType;
  final String format;
  final int bytes;
  final int durationSeconds;
  final String accessMode;
  final int width;
  final int height;
  final String originalFilename;
  final DateTime createdAt;

  const CloudinaryUploadResult({
    required this.publicId,
    required this.secureUrl,
    required this.resourceType,
    required this.format,
    required this.bytes,
    this.durationSeconds = 0,
    required this.accessMode,
    this.width = 0,
    this.height = 0,
    this.originalFilename = '',
    required this.createdAt,
  });

  factory CloudinaryUploadResult.fromJson(Map<String, dynamic> json) {
    return CloudinaryUploadResult(
      publicId: json['public_id'] as String? ?? '',
      secureUrl: json['secure_url'] as String? ?? '',
      resourceType: json['resource_type'] as String? ?? 'video',
      format: json['format'] as String? ?? 'mp4',
      bytes: (json['bytes'] as num?)?.toInt() ?? 0,
      durationSeconds: (json['duration'] as num?)?.toInt() ?? 0,
      accessMode: json['access_mode'] as String? ?? 'authenticated',
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
      originalFilename: json['original_filename'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

typedef UploadProgressCallback = void Function(
  double progress,
  int bytesSent,
  int totalBytes,
);

class CloudinaryUploadService {
  final String cloudName;
  final http.Client _client;

  // Preset-locked access modes configured in the Cloudinary dashboard
  static const String publicPreviewPreset = 'edusphere_public_preview';
  static const String authenticatedPreset = 'edusphere_authenticated';

  // Hard 100MB Cloudinary free-tier ceiling (strictly enforced client-side)
  static const int maxFileSizeBytes = 100 * 1024 * 1024; // 100 MB

  // Chunk size for large file chunked uploads (6MB per chunk)
  static const int chunkSizeBytes = 6 * 1024 * 1024; // 6 MB

  CloudinaryUploadService({
    this.cloudName = 'kl8rl0al',
    http.Client? client,
  }) : _client = client ?? http.Client();

  String get _baseUploadUrl => 'https://api.cloudinary.com/v1_1/$cloudName';

  /// Uploads a lecture video to Cloudinary via real multipart HTTP requests.
  /// - Non-preview (Paid) lessons use preset `edusphere_authenticated` (Access Mode: Authenticated)
  /// - Preview (Free) lessons use preset `edusphere_public_preview` (Access Mode: Public)
  Future<CloudinaryUploadResult> uploadLessonVideo({
    required String courseId,
    required String lessonId,
    required String fileName,
    required Uint8List fileBytes,
    bool isPreview = false,
    UploadProgressCallback? onProgress,
  }) async {
    return _uploadFile(
      resourceType: 'video',
      folderPath: 'courses/$courseId',
      customPublicId: 'courses/$courseId/$lessonId',
      fileName: fileName,
      fileBytes: fileBytes,
      isPreview: isPreview,
      onProgress: onProgress,
    );
  }

  /// Uploads a PDF / Blueprint resource to Cloudinary (resource_type: raw).
  Future<CloudinaryUploadResult> uploadLessonResource({
    required String courseId,
    required String resourceId,
    required String fileName,
    required Uint8List fileBytes,
    bool isPreview = false,
    UploadProgressCallback? onProgress,
  }) async {
    return _uploadFile(
      resourceType: 'raw',
      folderPath: 'resources/$courseId',
      customPublicId: 'resources/$courseId/$resourceId',
      fileName: fileName,
      fileBytes: fileBytes,
      isPreview: isPreview,
      onProgress: onProgress,
    );
  }

  /// Uploads a user profile photo to Cloudinary (resource_type: image, public mode).
  Future<CloudinaryUploadResult> uploadProfilePhoto({
    required String userId,
    required String fileName,
    required Uint8List fileBytes,
    UploadProgressCallback? onProgress,
  }) async {
    return _uploadFile(
      resourceType: 'image',
      folderPath: 'profiles/$userId',
      customPublicId: 'profiles/$userId/avatar_${DateTime.now().millisecondsSinceEpoch}',
      fileName: fileName,
      fileBytes: fileBytes,
      isPreview: true, // Public access mode for avatars
      onProgress: onProgress,
    );
  }

  /// Core implementation handling direct single-part or chunked multipart upload.
  Future<CloudinaryUploadResult> _uploadFile({
    required String resourceType,
    required String folderPath,
    required String customPublicId,
    required String fileName,
    required Uint8List fileBytes,
    required bool isPreview,
    UploadProgressCallback? onProgress,
  }) async {
    final totalBytes = fileBytes.length;

    // 1. Client-Side Size Guard: Block files exceeding 100MB free-tier ceiling
    if (totalBytes > maxFileSizeBytes) {
      final sizeMb = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
      debugPrint('[CloudinaryUploadService] 🚫 Upload blocked: $sizeMb MB exceeds 100MB free-tier ceiling.');
      throw CloudinaryUploadException(
        'File size ($sizeMb MB) exceeds Cloudinary free tier limit (100MB). Please compress or trim the video before uploading.',
      );
    }

    // 2. Preset-Level Access Mode Selection (cannot be overridden client-side)
    final presetName = isPreview ? publicPreviewPreset : authenticatedPreset;
    final accessMode = isPreview ? 'public' : 'authenticated';

    debugPrint(
      '[CloudinaryUploadService] 🚀 Starting real upload ($totalBytes bytes, $resourceType) '
      'using locked preset "$presetName" (Access: $accessMode) to $customPublicId',
    );

    // 3. For files > chunkSizeBytes (6MB), use Cloudinary's chunked upload protocol
    if (totalBytes > chunkSizeBytes) {
      return _uploadChunked(
        resourceType: resourceType,
        presetName: presetName,
        customPublicId: customPublicId,
        fileName: fileName,
        fileBytes: fileBytes,
        onProgress: onProgress,
      );
    }

    // 4. Single-part multipart POST for files <= 6MB
    final uri = Uri.parse('$_baseUploadUrl/$resourceType/upload');
    final request = http.MultipartRequest('POST', uri);

    request.fields['upload_preset'] = presetName;
    request.fields['public_id'] = customPublicId;

    final multipartFile = http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: fileName,
    );
    request.files.add(multipartFile);

    onProgress?.call(0.1, 0, totalBytes);

    try {
      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      onProgress?.call(1.0, totalBytes, totalBytes);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('[CloudinaryUploadService] ✅ Upload succeeded: public_id=${data['public_id']}, access_mode=${data['access_mode']}');
        return CloudinaryUploadResult.fromJson(data);
      } else {
        dynamic errorJson;
        try {
          errorJson = jsonDecode(response.body);
        } catch (_) {
          errorJson = response.body;
        }
        final errorMessage = errorJson is Map && errorJson['error']?['message'] != null
            ? errorJson['error']['message'] as String
            : 'Cloudinary upload failed with status ${response.statusCode}';

        debugPrint('[CloudinaryUploadService] ❌ Upload error: $errorMessage');
        throw CloudinaryUploadException(
          errorMessage,
          statusCode: response.statusCode,
          errorDetails: errorJson,
        );
      }
    } catch (e) {
      if (e is CloudinaryUploadException) rethrow;
      debugPrint('[CloudinaryUploadService] ❌ Network error during upload: $e');
      throw CloudinaryUploadException('Network error during upload: $e');
    }
  }

  /// Cloudinary Chunked Large Upload protocol for files > 6MB
  Future<CloudinaryUploadResult> _uploadChunked({
    required String resourceType,
    required String presetName,
    required String customPublicId,
    required String fileName,
    required Uint8List fileBytes,
    UploadProgressCallback? onProgress,
  }) async {
    final totalBytes = fileBytes.length;
    final uniqueUploadId = const Uuid().v4();
    final uri = Uri.parse('$_baseUploadUrl/$resourceType/upload');

    int start = 0;
    CloudinaryUploadResult? finalResult;

    while (start < totalBytes) {
      final end = (start + chunkSizeBytes < totalBytes) ? start + chunkSizeBytes : totalBytes;
      final chunkBytes = fileBytes.sublist(start, end);
      final contentRange = 'bytes $start-${end - 1}/$totalBytes';

      debugPrint('[CloudinaryUploadService] 📦 Uploading chunk: $contentRange (id: $uniqueUploadId)');

      final request = http.MultipartRequest('POST', uri);
      request.headers['X-Unique-Upload-Id'] = uniqueUploadId;
      request.headers['Content-Range'] = contentRange;

      request.fields['upload_preset'] = presetName;
      request.fields['public_id'] = customPublicId;

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          chunkBytes,
          filename: fileName,
        ),
      );

      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final progressFraction = end / totalBytes;
        onProgress?.call(progressFraction, end, totalBytes);

        if (end >= totalBytes) {
          finalResult = CloudinaryUploadResult.fromJson(data);
        }
      } else {
        dynamic err;
        try {
          err = jsonDecode(response.body);
        } catch (_) {
          err = response.body;
        }
        final msg = err is Map && err['error']?['message'] != null
            ? err['error']['message'] as String
            : 'Chunked upload error on range $contentRange';
        throw CloudinaryUploadException(msg, statusCode: response.statusCode, errorDetails: err);
      }

      start = end;
    }

    if (finalResult == null) {
      throw const CloudinaryUploadException('Chunked upload completed without final response payload.');
    }

    debugPrint('[CloudinaryUploadService] ✅ Chunked upload completed: public_id=${finalResult.publicId}');
    return finalResult;
  }

  /// Safely deletes an asset from Cloudinary storage via Cloudflare Worker
  Future<bool> deleteCloudinaryAsset({
    required String publicId,
    String? courseId,
    String resourceType = 'video',
    String? idToken,
  }) async {
    if (publicId.isEmpty) return false;

    debugPrint('[CloudinaryUploadService] 🗑️ Requesting deletion of asset $publicId ($resourceType)...');

    try {
      final workerUrl = Uri.parse('https://delete-cloudinary-asset.edusphere-app.workers.dev');
      final token = idToken ?? 'test_instructor_token';

      final res = await _client.post(
        workerUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'publicId': publicId,
          'courseId': courseId,
          'resourceType': resourceType,
        }),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        debugPrint('[CloudinaryUploadService] ✅ Cloudinary asset deleted successfully: $publicId');
        return true;
      } else {
        debugPrint('[CloudinaryUploadService] ⚠️ Deletion warning from worker: ${res.body}');
        return false;
      }
    } catch (e) {
      debugPrint('[CloudinaryUploadService] ⚠️ Deletion error: $e');
      return false;
    }
  }
}
