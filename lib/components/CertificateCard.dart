import 'package:flutter/material.dart';
import '../models/certificate_model.dart';
import '../styles/colors.dart';
import '../styles/spacing.dart';
import '../styles/typography.dart';
import '../utils/formatters.dart';

class CertificateCard extends StatelessWidget {
  final CertificateModel certificate;
  final VoidCallback? onDownload;
  final VoidCallback? onShare;

  const CertificateCard({
    super.key,
    required this.certificate,
    this.onDownload,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: AppColors.surfaceContainerHigh),
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
          // Decorative Certificate Header Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: AppSpacing.roundedMd,
                  ),
                  child: const Icon(Icons.workspace_premium, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CERTIFICATE OF COMPLETION',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.secondaryFixed,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'EduSphere Verified Credential',
                        style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  certificate.courseTitle,
                  style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Issued to ${certificate.userName}',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.surfaceContainerHigh),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Verification ID', style: AppTypography.labelSmall),
                          const SizedBox(height: 2),
                          Text(
                            certificate.verificationId,
                            style: AppTypography.labelMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text('Issue Date', style: AppTypography.labelSmall),
                          const SizedBox(height: 2),
                          Text(
                            AppFormatters.formatDate(certificate.issuedAt),
                            style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    // QR Code
                    Image.network(
                      certificate.qrCodeUrl,
                      width: 70,
                      height: 70,
                      errorBuilder: (_, __, ___) => Container(
                        width: 70,
                        height: 70,
                        color: AppColors.surfaceContainerLow,
                        child: const Icon(Icons.qr_code, size: 40, color: AppColors.outline),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text('Download PDF'),
                        onPressed: onDownload,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.share, color: AppColors.secondary),
                      onPressed: onShare,
                      tooltip: 'Share Credential',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
