import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/certificate_model.dart';

class CertificatePdfGenerator {
  CertificatePdfGenerator._();

  static String getOrdinal(int day) {
    if (day >= 11 && day <= 13) return '${day}th';
    switch (day % 10) {
      case 1:
        return '${day}st';
      case 2:
        return '${day}nd';
      case 3:
        return '${day}rd';
      default:
        return '${day}th';
    }
  }

  static String formatPresentedDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final dayStr = getOrdinal(date.day);
    final monthStr = months[date.month - 1];
    return 'Presented on this $dayStr day of $monthStr, ${date.year}';
  }

  /// Generates the high-resolution landscape certificate PDF document matching the user's design.
  static Future<pw.Document> generatePdfDocument(CertificateModel cert) async {
    final pdf = pw.Document(
      title: 'Certificate - ${cert.verificationId}',
      author: 'EduSphere Academic Council',
    );

    // Load stylish fonts for the PDF
    final titleFont = await PdfGoogleFonts.greatVibesRegular();
    final bodyFont = await PdfGoogleFonts.plusJakartaSansRegular();
    final boldFont = await PdfGoogleFonts.plusJakartaSansBold();

    final presentedDateText = formatPresentedDate(cert.issuedAt);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [
                  PdfColor.fromInt(0xFF030D1E),
                  PdfColor.fromInt(0xFF002244),
                  PdfColor.fromInt(0xFF003873),
                  PdfColor.fromInt(0xFF030D1E),
                ],
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
              ),
            ),
            padding: const pw.EdgeInsets.all(22),
            child: pw.Container(
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(16),
                border: pw.Border.all(color: const PdfColor.fromInt(0xFFCBD5E1), width: 1.5),
              ),
              padding: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 24),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // Top Row: Medal on left + Certificate Title in Center
                  pw.Stack(
                    alignment: pw.Alignment.center,
                    children: [
                      // Medal Ribbon on Top Left
                      pw.Align(
                        alignment: pw.Alignment.topLeft,
                        child: pw.Column(
                          mainAxisSize: pw.MainAxisSize.min,
                          children: [
                            pw.Container(
                              width: 22,
                              height: 16,
                              decoration: const pw.BoxDecoration(
                                color: PdfColor.fromInt(0xFF0F172A),
                                borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(3)),
                              ),
                            ),
                            pw.Container(
                              width: 44,
                              height: 44,
                              decoration: pw.BoxDecoration(
                                shape: pw.BoxShape.circle,
                                color: const PdfColor.fromInt(0xFFD4AF37),
                                border: pw.Border.all(color: const PdfColor.fromInt(0xFFFFF5C0), width: 2),
                              ),
                              child: pw.Center(
                                child: pw.Text(
                                  '*',
                                  style: pw.TextStyle(
                                    fontSize: 26,
                                    color: const PdfColor.fromInt(0xFF5A3C00),
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Center Header
                      pw.Column(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Text(
                            'Certificate',
                            style: pw.TextStyle(
                              font: titleFont,
                              fontSize: 48,
                              color: const PdfColor.fromInt(0xFF0A2540),
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'OF COMPLETION & APPRECIATION',
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 10,
                              letterSpacing: 3.5,
                              color: const PdfColor.fromInt(0xFF5A6A80),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 12),

                  // Subheading
                  pw.Text(
                    'This Certificate is Honorably Bestowed Upon',
                    style: pw.TextStyle(
                      font: bodyFont,
                      fontSize: 12,
                      color: const PdfColor.fromInt(0xFF64748B),
                    ),
                  ),
                  pw.SizedBox(height: 4),

                  // Recipient Name
                  pw.Text(
                    cert.userName,
                    style: pw.TextStyle(
                      font: titleFont,
                      fontSize: 44,
                      color: const PdfColor.fromInt(0xFF0A192F),
                    ),
                  ),
                  pw.SizedBox(height: 6),

                  // Gold Divider Line with Emblem
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Container(width: 80, height: 1.5, color: const PdfColor.fromInt(0xFFD4AF37)),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10),
                        child: pw.Text(
                          '✦ ❖ ✦',
                          style: const pw.TextStyle(
                            fontSize: 11,
                            color: PdfColor.fromInt(0xFFD4AF37),
                          ),
                        ),
                      ),
                      pw.Container(width: 80, height: 1.5, color: const PdfColor.fromInt(0xFFD4AF37)),
                    ],
                  ),
                  pw.SizedBox(height: 10),

                  // Commendation text
                  pw.Text(
                    'In recognition of your outstanding dedication, integrity, and meaningful contributions throughout the masterclass curriculum of',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: bodyFont,
                      fontSize: 11.5,
                      color: const PdfColor.fromInt(0xFF334155),
                      lineSpacing: 1.3,
                    ),
                  ),
                  pw.SizedBox(height: 4),

                  // PROMINENT COURSE NAME
                  pw.Text(
                    cert.courseTitle,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 16,
                      color: const PdfColor.fromInt(0xFF0A192F),
                    ),
                  ),
                  pw.SizedBox(height: 8),

                  // Presented Date
                  pw.Text(
                    presentedDateText,
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 10.5,
                      color: const PdfColor.fromInt(0xFF0F172A),
                    ),
                  ),

                  pw.Spacer(),

                  // Bottom Signatures & QR Code
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      // Instructor Signature
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Container(width: 140, height: 2, color: const PdfColor.fromInt(0xFFD4AF37)),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            cert.instructorName,
                            style: pw.TextStyle(font: boldFont, fontSize: 11, color: const PdfColor.fromInt(0xFF0A192F)),
                          ),
                          pw.Text(
                            'Lead Faculty & Course Director',
                            style: pw.TextStyle(font: bodyFont, fontSize: 8.5, color: const PdfColor.fromInt(0xFF64748B)),
                          ),
                        ],
                      ),

                      // Academic Excellence Signature
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Container(width: 140, height: 2, color: const PdfColor.fromInt(0xFFD4AF37)),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Donna Stroupe',
                            style: pw.TextStyle(font: boldFont, fontSize: 11, color: const PdfColor.fromInt(0xFF0A192F)),
                          ),
                          pw.Text(
                            'Head of Academic Excellence',
                            style: pw.TextStyle(font: bodyFont, fontSize: 8.5, color: const PdfColor.fromInt(0xFF64748B)),
                          ),
                        ],
                      ),

                      // Framed Scannable QR Code
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.all(4),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.white,
                              borderRadius: pw.BorderRadius.circular(6),
                              border: pw.Border.all(color: const PdfColor.fromInt(0xFFCBD5E1)),
                            ),
                            child: pw.BarcodeWidget(
                              data: 'https://verify-certificate.edusphere-app.workers.dev/verify/${cert.verificationId}',
                              barcode: pw.Barcode.qrCode(),
                              width: 62,
                              height: 62,
                            ),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            cert.verificationId,
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 7.5,
                              color: const PdfColor.fromInt(0xFF00696E),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    return pdf;
  }

  /// Downloads, prints, or shares the PDF directly on the client device.
  static Future<void> downloadOrPrintPdf(CertificateModel cert) async {
    final doc = await generatePdfDocument(cert);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'EduSphere_Certificate_${cert.verificationId}.pdf',
    );
  }
}
