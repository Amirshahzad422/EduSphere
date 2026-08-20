import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/certificate_model.dart';
import '../services/certificate_pdf_generator.dart';
import '../styles/colors.dart';
import '../styles/spacing.dart';
import '../utils/helpers.dart';

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
        borderRadius: AppSpacing.roundedLg,
        gradient: const LinearGradient(
          colors: [Color(0xFF030D1E), Color(0xFF002244), Color(0xFF003D7A), Color(0xFF030D1E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Top Bar: Gold Medal on Left + Script Title in Center
            Stack(
              alignment: Alignment.center,
              children: [
                // Top-Left Medal Ribbon
                Align(
                  alignment: Alignment.topLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 18,
                        height: 14,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF0F172A), Color(0xFFD4AF37), Color(0xFF0F172A)],
                          ),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(2)),
                        ),
                      ),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            center: Alignment(-0.3, -0.3),
                            colors: [Color(0xFFFFF5C0), Color(0xFFD4AF37), Color(0xFF8C6200)],
                          ),
                          border: Border.all(color: const Color(0xFFFDF6C7), width: 2),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.star, size: 16, color: Color(0xFF5A3C00)),
                        ),
                      ),
                    ],
                  ),
                ),

                // Center Title
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Certificate',
                      style: GoogleFonts.greatVibes(
                        fontSize: 34,
                        color: const Color(0xFF0A2540),
                        fontWeight: FontWeight.w600,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      'OF APPRECIATION & COMPLETION',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 8.5,
                        letterSpacing: 3.0,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF5A6A80),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              'This Certificate is Honorably Bestowed Upon',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                color: const Color(0xFF64748B),
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 4),

            // Recipient Name in Cursive Calligraphy
            Text(
              certificate.userName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.greatVibes(
                fontSize: 30,
                color: const Color(0xFF0A192F),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),

            // Gold Divider Flourish
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 1.2,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Color(0xFFD4AF37)],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.0),
                  child: Text(
                    '✦ ❖ ✦',
                    style: TextStyle(color: Color(0xFFD4AF37), fontSize: 9),
                  ),
                ),
                Container(
                  width: 50,
                  height: 1.2,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFD4AF37), Colors.transparent],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Commendation Intro
            Text(
              'In recognition of your outstanding dedication, integrity, and meaningful contributions throughout the masterclass curriculum of',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5,
                color: const Color(0xFF475569),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 3),

            // PROMINENT COURSE NAME
            Text(
              certificate.courseTitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0A192F),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),

            // Presented Date
            Text(
              CertificatePdfGenerator.formatPresentedDate(certificate.issuedAt),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const Spacer(),

            // Bottom Section: Signature on Left + Scannable QR Code on Right
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Signature Block Left (Instructor)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 100,
                        height: 1.5,
                        color: const Color(0xFFD4AF37),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        certificate.instructorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0A192F),
                        ),
                      ),
                      Text(
                        'Lead Faculty & Course Director',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 7.5,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Framed High-Contrast Scannable QR Code
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
                        ],
                      ),
                      child: AppHelpers.buildCachedImage(
                        imageUrl: certificate.qrCodeUrl,
                        width: 52,
                        height: 52,
                        fit: BoxFit.contain,
                        memCacheWidth: 150,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      certificate.verificationId,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 7,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Card Action Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 32,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.download, size: 14),
                      label: const Text('Download PDF', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () async {
                        try {
                          await CertificatePdfGenerator.downloadOrPrintPdf(certificate);
                        } catch (e) {
                          if (context.mounted) {
                            AppHelpers.showSnackBar(context, 'PDF generation: $e', isError: true);
                          }
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.share, size: 18, color: AppColors.secondary),
                    onPressed: onShare,
                    tooltip: 'Share Verification Link',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

