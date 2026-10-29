import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/app_models.dart';

class PdfService {
  static const List<String> _monthNames = [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<String> _shortMonths = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static Future<void> generateAndDownloadBill(
    BillModel bill, {
    StudentModel? student,
    MessModel? mess,
    MealPlanModel? plan,
  }) async {
    // 1. Load fonts safely with fallback
    pw.Font? regularFont;
    pw.Font? mediumFont;
    pw.Font? boldFont;
    pw.Font? displayFont;
    bool fontSupportsRupee = false;

    try {
      regularFont = await PdfGoogleFonts.interRegular();
      mediumFont = await PdfGoogleFonts.interMedium();
      boldFont = await PdfGoogleFonts.interBold();
      displayFont = await PdfGoogleFonts.playfairDisplayBold();
      fontSupportsRupee = true;
    } catch (_) {
      regularFont = pw.Font.helvetica();
      mediumFont = pw.Font.helvetica();
      boldFont = pw.Font.helveticaBold();
      displayFont = pw.Font.helveticaBold();
      fontSupportsRupee = false;
    }

    // 2. Load brand image and meal thali thumbnail
    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/images/mezzo_logo.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {}

    pw.MemoryImage? mealImage;
    try {
      final mealBytes = await rootBundle.load('assets/images/onboard_smart_meals.jpg');
      mealImage = pw.MemoryImage(mealBytes.buffer.asUint8List());
    } catch (_) {}

    final pdf = pw.Document();

    // Currency helper
    String formatCurrency(num amount, {bool showSign = false}) {
      final prefix = fontSupportsRupee ? '₹ ' : 'Rs ';
      final absVal = amount.abs().toInt();
      if (showSign) {
        if (amount > 0) return '+$prefix$absVal';
        if (amount < 0) return '-$prefix$absVal';
      }
      return '$prefix$absVal';
    }

    // Palette matching screenshot
    final bgColor = PdfColor.fromInt(0xFFFAF8F5);
    final cardBgColor = PdfColor.fromInt(0xFFFFFFFF);
    final softBeige = PdfColor.fromInt(0xFFF9F6F0);
    final borderColor = PdfColor.fromInt(0xFFE8E2D9);
    final forestGreen = PdfColor.fromInt(0xFF1E3A2B);
    final forestGreenHeader = PdfColor.fromInt(0xFF243E30);
    final terracotta = PdfColor.fromInt(0xFF7B4322);
    final charcoal = PdfColor.fromInt(0xFF1C2E24);
    final mutedGrey = PdfColor.fromInt(0xFF6B7280);
    final sageBg = PdfColor.fromInt(0xFFE4EFE4);
    final sageBorder = PdfColor.fromInt(0xFFC4DCC4);
    final sageGreenText = PdfColor.fromInt(0xFF1A5328);
    final deductionGreen = PdfColor.fromInt(0xFF2E7D32);
    final amberOrange = PdfColor.fromInt(0xFFC25E00);
    final noteBg = PdfColor.fromInt(0xFFFFF9EE);
    final noteBorder = PdfColor.fromInt(0xFFF0E6D2);

    final monthName = (bill.month >= 1 && bill.month <= 12) ? _monthNames[bill.month] : 'Month';
    final monthShort = (bill.month >= 1 && bill.month <= 12) ? _shortMonths[bill.month] : 'M';
    final daysInMonth = DateTime(bill.year, bill.month + 1, 0).day;
    final billingPeriod = '01 $monthShort ${bill.year} - $daysInMonth $monthShort ${bill.year}';

    // Format Bill ID
    final rawBillId = bill.billId.isNotEmpty ? bill.billId : 'BILL';
    final displayBillId = rawBillId.length > 14
        ? 'MZ-BILL-${bill.year}-${bill.month.toString().padLeft(2, '0')}-${rawBillId.substring(0, 4).toUpperCase()}'
        : (rawBillId.startsWith('MZ') ? rawBillId : 'MZ-$rawBillId');

    final now = DateTime.now();
    final generatedDate = '${now.day} ${_shortMonths[now.month]} ${now.year}';

    // Student & Mess Details
    final studentName = student?.name.isNotEmpty == true ? student!.name : 'Student Diner';
    final studentInitial = studentName.trim().isNotEmpty ? studentName.trim()[0].toUpperCase() : 'S';
    final studentDisplayId = (student != null && student.studentId.isNotEmpty)
        ? (student.studentId.length > 10 ? 'MZ-ST-${student.studentId.substring(0, 4).toUpperCase()}' : student.studentId)
        : (bill.studentId.isNotEmpty ? 'MZ-ST-${bill.studentId.substring(0, 4).toUpperCase()}' : 'MZ-ST-1001');

    final messName = mess?.name.isNotEmpty == true ? mess!.name : 'Campus Mess';
    final messLocation = mess?.messCode.isNotEmpty == true ? 'Code: #${mess!.messCode}' : 'Hostel Campus';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        theme: pw.ThemeData.withFont(
          base: regularFont,
          bold: boldFont,
        ),
        build: (pw.Context context) {
          return pw.Container(
            color: bgColor,
            padding: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 26),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // ── 1. Brand & Header Bar ────────────────────────────
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Mezzo Brand
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            if (logoImage != null)
                              pw.Container(
                                width: 28,
                                height: 28,
                                margin: const pw.EdgeInsets.only(right: 8),
                                child: pw.Image(logoImage),
                              )
                            else
                              pw.Container(
                                width: 26,
                                height: 26,
                                margin: const pw.EdgeInsets.only(right: 8),
                                decoration: pw.BoxDecoration(
                                  shape: pw.BoxShape.circle,
                                  color: forestGreen,
                                ),
                                child: pw.Center(
                                  child: pw.Text(
                                    'M',
                                    style: pw.TextStyle(
                                      color: PdfColors.white,
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'Mezzo',
                                  style: pw.TextStyle(
                                    fontSize: 20,
                                    fontWeight: pw.FontWeight.bold,
                                    color: charcoal,
                                    font: displayFont ?? boldFont,
                                  ),
                                ),
                                pw.Text(
                                  'GOOD FOOD • BETTER DAYS',
                                  style: pw.TextStyle(
                                    fontSize: 6.5,
                                    letterSpacing: 1.2,
                                    color: mutedGrey,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 12),
                        pw.Text(
                          'Mess Monthly Bill',
                          style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            color: forestGreen,
                            font: displayFont ?? boldFont,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          '$monthName ${bill.year}',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: terracotta,
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        // Billing Period Pill
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromInt(0xFFF0EBE4),
                            borderRadius: pw.BorderRadius.circular(6),
                            border: pw.Border.all(color: borderColor, width: 0.8),
                          ),
                          child: pw.Row(
                            mainAxisSize: pw.MainAxisSize.min,
                            children: [
                              pw.Container(
                                width: 6,
                                height: 6,
                                decoration: pw.BoxDecoration(
                                  shape: pw.BoxShape.circle,
                                  color: terracotta,
                                ),
                              ),
                              pw.SizedBox(width: 5),
                              pw.Text(
                                'Billing Period: $billingPeriod',
                                style: pw.TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: pw.FontWeight.bold,
                                  color: charcoal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Right Side: Graphic Thumbnail & Tag Pill
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        // Tag Pill
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromInt(0xFFF3EEE6),
                            borderRadius: pw.BorderRadius.circular(12),
                            border: pw.Border.all(color: borderColor, width: 0.8),
                          ),
                          child: pw.Text(
                            'Simple Meals, Happier Days',
                            style: pw.TextStyle(
                              fontSize: 8.5,
                              fontWeight: pw.FontWeight.bold,
                              color: forestGreen,
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        if (mealImage != null)
                          pw.Container(
                            width: 68,
                            height: 68,
                            decoration: pw.BoxDecoration(
                              shape: pw.BoxShape.circle,
                              border: pw.Border.all(color: borderColor, width: 2),
                            ),
                            child: pw.ClipOval(
                              child: pw.Image(mealImage, fit: pw.BoxFit.cover),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 14),

                // ── 2. Student & Mess Info Card ──────────────────────
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: pw.BoxDecoration(
                    color: softBeige,
                    borderRadius: pw.BorderRadius.circular(10),
                    border: pw.Border.all(color: borderColor, width: 0.9),
                  ),
                  child: pw.Row(
                    children: [
                      // Student Column
                      pw.Container(
                        width: 32,
                        height: 32,
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          color: forestGreen,
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            studentInitial,
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Student Name',
                              style: pw.TextStyle(fontSize: 7.5, color: mutedGrey),
                            ),
                            pw.Text(
                              studentName,
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                color: charcoal,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'Student ID: $studentDisplayId',
                              style: pw.TextStyle(fontSize: 7.5, color: mutedGrey),
                            ),
                          ],
                        ),
                      ),
                      // Subtle Divider
                      pw.Container(
                        width: 1,
                        height: 36,
                        color: borderColor,
                        margin: const pw.EdgeInsets.symmetric(horizontal: 12),
                      ),
                      // Mess Column
                      pw.Container(
                        width: 32,
                        height: 32,
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          color: PdfColor.fromInt(0xFFF0E5D8),
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            '⌂',
                            style: pw.TextStyle(
                              color: terracotta,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Mess Name',
                              style: pw.TextStyle(fontSize: 7.5, color: mutedGrey),
                            ),
                            pw.Text(
                              messName,
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                color: charcoal,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'Location: $messLocation',
                              style: pw.TextStyle(fontSize: 7.5, color: mutedGrey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 12),

                // ── 3. Bill Summary Card ─────────────────────────────
                pw.Container(
                  decoration: pw.BoxDecoration(
                    color: cardBgColor,
                    borderRadius: pw.BorderRadius.circular(10),
                    border: pw.Border.all(color: borderColor, width: 0.9),
                  ),
                  child: pw.Column(
                    children: [
                      // Header Band
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: pw.BoxDecoration(
                          color: forestGreenHeader,
                          borderRadius: const pw.BorderRadius.only(
                            topLeft: pw.Radius.circular(9),
                            topRight: pw.Radius.circular(9),
                          ),
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'Bill Summary',
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 11.5,
                              ),
                            ),
                            pw.Text(
                              'Bill ID: $displayBillId   •   Generated: $generatedDate',
                              style: pw.TextStyle(
                                color: PdfColor.fromInt(0xFFC0D8C8),
                                fontSize: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Summary Rows
                      pw.Padding(
                        padding: const pw.EdgeInsets.fromLTRB(14, 10, 14, 6),
                        child: pw.Column(
                          children: [
                            _buildSummaryItem(
                              label: 'Basic Monthly Fee',
                              subtitle: plan?.name ?? '(Full month plan)',
                              value: formatCurrency(bill.baseFee),
                              valueColor: charcoal,
                              isBold: true,
                            ),
                            pw.Divider(color: borderColor, thickness: 0.5, height: 10),
                            _buildSummaryItem(
                              label: 'Total Deductions',
                              subtitle: '(Prorated discount, skips, etc.)',
                              value: '- ${formatCurrency(bill.totalDeductions)}',
                              valueColor: deductionGreen,
                              isBold: true,
                            ),
                            pw.Divider(color: borderColor, thickness: 0.5, height: 10),
                            _buildSummaryItem(
                              label: 'Guest Add-ons',
                              subtitle: '(Extra meals for guests)',
                              value: formatCurrency(bill.guestAddons),
                              valueColor: charcoal,
                              isBold: false,
                            ),
                            pw.Divider(color: borderColor, thickness: 0.5, height: 10),
                            _buildSummaryItem(
                              label: 'Extra Fees',
                              subtitle: '(Additional charges)',
                              value: bill.extraFeesAddon > 0
                                  ? '+ ${formatCurrency(bill.extraFeesAddon)}'
                                  : formatCurrency(0),
                              valueColor: bill.extraFeesAddon > 0 ? amberOrange : charcoal,
                              isBold: bill.extraFeesAddon > 0,
                            ),
                            pw.SizedBox(height: 8),

                            // Highlighted Final Payable Container
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                              decoration: pw.BoxDecoration(
                                color: sageBg,
                                borderRadius: pw.BorderRadius.circular(8),
                                border: pw.Border.all(color: sageBorder, width: 1),
                              ),
                              child: pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: pw.CrossAxisAlignment.center,
                                children: [
                                  pw.Column(
                                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text(
                                        'Final Payable Amount',
                                        style: pw.TextStyle(
                                          fontSize: 11,
                                          fontWeight: pw.FontWeight.bold,
                                          color: charcoal,
                                        ),
                                      ),
                                      pw.SizedBox(height: 1),
                                      pw.Text(
                                        '(Amount to be paid for $monthName ${bill.year})',
                                        style: pw.TextStyle(
                                          fontSize: 7.5,
                                          color: PdfColor.fromInt(0xFF4A6B53),
                                        ),
                                      ),
                                    ],
                                  ),
                                  pw.Text(
                                    formatCurrency(bill.finalPayable),
                                    style: pw.TextStyle(
                                      fontSize: 18,
                                      fontWeight: pw.FontWeight.bold,
                                      color: sageGreenText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            pw.SizedBox(height: 4),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 12),

                // ── 4. Bill Adjustments & Details Table ───────────────
                pw.Container(
                  decoration: pw.BoxDecoration(
                    color: cardBgColor,
                    borderRadius: pw.BorderRadius.circular(10),
                    border: pw.Border.all(color: borderColor, width: 0.9),
                  ),
                  child: pw.Column(
                    children: [
                      // Header Band
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: pw.BoxDecoration(
                          color: terracotta,
                          borderRadius: const pw.BorderRadius.only(
                            topLeft: pw.Radius.circular(9),
                            topRight: pw.Radius.circular(9),
                          ),
                        ),
                        child: pw.Row(
                          children: [
                            pw.Text(
                              'Bill Adjustments & Details',
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Table Column Headers
                      pw.Container(
                        color: PdfColor.fromInt(0xFFF7F2ED),
                        padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        child: pw.Row(
                          children: [
                            pw.Expanded(
                              flex: 2,
                              child: pw.Text(
                                'Date',
                                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: mutedGrey),
                              ),
                            ),
                            pw.Expanded(
                              flex: 5,
                              child: pw.Text(
                                'Description',
                                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: mutedGrey),
                              ),
                            ),
                            pw.Expanded(
                              flex: 2,
                              child: pw.Center(
                                child: pw.Text(
                                  'Type',
                                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: mutedGrey),
                                ),
                              ),
                            ),
                            pw.Expanded(
                              flex: 2,
                              child: pw.Align(
                                alignment: pw.Alignment.centerRight,
                                child: pw.Text(
                                  'Amount',
                                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: mutedGrey),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Items
                      ..._buildAdjustmentRows(
                        bill: bill,
                        monthShort: monthShort,
                        formatCurrency: formatCurrency,
                        borderColor: borderColor,
                        charcoal: charcoal,
                        mutedGrey: mutedGrey,
                        deductionGreen: deductionGreen,
                        amberOrange: amberOrange,
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 10),

                // ── 5. Note Banner ───────────────────────────────────
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: pw.BoxDecoration(
                    color: noteBg,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: noteBorder, width: 0.8),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Container(
                        width: 14,
                        height: 14,
                        margin: const pw.EdgeInsets.only(right: 8),
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          color: PdfColor.fromInt(0xFFE8C488),
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            '!',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.RichText(
                          text: pw.TextSpan(
                            children: [
                              pw.TextSpan(
                                text: 'Note: ',
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColor.fromInt(0xFF8D621B),
                                ),
                              ),
                              pw.TextSpan(
                                text: 'If you have any queries regarding this bill or skips, please contact the mess owner directly.',
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  color: PdfColor.fromInt(0xFF8D621B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                pw.Spacer(),

                // ── 6. Warm Footer & Contact Owner ───────────────────
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(top: pw.BorderSide(color: borderColor, width: 0.8)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      // Warm Quote
                      pw.Row(
                        children: [
                          pw.Text(
                            'Good Food Builds Better Tomorrows',
                            style: pw.TextStyle(
                              fontSize: 9.5,
                              fontWeight: pw.FontWeight.bold,
                              color: terracotta,
                            ),
                          ),
                          pw.SizedBox(width: 4),
                          pw.Text(
                            '• Mezzo',
                            style: pw.TextStyle(fontSize: 8.5, color: mutedGrey),
                          ),
                        ],
                      ),
                      // Contact Owner
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Contact Owner',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: charcoal,
                            ),
                          ),
                          pw.SizedBox(height: 1),
                          pw.Text(
                            mess?.ownerPhone.isNotEmpty == true ? mess!.ownerPhone : '+91 98765 43210',
                            style: pw.TextStyle(fontSize: 8, color: mutedGrey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Mezzo_Bill_${monthName}_${bill.year}.pdf',
    );
  }

  static Future<void> generateAndDownloadInvoice(
    BillModel bill, {
    StudentModel? student,
    MessModel? mess,
    MealPlanModel? plan,
  }) =>
      generateAndDownloadBill(bill, student: student, mess: mess, plan: plan);

  static pw.Widget _buildSummaryItem({
    required String label,
    required String subtitle,
    required String value,
    required PdfColor valueColor,
    required bool isBold,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 9.5,
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: PdfColor.fromInt(0xFF1C2E24),
              ),
            ),
            pw.Text(
              subtitle,
              style: pw.TextStyle(
                fontSize: 7.5,
                color: PdfColor.fromInt(0xFF6B7280),
              ),
            ),
          ],
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 10.5,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  static List<pw.Widget> _buildAdjustmentRows({
    required BillModel bill,
    required String monthShort,
    required String Function(num amount, {bool showSign}) formatCurrency,
    required PdfColor borderColor,
    required PdfColor charcoal,
    required PdfColor mutedGrey,
    required PdfColor deductionGreen,
    required PdfColor amberOrange,
  }) {
    final rows = <pw.Widget>[];

    // Green Pill
    final greenPillBg = PdfColor.fromInt(0xFFE8F5E9);
    final greenPillText = PdfColor.fromInt(0xFF2E7D32);
    // Amber Pill
    final amberPillBg = PdfColor.fromInt(0xFFFFF3E0);
    final amberPillText = PdfColor.fromInt(0xFFC25E00);
    // Blue Pill
    final bluePillBg = PdfColor.fromInt(0xFFE3F2FD);
    final bluePillText = PdfColor.fromInt(0xFF1565C0);
    // Teal Pill
    final tealPillBg = PdfColor.fromInt(0xFFE0F2F1);
    final tealPillText = PdfColor.fromInt(0xFF00695C);

    // 1. Prorated Discount
    if (bill.proratedDiscount > 0) {
      rows.add(
        _buildTableRow(
          date: '01 $monthShort ${bill.year}',
          title: 'Joined Late Discount',
          subtitle: 'Prorated deduction for joining mid-month',
          badgeText: 'Discount',
          badgeBg: greenPillBg,
          badgeColor: greenPillText,
          amount: '- ${formatCurrency(bill.proratedDiscount)}',
          amountColor: greenPillText,
          borderColor: borderColor,
          charcoal: charcoal,
          mutedGrey: mutedGrey,
        ),
      );
    }

    // 2. Itemized Deductions / Extra Fees
    for (final d in bill.deductions) {
      final dateStr = '${d.date.day} ${_shortMonths[d.date.month]} ${d.date.year}';
      if (d.type == 'extra_fee') {
        final feeName = (d.mealSlot.isNotEmpty && d.mealSlot != 'general' && d.mealSlot != 'noon')
            ? d.mealSlot
            : 'Additional charge added by owner';
        rows.add(
          _buildTableRow(
            date: dateStr,
            title: feeName,
            subtitle: 'Extra Fee applied to bill',
            badgeText: 'Extra Fee',
            badgeBg: amberPillBg,
            badgeColor: amberPillText,
            amount: '+ ${formatCurrency(d.amount)}',
            amountColor: amberPillText,
            borderColor: borderColor,
            charcoal: charcoal,
            mutedGrey: mutedGrey,
          ),
        );
      } else if (d.type == 'guest') {
        rows.add(
          _buildTableRow(
            date: dateStr,
            title: 'Guest Meal (${d.mealSlot})',
            subtitle: 'Additional guest dining charges',
            badgeText: 'Guest',
            badgeBg: bluePillBg,
            badgeColor: bluePillText,
            amount: '+ ${formatCurrency(d.amount)}',
            amountColor: bluePillText,
            borderColor: borderColor,
            charcoal: charcoal,
            mutedGrey: mutedGrey,
          ),
        );
      } else if (d.type == 'carry_forward_credit') {
        rows.add(
          _buildTableRow(
            date: dateStr,
            title: 'Prior Month Skip Credit',
            subtitle: 'Carried forward from previous cycle',
            badgeText: 'Credit',
            badgeBg: greenPillBg,
            badgeColor: greenPillText,
            amount: '- ${formatCurrency(d.amount.abs())}',
            amountColor: greenPillText,
            borderColor: borderColor,
            charcoal: charcoal,
            mutedGrey: mutedGrey,
          ),
        );
      } else if (d.type == 'prorated_discount') {
        // Handled above or separately
        if (bill.proratedDiscount == 0) {
          rows.add(
            _buildTableRow(
              date: dateStr,
              title: 'Prorated Late Join',
              subtitle: 'Calculated pro-rated credit',
              badgeText: 'Discount',
              badgeBg: greenPillBg,
              badgeColor: greenPillText,
              amount: '- ${formatCurrency(d.amount.abs())}',
              amountColor: greenPillText,
              borderColor: borderColor,
              charcoal: charcoal,
              mutedGrey: mutedGrey,
            ),
          );
        }
      } else {
        // Standard meal skip rebate
        rows.add(
          _buildTableRow(
            date: dateStr,
            title: 'Skipped Meal (${d.mealSlot})',
            subtitle: 'Rebate credited to bill',
            badgeText: 'Skip Rebate',
            badgeBg: tealPillBg,
            badgeColor: tealPillText,
            amount: '- ${formatCurrency(d.amount.abs())}',
            amountColor: tealPillText,
            borderColor: borderColor,
            charcoal: charcoal,
            mutedGrey: mutedGrey,
          ),
        );
      }
    }

    // 3. Current month skips note/row if present
    if (bill.currentMonthSkipsCount > 0) {
      rows.add(
        _buildTableRow(
          date: '$monthShort ${bill.year}',
          title: 'Current Month Skips (${bill.currentMonthSkipsCount} meals)',
          subtitle: 'Logged - to be credited to next month bill',
          badgeText: 'Next Bill',
          badgeBg: amberPillBg,
          badgeColor: amberPillText,
          amount: formatCurrency(bill.currentMonthSkipsAmount),
          amountColor: amberPillText,
          borderColor: borderColor,
          charcoal: charcoal,
          mutedGrey: mutedGrey,
        ),
      );
    }

    // Fallback if empty
    if (rows.isEmpty) {
      rows.add(
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: pw.Center(
            child: pw.Text(
              'No special adjustments or extra fees for this billing cycle.',
              style: pw.TextStyle(
                fontSize: 8.5,
                color: mutedGrey,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ),
        ),
      );
    }

    return rows;
  }

  static pw.Widget _buildTableRow({
    required String date,
    required String title,
    required String subtitle,
    required String badgeText,
    required PdfColor badgeBg,
    required PdfColor badgeColor,
    required String amount,
    required PdfColor amountColor,
    required PdfColor borderColor,
    required PdfColor charcoal,
    required PdfColor mutedGrey,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 6.5),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: borderColor, width: 0.5)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              date,
              style: pw.TextStyle(
                fontSize: 8,
                color: charcoal,
              ),
            ),
          ),
          pw.Expanded(
            flex: 5,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                    color: charcoal,
                  ),
                ),
                pw.Text(
                  subtitle,
                  style: pw.TextStyle(
                    fontSize: 7,
                    color: mutedGrey,
                  ),
                ),
              ],
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Center(
              child: _buildBadge(badgeText, badgeBg, badgeColor),
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                amount,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: amountColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildBadge(String text, PdfColor bgColor, PdfColor textColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 7,
          fontWeight: pw.FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
