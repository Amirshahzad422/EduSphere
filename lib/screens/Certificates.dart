import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../models/certificate_model.dart';
import '../styles/colors.dart';
import '../styles/spacing.dart';
import '../styles/typography.dart';
import '../components/CertificateCard.dart';
import '../utils/helpers.dart';

class CertificatesScreen extends ConsumerWidget {
  const CertificatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final isDesktop = AppHelpers.isDesktop(context);

    final certificates = [
      CertificateModel(
        id: 'cert_001',
        userId: user?.id ?? 'user_demo_01',
        userName: user?.name ?? 'Alex Morgan',
        courseId: 'course_1',
        courseTitle: 'Complete Flutter & Firebase Masterclass 2026',
        instructorName: 'Alexandre Rivera',
        verificationId: 'EDUS-849204-FLUTTER',
        qrCodeUrl: 'https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=https://edusphere.io/verify/EDUS-849204-FLUTTER',
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
        qrCodeUrl: 'https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=https://edusphere.io/verify/EDUS-731902-DESIGN',
        issuedAt: DateTime.now().subtract(const Duration(days: 45)),
      ),
    ];

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
                'View and verify all your earned accredited certificates and skill badges.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
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
                    Text('Earned Badges', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800)),
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
                      return CertificateCard(
                        certificate: cert,
                        onDownload: () => AppHelpers.showSnackBar(context, 'Downloading Certificate PDF...'),
                        onShare: () => AppHelpers.showSnackBar(context, 'Verification link copied to clipboard!'),
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
