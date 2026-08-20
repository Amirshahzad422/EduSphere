class CertificateModel {
  final String id;
  final String userId;
  final String userName;
  final String courseId;
  final String courseTitle;
  final String instructorName;
  final String verificationId;
  final String qrCodeUrl;
  final String? pdfUrl;
  final DateTime issuedAt;

  const CertificateModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.courseId,
    required this.courseTitle,
    required this.instructorName,
    required this.verificationId,
    required this.qrCodeUrl,
    this.pdfUrl,
    required this.issuedAt,
  });

  factory CertificateModel.fromJson(Map<String, dynamic> json) {
    return CertificateModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      courseTitle: json['courseTitle'] as String? ?? '',
      instructorName: json['instructorName'] as String? ?? '',
      verificationId: json['verificationId'] as String? ?? '',
      qrCodeUrl: json['qrCodeUrl'] as String? ?? '',
      pdfUrl: json['pdfUrl'] as String?,
      issuedAt: json['issuedAt'] != null
          ? DateTime.tryParse(json['issuedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'courseId': courseId,
      'courseTitle': courseTitle,
      'instructorName': instructorName,
      'verificationId': verificationId,
      'qrCodeUrl': qrCodeUrl,
      'pdfUrl': pdfUrl,
      'issuedAt': issuedAt.toIso8601String(),
    };
  }
}
