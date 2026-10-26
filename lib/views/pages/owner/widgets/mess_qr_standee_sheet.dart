import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../models/app_models.dart';

class MessQrStandeeSheet extends StatelessWidget {
  final MessModel mess;

  const MessQrStandeeSheet({super.key, required this.mess});

  static Future<void> show(BuildContext context, MessModel mess) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MessQrStandeeSheet(mess: mess),
    );
  }

  String get _qrPayload =>
      'https://mezzo-69cab.web.app/?id=${mess.messId}&code=${mess.messCode}';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFBF8F2),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD6CEC5),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header (Screenshot 1)
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Counter QR standee',
                  style: GoogleFonts.newsreader(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF231A14),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Place it on your counter so walk-ins can scan for quick info.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF7A7971),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Standee Preview Card (Screenshot 1)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0x142D231C),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Top Badge: MEZZO SMART COUNTER
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCECD9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'MEZZO SMART COUNTER',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: const Color(0xFFBA6311),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Mess Name
                Text(
                  mess.name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.newsreader(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF231A14),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 5),

                // Subtitle: ★ 4.8 (New) · Code 404646
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 15,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      mess.rating > 0
                          ? mess.rating.toStringAsFixed(1)
                          : '4.8 (New)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF55504A),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('·',
                        style: TextStyle(
                            color: Color(0xFF8C8881),
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    Text(
                      'Code ',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF7A7971),
                      ),
                    ),
                    Text(
                      mess.messCode,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF231A14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // QR Code Container
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: _qrPayload,
                    version: QrVersions.auto,
                    size: 195,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF231A14),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF231A14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Caption
                Text(
                  'Scan with any camera, Google Lens or Mezzo',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF332B25),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Primary Orange Button: Print standee PDF (Screenshot 1)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => _printStandeePdf(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF58410),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              child: Text(
                'Print standee PDF',
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Secondary Action Buttons: Copy link, WhatsApp, PNG (Screenshot 1)
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _qrPayload));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Link copied to clipboard!'),
                          backgroundColor: const Color(0xFF2B2019),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE2EBE0),
                      foregroundColor: const Color(0xFF2B3B2C),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: Text(
                      'Copy link',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2B3B2C),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => _shareToWhatsApp(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE2EBE0),
                      foregroundColor: const Color(0xFF2B3B2C),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: Text(
                      'WhatsApp',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2B3B2C),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => _shareQrAsPng(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE2EBE0),
                      foregroundColor: const Color(0xFF2B3B2C),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: Text(
                      'PNG',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2B3B2C),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _shareToWhatsApp(BuildContext context) async {
    final text =
        'Scan this QR code to view today\'s live menu, weekly plans and admission details for ${mess.name}:\n$_qrPayload\nMess Code: ${mess.messCode}';
    final whatsappUrl = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(text)}');
    final webUrl = Uri.parse('https://api.whatsapp.com/send?text=${Uri.encodeComponent(text)}');

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl);
      } else {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('WhatsApp not found. Link copied to clipboard!'),
            backgroundColor: const Color(0xFF2B2019),
          ),
        );
      }
    }
  }

  Future<void> _shareQrAsPng(BuildContext context) async {
    try {
      final doc = await _buildStandeePdfDocument();
      final pdfBytes = await doc.save();
      final raster = await Printing.raster(pdfBytes, pages: [0], dpi: 200).first;
      final pngBytes = await raster.toPng();

      await Printing.sharePdf(
        bytes: pngBytes,
        filename: '${mess.name.replaceAll(' ', '_')}_Counter_Standee.png',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PNG: $e'),
            backgroundColor: const Color(0xFFB93822),
          ),
        );
      }
    }
  }

  Future<pw.Document> _buildStandeePdfDocument() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context ctx) {
          final isPureVeg = mess.foodType == 'pure_veg';
          final ratingText = mess.rating > 0
              ? mess.rating.toStringAsFixed(1)
              : '4.8';

          return pw.Container(
            color: PdfColor.fromInt(0xFFFAF7F2),
            child: pw.Column(
              children: [
                // Top Header (Dark Walnut - Screenshot 5)
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(vertical: 28),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFF2B2019),
                  ),
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 44,
                        height: 44,
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromInt(0xFF3B2E24),
                          borderRadius: pw.BorderRadius.circular(12),
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            '♨',
                            style: pw.TextStyle(
                              fontSize: 22,
                              color: PdfColor.fromInt(0xFFF4B34C),
                            ),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Mezzo',
                        style: pw.TextStyle(
                          fontSize: 26,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(0xFFFFF4E4),
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 24),

                // SCAN FOR TODAY'S MENU (Screenshot 5)
                pw.Text(
                  'SCAN FOR TODAY\'S MENU',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 2,
                    color: PdfColor.fromInt(0xFF4A684C),
                  ),
                ),
                pw.SizedBox(height: 8),

                // Mess Name
                pw.Text(
                  mess.name,
                  style: pw.TextStyle(
                    fontSize: 32,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF231A14),
                  ),
                ),
                pw.SizedBox(height: 8),

                // Pills: [Pure veg] [★ 4.8]
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 5,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFFE2EBE0),
                        borderRadius: pw.BorderRadius.circular(16),
                      ),
                      child: pw.Text(
                        isPureVeg ? 'Pure veg' : 'Veg & Non-Veg',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(0xFF2B3B2C),
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 5,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFFE2EBE0),
                        borderRadius: pw.BorderRadius.circular(16),
                      ),
                      child: pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Text(
                            '★ ',
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: PdfColor.fromInt(0xFFBA6311),
                            ),
                          ),
                          pw.Text(
                            ratingText,
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromInt(0xFF2B3B2C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 24),

                // Crisp QR Box (Screenshot 5)
                pw.Container(
                  padding: const pw.EdgeInsets.all(18),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(20),
                    boxShadow: const [
                      pw.BoxShadow(
                        color: PdfColors.grey300,
                        blurRadius: 10,
                        offset: PdfPoint(0, 4),
                      ),
                    ],
                  ),
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: _qrPayload,
                    width: 220,
                    height: 220,
                    color: PdfColor.fromInt(0xFF231A14),
                  ),
                ),

                pw.SizedBox(height: 18),

                // Caption
                pw.Text(
                  'Scan with any camera, Google Lens or Mezzo',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF231A14),
                  ),
                ),
                pw.SizedBox(height: 12),

                // Feature Pills: [Live menu] [Weekly schedule] [Join mess]
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    _buildPdfFeaturePill('Live menu'),
                    pw.SizedBox(width: 8),
                    _buildPdfFeaturePill('Weekly schedule'),
                    pw.SizedBox(width: 8),
                    _buildPdfFeaturePill('Join mess'),
                  ],
                ),

                pw.SizedBox(height: 16),

                // MESS CODE · 404646
                pw.Text(
                  'MESS CODE · ${mess.messCode}',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.5,
                    color: PdfColor.fromInt(0xFF6B6862),
                  ),
                ),

                pw.Spacer(),

                // Decorative wave banner at bottom (Screenshot 5)
                pw.Container(
                  width: double.infinity,
                  height: 48,
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFF4A684C),
                    borderRadius: const pw.BorderRadius.vertical(
                      top: pw.Radius.circular(28),
                    ),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'Powered by Mezzo • Instant Digital Mess Admission',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColor.fromInt(0xFFE2EBE0),
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildPdfFeaturePill(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFE2EBE0),
        borderRadius: pw.BorderRadius.circular(14),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 9.5,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromInt(0xFF2B3B2C),
        ),
      ),
    );
  }

  Future<void> _printStandeePdf(BuildContext context) async {
    final pdf = await _buildStandeePdfDocument();
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${mess.name}_Counter_Standee',
    );
  }
}
