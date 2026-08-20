import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/enrolment_provider.dart';
import '../providers/course_provider.dart';
import '../models/course_model.dart';
import '../models/certificate_model.dart';
import '../services/certificate_service.dart';
import '../services/certificate_pdf_generator.dart';
import '../styles/colors.dart';
import '../styles/spacing.dart';
import '../styles/typography.dart';
import '../components/CertificateCard.dart';
import '../components/Button.dart';
import '../utils/formatters.dart';
import '../utils/helpers.dart';

class CertificatesScreen extends ConsumerStatefulWidget {
  final String? initialVerificationId;

  const CertificatesScreen({
    super.key,
    this.initialVerificationId,
  });

  @override
  ConsumerState<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends ConsumerState<CertificatesScreen> {
  final TextEditingController _verifyController = TextEditingController();
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialVerificationId?.isNotEmpty == true) {
      _verifyController.text = widget.initialVerificationId!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleVerifyId(widget.initialVerificationId!);
      });
    }
  }

  @override
  void dispose() {
    _verifyController.dispose();
    super.dispose();
  }

  Future<void> _handleVerifyId(String id) async {
    final cleanId = id.trim();
    if (cleanId.isEmpty) {
      AppHelpers.showSnackBar(context, 'Please enter a valid certificate ID', isError: true);
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      final certService = ref.read(certificateServiceProvider);
      final result = await certService.verifyCertificate(cleanId);
      if (mounted) {
        _showVerificationModal(result);
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(context, 'Verification error: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  void _showVerificationModal(Map<String, dynamic> result) {
    final isValid = result['valid'] == true;
    final certData = result['certificate'] as Map<String, dynamic>?;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(
              isValid ? Icons.verified : Icons.error_outline,
              color: isValid ? AppColors.secondary : AppColors.error,
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isValid ? 'Verified Credential' : 'Verification Failed',
                style: AppTypography.titleLarge.copyWith(
                  color: isValid ? AppColors.secondary : AppColors.error,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isValid && certData != null) ...[
              Text(
                'This certificate is authentic, accredited, and verified on the EduSphere ledger.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              _buildModalRow('Student Name', certData['userName'] ?? 'N/A'),
              _buildModalRow('Course', certData['courseTitle'] ?? 'N/A'),
              _buildModalRow('Instructor', certData['instructorName'] ?? 'N/A'),
              _buildModalRow('Verification ID', certData['verificationId'] ?? 'N/A', isHighlight: true),
              if (certData['issuedAt'] != null)
                _buildModalRow(
                  'Issued On',
                  AppFormatters.formatDate(DateTime.tryParse(certData['issuedAt'].toString()) ?? DateTime.now()),
                ),
            ] else ...[
              Text(
                result['error']?.toString() ?? 'Certificate ID could not be found on the verified registry.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurface),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          if (isValid && certData != null)
            AppButton(
              label: 'Download PDF',
              variant: ButtonVariant.primary,
              size: ButtonSize.sm,
              onPressed: () async {
                Navigator.pop(ctx);
                final cert = CertificateModel.fromJson(certData);
                await _handleDownloadPdf(cert);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildModalRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTypography.labelSmall.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: isHighlight ? AppColors.secondary : AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDownloadPdf(CertificateModel cert) async {
    try {
      await CertificatePdfGenerator.downloadOrPrintPdf(cert);
      if (mounted) {
        AppHelpers.showSnackBar(context, '✅ Generating & downloading official PDF for ${cert.userName}');
      }
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(context, 'PDF download exception: $e', isError: true);
      }
    }
  }

  void _showCertificateDetailModal(CertificateModel cert) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedXl),
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 760),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFF030D1E), Color(0xFF002244), Color(0xFF00407A), Color(0xFF030D1E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: const [
              BoxShadow(color: Colors.black54, blurRadius: 30, offset: Offset(0, 10)),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top close action row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0x2010B981),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF10B981)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified, size: 14, color: Color(0xFF10B981)),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'OFFICIALLY VERIFIED CREDENTIAL',
                                style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Main Certificate Parchment
                LayoutBuilder(
                  builder: (context, parchmentConstraints) {
                    final isParchmentNarrow = parchmentConstraints.maxWidth < 450;
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 10),
                        ],
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: isParchmentNarrow ? 14 : 28,
                        vertical: isParchmentNarrow ? 18 : 24,
                      ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Top Medal + Script Header
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 22,
                                  height: 18,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFF0F172A), Color(0xFFD4AF37), Color(0xFF0F172A)],
                                    ),
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
                                  ),
                                ),
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const RadialGradient(
                                      center: Alignment(-0.3, -0.3),
                                      colors: [Color(0xFFFFF5C0), Color(0xFFD4AF37), Color(0xFF8C6200)],
                                    ),
                                    border: Border.all(color: const Color(0xFFFDF6C7), width: 2.5),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.star, size: 22, color: Color(0xFF5A3C00)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Certificate',
                                style: GoogleFonts.greatVibes(
                                  fontSize: 48,
                                  color: const Color(0xFF0A2540),
                                  fontWeight: FontWeight.w600,
                                  height: 1.0,
                                ),
                              ),
                              Text(
                                'OF COMPLETION & APPRECIATION',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  letterSpacing: 4.0,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'This Certificate is Honorably Bestowed Upon',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          color: const Color(0xFF64748B),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Student Name
                      Text(
                        cert.userName,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.greatVibes(
                          fontSize: 42,
                          color: const Color(0xFF0A192F),
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Gold Divider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 80),
                              height: 1.5,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.transparent, Color(0xFFD4AF37)],
                                ),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6.0),
                            child: Text(
                              '✦ ❖ ✦',
                              style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10),
                            ),
                          ),
                          Flexible(
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 80),
                              height: 1.5,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFFD4AF37), Colors.transparent],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Commendation
                      Text(
                        'In recognition of your outstanding dedication, integrity, and meaningful contributions throughout the masterclass curriculum of',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF475569), height: 1.4),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cert.courseTitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0A192F),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Text(
                        CertificatePdfGenerator.formatPresentedDate(cert.issuedAt),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Bottom Signatures + High-Res Scannable QR Code
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.end,
                        children: [
                          // Left Signature (Instructor)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 120,
                                height: 2,
                                color: const Color(0xFFD4AF37),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                cert.instructorName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0A192F),
                                ),
                              ),
                              Text(
                                'Lead Faculty & Course Director',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.5,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),

                          // Center Signature (Organizational Excellence)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 120,
                                height: 2,
                                color: const Color(0xFFD4AF37),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Donna Stroupe',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0A192F),
                                ),
                              ),
                              Text(
                                'Head of Organizational Excellence',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.5,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),

                          // Right QR Code
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                                  ],
                                ),
                                child: Image.network(
                                  cert.qrCodeUrl,
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 70,
                                    height: 70,
                                    color: const Color(0xFFF1F5F9),
                                    child: const Icon(Icons.qr_code_2, size: 40, color: Color(0xFF64748B)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              SelectableText(
                                cert.verificationId,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
                const SizedBox(height: 20),

                // Modal Actions
                LayoutBuilder(
                  builder: (context, actionConstraints) {
                    final isCompact = actionConstraints.maxWidth < 450;
                    final downloadBtn = AppButton(
                      label: 'Download / Print PDF',
                      icon: Icons.print,
                      variant: ButtonVariant.primary,
                      isFullWidth: isCompact,
                      onPressed: () => _handleDownloadPdf(cert),
                    );

                    final copyBtn = OutlinedButton.icon(
                      icon: const Icon(Icons.link, size: 18),
                      label: const Text('Copy Verification Link'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                      ),
                      onPressed: () {
                        final url = 'https://verify-certificate.edusphere-app.workers.dev/verify/${cert.verificationId}';
                        Clipboard.setData(ClipboardData(text: url));
                        Navigator.pop(ctx);
                        AppHelpers.showSnackBar(context, 'Verification link copied to clipboard!');
                      },
                    );

                    if (isCompact) {
                      return Column(
                        children: [
                          downloadBtn,
                          const SizedBox(height: 10),
                          SizedBox(width: double.infinity, child: copyBtn),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: downloadBtn),
                        const SizedBox(width: 12),
                        Expanded(child: copyBtn),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final isDesktop = AppHelpers.isDesktop(context);
    final enrolments = ref.watch(enrolmentProvider);
    final coursesAsync = ref.watch(allCoursesProvider);
    final courses = coursesAsync.maybeWhen(data: (c) => c, orElse: () => <CourseModel>[]);

    final userCertsAsync = ref.watch(userCertificatesStreamProvider(user?.id ?? ''));
    final firestoreCertificates = userCertsAsync.when(
      data: (certs) => certs,
      loading: () => <CertificateModel>[],
      error: (_, __) => <CertificateModel>[],
    );

    // Merge Firestore certificates with any completed enrollments
    final Map<String, CertificateModel> certsByCourseId = {};
    for (final cert in firestoreCertificates) {
      certsByCourseId[cert.courseId] = cert;
    }

    if (user != null && courses.isNotEmpty) {
      for (final enrol in enrolments) {
        if ((enrol.isCompleted || enrol.progress >= 1.0) && !certsByCourseId.containsKey(enrol.courseId)) {
          final matchingCourses = courses.where((c) => c.id == enrol.courseId).toList();
          if (matchingCourses.isNotEmpty) {
            final matchingCourse = matchingCourses.first;
            final cleanTag = enrol.courseId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
            final tagSub = cleanTag.length > 6 ? cleanTag.substring(0, 6) : cleanTag;
            final deterministicId = 'EDUS-${user.id.hashCode.abs().toString().padLeft(6, '0').substring(0, 6)}-$tagSub';

            certsByCourseId[enrol.courseId] = CertificateModel(
              id: deterministicId,
              userId: user.id,
              userName: user.name,
              courseId: enrol.courseId,
              courseTitle: matchingCourse.title,
              instructorName: matchingCourse.instructor.name,
              verificationId: deterministicId,
              qrCodeUrl: 'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${Uri.encodeComponent("https://verify-certificate.edusphere-app.workers.dev/verify/$deterministicId")}',
              pdfUrl: 'https://res.cloudinary.com/kl8rl0al/raw/upload/v1/certificates/$deterministicId.pdf',
              issuedAt: enrol.enrolledAt,
            );
          }
        }
      }
    }

    final certificates = certsByCourseId.values.toList();

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppSpacing.marginDesktop : AppSpacing.marginMobile,
        vertical: AppSpacing.lg,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Navigation Breadcrumb
              InkWell(
                onTap: () => context.go('/home'),
                borderRadius: AppSpacing.roundedMd,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 2.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back, size: 18, color: AppColors.secondary),
                      const SizedBox(width: 8),
                      Text(
                        'Back to Home',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Awards & Verified Certificates',
                          style: AppTypography.displayMedium.copyWith(
                            fontSize: isDesktop ? 32 : 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'View, verify, and share all your accredited certificates and earned badges.',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Public Verification Search Bar Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppSpacing.roundedLg,
                  border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_user, color: AppColors.secondary, size: 22),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Verify Any Certificate',
                            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enter any EduSphere verification ID (e.g. EDUS-849204-FLUTTER) to verify authenticity directly on our public ledger:',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact = constraints.maxWidth < 420;
                        if (isCompact) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: _verifyController,
                                decoration: InputDecoration(
                                  hintText: 'Enter Verification ID...',
                                  prefixIcon: const Icon(Icons.search, size: 20),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: AppSpacing.roundedMd,
                                    borderSide: const BorderSide(color: AppColors.outlineVariant),
                                  ),
                                ),
                                onSubmitted: _handleVerifyId,
                              ),
                              const SizedBox(height: 10),
                              AppButton(
                                label: _isVerifying ? 'Verifying...' : 'Verify Authenticity',
                                icon: Icons.check_circle_outline,
                                variant: ButtonVariant.secondary,
                                isFullWidth: true,
                                onPressed: _isVerifying ? null : () => _handleVerifyId(_verifyController.text),
                              ),
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _verifyController,
                                decoration: InputDecoration(
                                  hintText: 'Enter Verification ID...',
                                  prefixIcon: const Icon(Icons.search, size: 20),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: AppSpacing.roundedMd,
                                    borderSide: const BorderSide(color: AppColors.outlineVariant),
                                  ),
                                ),
                                onSubmitted: _handleVerifyId,
                              ),
                            ),
                            const SizedBox(width: 12),
                            AppButton(
                              label: _isVerifying ? 'Verifying...' : 'Verify',
                              icon: Icons.check_circle_outline,
                              variant: ButtonVariant.secondary,
                              size: ButtonSize.md,
                              onPressed: _isVerifying ? null : () => _handleVerifyId(_verifyController.text),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Badges Strip
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppSpacing.roundedLg,
                  border: Border.all(color: AppColors.surfaceContainerHigh),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Earned Badges', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800)),
                        Text(
                          '${user?.badges.length ?? 4} Total',
                          style: AppTypography.labelSmall.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: (user?.badges ?? ['Fast Learner', 'Quiz Master', 'Top Contributor', '7-Day Streak']).map((badge) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryFixedDim.withOpacity(0.2),
                            borderRadius: AppSpacing.roundedFull,
                            border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.workspace_premium, size: 18, color: AppColors.secondary),
                              const SizedBox(width: 6),
                              Text(
                                badge,
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Certificates Grid
              Text(
                'Verified Credentials (${certificates.length})',
                style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),

              if (certificates.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppSpacing.roundedLg,
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.workspace_premium_outlined, size: 56, color: AppColors.secondary.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      Text(
                        'No Issued Certificates Yet',
                        style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Complete any course curriculum and quizzes with 80%+ score to generate your verified cryptographic certificate with scannable QR verification.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossCount = constraints.maxWidth >= 800 ? 2 : 1;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: constraints.maxWidth >= 800
                            ? 1.15
                            : (constraints.maxWidth > 500 ? 1.05 : 0.85),
                      ),
                      itemCount: certificates.length,
                      itemBuilder: (context, index) {
                        final cert = certificates[index];
                        return InkWell(
                          onTap: () => _showCertificateDetailModal(cert),
                          borderRadius: AppSpacing.roundedLg,
                          child: CertificateCard(
                            certificate: cert,
                            onDownload: () => _handleDownloadPdf(cert),
                            onShare: () {
                              final url = 'https://verify-certificate.edusphere-app.workers.dev/verify/${cert.verificationId}';
                              Clipboard.setData(ClipboardData(text: url));
                              AppHelpers.showSnackBar(context, 'Verification link copied to clipboard!');
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
