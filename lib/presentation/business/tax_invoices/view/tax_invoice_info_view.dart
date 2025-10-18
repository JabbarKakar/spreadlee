import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdfx/pdfx.dart';
import 'package:spreadlee/core/constant.dart';
import 'package:spreadlee/domain/tax_invoice_model.dart';
import 'package:spreadlee/presentation/resources/color_manager.dart';
import 'package:spreadlee/presentation/resources/string_manager.dart';
import 'package:spreadlee/presentation/resources/values_manager.dart';
import 'package:spreadlee/presentation/widgets/loading_indicator.dart';
import '../utils/pdf_generator.dart';
import '../widget/tax_invoice_info_model.dart';

class TaxInvoiceInfoView extends StatefulWidget {
  const TaxInvoiceInfoView({
    super.key,
    required this.invoice,
    this.pdfData,
  });

  final TaxInvoiceData invoice;
  final Uint8List? pdfData;

  @override
  State<TaxInvoiceInfoView> createState() => _TaxInvoiceInfoViewState();
}

class _TaxInvoiceInfoViewState extends State<TaxInvoiceInfoView> {
  late TaxInvoiceInfoModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  Uint8List? _generatedPdfData;
  bool _isGenerating = false;
  PdfController? _pdfController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _model = TaxInvoiceInfoModel();
    _generatePdfIfNeeded();
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _initializePdfController(Uint8List pdfBytes) async {
    try {
      _pdfController?.dispose();
      _pdfController = PdfController(
        document: PdfDocument.openData(pdfBytes),
      );
      setState(() {
        _errorMessage = null;
      });
    } catch (e) {
      print('Error initializing PDF controller: $e');
      setState(() {
        _errorMessage = 'Error loading PDF: $e';
      });
    }
  }

  Future<void> _generatePdfIfNeeded() async {
    print('TaxInvoiceInfoView - _generatePdfIfNeeded');
    if ((widget.invoice.tax_invoice_pdf == null ||
            widget.invoice.tax_invoice_pdf!.isEmpty) &&
        widget.pdfData == null) {
      print('TaxInvoiceInfoView - Generating new PDF');
      setState(() {
        _isGenerating = true;
        _errorMessage = null;
      });
      try {
        final pdfBytes = await generateTaxInvoicePdf(widget.invoice);
        print('TaxInvoiceInfoView - PDF generated successfully');
        if (mounted) {
          setState(() {
            _generatedPdfData = pdfBytes;
            _isGenerating = false;
          });
          await _initializePdfController(pdfBytes);
        }
      } catch (e) {
        print('TaxInvoiceInfoView - Error generating PDF: $e');
        if (mounted) {
          setState(() {
            _isGenerating = false;
            _errorMessage = 'Error generating PDF: $e';
          });
        }
      }
    } else if (widget.pdfData != null) {
      await _initializePdfController(widget.pdfData!);
    }
  }

