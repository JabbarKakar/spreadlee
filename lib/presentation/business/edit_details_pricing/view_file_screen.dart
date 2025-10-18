import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'dart:io';
import 'dart:typed_data';

class ViewFileScreen extends StatefulWidget {
  const ViewFileScreen({
    super.key,
    this.pricingDetails,
  });

  final String? pricingDetails;

  @override
  State<ViewFileScreen> createState() => _ViewFileScreenState();
}

class _ViewFileScreenState extends State<ViewFileScreen> {
  PdfController? pdfController;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.pricingDetails != null && widget.pricingDetails!.isNotEmpty) {
      _loadPdf();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadPdf() async {
    try {
      final uri = Uri.parse(widget.pricingDetails!);
      final response = await HttpClient().getUrl(uri);
      final httpResponse = await response.close();
      final bytes = await httpResponse.fold<Uint8List>(
        Uint8List(0),
        (previous, element) => Uint8List.fromList([...previous, ...element]),
      );

      if (mounted) {
        setState(() {
          pdfController = PdfController(
            document: PdfDocument.openData(bytes),
          );
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(
            content: Text('Error loading PDF'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
            size: 24.0,
          ),
        ),
        title: Text(
          'PDF View',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.black,
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
              ),
        ),
        centerTitle: false,
        elevation: 0.0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              if (isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (widget.pricingDetails != null &&
                  widget.pricingDetails!.isNotEmpty &&
                  pdfController != null)
                Expanded(
                  child: PdfView(
                    controller: pdfController!,
                    onDocumentLoaded: (document) {
                      setState(() {
                        isLoading = false;
                      });
                    },
                    onDocumentError: (error) {
                      setState(() {
                        isLoading = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(
                          content: Text('Error loading PDF'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    },
                    builders: PdfViewBuilders<DefaultBuilderOptions>(
                      options: const DefaultBuilderOptions(),
                      documentLoaderBuilder: (_) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      pageLoaderBuilder: (_) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorBuilder: (_, error) => Center(
                        child: Text('Error: $error'),
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: Center(
                    child: Text(
                      'No PDF Available.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
