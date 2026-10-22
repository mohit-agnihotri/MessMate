import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../models/app_models.dart';
import '../theme/owner_inspired_theme.dart';

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
      'https://mezzoapp.in/mess?id=${mess.messId}&code=${mess.messCode}';

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
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
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

          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Counter QR standee',
                      style: GoogleFonts.newsreader(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: OwnerColors.walnutDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Place on your mess counter for walk-in customers',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: OwnerColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
                color: OwnerColors.walnutDark,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Standee Preview Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: OwnerColors.borderSubtle,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Mezzo Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF8EE),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: OwnerColors.amberGlow),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        size: 14,
                        color: Color(0xFFC26E00),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'MEZZO SMART COUNTER',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: const Color(0xFFC26E00),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Mess Name
                Text(
                  mess.name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.newsreader(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: OwnerColors.walnutDark,
                  ),
                ),
                const SizedBox(height: 4),

                // Rating & Code
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      mess.rating > 0
                          ? mess.rating.toStringAsFixed(1)
                          : '4.8 (New)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: OwnerColors.walnutDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('•',
                        style: TextStyle(color: OwnerColors.textSecondary)),
                    const SizedBox(width: 8),
                    Text(
                      'Code: ${mess.messCode}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: OwnerColors.sageGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Crisp QR Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE8E4DC), width: 1.5),
                  ),
                  child: QrImageView(
                    data: _qrPayload,
                    version: QrVersions.auto,
                    size: 190,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF1E1711),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF1E1711),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Instruction
                Text(
                  'Scan with any Camera, Google Lens or Mezzo App',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: OwnerColors.walnutDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'To view live menu, weekly schedule & join mess directly',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: OwnerColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              // Print Standee Button
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => _printStandeePdf(context),
                    icon: const Icon(Icons.print_rounded, size: 18),
                    label: Text(
                      'Print standee PDF',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: OwnerColors.amberGlow,
                      foregroundColor: OwnerColors.walnutDark,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Copy Link Button
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _qrPayload));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Mess join link copied to clipboard!'),
                        backgroundColor: OwnerColors.walnutDark,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: Text(
                    'Copy link',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: OwnerColors.walnutDark,
                    side: const BorderSide(color: OwnerColors.borderSubtle),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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

  Future<void> _printStandeePdf(BuildContext context) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) {
          return pw.Center(
            child: pw.Container(
              width: 360,
              padding: const pw.EdgeInsets.all(28),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey700, width: 2),
                borderRadius: pw.BorderRadius.circular(18),
              ),
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'WELCOME TO',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey700,
                      letterSpacing: 2,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    mess.name.toUpperCase(),
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'Mess Code: ${mess.messCode}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey800,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: _qrPayload,
                    width: 200,
                    height: 200,
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'SCAN TO VIEW TODAY\'S LIVE MENU & PLANS',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                      letterSpacing: 1,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Point phone camera or Google Lens to view dishes & request admission.',
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 18),
                  pw.Divider(color: PdfColors.grey400),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'Powered by Mezzo • Instant Digital Mess Admission',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${mess.name}_Counter_Standee',
    );
  }
}
