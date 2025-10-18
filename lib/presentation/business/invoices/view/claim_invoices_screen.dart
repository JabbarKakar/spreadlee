import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:spreadlee/domain/invoice_model.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';

class ClaimInvoicesScreen extends StatelessWidget {
  final InvoiceModel invoice;

  const ClaimInvoicesScreen({Key? key, required this.invoice})
      : super(key: key);

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return const Color(0xFF4CAF50); // Green
      case 'unpaid':
        return Colors.red; // Grey
      case 'expired':
        return ColorManager.lightGrey; // Grey
      case 'under review':
        return ColorManager.primaryunderreview; // Blue
      default:
        return ColorManager.lightGrey;
    }
  }

  String _getStatusMessage(String status) {
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

  Future<void> _generateAndDownloadPdf(BuildContext context) async {
    try {
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

                pw.SizedBox(height: 8),

                // Invoice ID
                pw.Center(
                  child: pw.Text(
                    'Invoice ID: ${invoice.invoice_id}',
                    style: pw.TextStyle(fontSize: 16, font: ttf),
                  ),
                ),

                pw.SizedBox(height: 6),

                // Company Details
                _buildPdfSectionHeader('1st Party Details:'),
                pw.SizedBox(height: 16),
                _buildPdfDetailRow(
                    'Company Name:', invoice.invoiceCompanyRef.companyName,
                    font: ttf),
                _buildPdfDetailRow('Commercial Name:',
                    invoice.invoiceCompanyRef.commercialName,
                    font: ttf),
                _buildPdfDetailRow(
                    'Commercial Number:',
                    invoice.invoiceCompanyRef.commercialNumber?.toString() ??
                        'N/A',
                    font: ttf),
                _buildPdfDetailRow(
                    'VAT Number:', invoice.invoiceCompanyRef.vATNumber ?? '0',
                    font: ttf),

                pw.SizedBox(height: 4),

                // 2nd Party Details
                _buildPdfSectionHeader('2nd Party Details:'),
                pw.SizedBox(height: 8),
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

                pw.SizedBox(height: 6),

                // Service Description
                _buildPdfSectionHeader('Service Description:'),
                pw.SizedBox(height: 4),
                _buildPdfDetailRow('Description', invoice.invoiceDescription,
                    font: ttf),
                _buildPdfDetailRow('Amount:',
                    '${invoice.currency ?? 'SAR'} ${invoice.invoiceAmount.toStringAsFixed(2)}',
                    font: ttf),
                _buildPdfDetailRow('VAT:', '${invoice.invoiceVat1}%',
                    font: ttf),
                _buildPdfDetailRow('Total:',
                    '${invoice.currency ?? 'SAR'} ${invoice.invoiceTotal.toStringAsFixed(2)}',
                    font: ttf),
                _buildPdfDetailRow('App Fees 3%:', '${invoice.appFeeAmount}',
                    font: ttf),
                _buildPdfDetailRow('VAT 15%:', '${invoice.vat2Amount}',
                    font: ttf),
                pw.Divider(),
                _buildPdfDetailRow(
                  'Grand total:',
                  '${invoice.currency ?? 'SAR'} ${invoice.invoice_total_with_app_fee.toStringAsFixed(3)}',
                  isBold: true,
                  font: ttf,
                ),
              ],
            );
          },
        ));

        // Get the application documents directory
        final directory = await getApplicationDocumentsDirectory();
        final file =
            File('${directory.path}/invoice_${invoice.invoiceSubRef}.pdf');

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

  PdfColor _getPdfStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return PdfColor.fromHex('#4CAF50');
      case 'unpaid':
        return PdfColor.fromHex('#FF0000');
      case 'expired':
        return PdfColor.fromHex('#98A2B3');
      case 'under review':
        return PdfColor.fromHex('#2196F3');
      default:
        return PdfColor.fromHex('#98A2B3');
    }
  }

  pw.Widget _buildPdfSectionHeader(String title) {
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

  pw.Widget _buildPdfDetailRow(String label, String value,
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

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF8BA793),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Invoices',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_for_offline_outlined,
                color: Colors.black, size: 20),
            onPressed: () => _generateAndDownloadPdf(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                margin:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 110),
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(invoice.invoiceStatus),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  _getStatusMessage(invoice.invoiceStatus),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Invoice ID: ${invoice.invoice_id}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 1st Party Details
                    _buildSectionHeader('1st Party Details: (company)'),
                    const SizedBox(height: 10),
                    _buildDetailRow(
                        'Company Name:', invoice.invoiceCompanyRef.companyName),
                    _buildDetailRow('Commercial Number:',
                        invoice.getFirstPartyCommercialNumberAsString()),
                    _buildDetailRow('Commercial Name:',
                        invoice.invoiceCompanyRef.commercialName),
                    _buildDetailRow(
                      'VAT Number:',
                      invoice.invoiceCompanyRef.vATNumber ?? '0',
                    ),
                    const SizedBox(height: 10),

                    // 2nd Party Details
                    _buildSectionHeader('2nd Party Details:'),
                    const SizedBox(height: 10),
                    _buildDetailRow('Company Name:',
                        invoice.invoiceCustomerCompanyRef.companyName),
                    _buildDetailRow('Commercial Number:',
                        invoice.getSecondPartyCommercialNumberAsString()),
                    _buildDetailRow('Commercial Name:',
                        invoice.invoiceCustomerCompanyRef.commercialName),
                    _buildDetailRow('VAT Number:',
                        invoice.invoiceCustomerCompanyRef.vATNumber ?? '0'),
                    const SizedBox(height: 10),

                    // Service Description
                    _buildSectionHeader('Service Description:'),
                    const SizedBox(height: 10),
                    _buildDetailRow('Description', invoice.invoiceDescription),
                    _buildDetailRow('Amount:',
                        '${invoice.currency ?? 'SAR'} ${invoice.invoiceAmount.toStringAsFixed(2)}'),
                    _buildDetailRow('VAT:', '${invoice.invoiceVat1}%'),
                    _buildDetailRow('Total:',
                        '${invoice.currency ?? 'SAR'} ${invoice.invoiceTotal.toStringAsFixed(2)}'),
                    _buildDetailRow('App Fees 3%:', '${invoice.appFeeAmount}'),
                    _buildDetailRow('VAT 15%:', '${invoice.vat2Amount}'),
                    const SizedBox(height: 4),
                    const Divider(thickness: 1),
                    const SizedBox(height: 2),
                    _buildDetailRow(
                      'Grand total:',
                      '${invoice.currency ?? 'SAR'} ${invoice.invoice_total_with_app_fee.toStringAsFixed(3)}',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
