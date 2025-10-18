import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:spreadlee/domain/invoice_model.dart';

class InvoiceDownloadService {
  static Future<void> generateAndDownloadPdf({
    required BuildContext context,
    required InvoiceModel invoice,
    bool isBankTransfer = false,
  }) async {
    try {
      if (isBankTransfer) {
        await _generateAndShareBankTransferPdf(context, invoice);
      } else {
        await _generateAndSaveRegularPdf(context, invoice);
      }
    } catch (e) {
      if (kDebugMode) {
        print('PDF Generation Error: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to generate PDF'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static Future<void> _generateAndShareBankTransferPdf(
      BuildContext context, InvoiceModel invoice) async {
    final pdf = pw.Document();

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          mainAxisSize: pw.MainAxisSize.max,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Status Banner
            pw.Row(
              mainAxisSize: pw.MainAxisSize.max,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Container(
                  width: 191,
                  decoration: pw.BoxDecoration(
                    color: _getPdfStatusColor(invoice.invoiceStatus),
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  alignment: pw.Alignment.center,
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 4, horizontal: 8),
                    child: pw.Text(
                      _getStatusMessage(invoice.invoiceStatus),
                      style: const pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 16),

            // Invoice ID
            pw.Center(
              child: pw.Text(
                'Invoice ID: ${invoice.invoice_id?.toString() ?? 'N/A'}',
                style: const pw.TextStyle(fontSize: 16),
              ),
            ),

            pw.SizedBox(height: 16),

            // Company Details
            _buildPdfSectionHeader('1st Party Details:'),
            pw.SizedBox(height: 16),
            _buildPdfDetailRow(
                'Company Name:', invoice.invoiceCompanyRef.companyName),
            _buildPdfDetailRow(
                'Commercial Number:',
                invoice.invoiceCompanyRef.commercialNumber?.toString() ??
                    'N/A'),
            _buildPdfDetailRow(
                'Commercial Name:', invoice.invoiceCompanyRef.commercialName),
            _buildPdfDetailRow(
                'VAT Number:', invoice.invoiceCompanyRef.vATNumber ?? '0'),

            pw.SizedBox(height: 16),

            // 2nd Party Details
            _buildPdfSectionHeader('2nd Party Details:'),
            pw.SizedBox(height: 16),
            _buildPdfDetailRow(
                'Company Name:', invoice.invoiceCustomerCompanyRef.companyName),
            _buildPdfDetailRow(
                'Commercial Number:',
                invoice.invoiceCustomerCompanyRef.commercialNumber
                        ?.toString() ??
                    'N/A'),
            _buildPdfDetailRow('Commercial Name:',
                invoice.invoiceCustomerCompanyRef.commercialName),
            _buildPdfDetailRow('VAT Number:',
                invoice.invoiceCustomerCompanyRef.vATNumber ?? '0'),

            pw.SizedBox(height: 16),

            // Service Description
            _buildPdfSectionHeader('Service Description:'),
            pw.SizedBox(height: 16),
            _buildPdfDetailRow('Description', invoice.invoiceDescription),
            _buildPdfDetailRow('Amount:',
                '${invoice.currency ?? 'SAR'} ${invoice.invoiceAmount.toStringAsFixed(2)}'),
            _buildPdfDetailRow('VAT:', '${invoice.invoiceVat1}%'),
            _buildPdfDetailRow('Total:',
                '${invoice.currency ?? 'SAR'} ${invoice.invoiceTotal.toStringAsFixed(2)}'),

            pw.SizedBox(height: 8),
            pw.Divider(),
            pw.SizedBox(height: 8),

            _buildPdfDetailRow(
              'Grand total:',
              '${invoice.currency ?? 'SAR'} ${invoice.invoiceGrandTotal.toStringAsFixed(3)}',
              isBold: true,
            ),

            // pw.SizedBox(height: 16),

            // // Bank Account Details
            // _buildPdfSectionHeader('Bank Account Details'),
            // pw.SizedBox(height: 16),
            // _buildPdfDetailRow('Bank Name', invoice.bankName ?? ''),
            // _buildPdfDetailRow('Account Name', invoice.accountName ?? ''),
            // _buildPdfDetailRow('Account No', invoice.accountNumber ?? ''),
            // _buildPdfDetailRow('Account No. IBAN', invoice.iban ?? ''),
            // _buildPdfDetailRow('Swift Code', invoice.invoiceSwift ?? ''),
          ],
        );
      },
    ));

    // Share the PDF file
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'invoice_${invoice.invoice_id?.toString() ?? 'unknown'}.pdf',
    );
  }

