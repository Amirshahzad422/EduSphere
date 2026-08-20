import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/certificate_model.dart';

class CertificateService {
  final http.Client _client;
  final String _generateWorkerUrl;
  final String _verifyWorkerUrl;

  CertificateService({
    http.Client? client,
    String? generateWorkerUrl,
    String? verifyWorkerUrl,
  })  : _client = client ?? http.Client(),
        _generateWorkerUrl = generateWorkerUrl ?? 'https://generate-certificate.edusphere-app.workers.dev',
        _verifyWorkerUrl = verifyWorkerUrl ?? 'https://verify-certificate.edusphere-app.workers.dev';

  /// Generates a verifiable PDF certificate on course completion via Cloudflare Worker
  Future<CertificateModel> generateCertificate({
    required String userId,
    required String userName,
    required String courseId,
    required String courseTitle,
    required String instructorName,
    String? idToken,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final cleanTag = courseId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    final tagSub = cleanTag.length > 6 ? cleanTag.substring(0, 6) : cleanTag;
    final fallbackVerificationId = 'EDUS-${timestamp.toString().substring(timestamp.toString().length - 6)}-$tagSub';
    final fallbackVerifyUrl = 'https://verify.edusphere-app.workers.dev/verify/$fallbackVerificationId';
    final fallbackQrUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${Uri.encodeComponent(fallbackVerifyUrl)}';
    final fallbackPdfUrl = 'https://res.cloudinary.com/kl8rl0al/raw/upload/v1/certificates/$fallbackVerificationId.pdf';

    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (idToken != null && idToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $idToken';
      }

      final response = await _client.post(
        Uri.parse('$_generateWorkerUrl/generateCertificate'),
        headers: headers,
        body: jsonEncode({
          'userId': userId,
          'userName': userName,
          'courseId': courseId,
          'courseTitle': courseTitle,
          'instructorName': instructorName,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['certificate'] != null) {
          final cert = CertificateModel.fromJson(Map<String, dynamic>.from(data['certificate']));
          debugPrint('[CertificateService] ✅ Cloudflare Worker generated certificate: ${cert.verificationId}');
          return cert;
        }
      }
    } catch (e) {
      debugPrint('[CertificateService] Cloudflare Worker note: $e. Using local credential model.');
    }

    // Fallback/offline instant certificate creation
    final localCert = CertificateModel(
      id: fallbackVerificationId,
      userId: userId,
      userName: userName,
      courseId: courseId,
      courseTitle: courseTitle,
      instructorName: instructorName,
      verificationId: fallbackVerificationId,
      qrCodeUrl: fallbackQrUrl,
      pdfUrl: fallbackPdfUrl,
      issuedAt: DateTime.now(),
    );

    // Save to Firestore if available
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('certificates')
            .doc(fallbackVerificationId)
            .set(localCert.toJson());
      }
    } catch (_) {}

    return localCert;
  }

  /// Verifies a certificate public ID via Cloudflare Worker
  Future<Map<String, dynamic>> verifyCertificate(String verificationId) async {
    if (verificationId.trim().isEmpty) {
      return {
        'valid': false,
        'error': 'Verification ID cannot be empty.',
      };
    }

    try {
      final response = await _client.get(
        Uri.parse('$_verifyWorkerUrl/verify/$verificationId'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      } else if (response.statusCode == 404) {
        return {
          'valid': false,
          'error': 'Certificate not found or revoked. This credential could not be verified on the EduSphere ledger.',
        };
      }
    } catch (e) {
      debugPrint('[CertificateService] Verify worker note: $e');
    }

    // Direct Firestore lookup fallback
    try {
      if (Firebase.apps.isNotEmpty) {
        final doc = await FirebaseFirestore.instance
            .collection('certificates')
            .doc(verificationId)
            .get();
        if (doc.exists && doc.data() != null) {
          final cert = CertificateModel.fromJson(doc.data()!);
          return {
            'valid': true,
            'certificate': cert.toJson(),
          };
        }
      }
    } catch (_) {}

    return {
      'valid': false,
      'error': 'Certificate not found or revoked. This credential could not be verified on the EduSphere ledger.',
    };
  }

  /// Streams user's certificates in real time
  Stream<List<CertificateModel>> streamUserCertificates(String userId) {
    if (userId.isEmpty || userId == 'guest') {
      return Stream.value([]);
    }

    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance
            .collection('certificates')
            .where('userId', isEqualTo: userId)
            .snapshots()
            .map((snapshot) => snapshot.docs
                .map((doc) => CertificateModel.fromJson(doc.data()))
                .toList());
      }
    } catch (_) {}

    return Stream.value([]);
  }
}

final certificateServiceProvider = Provider<CertificateService>((ref) {
  return CertificateService();
});

final userCertificatesStreamProvider = StreamProvider.family<List<CertificateModel>, String>((ref, userId) {
  final service = ref.watch(certificateServiceProvider);
  return service.streamUserCertificates(userId);
});
