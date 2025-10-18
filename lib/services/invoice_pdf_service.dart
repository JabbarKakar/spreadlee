import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:spreadlee/domain/invoice_model.dart'
    show InvoiceModel, InvoiceCompanyRef, InvoiceCustomerCompanyRef;
import 'package:printing/printing.dart';

class InvoicePdfService {
  static Future<String> generateAndDownloadInvoice(
    InvoiceModel invoice,
    String? customFileName,
  ) async {
    try {
      print(
          'Starting PDF generation for invoice: ${invoice.invoice_id?.toString() ?? 'N/A'}');

      // Generate PDF
      final pdfBytes = await _generateInvoicePdf(invoice);
      if (pdfBytes.isEmpty) {
        print('Error: Generated PDF is empty');
        return 'Error: Generated PDF is empty';
      }
      print('PDF generated successfully, size: ${pdfBytes.length} bytes');

      // Generate file name
      String fileName = customFileName ??
          'Invoice_${invoice.invoice_id?.toString() ?? 'unknown'}.pdf';
      print('Generated filename: $fileName');

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$fileName';
      print('Saving file to: $filePath');

      final file = File(filePath);

      // Save the file
      await file.writeAsBytes(pdfBytes, flush: true);
      print('File saved successfully');

      // Verify file exists and has content
      if (await file.exists()) {
        final fileSize = await file.length();
        print('File exists, size: $fileSize bytes');
        if (fileSize == 0) {
          print('Error: Saved file is empty');
          return 'Error: Saved file is empty';
        }
      } else {
        print('Error: File does not exist after saving');
        return 'Error: File not saved properly';
      }

      // Open the file
      final result = await OpenFile.open(file.path);
      print('Open file result: $result');

      return 'Download successfully completed!';
    } catch (e, stackTrace) {
      print('Error generating/downloading invoice: $e');
      print('Stack trace: $stackTrace');
      return 'Error downloading file';
    }
  }