  static Future<void> _generateAndSaveRegularPdf(
      BuildContext context, InvoiceModel invoice) async {
    // Check if permission is already granted
    var status = await Permission.storage.status;
    if (status.isDenied) {
      // Request permission
      status = await Permission.storage.request();
    }

    if (status.isGranted) {
      final pdf = pw.Document();

      // Load a font that supports Unicode
      final font = await rootBundle.load("assets/fonts/Amiri-Regular.ttf");
      final ttf = pw.Font.ttf(font);

      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            mainAxisSize: pw.MainAxisSize.max,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Status Banner
              pw.Row(
                mainAxisSize: pw.MainAxisSize.max,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Container(
                    width: 191,
                    decoration: pw.BoxDecoration(
                      color: _getPdfStatusColor(invoice.invoiceStatus),
                      borderRadius: pw.BorderRadius.circular(10),
                    ),
                    alignment: pw.Alignment.center,
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      child: pw.Text(
                        _getStatusMessage(invoice.invoiceStatus),
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 10,
                          font: ttf,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 16),

              // Invoice ID
              pw.Center(
                child: pw.Text(
                  'Invoice ID: ${invoice.invoice_id?.toString() ?? 'N/A'}',
                  style: pw.TextStyle(fontSize: 16, font: ttf),
                ),
              ),

              pw.SizedBox(height: 16),

              // Company Details
              _buildPdfSectionHeader('1st Party Details:'),
              pw.SizedBox(height: 16),
              _buildPdfDetailRow(
                  'Company Name:', invoice.invoiceCompanyRef.companyName,
                  font: ttf),
              _buildPdfDetailRow(
                  'Commercial Number:',
                  invoice.invoiceCompanyRef.commercialNumber?.toString() ??
                      'N/A',
                  font: ttf),
              _buildPdfDetailRow(
                  'Commercial Name:', invoice.invoiceCompanyRef.commercialName,
                  font: ttf),
              _buildPdfDetailRow(
                  'VAT Number:', invoice.invoiceCompanyRef.vATNumber ?? '0',
                  font: ttf),

              pw.SizedBox(height: 16),

              // 2nd Party Details
              _buildPdfSectionHeader('2nd Party Details:'),
              pw.SizedBox(height: 16),
              _buildPdfDetailRow('Company Name:',
                  invoice.invoiceCustomerCompanyRef.companyName,
                  font: ttf),
              _buildPdfDetailRow(
                  'Commercial Number:',
                  invoice.invoiceCustomerCompanyRef.commercialNumber
                          ?.toString() ??
                      'N/A',
                  font: ttf),
              _buildPdfDetailRow('Commercial Name:',
                  invoice.invoiceCustomerCompanyRef.commercialName,
                  font: ttf),
              _buildPdfDetailRow('VAT Number:',
                  invoice.invoiceCustomerCompanyRef.vATNumber ?? '0',
                  font: ttf),

              pw.SizedBox(height: 16),

              // Service Description
              _buildPdfSectionHeader('Service Description:'),
              pw.SizedBox(height: 16),
              _buildPdfDetailRow('Description', invoice.invoiceDescription,
                  font: ttf),
              _buildPdfDetailRow('Amount:',
                  '${invoice.currency ?? 'SAR'} ${invoice.invoiceAmount.toStringAsFixed(2)}',
                  font: ttf),
              _buildPdfDetailRow('VAT:', '${invoice.invoiceVat1}%', font: ttf),
              _buildPdfDetailRow('Total:',
                  '${invoice.currency ?? 'SAR'} ${invoice.invoiceTotal.toStringAsFixed(2)}',
                  font: ttf),
              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.SizedBox(height: 8),
              _buildPdfDetailRow(
                'Grand total:',
                '${invoice.currency ?? 'SAR'} ${invoice.invoiceGrandTotal.toStringAsFixed(3)}',
                isBold: true,
                font: ttf,
              ),
            ],
          );
        },
      ));

      // Get the application documents directory
      final directory = await getApplicationDocumentsDirectory();
      final file = File(
          '${directory.path}/invoice_${invoice.invoice_id?.toString() ?? 'unknown'}.pdf');

      // Save the PDF file
      await file.writeAsBytes(await pdf.save());

      // Open the PDF file
      final result = await OpenFile.open(file.path);
      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to open PDF file'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else if (status.isPermanentlyDenied) {
      // Show a dialog to open app settings
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Permission Required'),
          content: const Text(
              'Storage permission is required to save PDF files. Please enable it in app settings.'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Storage permission is required to save PDF files'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static PdfColor _getPdfStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return PdfColor.fromHex('#4CAF50'); // Green
      case 'unpaid':
        return PdfColor.fromHex('#FF0000'); // Red
      case 'expired':
        return PdfColor.fromHex('#D3D3D3'); // Grey
      case 'under review':
        return PdfColor.fromHex(
            '#F9CF58'); // Under review (matches ColorManager.primaryunderreview)
      default:
        return PdfColor.fromHex('#D3D3D3');
    }
  }

  static String _getStatusMessage(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'This invoice is paid';
      case 'unpaid':
        return 'This invoice is unpaid';
      case 'expired':
        return 'This invoice has expired';
      case 'under review':
        return 'This invoice is under review';
      default:
        return 'Invoice status: $status';
    }
  }

  static pw.Widget _buildPdfSectionHeader(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 10),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#7e9688'),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      alignment: pw.Alignment.center,
      child: pw.Text(
        title,
        style: const pw.TextStyle(
          color: PdfColors.white,
          fontSize: 14,
        ),
      ),
    );
  }

  static pw.Widget _buildPdfDetailRow(String label, String value,
      {bool isBold = false, pw.Font? font}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                font: font,
              ),
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 12,
                color: PdfColor.fromHex('#667085'),
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                font: font,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