  Future<void> _downloadPdf() async {
    if (widget.invoice.tax_invoice_pdf != null &&
        widget.invoice.tax_invoice_pdf!.isNotEmpty) {
      _model.setLoading(true);
      try {
        // Download from network URL
        final response =
            await NetworkAssetBundle(Uri.parse(widget.invoice.tax_invoice_pdf!))
                .load(widget.invoice.tax_invoice_pdf!);
        final bytes = response.buffer.asUint8List();
        await _savePdf(bytes);
        _model.setDownloadStatus('File downloaded successfully');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _model.downloadStatus!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: Constants.fontFamily,
                      color: ColorManager.white,
                    ),
              ),
              duration: const Duration(milliseconds: 4000),
              backgroundColor: ColorManager.success,
            ),
          );
        }
      } catch (e) {
        _model.setDownloadStatus('Error downloading file');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _model.downloadStatus!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: Constants.fontFamily,
                      color: ColorManager.white,
                    ),
              ),
              duration: const Duration(milliseconds: 4000),
              backgroundColor: ColorManager.error,
            ),
          );
        }
      } finally {
        _model.setLoading(false);
      }
    } else {
      // Generate new PDF
      _model.setLoading(true);
      try {
        final pdfBytes = await generateTaxInvoicePdf(widget.invoice);
        await _savePdf(pdfBytes);
        _model.setSavedStatus('File generated and saved successfully');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _model.savedStatus!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: Constants.fontFamily,
                      color: ColorManager.white,
                    ),
              ),
              duration: const Duration(milliseconds: 4000),
              backgroundColor: ColorManager.success,
            ),
          );
        }
      } catch (e) {
        _model.setSavedStatus('Error generating file');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _model.savedStatus!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: Constants.fontFamily,
                      color: ColorManager.white,
                    ),
              ),
              duration: const Duration(milliseconds: 4000),
              backgroundColor: ColorManager.error,
            ),
          );
        }
      } finally {
        _model.setLoading(false);
      }
    }
  }

  Future<void> _savePdf(Uint8List bytes) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File(
        '${directory.path}/tax_invoice_${widget.invoice.invoice_id?.toString() ?? 'unknown'}.pdf',
      );
      await file.writeAsBytes(bytes);

      // Open the file after saving
      final result = await OpenFile.open(file.path);
      if (result.type != ResultType.done) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error opening file',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: Constants.fontFamily,
                      color: ColorManager.white,
                    ),
              ),
              duration: const Duration(milliseconds: 4000),
              backgroundColor: ColorManager.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving file',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: Constants.fontFamily,
                    color: ColorManager.white,
                  ),
            ),
            duration: const Duration(milliseconds: 4000),
            backgroundColor: ColorManager.error,
          ),
        );
      }
      rethrow;
    }
  }

  Widget _buildPdfViewer() {
    print('TaxInvoiceInfoView - _buildPdfViewer');
    print('Network PDF URL: ${widget.invoice.tax_invoice_pdf}');
    print('Has PDF Data: ${widget.pdfData != null}');
    print('Has Generated PDF: ${_generatedPdfData != null}');
    print('Is Generating: $_isGenerating');

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: Constants.fontFamily,
                    color: ColorManager.error,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSize.s16),
            ElevatedButton(
              onPressed: _generatePdfIfNeeded,
              child: Text(
                'Try Again',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: Constants.fontFamily,
                      color: ColorManager.white,
                    ),
              ),
            ),
          ],
        ),
      );
    }

    if (_isGenerating) {
      return const Center(
        child: LoadingIndicator(size: AppSize.s40),
      );
    }

    if (_pdfController != null) {
      return PdfView(
        controller: _pdfController!,
        scrollDirection: Axis.vertical,
        pageSnapping: true,
        builders: PdfViewBuilders<DefaultBuilderOptions>(
          options: const DefaultBuilderOptions(),
          documentLoaderBuilder: (_) =>
              const Center(child: LoadingIndicator(size: AppSize.s40)),
          pageLoaderBuilder: (_) =>
              const Center(child: LoadingIndicator(size: AppSize.s20)),
          errorBuilder: (_, error) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Error displaying PDF: $error',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: Constants.fontFamily,
                        color: ColorManager.error,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSize.s16),
                ElevatedButton(
                  onPressed: _generatePdfIfNeeded,
                  child: Text(
                    'Try Again',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: Constants.fontFamily,
                          color: ColorManager.white,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (widget.invoice.tax_invoice_pdf != null &&
        widget.invoice.tax_invoice_pdf!.isNotEmpty) {
      return FutureBuilder<Uint8List>(
        future: NetworkAssetBundle(Uri.parse(widget.invoice.tax_invoice_pdf!))
            .load(widget.invoice.tax_invoice_pdf!)
            .then((response) => response.buffer.asUint8List()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: LoadingIndicator(size: AppSize.s40));
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error loading PDF: ${snapshot.error}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: Constants.fontFamily,
                          color: ColorManager.error,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSize.s16),
                  ElevatedButton(
                    onPressed: _generatePdfIfNeeded,
                    child: Text(
                      'Try Again',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontFamily: Constants.fontFamily,
                            color: ColorManager.white,
                          ),
                    ),
                  ),
                ],
              ),
            );
          }
          if (snapshot.hasData) {
            _initializePdfController(snapshot.data!);
            return const Center(child: LoadingIndicator(size: AppSize.s40));
          }
          return const Center(child: Text('No PDF data available'));
        },
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppStrings.noPdfAvailable,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: Constants.fontFamily,
                  color: ColorManager.gray400,
                ),
          ),
          const SizedBox(height: AppSize.s16),
          ElevatedButton(
            onPressed: _generatePdfIfNeeded,
            child: Text(
              'Generate PDF',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: Constants.fontFamily,
                    color: ColorManager.white,
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
      key: scaffoldKey,
      backgroundColor: ColorManager.gray50,
      appBar: AppBar(
        backgroundColor: ColorManager.white,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: ColorManager.black,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppStrings.taxInvoicesTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontFamily: Constants.fontFamily,
                color: ColorManager.black,
                fontSize: AppSize.s16,
                fontWeight: FontWeight.w500,
              ),
        ),
        actions: [
          if (_model.isLoading || _isGenerating)
            const Padding(
              padding: EdgeInsets.all(AppPadding.p16),
              child: LoadingIndicator(size: AppSize.s20),
            )
          else
            IconButton(
              icon: const Icon(Icons.download),
              color: ColorManager.black,
              onPressed: _downloadPdf,
            ),
        ],
        centerTitle: false,
        elevation: 0,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            _buildPdfViewer(),
          ],
        ),
      ),
    );
  }
}
