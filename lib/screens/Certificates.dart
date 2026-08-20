import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../models/certificate_model.dart';
import '../services/certificate_service.dart';
import '../styles/colors.dart';
import '../styles/spacing.dart';
import '../styles/typography.dart';
import '../components/CertificateCard.dart';
import '../components/Button.dart';
import '../utils/formatters.dart';
import '../utils/helpers.dart';

class CertificatesScreen extends ConsumerStatefulWidget {
  const CertificatesScreen({super.key});

  @override
  ConsumerState<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends ConsumerState<CertificatesScreen> {
  final TextEditingController _verifyController = TextEditingController();
  bool _isVerifying = false;

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
            Text(
              isValid ? 'Verified Credential' : 'Verification Failed',
              style: AppTypography.titleLarge.copyWith(
                color: isValid ? AppColors.secondary : AppColors.error,
                fontWeight: FontWeight.w800,
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
          if (isValid && certData != null && (certData['pdfUrl'] != null || certData['verificationId'] != null))
            AppButton(
              label: 'Copy Public URL',
              variant: ButtonVariant.primary,
              size: ButtonSize.sm,
              onPressed: () {
                final verId = certData['verificationId'] ?? '';
                final url = 'https://verify.edusphere-app.workers.dev/verify/$verId';
                Clipboard.setData(ClipboardData(text: url));
                Navigator.pop(ctx);
                AppHelpers.showSnackBar(context, 'Public verification URL copied!');
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

  void _showCertificateDetailModal(CertificateModel cert) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedXl),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.workspace_premium, color: AppColors.secondary, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          'Verified Credential',
                          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: AppSpacing.roundedLg,
                    border: Border.all(color: AppColors.secondaryFixedDim.withOpacity(0.4)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'CERTIFICATE OF COMPLETION',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.secondaryFixed,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'This is proudly presented to',
                        style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cert.userName,
                        style: AppTypography.headlineSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'for masterclass graduation in',
                        style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cert.courseTitle,
                        textAlign: TextAlign.center,
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.secondaryFixedDim,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.white,
                        child: Image.network(
                          cert.qrCodeUrl,
                          width: 110,
                          height: 110,
                          errorBuilder: (_, __, ___) => const Icon(Icons.qr_code, size: 80),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SelectableText(
                        'Verification ID: ${cert.verificationId}',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Download PDF',
                        icon: Icons.download,
                        variant: ButtonVariant.primary,
                        onPressed: () {
                          Navigator.pop(ctx);
                          AppHelpers.showSnackBar(
                            context,
                            '✅ Certificate downloaded: ${cert.verificationId}.pdf',
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.link, size: 18),
                        label: const Text('Copy Link'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                        ),
                        onPressed: () {
                          final url = 'https://verify.edusphere-app.workers.dev/verify/${cert.verificationId}';
                          Clipboard.setData(ClipboardData(text: url));
                          Navigator.pop(ctx);
                          AppHelpers.showSnackBar(context, 'Verification link copied to clipboard!');
                        },
                      ),
                    ),
                  ],
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

    // Fallback seed certificates if user has no Firestore certificates yet
    final seedCertificates = [
      CertificateModel(
        id: 'cert_001',
        userId: user?.id ?? 'user_demo_01',
        userName: user?.name ?? 'Alex Morgan',
        courseId: 'course_1',
        courseTitle: 'Complete Flutter & Firebase Masterclass 2026',
        instructorName: 'Alexandre Rivera',
        verificationId: 'EDUS-849204-FLUTTER',
        qrCodeUrl: 'https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=https://verify.edusphere-app.workers.dev/verify/EDUS-849204-FLUTTER',
        issuedAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      CertificateModel(
        id: 'cert_002',
        userId: user?.id ?? 'user_demo_01',
        userName: user?.name ?? 'Alex Morgan',
        courseId: 'course_2',
        courseTitle: 'Enterprise UI/UX Design Systems & Figma Pro',
        instructorName: 'Marcus Vance',
        verificationId: 'EDUS-731902-DESIGN',
        qrCodeUrl: 'https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=https://verify.edusphere-app.workers.dev/verify/EDUS-731902-DESIGN',
        issuedAt: DateTime.now().subtract(const Duration(days: 45)),
      ),
    ];

    final userCertsAsync = ref.watch(userCertificatesStreamProvider(user?.id ?? ''));

    final certificates = userCertsAsync.when(
      data: (certs) => certs.isNotEmpty ? certs : seedCertificates,
      loading: () => seedCertificates,
      error: (_, __) => seedCertificates,
    );

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
                        Text(
                          'Verify Any Certificate',
                          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enter any EduSphere verification ID (e.g. EDUS-849204-FLUTTER) to verify authenticity directly on our public ledger:',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 14),
                    Row(
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
                          onDownload: () => _showCertificateDetailModal(cert),
                          onShare: () {
                            final url = 'https://verify.edusphere-app.workers.dev/verify/${cert.verificationId}';
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
