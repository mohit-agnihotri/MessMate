import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/app_models.dart';

class PdfService {
  static Future<void> generateAndDownloadBill(BillModel bill) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Mess Monthly Bill',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Student ID: ${bill.studentId}',
                style: const pw.TextStyle(fontSize: 14),
              ),
              pw.Text(
                'Billing Period: ${bill.month}/${bill.year}',
                style: const pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 30),

              pw.Text(
                'Bill Summary',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Divider(),
              _buildRow('Basic Monthly Fee', 'Rs ${bill.baseFee.toInt()}'),
              _buildRow(
                'Total Deductions',
                '-Rs ${bill.totalDeductions.toInt()}',
              ),
              _buildRow('Guest Add-ons', '+Rs ${bill.guestAddons.toInt()}'),
              pw.Divider(),
              _buildRow(
                'Final Payable',
                'Rs ${bill.finalPayable.toInt()}',
                isBold: true,
              ),
              pw.SizedBox(height: 30),

              pw.Text(
                'Deduction Breakdown',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Divider(),
              ...bill.deductions.map((d) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        '${d.date.month}/${d.date.day} - ${d.mealSlot} (${d.type})',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.Text(
                        '${d.amount.isNegative ? '-' : '+'}Rs ${d.amount.abs().toInt()}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Mess_Bill_${bill.month}_${bill.year}.pdf',
    );
  }

  static pw.Widget _buildRow(
    String label,
    String value, {
    bool isBold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
