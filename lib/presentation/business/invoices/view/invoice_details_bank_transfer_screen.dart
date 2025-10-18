import 'package:flutter/material.dart';
import 'package:spreadlee/domain/invoice_model.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class InvoiceDetailsBankTransferBusinessScreen extends StatelessWidget {
  final InvoiceModel invoice;
  final Map<String, dynamic>? companyDetails;

  const InvoiceDetailsBankTransferBusinessScreen({
    Key? key,
    required this.invoice,
    this.companyDetails,
  }) : super(key: key);

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
      case 'under_review':
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
      case 'under_review':
        return 'This invoice is under review';
      default:
        return 'Invoice status: $status';
    }
  }

  Future<void> _generateAndDownloadPdf() async {
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
            _buildPdfDetailRow('Commercial Number:',
                invoice.getFirstPartyCommercialNumberAsString()),
            _buildPdfDetailRow(
                'Commercial Name:', invoice.invoiceCompanyRef.commercialName),
            _buildPdfDetailRow(
                'VAT Number:', invoice.invoiceCompanyRef.vATNumber ?? ''),

            pw.SizedBox(height: 16),

            // 2nd Party Details
            _buildPdfSectionHeader('2nd Party Details:'),
            pw.SizedBox(height: 16),
            _buildPdfDetailRow(
                'Company Name:', invoice.invoiceCustomerCompanyRef.companyName),
            _buildPdfDetailRow('Commercial Number:',
                invoice.getSecondPartyCommercialNumberAsString()),
            _buildPdfDetailRow('Commercial Name:',
                invoice.invoiceCustomerCompanyRef.commercialName,),
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
            // _buildPdfDetailRow('App Fees:', '${invoice.invoiceAppFee}%'),
            // _buildPdfDetailRow('VAT:', '${invoice.invoiceVat2}%'),

            pw.SizedBox(height: 8),
            pw.Divider(),
            pw.SizedBox(height: 8),

            _buildPdfDetailRow(
              'Grand total:',
              '${invoice.currency ?? 'SAR'} ${invoice.invoiceGrandTotal.toStringAsFixed(3)}',
              isBold: true,
            ),

            pw.SizedBox(height: 16),

            // // Bank Account Details
            // _buildPdfSectionHeader('Bank Account Details'),
            // pw.SizedBox(height: 16),
            // _buildPdfDetailRow('Bank Name', 'Riyadh Bank'),
            // _buildPdfDetailRow(
            //     'Account Name', 'شركة الربط العالمي لخدمات الدعاية و الاعلان'),
            // _buildPdfDetailRow('Account No', '2581382949940'),
            // _buildPdfDetailRow('Account No. IBAN', 'SA0720000002581382949940'),
            // _buildPdfDetailRow('Swift Code', 'RIBLSARI'),
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

  PdfColor _getPdfStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return PdfColor.fromHex('#4CAF50');
      case 'unpaid':
        return PdfColor.fromHex('#98A2B3');
      case 'expired':
        return PdfColor.fromHex('#98A2B3');
      case 'under review':
        return PdfColor.fromHex(
            '#FFA500'); // Using orange color for under review status
      case 'under_review':
        return PdfColor.fromHex(
            '#FFA500'); // Using orange color for under review status
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
      {bool isBold = false}) {
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
            onPressed: _generateAndDownloadPdf,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                        'Company Name:', invoice.invoiceCompanyRef.companyName),
                    _buildDetailRow('Commercial Number:',
                        invoice.getFirstPartyCommercialNumberAsString()),
                    _buildDetailRow('Commercial Name:',
                        invoice.invoiceCompanyRef.commercialName),
                    _buildDetailRow('VAT Number:',
                        invoice.invoiceCompanyRef.vATNumber ?? ''),
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
                    // _buildDetailRow('App Fees:', '${invoice.invoiceAppFee}%'),
                    // _buildDetailRow('VAT:', '${invoice.invoiceVat2}%'),
                    const SizedBox(height: 4),
                    const Divider(thickness: 1),
                    const SizedBox(height: 2),
                    _buildDetailRow(
                      'Grand total:',
                      '${invoice.currency ?? 'SAR'} ${invoice.invoiceGrandTotal.toStringAsFixed(3)}',
                    ),
                    const SizedBox(height: 10),

                    // Bank Account Details
                    _buildSectionHeader('Bank Account Details'),
                    const SizedBox(height: 10),
                    _buildDetailRow('Bank Name', 'Riyadh Bank'),
                    _buildDetailRow('Account Name',
                        'شركة الربط العالمي لخدمات الدعاية و الاعلان'),
                    _buildDetailRow('Account No', '2581382949940'),
                    _buildDetailRow(
                        'Account No. IBAN', 'SA0720000002581382949940'),
                    _buildDetailRow('Swift Code', 'RIBLSARI'),
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