  static Future<Uint8List> _generateInvoicePdf(InvoiceModel invoice) async {
    try {
      print('Loading fonts...');
      // Load Arabic font
      final font = await rootBundle.load('assets/fonts/Hacen Tunisia.ttf');
      final arabicFont = pw.Font.ttf(font);
      final fontBold =
          await rootBundle.load('assets/fonts/Hacen Tunisia Bold.ttf');
      final arabicFontBold = pw.Font.ttf(fontBold);
      print('Fonts loaded successfully');

      print('Creating PDF document...');
      final pdf = pw.Document();

      // Verify invoice data
      print('Verifying invoice data...');
      print('Invoice ID: ${invoice.invoice_id?.toString() ?? 'N/A'}');
      print('Company Name: ${invoice.invoiceCompanyRef.companyName}');
      print(
          'Customer Company Name: ${invoice.invoiceCustomerCompanyRef.companyName}');
      print('Amount: ${invoice.invoiceAmount}');
      print('Description: ${invoice.invoiceDescription}');

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(
            bold: arabicFontBold,
          ),
          build: (pw.Context context) {
            print('Building PDF content...');
            return [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Status Container
                  pw.Center(
                    child: _buildStatusContainer(
                        invoice.invoiceStatus, arabicFontBold),
                  ),
                  pw.SizedBox(height: 16),

                  // Invoice ID
                  pw.Center(
                    child: pw.Text(
                      'Invoice ID: ${invoice.invoice_id?.toString() ?? 'N/A'}',
                      style: pw.TextStyle(
                        font: arabicFontBold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 16),

                  // 1st Party Details
                  _buildSectionHeader('1st Party Details', arabicFontBold),
                  pw.SizedBox(height: 16),
                  _buildCompanyDetails(
                    invoice.invoiceCompanyRef,
                    arabicFont,
                  ),
                  pw.SizedBox(height: 16),

                  // 2nd Party Details
                  _buildSectionHeader('2nd Party Details', arabicFontBold),
                  pw.SizedBox(height: 16),
                  _buildCompanyDetails(
                      invoice.invoiceCustomerCompanyRef, arabicFont,
                      isArabic: false),
                  pw.SizedBox(height: 16),

                  // Service Description
                  _buildSectionHeader('Service Description', arabicFontBold),
                  pw.SizedBox(height: 16),
                  pw.Text(
                    fixArabic(invoice.invoiceDescription),
                    style: pw.TextStyle(
                      font: arabicFont,
                      color: PdfColor.fromHex('#667085'),
                      fontSize: 12,
                    ),
                  ),
                  pw.SizedBox(height: 16),

                  // Amount Breakdown
                  _buildAmountBreakdown(invoice, arabicFont, arabicFontBold),
                  pw.SizedBox(height: 16),

                  // Grand Total
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        fixArabic('Grand Total:'),
                        textDirection: pw.TextDirection.rtl,
                        style: pw.TextStyle(
                          font: arabicFontBold,
                          fontSize: 16,
                        ),
                      ),
                      pw.Text(
                        'SAR ${invoice.invoiceGrandTotal}',
                        style: pw.TextStyle(
                          font: arabicFontBold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ];
          },
        ),
      );

      print('Saving PDF to bytes...');
      final bytes = await pdf.save();
      if (bytes.isEmpty) {
        print('Error: Generated PDF bytes are empty');
        throw Exception('Generated PDF is empty');
      }
      print('PDF saved successfully, size: ${bytes.length} bytes');

      await Printing.sharePdf(
        bytes: bytes,
        filename: 'Invoice_${invoice.invoice_id?.toString() ?? 'unknown'}.pdf',
      );

      return bytes;
    } catch (e, stackTrace) {
      print('Error in _generateInvoicePdf: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static pw.Widget _buildStatusContainer(String status, pw.Font boldFont) {
    PdfColor statusColor;
    String statusText;

    switch (status.toLowerCase()) {
      case 'paid':
        statusColor = PdfColors.green;
        statusText = 'This invoice is paid';
        break;
      case 'unpaid':
        statusColor = PdfColors.red;
        statusText = 'This invoice is unpaid';
        break;
      case 'expired':
        statusColor = PdfColor.fromHex('#98A2B3');
        statusText = 'This invoice is expired';
        break;
      case 'under review':
        statusColor = PdfColor.fromHex('#FCC737');
        statusText = 'This invoice is under review';
        break;
      default:
        statusColor = PdfColors.grey;
        statusText = 'Status: $status';
    }

    return pw.Container(
      width: 191,
      decoration: pw.BoxDecoration(
        color: statusColor,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      alignment: pw.Alignment.center,
      child: pw.Text(
        statusText,
        style: pw.TextStyle(
          font: boldFont,
          color: PdfColors.white,
          fontSize: 10,
        ),
      ),
    );
  }

  static pw.Widget _buildSectionHeader(String title, pw.Font arabicFontBold) {
    return pw.Container(
      width: double.infinity,
      height: 44,
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#7e9688'),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      alignment: pw.Alignment.center,
      child: pw.Text(
        title,
        style: pw.TextStyle(
          font: arabicFontBold,
          color: PdfColors.white,
          fontSize: 14,
        ),
      ),
    );
  }

  static pw.Widget _buildCompanyDetails(dynamic company, pw.Font arabicFont,
      {bool isArabic = false}) {
    String companyName;
    String commercialNumber;
    String commercialName;
    String? vatNumber;

    if (company is InvoiceCompanyRef) {
      companyName = company.companyName ?? 'N/A';
      commercialNumber = company.commercialNumber ?? 'N/A';
      commercialName = company.commercialName ?? 'N/A';
      vatNumber = company.vATNumber?.toString();
    } else if (company is InvoiceCustomerCompanyRef) {
      companyName = company.companyName ?? 'N/A';
      commercialNumber = company.commercialNumber ?? 'N/A';
      commercialName = company.commercialName ?? 'N/A';
      vatNumber = company.vATNumber?.toString();
    } else {
      companyName = 'N/A';
      commercialNumber = 'N/A';
      commercialName = 'N/A';
      vatNumber = null;
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildDetailRow('Company Name:', companyName, arabicFont,
            isArabic: true),
        pw.SizedBox(height: 8),
        _buildDetailRow('Commercial Number:', commercialNumber, arabicFont,
            isArabic: isArabic),
        pw.SizedBox(height: 8),
        _buildDetailRow('Commercial Name:', commercialName, arabicFont,
            isArabic: isArabic),
        pw.SizedBox(height: 8),
        _buildDetailRow('VAT Number:', vatNumber ?? 'N/A', arabicFont,
            isArabic: isArabic),
      ],
    );
  }

  static pw.Widget _buildDetailRow(String label, String value, pw.Font font,
      {bool isArabic = false}) {
    if (isArabic) {
      return pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Expanded(
            child: pw.Text(
              fixArabic(label),
              // textDirection: pw.TextDirection.rtl,
              style: pw.TextStyle(
                font: font,
                fontSize: 12,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              fixArabic(value),
              textDirection: pw.TextDirection.rtl,
              style: pw.TextStyle(
                font: font,
                color: PdfColor.fromHex('#667085'),
                fontSize: 12,
              ),
            ),
          ),
        ],
      );
    } else {
      return pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Text(
              label,
              // textDirection: pw.TextDirection.ltr,
              style: pw.TextStyle(
                font: font,
                fontSize: 12,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              textDirection: pw.TextDirection.ltr,
              style: pw.TextStyle(
                font: font,
                color: PdfColor.fromHex('#667085'),
                fontSize: 12,
              ),
            ),
          ),
        ],
      );
    }
  }

  static pw.Widget _buildAmountBreakdown(
      InvoiceModel invoice, pw.Font font, pw.Font boldFont) {
    return pw.Column(
      children: [
        _buildDetailRow('Amount:', 'SAR ${invoice.invoiceAmount}', font),
        pw.SizedBox(height: 8),
        _buildDetailRow('VAT:', '${invoice.invoiceVat1}%', font),
        pw.SizedBox(height: 8),
        _buildDetailRow('Total:', 'SAR ${invoice.invoiceTotal}', font),
      ],
    );
  }

  // Helper for Arabic shaping and bidi
  static String fixArabic(String text) {
    return Bidi.stripHtmlIfNeeded(text);
  }
}
