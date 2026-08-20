import 'package:flutter/foundation.dart';
import '../models/certificate_model.dart';

class CertificateService {
  Future<CertificateModel> generateCertificate({
    required String userId,
    required String userName,
    required String courseId,
    required String courseTitle,
    required String instructorName,
  }) async {
    final verificationId = 'EDUS-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    final cert = CertificateModel(
      id: 'cert_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      userName: userName,
      courseId: courseId,
      courseTitle: courseTitle,
      instructorName: instructorName,
      verificationId: verificationId,
      qrCodeUrl: 'https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=https://edusphere.io/verify/$verificationId',
      issuedAt: DateTime.now(),
    );

    debugPrint('[CertificateService] Generated certificate $verificationId for $userName');
    return cert;
  }
}
